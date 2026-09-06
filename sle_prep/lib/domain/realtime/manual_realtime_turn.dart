import 'dart:async';

import 'realtime_voice_session.dart';

/// Manual turn boundaries: audio is committed only after the learner submits.
/// The server acknowledgement gates response.create, so an empty/rejected
/// audio buffer cannot accidentally make the interviewer skip a question.
class ManualRealtimeTurn {
  ManualRealtimeTurn({required this.send, required this.mute});

  final Future<void> Function(Map<String, dynamic>) send;
  final Future<void> Function(bool) mute;
  Completer<void>? _committed;
  bool _recording = false;
  bool _busy = false;
  bool _closed = false;

  Future<void> start() async {
    if (_closed || _busy || _recording) return;
    _busy = true;
    try {
      await send({'type': 'input_audio_buffer.clear'});
      if (_closed) return;
      await mute(false);
      if (_closed) {
        await mute(true);
        return;
      }
      _recording = true;
    } finally {
      _busy = false;
    }
  }

  Future<void> submit({bool requestResponse = true}) async {
    if (_closed || _busy || !_recording) return;
    _busy = true;
    try {
      await mute(true);
      // Audio RTP and the control data channel are separate transports. Let
      // the last captured frames reach the server before sending the boundary.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (_closed) return;
      final committed = Completer<void>();
      _committed = committed;
      // Attach the handler before send, which may synchronously trigger events.
      final acknowledgement = committed.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw const RealtimeVoiceException(
          'La réponse audio n’a pas été confirmée. Vérifiez la connexion.',
        ),
      );
      unawaited(acknowledgement.catchError((Object _) {}));
      await send({'type': 'input_audio_buffer.commit'});
      await acknowledgement;
      _recording = false;
      if (!_closed && requestResponse) await send({'type': 'response.create'});
    } finally {
      final pending = _committed;
      if (pending != null && !pending.isCompleted) pending.complete();
      _committed = null;
      _recording = false;
      _busy = false;
    }
  }

  void handleEvent(Map<String, dynamic> event) {
    final pending = _committed;
    if (pending == null || pending.isCompleted) return;
    if (event['type'] == 'input_audio_buffer.committed') {
      pending.complete();
    } else if (event['type'] == 'error') {
      pending.completeError(
        const RealtimeVoiceException(
          'La réponse audio n’a pas pu être envoyée. Reprenez le microphone.',
        ),
      );
      _recording = false;
    }
  }

  void close() {
    _closed = true;
    final pending = _committed;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(
        const RealtimeVoiceException('La session est fermée.'),
      );
    }
  }
}
