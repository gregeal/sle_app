import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'openai_realtime_api.dart';
import 'realtime_interview_prompt.dart';
import 'realtime_voice_session.dart';

class OpenAiRealtimeVoiceSession implements RealtimeVoiceSession {
  OpenAiRealtimeVoiceSession({
    required this.api,
    this.model = defaultRealtimeModel,
    this.voice = defaultRealtimeVoice,
  });

  final OpenAiRealtimeApi api;
  final String model;
  final String voice;
  final _events = StreamController<RealtimeVoiceEvent>.broadcast();

  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  MediaStream? _localStream;
  MediaStream? _fallbackRemoteStream;
  RTCVideoRenderer? _remoteAudioRenderer;
  Completer<void>? _channelReady;
  Future<void>? _connectFuture;
  Future<void>? _closeFuture;
  Future<void>? _releaseFuture;
  var _muted = false;
  var _closed = false;
  var _openingSent = false;

  @override
  Stream<RealtimeVoiceEvent> get events => _events.stream;

  @override
  bool get isMuted => _muted;

  @override
  Future<void> connect() {
    if (_closed) {
      return Future.error(
        const RealtimeVoiceException('Cette session est déjà terminée.'),
      );
    }
    final pending = _connectFuture;
    if (pending != null) return pending;

    // Keep exactly one bootstrap in flight. In particular, concurrent taps
    // must not mint multiple secrets or open multiple microphone captures.
    late final Future<void> tracked;
    tracked = _connect().whenComplete(() {
      if (identical(_connectFuture, tracked) && _peerConnection == null) {
        _connectFuture = null;
      }
    });
    _connectFuture = tracked;
    return tracked;
  }

  Future<void> _connect() async {
    _emit(const RealtimeActivityEvent(RealtimeVoiceActivity.connecting));

    try {
      // Authenticate and enforce broker quota before prompting for microphone
      // permission. A rejected secret request should never activate the mic.
      final clientSecret = await api.createClientSecret(
        model: model,
        voice: voice,
      );
      _ensureOpen();

      // flutter_webrtc creates the web audio element from an initialized
      // renderer. Assigning the remote MediaStream below is also important on
      // native platforms; merely enabling the incoming track is insufficient.
      final renderer = RTCVideoRenderer();
      _remoteAudioRenderer = renderer;
      await renderer.initialize();
      _ensureOpen();

      final localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });
      _localStream = localStream;
      _ensureOpen();

      final peer = await createPeerConnection({'sdpSemantics': 'unified-plan'});
      _peerConnection = peer;
      _ensureOpen();
      peer.onConnectionState = _handleConnectionState;
      peer.onTrack = (event) {
        if (event.track.kind == 'audio') {
          unawaited(_attachRemoteAudio(event));
        }
      };

      for (final track in localStream.getAudioTracks()) {
        track.enabled = !_muted;
        await peer.addTrack(track, localStream);
      }
      _ensureOpen();

      final channel = await peer.createDataChannel(
        'oai-events',
        RTCDataChannelInit(),
      );
      _dataChannel = channel;
      _ensureOpen();
      _channelReady = Completer<void>();
      // Register an error handler now. The channel can close while the SDP
      // request is in flight, before connect() reaches its await below.
      unawaited(_channelReady!.future.catchError((Object _) {}));
      channel.onMessage = (message) {
        if (message.isBinary) return;
        for (final event in parseRealtimeServerEvent(message.text)) {
          _emit(event);
        }
      };
      channel.onDataChannelState = (state) {
        if (state == RTCDataChannelState.RTCDataChannelOpen) {
          if (!(_channelReady?.isCompleted ?? true)) {
            _channelReady!.complete();
          }
          _emit(const RealtimeActivityEvent(RealtimeVoiceActivity.connected));
          _sendOpeningTurn();
        } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
          _failConnection(
            'Le canal Realtime s’est fermé avant la fin de l’entrevue.',
          );
        }
      };

      final offer = await peer.createOffer({'offerToReceiveAudio': true});
      _ensureOpen();
      await peer.setLocalDescription(offer);
      _ensureOpen();
      final offerSdp = offer.sdp;
      if (offerSdp == null || offerSdp.isEmpty) {
        throw const RealtimeVoiceException(
          'L’appareil n’a pas pu créer l’offre audio WebRTC.',
        );
      }
      final answerSdp = await api.exchangeSdp(
        clientSecret: clientSecret,
        offerSdp: offerSdp,
      );
      _ensureOpen();
      await peer.setRemoteDescription(
        RTCSessionDescription(answerSdp, 'answer'),
      );
      _ensureOpen();
      await _channelReady!.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw const RealtimeVoiceException(
          'Le canal audio Realtime ne s’est pas ouvert. Vérifiez le réseau.',
        ),
      );
    } catch (error) {
      await _releaseMedia();
      if (error is RealtimeVoiceException) rethrow;
      throw RealtimeVoiceException(
        'Impossible de démarrer l’entrevue Realtime : $error',
      );
    }
  }

  void _ensureOpen() {
    if (_closed) {
      throw const RealtimeVoiceException('Cette session est déjà terminée.');
    }
  }

  Future<void> _attachRemoteAudio(RTCTrackEvent event) async {
    try {
      _ensureOpen();
      event.track.enabled = true;
      final MediaStream stream;
      if (event.streams.isNotEmpty) {
        stream = event.streams.first;
      } else {
        // Unified Plan normally supplies a stream, but handle streamless
        // onTrack events so playback remains reliable across implementations.
        var fallback = _fallbackRemoteStream;
        if (fallback == null) {
          fallback = await createLocalMediaStream('realtime-remote-audio');
          _fallbackRemoteStream = fallback;
        }
        await fallback.addTrack(event.track);
        stream = fallback;
      }
      _ensureOpen();
      _remoteAudioRenderer?.srcObject = stream;
    } catch (_) {
      _failConnection(
        'Impossible de lire l’audio de l’évaluatrice. Réessayez.',
      );
      return;
    }
    if (!kIsWeb) {
      try {
        // Routing is an enhancement. Missing Bluetooth permission or an OEM
        // routing failure must not tear down otherwise working remote audio.
        await Helper.setSpeakerphoneOnButPreferBluetooth();
      } on Object {
        // Keep the platform's current output route as a safe fallback.
      }
    }
  }

  void _sendOpeningTurn() {
    if (_openingSent || _closed) return;
    _openingSent = true;
    _send({
      'type': 'response.create',
      'response': {
        'output_modalities': ['audio'],
        'instructions': buildRealtimeOpeningInstruction(),
      },
    });
  }

  void _send(Map<String, dynamic> event) {
    final channel = _dataChannel;
    if (channel?.state != RTCDataChannelState.RTCDataChannelOpen) return;
    unawaited(
      channel!.send(RTCDataChannelMessage(jsonEncode(event))).catchError((
        Object _,
      ) {
        _failConnection(
          'Le canal Realtime s’est fermé avant l’envoi. Réessayez.',
        );
      }),
    );
  }

  void _handleConnectionState(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        _emit(const RealtimeActivityEvent(RealtimeVoiceActivity.connected));
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        _failConnection(
          'La connexion WebRTC a échoué. Vérifiez votre réseau et réessayez.',
        );
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        _emit(const RealtimeActivityEvent(RealtimeVoiceActivity.disconnected));
      case RTCPeerConnectionState.RTCPeerConnectionStateNew:
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        break;
    }
  }

  void _failConnection(String message) {
    if (_closed) return;
    final ready = _channelReady;
    if (ready != null && !ready.isCompleted) {
      ready.completeError(RealtimeVoiceException(message));
    }
    _emit(RealtimeErrorEvent(message, type: 'transport_error', isFatal: true));
    _emit(const RealtimeActivityEvent(RealtimeVoiceActivity.disconnected));
    // A failed peer/channel must not retain microphone, renderer, or network
    // resources while the learner decides whether to retry.
    unawaited(close());
  }

  @override
  Future<void> setMuted(bool muted) async {
    _muted = muted;
    for (final track in _localStream?.getAudioTracks() ?? const []) {
      track.enabled = !muted;
    }
  }

  @override
  Future<void> close() {
    final pending = _closeFuture;
    if (pending != null) return pending;
    _closed = true;
    final closing = _close();
    _closeFuture = closing;
    return closing;
  }

  Future<void> _close() async {
    final ready = _channelReady;
    if (ready != null && !ready.isCompleted) {
      ready.completeError(
        const RealtimeVoiceException('La session Realtime a été fermée.'),
      );
    }
    await _releaseMedia();
    try {
      api.close();
    } catch (_) {
      // Cleanup is deliberately best effort. One client failure must not
      // prevent the remaining resources and event stream from closing.
    }
    if (!_events.isClosed) {
      _events.add(
        const RealtimeActivityEvent(RealtimeVoiceActivity.disconnected),
      );
      await _events.close();
    }
  }

  Future<void> _releaseMedia() {
    final pending = _releaseFuture;
    if (pending != null) return pending;
    late final Future<void> tracked;
    tracked = _releaseMediaResources().whenComplete(() {
      if (identical(_releaseFuture, tracked)) _releaseFuture = null;
    });
    _releaseFuture = tracked;
    return tracked;
  }

  Future<void> _releaseMediaResources() async {
    // Detach every resource from the object before awaiting. Concurrent close
    // calls therefore see an already-drained state and remain idempotent.
    final channel = _dataChannel;
    _dataChannel = null;
    _channelReady = null;
    _openingSent = false;
    if (channel != null) {
      channel.onMessage = null;
      channel.onDataChannelState = null;
      await _bestEffort(channel.close);
    }

    final peer = _peerConnection;
    _peerConnection = null;
    if (peer != null) {
      peer.onConnectionState = null;
      peer.onTrack = null;
      await _bestEffort(peer.close);
      await _bestEffort(peer.dispose);
    }

    final stream = _localStream;
    _localStream = null;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await _bestEffort(track.stop);
      }
      await _bestEffort(stream.dispose);
    }

    final fallbackRemoteStream = _fallbackRemoteStream;
    _fallbackRemoteStream = null;
    if (fallbackRemoteStream != null) {
      await _bestEffort(fallbackRemoteStream.dispose);
    }

    final renderer = _remoteAudioRenderer;
    _remoteAudioRenderer = null;
    if (renderer != null) {
      await _bestEffort(() async => renderer.srcObject = null);
      await _bestEffort(renderer.dispose);
    }
  }

  Future<void> _bestEffort(FutureOr<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Continue releasing all other independent WebRTC resources.
    }
  }

  void _emit(RealtimeVoiceEvent event) {
    if (!_events.isClosed) _events.add(event);
  }
}
