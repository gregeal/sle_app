import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Thin, fakeable wrappers around the device speech plugins so the coach UI
/// can be widget-tested without a microphone or TTS engine.

abstract class SpeechService {
  Future<bool> initialize();

  /// Starts listening in Canadian French; [onResult] receives the running
  /// transcript (partial results included), [onDone] fires when the engine
  /// stops on its own (silence timeout).
  Future<void> listen({
    required void Function(String transcript) onResult,
    required void Function() onDone,
  });

  Future<void> stop();

  bool get isListening;
}

class DeviceSpeechService implements SpeechService {
  final _speech = stt.SpeechToText();
  var _initialized = false;
  void Function()? _onDone;
  var _didFinish = false;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') _finishOnce();
      },
      onError: (_) => _finishOnce(),
    );
    return _initialized;
  }

  @override
  Future<void> listen({
    required void Function(String transcript) onResult,
    required void Function() onDone,
  }) async {
    _onDone = onDone;
    _didFinish = false;
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: 'fr_CA',
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        pauseFor: const Duration(seconds: 6),
        listenFor: const Duration(minutes: 3),
      ),
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) _finishOnce();
      },
    );
  }

  void _finishOnce() {
    if (_didFinish || _onDone == null) return;
    _didFinish = true;
    final callback = _onDone;
    _onDone = null;
    callback?.call();
  }

  @override
  Future<void> stop() {
    _onDone = null;
    _didFinish = true;
    return _speech.stop();
  }

  @override
  bool get isListening => _speech.isListening;
}

abstract class TtsService {
  Future<void> speak(String textFr);

  Future<void> stop();
}

class DeviceTtsService implements TtsService {
  DeviceTtsService() {
    _ready = _initialize();
  }

  final _tts = FlutterTts();
  late final Future<void> _ready;

  Future<void> _initialize() async {
    await _tts.setLanguage('fr-CA');
    await _tts.setSpeechRate(0.48);
  }

  @override
  Future<void> speak(String textFr) async {
    await _ready;
    await _tts.stop();
    await _tts.speak(textFr);
  }

  @override
  Future<void> stop() async {
    await _ready;
    await _tts.stop();
  }
}
