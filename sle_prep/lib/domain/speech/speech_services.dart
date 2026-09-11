import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Thin, fakeable wrappers around the device speech plugins so the coach UI
/// can be widget-tested without a microphone or TTS engine.

abstract class SpeechService {
  Future<bool> initialize();

  /// Starts listening in Canadian French; [onResult] receives the running
  /// transcript (partial results included), [onDone] fires when the engine
  /// stops because of an unrecoverable recognition error. Ordinary silence
  /// must not finish the learner's answer.
  Future<void> listen({
    required void Function(String transcript) onResult,
    required void Function() onDone,
  });

  Future<void> stop();

  bool get isListening;
}

/// Separate platform callbacks from session orchestration for regression tests.
abstract class SpeechEngine {
  Future<bool> initialize({
    required void Function(String) onStatus,
    required void Function(String, bool) onError,
  });
  Future<void> listen(void Function(String, bool) onResult);
  Future<void> stop();
}

class _DeviceSpeechEngine implements SpeechEngine {
  final _speech = stt.SpeechToText();
  @override
  Future<bool> initialize({
    required void Function(String) onStatus,
    required void Function(String, bool) onError,
  }) => _speech.initialize(
    onStatus: onStatus,
    onError: (error) => onError(error.errorMsg, error.permanent),
  );

  @override
  Future<void> listen(void Function(String, bool) onResult) => _speech.listen(
    listenOptions: stt.SpeechListenOptions(
      localeId: 'fr_CA',
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
      pauseFor: const Duration(seconds: 6),
      listenFor: const Duration(minutes: 1),
      cancelOnError: false,
    ),
    onResult: (result) => onResult(result.recognizedWords, result.finalResult),
  );

  @override
  Future<void> stop() => _speech.stop();
}

class DeviceSpeechService implements SpeechService {
  DeviceSpeechService({SpeechEngine? engine})
    : _engine = engine ?? _DeviceSpeechEngine();

  final SpeechEngine _engine;
  var _initialized = false;
  var _sessionActive = false;
  var _generation = 0;
  var _segment = 0;
  var _errors = 0;
  Timer? _restart;
  Timer? _drainWatchdog;
  Future<void>? _starting;
  Future<void>? _stopping;
  Completer<void>? _finalized;
  var _committed = '';
  var _segmentWords = '';
  void Function(String transcript)? _onResult;
  void Function()? _onDone;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _engine.initialize(
      onStatus: (status) {
        // notListening means the microphone closed, NOT that the final text
        // arrived. Restarting there discards late corrections and duplicates
        // partial words. The plugin emits done after final results are drained.
        if (status == 'done') {
          _drainWatchdog?.cancel();
          final finalized = _finalized;
          if (finalized != null && !finalized.isCompleted) finalized.complete();
          _scheduleRestart();
        } else if (status == 'notListening' && _sessionActive) {
          _drainWatchdog?.cancel();
          // OEM/browser engines occasionally omit done. Preserve the partial
          // text and recover only after allowing the usual final-result grace.
          _drainWatchdog = Timer(const Duration(seconds: 2), _scheduleRestart);
        }
      },
      onError: (code, permanent) {
        if (!_sessionActive) return;
        if (code == 'error_no_match' || code == 'error_speech_timeout') {
          _scheduleRestart();
        } else if (permanent || ++_errors >= 3) {
          unawaited(_finishAfterError());
        } else {
          _scheduleRestart();
        }
      },
    );
    return _initialized;
  }

  @override
  Future<void> listen({
    required void Function(String transcript) onResult,
    required void Function() onDone,
  }) async {
    final stopping = _stopping;
    if (stopping != null) await stopping;
    if (_sessionActive) return;
    final generation = ++_generation;
    _onResult = onResult;
    _onDone = onDone;
    _committed = '';
    _segmentWords = '';
    _sessionActive = true;
    _errors = 0;
    try {
      await _startSegment(generation);
    } catch (_) {
      await stop();
      rethrow;
    }
  }

  Future<void> _startSegment(int generation) async {
    if (!_sessionActive || generation != _generation) return;
    _drainWatchdog?.cancel();
    _drainWatchdog = null;
    _committed = _join(_committed, _segmentWords);
    _segmentWords = '';
    final segment = ++_segment;
    _finalized = Completer<void>();
    final starting = _engine.listen((words, isFinal) {
      if (generation != _generation || segment != _segment) return;
      _segmentWords = words;
      if (words.isNotEmpty) _errors = 0;
      _onResult?.call(_join(_committed, _segmentWords));
    });
    _starting = starting;
    try {
      await starting;
    } finally {
      if (identical(_starting, starting)) _starting = null;
    }
  }

  void _scheduleRestart() {
    if (!_sessionActive || _restart != null) return;
    final generation = _generation;
    _restart = Timer(const Duration(milliseconds: 350), () async {
      _restart = null;
      try {
        await _starting;
        await _startSegment(generation);
      } catch (_) {
        if (generation == _generation) await _finishAfterError();
      }
    });
  }

  Future<void> _finishAfterError() async {
    if (!_sessionActive) return;
    final callback = _onDone;
    try {
      await stop();
    } catch (_) {
      // Preserve the transcript and allow a deliberate user retry.
    }
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
    final stopping = _stopping;
    if (stopping != null) return stopping;
    _sessionActive = false;
    _drainWatchdog?.cancel();
    _restart?.cancel();
    _restart = null;
    return _stopping = _stop().whenComplete(() => _stopping = null);
  }

  Future<void> _stop() async {
    try {
      try {
        await _starting;
      } catch (_) {
        // A failed start can still have opened native microphone resources.
      }
      await _engine.stop();
      // The stop future only confirms the native call, not final recognition.
      await _finalized?.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
    } finally {
      ++_generation;
      _onResult = null;
      _onDone = null;
      _finalized = null;
    }
  }

  @override
  bool get isListening => _sessionActive;
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
  int _generation = 0;

  Future<void> _initialize() async {
    await _tts.setLanguage('fr-CA');
    await _tts.setSpeechRate(0.48);
  }

  @override
  Future<void> speak(String textFr) async {
    final generation = ++_generation;
    await _ready;
    if (generation != _generation) return;
    await _tts.stop();
    if (generation != _generation) return;
    await _tts.speak(textFr);
  }

  @override
  Future<void> stop() async {
    ++_generation;
    await _ready;
    await _tts.stop();
  }
}
