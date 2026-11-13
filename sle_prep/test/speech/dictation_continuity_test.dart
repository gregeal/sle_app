import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/domain/speech/speech_services.dart';
import 'package:sle_prep/features/habit/wake_lock.dart';
import 'package:sle_prep/features/speaking/voice_draft.dart';
import 'package:sle_prep/providers.dart';

import '../speaking/speaking_screens_test.dart' show TestSpeech, TestTts;
import '../support/test_db.dart';
import 'speech_services_test.dart' show FakeEngine;

class RecordingWakeLock implements ScreenWakeLock {
  final calls = <String>[];

  @override
  Future<void> enable() async => calls.add('on');

  @override
  Future<void> disable() async => calls.add('off');
}

Future<(DeviceSpeechService, FakeEngine, List<String>)> listening() async {
  final engine = FakeEngine();
  final speech = DeviceSpeechService(engine: engine);
  final shown = <String>[];
  await speech.initialize();
  await speech.listen(onResult: shown.add, onDone: () {});
  return (speech, engine, shown);
}

void main() {
  group('what was said is never erased by a pause', () {
    testWidgets('a recognizer that starts its text over keeps the first part', (
      tester,
    ) async {
      final (speech, engine, shown) = await listening();
      final say = engine.results.last;
      say('je travaille au ministère depuis trois ans', false);
      // The learner pauses to think. The recognizer keeps the session open
      // but its next partial contains only the new words.
      say('et', false);
      say('et je prépare', false);
      say('et je prépare des rapports chaque semaine', false);
      expect(
        shown.last,
        'je travaille au ministère depuis trois ans '
        'et je prépare des rapports chaque semaine',
      );
      await speech.stop();
    });

    testWidgets('an empty result does not wipe the transcript', (tester) async {
      final (speech, engine, shown) = await listening();
      final say = engine.results.last;
      say('je travaille au ministère', false);
      say('', false);
      say('   ', false);
      expect(shown.last, 'je travaille au ministère');
      await speech.stop();
    });

    testWidgets('a cumulative final after a start-over is not counted twice', (
      tester,
    ) async {
      final (speech, engine, shown) = await listening();
      final say = engine.results.last;
      say('je travaille au ministère depuis trois ans', false);
      say('et je prépare', false);
      say(
        'Je travaille au ministère depuis trois ans et je prépare des rapports',
        true,
      );
      expect(
        shown.last,
        'je travaille au ministère depuis trois ans '
        'et je prépare des rapports',
      );
      await speech.stop();
    });

    testWidgets('a final holding only the last words adds nothing', (
      tester,
    ) async {
      final (speech, engine, shown) = await listening();
      final say = engine.results.last;
      say('je travaille au ministère depuis trois ans déjà', false);
      say('trois ans déjà', true);
      expect(shown.last, 'je travaille au ministère depuis trois ans déjà');
      await speech.stop();
    });

    testWidgets('ordinary corrections still replace the hypothesis', (
      tester,
    ) async {
      final (speech, engine, shown) = await listening();
      final say = engine.results.last;
      say('je travail au ministre', false);
      say('je travaille au ministère', false);
      say('je travaille au ministère depuis', false);
      say('Je travaille au ministère depuis trois ans.', true);
      expect(shown.last, 'Je travaille au ministère depuis trois ans.');
      await speech.stop();
    });

    testWidgets('kept text survives the recognizer restarting after a pause', (
      tester,
    ) async {
      final (speech, engine, shown) = await listening();
      engine.results.last('je travaille au ministère depuis trois ans', false);
      engine.results.last('et', false);
      engine.results.last('et je prépare des rapports', true);
      engine.status('done');
      await tester.pump(const Duration(milliseconds: 400));
      expect(engine.results, hasLength(2));
      engine.results.last('chaque semaine', false);
      expect(
        shown.last,
        'je travaille au ministère depuis trois ans '
        'et je prépare des rapports chaque semaine',
      );
      await speech.stop();
    });
  });

  group('the screen stays on while the microphone is live', () {
    test('the wake lock is shared, not switched off by the first to leave', () {
      final device = RecordingWakeLock();
      final counter = WakeLockCounter(device);
      final screen = WakeLockHold(counter);
      final dictation = WakeLockHold(counter);

      screen.acquire();
      dictation.acquire();
      dictation.acquire();
      expect(device.calls, ['on'], reason: 'one lock, however many holders');

      dictation.release();
      dictation.release();
      expect(device.calls, ['on'], reason: 'the screen around it still holds');

      screen.release();
      expect(device.calls, ['on', 'off']);
      screen.release();
      expect(device.calls, ['on', 'off'], reason: 'releasing twice is safe');
    });

    testWidgets('dictation holds it from start to stop', (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final device = RecordingWakeLock();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            speechServiceProvider.overrideWithValue(TestSpeech()),
            ttsServiceProvider.overrideWithValue(TestTts()),
            wakeLockProvider.overrideWithValue(device),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: VoiceDraft(
                  controller: controller,
                  onChanged: (_) {},
                  onBusy: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(device.calls, isEmpty, reason: 'not while merely on screen');

      await tester.tap(find.byKey(const Key('partner-mic')));
      await tester.pumpAndSettle();
      expect(device.calls, ['on']);

      await tester.tap(find.byKey(const Key('partner-mic')));
      await tester.pumpAndSettle();
      expect(device.calls, ['on', 'off']);

      // Leaving mid-dictation must release it too.
      await tester.tap(find.byKey(const Key('partner-mic')));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(device.calls, ['on', 'off', 'on', 'off']);
    });
  });
}
