import 'dart:async';
import 'openai_dictation_transport.dart';
import 'speech_services.dart';

class DictationException implements Exception {
  const DictationException(this.message);
  final String message;
}

/// One manual audio turn per capture. Streaming deltas are provisional; the
/// completed transcript replaces them before the editor becomes writable.
class OpenAiSpeechService implements SpeechService {
  OpenAiSpeechService({
    required this.createTransport,
    this.finalTimeout = const Duration(seconds: 20),
    this.drainDelay = const Duration(milliseconds: 300),
    this.maxDuration = const Duration(minutes: 10),
  });
  final DictationTransport Function() createTransport;
  final Duration finalTimeout, drainDelay, maxDuration;
  DictationTransport? _transport;
  bool _active = false, _connected = false;
  int _generation = 0;
  Timer? _limit;
  Future<void>? _stopping;
  Completer<void>? _final;
  String? _committedId;
  final _text = <String, String>{};
  final _completed = <String>{};
  final _eventIds = <String>{};
  void Function(String)? _onResult;
  void Function()? _onDone;
  String? lastError;

  @override
  bool get isListening => _active;
  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> listen({
    required void Function(String) onResult,
    required void Function() onDone,
  }) async {
    await _stopping;
    if (_active) return;
    final generation = ++_generation;
    final transport = createTransport();
    _transport = transport;
    _active = true;
    _connected = false;
    _text.clear();
    _completed.clear();
    _eventIds.clear();
    _committedId = null;
    lastError = null;
    _onResult = onResult;
    _onDone = onDone;
    try {
      await transport.connect(
        onEvent: (event) {
          if (generation == _generation) _event(event);
        },
        onFailure: () {
          if (generation == _generation) {
            _fail(
              'Connexion de dictée interrompue. Vérifiez le texte conservé avant de continuer.',
            );
          }
        },
      );
      if (!_active || generation != _generation) {
        await transport.close();
        return;
      }
      _connected = true;
      await transport.mute(false);
      if (!_active || generation != _generation) {
        await transport.mute(true);
        return;
      }
      _limit = Timer(maxDuration, () async {
        final done = _onDone;
        try {
          await stop();
        } catch (_) {
          /* lastError already records failure. */
        }
        lastError ??=
            'Dix minutes de dictée : vérifiez le texte puis continuez si nécessaire.';
        done?.call();
      });
    } catch (_) {
      await transport.close();
      if (generation != _generation) return;
      _active = false;
      _connected = false;
      _transport = null;
      throw const DictationException(
        'Dictée OpenAI indisponible. Vérifiez la clé OpenAI, l’accès à gpt-live-transcribe, '
        'le réseau et le microphone. La dictée de l’appareil reste disponible.',
      );
    }
  }

  void _event(Map<String, dynamic> event) {
    final eventId = event['event_id'];
    if (eventId is String && !_eventIds.add(eventId)) return;
    if (_eventIds.length > 20000) {
      _fail('Limite de dictée atteinte. Vérifiez le texte conservé.');
      return;
    }
    final type = event['type'];
    final id = event['item_id'];
    if (type == 'error' ||
        type == 'conversation.item.input_audio_transcription.failed') {
      final error = event['error'];
      if (error is Map &&
          error['code'] == 'input_audio_buffer_commit_empty' &&
          _final != null) {
        if (!_final!.isCompleted) _final!.complete();
      } else {
        _fail(
          'La dictée OpenAI n’a pas pu terminer la transcription. Le texte partiel est conservé; vérifiez-le.',
        );
      }
      return;
    }
    if (id is! String || id.isEmpty || id.length > 256) return;
    if (type == 'input_audio_buffer.committed') {
      _committedId = id;
      _checkFinal();
      return;
    }
    if (event['content_index'] != null && event['content_index'] != 0) return;
    if (type == 'conversation.item.input_audio_transcription.delta') {
      final delta = event['delta'];
      if (delta is! String || _completed.contains(id)) return;
      _text[id] = '${_text[id] ?? ''}$delta';
    } else if (type ==
        'conversation.item.input_audio_transcription.completed') {
      final transcript = event['transcript'];
      if (transcript is! String) return;
      _text[id] = transcript;
      _completed.add(id);
    } else {
      return;
    }
    final text = _text.values.join(' ').trim();
    _onResult?.call(text.length > 20000 ? text.substring(0, 20000) : text);
    if (text.length > 20000 || _text.length > 100) {
      _fail('Limite du brouillon atteinte. Vérifiez le texte conservé.');
      return;
    }
    _checkFinal();
  }

  void _checkFinal() {
    final pending = _final;
    if (pending != null &&
        !pending.isCompleted &&
        _completed.contains(_committedId)) {
      pending.complete();
    }
  }

  void _fail(String message) {
    lastError = message;
    final pending = _final;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(DictationException(message));
    } else if (_active) {
      final done = _onDone;
      unawaited(cancel().whenComplete(() => done?.call()));
    }
  }

  /// Immediate teardown for route disposal or cancelled startup, no new commit.
  Future<void> cancel() async {
    ++_generation;
    _active = false;
    _connected = false;
    _limit?.cancel();
    final transport = _transport;
    _transport = null;
    final pending = _final;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(const DictationException('Dictée annulée.'));
    }
    await transport?.close();
  }

  @override
  Future<void> stop() {
    if (_stopping != null) return _stopping!;
    final transport = _transport;
    if (transport == null) return Future.value();
    _active = false;
    _limit?.cancel();
    return _stopping = _stop(transport).whenComplete(() => _stopping = null);
  }

  Future<void> _stop(DictationTransport transport) async {
    try {
      await transport.mute(true);
      if (!_connected) return;
      final pending = _final = Completer<void>();
      unawaited(pending.future.catchError((Object _) {}));
      await Future<void>.delayed(drainDelay);
      await transport.send({'type': 'input_audio_buffer.commit'});
      await pending.future.timeout(finalTimeout);
    } catch (_) {
      lastError ??=
          'Transcription finale non reçue. Le texte affiché peut être incomplet; vérifiez-le avant l’envoi.';
      throw DictationException(lastError!);
    } finally {
      ++_generation;
      _connected = false;
      _final = null;
      if (identical(_transport, transport)) _transport = null;
      await transport.close();
    }
  }
}
