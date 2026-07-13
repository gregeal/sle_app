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
  Completer<void>? _channelReady;
  var _muted = false;
  var _closed = false;
  var _openingSent = false;

  @override
  Stream<RealtimeVoiceEvent> get events => _events.stream;

  @override
  bool get isMuted => _muted;

  @override
  Future<void> connect() async {
    if (_closed) {
      throw const RealtimeVoiceException('Cette session est déjà terminée.');
    }
    if (_peerConnection != null) return;
    _emit(const RealtimeActivityEvent(RealtimeVoiceActivity.connecting));

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });

      final clientSecret = await api.createClientSecret(
        model: model,
        voice: voice,
      );
      final peer = await createPeerConnection({'sdpSemantics': 'unified-plan'});
      _peerConnection = peer;
      peer.onConnectionState = _handleConnectionState;
      peer.onTrack = (event) {
        if (event.track.kind == 'audio') {
          event.track.enabled = true;
          if (!kIsWeb) {
            unawaited(Helper.setSpeakerphoneOnButPreferBluetooth());
          }
        }
      };

      for (final track in _localStream!.getAudioTracks()) {
        await peer.addTrack(track, _localStream!);
      }

      final channel = await peer.createDataChannel(
        'oai-events',
        RTCDataChannelInit(),
      );
      _dataChannel = channel;
      _channelReady = Completer<void>();
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
          _emit(
            const RealtimeActivityEvent(RealtimeVoiceActivity.disconnected),
          );
        }
      };

      final offer = await peer.createOffer({'offerToReceiveAudio': true});
      await peer.setLocalDescription(offer);
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
      await peer.setRemoteDescription(
        RTCSessionDescription(answerSdp, 'answer'),
      );
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
    unawaited(channel!.send(RTCDataChannelMessage(jsonEncode(event))));
  }

  void _handleConnectionState(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        _emit(const RealtimeActivityEvent(RealtimeVoiceActivity.connected));
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        _emit(
          const RealtimeErrorEvent(
            'La connexion WebRTC a échoué. Vérifiez votre réseau et réessayez.',
          ),
        );
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        _emit(const RealtimeActivityEvent(RealtimeVoiceActivity.disconnected));
      case RTCPeerConnectionState.RTCPeerConnectionStateNew:
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        break;
    }
  }

  @override
  Future<void> setMuted(bool muted) async {
    _muted = muted;
    for (final track in _localStream?.getAudioTracks() ?? const []) {
      track.enabled = !muted;
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _releaseMedia();
    api.close();
    if (!_events.isClosed) {
      _events.add(
        const RealtimeActivityEvent(RealtimeVoiceActivity.disconnected),
      );
      await _events.close();
    }
  }

  Future<void> _releaseMedia() async {
    final channel = _dataChannel;
    _dataChannel = null;
    if (channel != null) await channel.close();

    final peer = _peerConnection;
    _peerConnection = null;
    if (peer != null) {
      await peer.close();
      await peer.dispose();
    }

    final stream = _localStream;
    _localStream = null;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await track.stop();
      }
      await stream.dispose();
    }
  }

  void _emit(RealtimeVoiceEvent event) {
    if (!_events.isClosed) _events.add(event);
  }
}
