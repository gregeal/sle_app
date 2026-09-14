import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/speaking_daos.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/domain/speech/speech_services.dart';
import 'package:sle_prep/features/speaking/speaking_session_screen.dart';
import 'package:sle_prep/features/speaking/speaking_mistakes_screen.dart';
import 'package:sle_prep/features/speaking/speaking_home_screen.dart';
import 'package:sle_prep/providers.dart';
import '../support/test_db.dart';
import 'speaking_partner_test.dart'
    show PartnerClient, learnerAnswer, validFeedback;

class TestSpeech implements SpeechService {
  void Function(String)? result;
  void Function()? done;
  int stops = 0;
  bool failListen = false;
  String? finalTextOnStop;
  @override
  bool isListening = false;
  @override
  Future<bool> initialize() async => true;
  @override
  Future<void> listen({
    required void Function(String) onResult,
    required void Function() onDone,
  }) async {
    isListening = true;
    result = onResult;
    done = onDone;
    if (failListen) throw StateError('Microphone startup failed');
  }

  @override
  Future<void> stop() async {
    stops++;
    if (isListening && finalTextOnStop != null) result?.call(finalTextOnStop!);
    isListening = false;
  }
}

class TestTts implements TtsService {
  final spoken = <String>[];
  int stops = 0;
  @override
  Future<void> speak(String textFr) async {
    spoken.add(textFr);
  }

  @override
  Future<void> stop() async {
    stops++;
  }
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'speech pauses do not submit, continued answer saves corrections and spoken reply',
    (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final id = await db.createSpeakingSession(
        topic: 'Travail',
        prompt: 'Pourquoi ?',
        now: DateTime.now(),
      );
      final speech = TestSpeech();
      final tts = TestTts();
      final client = PartnerClient();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            llmClientProvider.overrideWith((ref) async => client),
            speechServiceProvider.overrideWithValue(speech),
            ttsServiceProvider.overrideWithValue(tts),
          ],
          child: MaterialApp(home: SpeakingSessionScreen(sessionId: id)),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('partner-mic')));
      speech.result!(learnerAnswer);
      await tester.pump(const Duration(seconds: 2));
      expect(client.calls, 0);
      speech.isListening = false;
      speech.done!();
      await tester.pumpAndSettle();
      expect(client.calls, 0);
      await tapVisible(tester, find.byKey(const Key('partner-mic')));
      speech.result!('Je demanderais aussi un avis.');
      await tester.pump();
      await tapVisible(tester, find.byKey(const Key('partner-mic')));
      await tapVisible(tester, find.byKey(const Key('partner-submit')));
      expect(client.calls, 1);
      final saved = (await db.speakingHistory(id)).single;
      expect(saved.answer, contains(learnerAnswer));
      expect(saved.answer, contains('Je demanderais aussi un avis.'));
      expect(await db.speakingMistakeLibrary(), hasLength(1));
      expect((await db.speakingMistakeLibrary()).single.repetitions, 0);
      expect(tts.spoken, contains(validFeedback.reply));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(speech.isListening, isFalse);
    },
  );

  testWidgets(
    'network failure retains draft and a reopened session can retry',
    (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final id = await db.createSpeakingSession(
        topic: 'Travail',
        prompt: 'Pourquoi ?',
        now: DateTime.now(),
      );
      final client = PartnerClient()..fail = true;
      Widget app() => ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          llmClientProvider.overrideWith((ref) async => client),
          speechServiceProvider.overrideWithValue(TestSpeech()),
          ttsServiceProvider.overrideWithValue(TestTts()),
        ],
        child: MaterialApp(home: SpeakingSessionScreen(sessionId: id)),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), learnerAnswer);
      await tapVisible(tester, find.byKey(const Key('partner-submit')));
      expect((await db.speakingSession(id)).draft, learnerAnswer);
      expect(await db.speakingHistory(id), isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      client.fail = false;
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        learnerAnswer,
      );
      await tapVisible(tester, find.byKey(const Key('partner-submit')));
      expect(await db.speakingHistory(id), hasLength(1));
      expect((await db.speakingSession(id)).draft, '');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'solo review reveals before self-grading and schedules without AI',
    (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final id = await db.createSpeakingSession(
        topic: 'Travail',
        prompt: 'Pourquoi ?',
        now: DateTime.now(),
      );
      await db.saveSpeakingTurn(
        sessionId: id,
        turnNumber: 0,
        prompt: 'Pourquoi ?',
        answer: learnerAnswer,
        feedback: validFeedback,
        now: DateTime.now(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            speechServiceProvider.overrideWithValue(TestSpeech()),
            ttsServiceProvider.overrideWithValue(TestTts()),
          ],
          child: const MaterialApp(home: SpeakingSoloScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bien'), findsNothing);
      await tapVisible(tester, find.text('Révéler après mon essai'));
      await tapVisible(tester, find.text('Bien'));
      expect((await db.speakingMistakeLibrary()).single.repetitions, 1);
      expect(await db.speakingMistakeLibrary(dueBy: DateTime.now()), isEmpty);
      expect(find.textContaining('Révision terminée'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('backgrounding stops the microphone and retains dictated text', (
    tester,
  ) async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    final id = await db.createSpeakingSession(
      topic: 'Travail',
      prompt: 'Pourquoi ?',
      now: DateTime.now(),
    );
    final speech = TestSpeech()..finalTextOnStop = '$learnerAnswer Merci.';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          speechServiceProvider.overrideWithValue(speech),
          ttsServiceProvider.overrideWithValue(TestTts()),
        ],
        child: MaterialApp(home: SpeakingSessionScreen(sessionId: id)),
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('partner-mic')));
    speech.result!(learnerAnswer);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(speech.isListening, isFalse);
    expect((await db.speakingSession(id)).draft, '$learnerAnswer Merci.');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'existing Coach answer imports as a draft without an AI request',
    (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      await db.recordOralAttempt(
        mode: 'daily',
        exchanges: [
          {'question': 'Pourquoi ?', 'answer': learnerAnswer},
        ],
        feedback: '{}',
        at: DateTime.now(),
      );
      final client = PartnerClient();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            llmClientProvider.overrideWith((ref) async => client),
            speechServiceProvider.overrideWithValue(TestSpeech()),
            ttsServiceProvider.overrideWithValue(TestTts()),
          ],
          child: const MaterialApp(home: SpeakingHomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Reprendre une réponse du Coach'));
      await tester.tap(find.text('Pourquoi ?'));
      await tester.pumpAndSettle();
      expect(client.calls, 0);
      expect((await db.recentSpeakingSessions()).single.draft, learnerAnswer);
      expect(
        (await db.oralHistory()).single.exchangesList.single['answer'],
        learnerAnswer,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('failed microphone start cleans up and permits typed practice', (
    tester,
  ) async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    final id = await db.createSpeakingSession(
      topic: 'Travail',
      prompt: 'Pourquoi ?',
      now: DateTime.now(),
    );
    final speech = TestSpeech()..failListen = true;
    final client = PartnerClient();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          llmClientProvider.overrideWith((ref) async => client),
          speechServiceProvider.overrideWithValue(speech),
          ttsServiceProvider.overrideWithValue(TestTts()),
        ],
        child: MaterialApp(home: SpeakingSessionScreen(sessionId: id)),
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('partner-mic')));
    expect(speech.isListening, isFalse);
    expect(speech.stops, greaterThan(0));
    expect(client.calls, 0);
    await tester.enterText(find.byType(TextField), learnerAnswer);
    await tapVisible(tester, find.byKey(const Key('partner-submit')));
    expect(await db.speakingHistory(id), hasLength(1));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
