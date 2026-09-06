import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/domain/speech/speech_services.dart';

class FakeEngine implements SpeechEngine {
  late void Function(String) status;
  late void Function(String, bool) error;
  final results = <void Function(String, bool)>[];
  void Function()? onStop;
  var stops = 0;

  @override
  Future<bool> initialize({
    required void Function(String) onStatus,
    required void Function(String, bool) onError,
  }) async {
    status = onStatus;
    error = onError;
    return true;
  }

  @override
  Future<void> listen(void Function(String, bool) onResult) async {
    results.add(onResult);
  }

  @override
  Future<void> stop() async {
    stops++;
    onStop?.call();
    status('done');
  }
}

void main() {
  testWidgets('old drain watchdog cannot interrupt a recovered segment', (
    tester,
  ) async {
    final engine = FakeEngine();
    final speech = DeviceSpeechService(engine: engine);
    await speech.initialize();
    await speech.listen(onResult: (_) {}, onDone: () {});
    engine.status('notListening');
    engine.error('error_speech_timeout', true);
    await tester.pump(const Duration(milliseconds: 400));
    expect(engine.results, hasLength(2));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(engine.results, hasLength(2));
    await speech.stop();
  });
  testWidgets(
    'waits for final words; continues after pauses beyond three minutes',
    (tester) async {
      final engine = FakeEngine();
      final speech = DeviceSpeechService(engine: engine);
      var text = '';
      var done = 0;
      await speech.initialize();
      await speech.listen(
        onResult: (value) => text = value,
        onDone: () => done++,
      );
      engine.results.last('Je pense', false);
      engine.status('notListening');
      await tester.pump(const Duration(seconds: 1));
      expect(engine.results, hasLength(1));
      engine.results.last('Je pensais.', true);
      engine.status('done');
      engine.status('done');
      await tester.pump(const Duration(milliseconds: 400));
      expect(engine.results, hasLength(2));
      engine.results.last('Ensuite.', true);
      engine.status('done');
      await tester.pump(const Duration(minutes: 4));
      expect(engine.results, hasLength(3));
      engine.results.last('Enfin.', true);
      expect(text, 'Je pensais. Ensuite. Enfin.');
      expect(done, 0);
      expect(speech.isListening, isTrue);
      await speech.stop();
    },
  );

  testWidgets('stop drains final result and cancels pending restart', (
    tester,
  ) async {
    final engine = FakeEngine();
    final speech = DeviceSpeechService(engine: engine);
    var text = '';
    await speech.initialize();
    await speech.listen(onResult: (value) => text = value, onDone: () {});
    engine.results.last('Mon trava', false);
    engine.onStop = () => engine.results.last('Mon travail.', true);
    await speech.stop();
    expect(text, 'Mon travail.');
    engine.results.first('late private audio', true);
    await tester.pump(const Duration(seconds: 1));
    expect(text, 'Mon travail.');
    expect(engine.results, hasLength(1));
    expect(speech.isListening, isFalse);
  });

  testWidgets('old segment callbacks cannot pollute a new answer', (
    tester,
  ) async {
    final engine = FakeEngine();
    final speech = DeviceSpeechService(engine: engine);
    var text = '';
    await speech.initialize();
    await speech.listen(onResult: (value) => text = value, onDone: () {});
    engine.status('done');
    await speech.stop();
    await speech.listen(onResult: (value) => text = value, onDone: () {});
    engine.results.first('old answer', true);
    engine.results.last('Nouvelle réponse.', true);
    await tester.pump(const Duration(seconds: 1));
    expect(engine.results, hasLength(2));
    expect(text, 'Nouvelle réponse.');
    await speech.stop();
  });

  testWidgets('silence is recoverable but permission errors stop the mic', (
    tester,
  ) async {
    final engine = FakeEngine();
    final speech = DeviceSpeechService(engine: engine);
    var done = 0;
    await speech.initialize();
    await speech.listen(onResult: (_) {}, onDone: () => done++);
    engine.error('error_speech_timeout', true);
    await tester.pump(const Duration(milliseconds: 400));
    expect(speech.isListening, isTrue);
    engine.error('error_permission', true);
    await tester.pump();
    expect(speech.isListening, isFalse);
    expect(done, 1);
    expect(engine.stops, 1);
  });
}
