import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/weekly_daos.dart';
import 'package:sle_prep/domain/weekly/weekly_plan.dart';
import 'package:sle_prep/domain/weekly/weekly_report.dart';
import 'package:sle_prep/domain/speech/speech_services.dart';
import 'package:sle_prep/features/weekly/placement_screen.dart';
import 'package:sle_prep/features/weekly/weekly_class_screen.dart';
import 'package:sle_prep/features/today/today_screen.dart';
import 'package:sle_prep/features/word_help/word_help_guard.dart';
import 'package:sle_prep/providers.dart';
import '../support/test_db.dart';

class Speech implements SpeechService {
  bool active = false;
  int stops = 0;
  @override
  Future<bool> initialize() async => true;
  @override
  Future<void> listen({
    required void Function(String) onResult,
    required void Function() onDone,
  }) async {
    active = true;
    onResult('Je travaille dans une équipe et je prépare des rapports.');
  }

  @override
  Future<void> stop() async {
    active = false;
    stops++;
  }

  @override
  bool get isListening => active;
}

class Tts implements TtsService {
  @override
  Future<void> speak(String textFr) async {}
  @override
  Future<void> stop() async {}
}

void main() {
  testWidgets(
    'placement capture blocks helper navigation and stops on background',
    (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final speech = Speech();
      final guard = WordHelpGuard();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            speechServiceProvider.overrideWithValue(speech),
            ttsServiceProvider.overrideWithValue(Tts()),
            wordHelpGuardProvider.overrideWithValue(guard),
          ],
          child: const MaterialApp(home: PlacementScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final mic = find.byKey(const Key('partner-mic'));
      await tester.ensureVisible(mic);
      await tester.pumpAndSettle();
      await tester.tap(mic);
      await tester.pumpAndSettle();
      expect(speech.active, isTrue);
      expect(guard.blocked, isTrue);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(speech.active, isFalse);
      expect(speech.stops, greaterThan(0));
      expect(guard.blocked, isFalse);
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'class restores its stage and does not allow an unchecked quiz to advance',
    (tester) async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final id = await db.createStudyWeek(
        plan: composeWeeklyPlan(
          weekNumber: 1,
          trackId: 'b-to-c-v1',
          lessonId: '01-detail',
          lessonTitleFr: 'Décrire',
        ),
        startDate: DateTime(2026, 11, 2),
      );
      await db.saveClassProgress(
        id,
        const ClassProgress(stage: 1, answers: [null, null]),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            ttsServiceProvider.overrideWithValue(Tts()),
          ],
          child: MaterialApp(
            home: WeeklyClassScreen(week: (await db.studyWeek(id))!),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, 1);
      final next = find.byKey(const Key('class-continue-1'));
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, 1);
      expect(find.textContaining('Terminez cette étape'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('weekly Today uses the same assignments and keeps rest days free', (
    tester,
  ) async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    final id = await db.createStudyWeek(
      plan: composeWeeklyPlan(
        weekNumber: 1,
        trackId: 'b-to-c-v1',
        lessonId: '01-detail',
        lessonTitleFr: 'Décrire',
      ),
      startDate: DateTime(2026, 11, 2),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          studyDayProvider.overrideWithValue(DateTime(2026, 11, 2)),
        ],
        child: const MaterialApp(home: Scaffold(body: TodayScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Classe de la semaine'), findsOneWidget);
    expect(find.text('Pratique guidée en direct'), findsOneWidget);
    expect((await db.assignmentsForDay(id, 1)).length, greaterThan(1));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    // Sunday before the first scheduled session is a rest day, not a legacy plan.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          studyDayProvider.overrideWithValue(DateTime(2026, 11, 1)),
        ],
        child: const MaterialApp(home: Scaffold(body: TodayScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Repos ou prochaine séance à venir.'), findsOneWidget);
    expect(find.text('Séance d’aujourd’hui'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
