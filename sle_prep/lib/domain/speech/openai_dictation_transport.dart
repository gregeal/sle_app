import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../realtime/openai_realtime_api.dart';

abstract class DictationTransport {
  Future<void> connect({
    required void Function(Map<String, dynamic>) onEvent,
    required void Function() onFailure,
  });
  Future<void> send(Map<String, dynamic> event);
  Future<void> mute(bool muted);
  Future<void> close();
}

/// Audio-only WebRTC to the official API. No recording file or audio response.
class OpenAiDictationTransport implements DictationTransport {
  OpenAiDictationTransport({required this.createSecret});
  final Future<String> Function() createSecret;
  final _api = OpenAiRealtimeApi(baseUrl: 'https://api.openai.com/v1');
  RTCPeerConnection? _peer;
  MediaStream? _stream;
  RTCDataChannel? _channel;
  Completer<void>? _ready;
  bool _closed = false;
  Future<void>? _releasing;

  void _check() {
    if (_closed) throw StateError('Dictation closed');
  }

  @override
  Future<void> connect({
    required void Function(Map<String, dynamic>) onEvent,
    required void Function() onFailure,
  }) async {
    try {
      _check();
      // Permission before minting a billed session; tracks remain muted until
      // the data channel and transcript handlers are ready.
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
          'channelCount': 1,
        },
        'video': false,
      });
      _stream = stream;
      for (final track in stream.getAudioTracks()) {
        track.enabled = false;
      }
      _check();
      final secret = await createSecret();
      _check();
      final peer = await createPeerConnection({'sdpSemantics': 'unified-plan'});
      _peer = peer;
      _check();
      peer.onConnectionState = (state) {
        if (!_closed &&
            {
              RTCPeerConnectionState.RTCPeerConnectionStateFailed,
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected,
              RTCPeerConnectionState.RTCPeerConnectionStateClosed,
            }.contains(state)) {
          _failReady();
          onFailure();
        }
      };
      for (final track in stream.getAudioTracks()) {
        await peer.addTrack(track, stream);
        _check();
      }
      final channel = await peer.createDataChannel(
        'oai-events',
        RTCDataChannelInit(),
      );
      _channel = channel;
      _check();
      final ready = _ready = Completer<void>();
      unawaited(ready.future.catchError((Object _) {}));
      channel.onMessage = (message) {
        if (_closed || message.isBinary || message.text.length > 100000) return;
        try {
          final event = jsonDecode(message.text);
          if (event is Map<String, dynamic>) onEvent(event);
        } on FormatException {
          onFailure();
        }
      };
      channel.onDataChannelState = (state) {
        if (_closed) return;
        if (state == RTCDataChannelState.RTCDataChannelOpen &&
            !ready.isCompleted) {
          ready.complete();
        } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
          _failReady();
          onFailure();
        }
      };
      final offer = await peer.createOffer({'offerToReceiveAudio': false});
      _check();
      await peer.setLocalDescription(offer);
      _check();
      final sdp = offer.sdp;
      if (sdp == null || sdp.isEmpty) throw StateError('Missing SDP');
      final answer = await _api.exchangeSdp(
        clientSecret: secret,
        offerSdp: sdp,
      );
      _check();
      await peer.setRemoteDescription(RTCSessionDescription(answer, 'answer'));
      _check();
      if (channel.state == RTCDataChannelState.RTCDataChannelOpen &&
          !ready.isCompleted) {
        ready.complete();
      }
      await ready.future.timeout(const Duration(seconds: 20));
      _check();
    } catch (_) {
      await close();
      rethrow;
    }
  }

  void _failReady() {
    final ready = _ready;
    if (ready != null && !ready.isCompleted) {
      ready.completeError(StateError('Dictation connection closed'));
    }
  }

  @override
  Future<void> send(Map<String, dynamic> event) async {
    _check();
    final channel = _channel;
    if (channel == null ||
        channel.state != RTCDataChannelState.RTCDataChannelOpen) {
      throw StateError('Dictation channel unavailable');
    }
    await channel.send(RTCDataChannelMessage(jsonEncode(event)));
  }

  @override
  Future<void> mute(bool muted) async {
    for (final track
        in _stream?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  @override
  Future<void> close() async {
    _closed = true;
    _failReady();
    await mute(true);
    // A cancelled getUserMedia/createPeerConnection can complete late; drain
    // again on its catch path instead of caching one permanently closed future.
    await _releasing;
    final releasing = _release();
    _releasing = releasing;
    await releasing;
    if (identical(_releasing, releasing)) _releasing = null;
    _api.close();
  }

  Future<void> _release() async {
    final channel = _channel;
    final peer = _peer;
    final stream = _stream;
    _channel = null;
    _peer = null;
    _stream = null;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await _bestEffort(track.stop);
      }
      await _bestEffort(stream.dispose);
    }
    if (channel != null) {
      channel.onMessage = null;
      channel.onDataChannelState = null;
      await _bestEffort(channel.close);
    }
    if (peer != null) {
      peer.onConnectionState = null;
      await _bestEffort(peer.close);
      await _bestEffort(peer.dispose);
    }
  }

  Future<void> _bestEffort(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      /* Release independent resources too. */
    }
  }
}
