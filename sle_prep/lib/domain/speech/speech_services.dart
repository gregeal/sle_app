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

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize();
    return _initialized;
  }

  @override
  Future<void> listen({
    required void Function(String transcript) onResult,
    required void Function() onDone,
  }) async {
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
        if (result.finalResult) onDone();
      },
    );
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  bool get isListening => _speech.isListening;
}

abstract class TtsService {
  Future<void> speak(String textFr);

  Future<void> stop();
}

class DeviceTtsService implements TtsService {
  DeviceTtsService() {
    _tts
      ..setLanguage('fr-CA')
      ..setSpeechRate(0.48);
  }

  final _tts = FlutterTts();

  @override
  Future<void> speak(String textFr) async {
    await _tts.stop();
    await _tts.speak(textFr);
  }

  @override
  Future<void> stop() => _tts.stop();
}
