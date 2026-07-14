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
  /// Android's SpeechRecognizer finalizes a few seconds after the first
  /// pause regardless of the requested pauseFor, which used to truncate
  /// answers mid-sentence. One [listen] call therefore chains recognition
  /// segments: every time the engine stops on its own, the recognized words
  /// are committed and a fresh segment starts, until [stop] is tapped or the
  /// total cap elapses. Callers keep seeing one growing transcript.
  static const _totalCap = Duration(minutes: 3);
  static const _restartDelay = Duration(milliseconds: 250);

  final _speech = stt.SpeechToText();
  var _initialized = false;
  var _sessionActive = false;
  var _restartScheduled = false;
  var _committed = '';
  var _segmentWords = '';
  final _sessionClock = Stopwatch();
  void Function(String transcript)? _onResult;
  void Function()? _onDone;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _handleEngineStop();
        }
      },
      onError: (_) => _handleEngineStop(),
    );
    return _initialized;
  }

  @override
  Future<void> listen({
    required void Function(String transcript) onResult,
    required void Function() onDone,
  }) async {
    _onResult = onResult;
    _onDone = onDone;
    _committed = '';
    _segmentWords = '';
    _sessionActive = true;
    _restartScheduled = false;
    _sessionClock
      ..reset()
      ..start();
    await _startSegment();
  }

  Future<void> _startSegment() async {
    _segmentWords = '';
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: 'fr_CA',
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        pauseFor: const Duration(seconds: 6),
        listenFor: _totalCap,
      ),
      onResult: (result) {
        if (!_sessionActive) return;
        _segmentWords = result.recognizedWords;
        _onResult?.call(_join(_committed, _segmentWords));
        if (result.finalResult) {
          _committed = _join(_committed, _segmentWords);
          _segmentWords = '';
        }
      },
    );
  }

  void _handleEngineStop() {
    if (!_sessionActive || _restartScheduled) return;
    // Words from a segment that ended without a finalResult still count.
    _committed = _join(_committed, _segmentWords);
    _segmentWords = '';
    if (_sessionClock.elapsed >= _totalCap) {
      _finishSession();
      return;
    }
    _restartScheduled = true;
    Future<void>.delayed(_restartDelay, () async {
      _restartScheduled = false;
      if (!_sessionActive) return;
      try {
        await _startSegment();
      } catch (_) {
        _finishSession();
      }
    });
  }

  void _finishSession() {
    if (!_sessionActive) return;
    _sessionActive = false;
    _sessionClock.stop();
    final callback = _onDone;
    _onResult = null;
    _onDone = null;
    callback?.call();
  }

  static String _join(String committed, String segment) {
    final trimmed = segment.trim();
    if (committed.isEmpty) return trimmed;
    if (trimmed.isEmpty) return committed;
    return '$committed $trimmed';
  }

  @override
  Future<void> stop() {
    _sessionActive = false;
    _sessionClock.stop();
    _onResult = null;
    _onDone = null;
    return _speech.stop();
  }

  @override
  bool get isListening => _sessionActive || _speech.isListening;
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
