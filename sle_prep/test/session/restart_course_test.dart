import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/domain/session/restart_course.dart';
import 'package:sle_prep/domain/session/session_composer.dart';
import 'package:sle_prep/features/settings/course_restart_card.dart';
import 'package:sle_prep/providers.dart';
import '../support/test_db.dart';

void main() {
  test(
    'restart uses week one and retains completed activity, SRS and reports',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final day = DateTime(2026, 9, 11);
      await db.upsertWeek(
        weekNumber: 1,
        themeFr: 'Début',
        themeEn: 'Start',
        grammarTopics: ['present'],
        vocabDomain: 'travail',
        resourceSlots: [],
      );
      await db.setSetting('planStartDate', '2026-07-12');
      await db.setSetting('llmModel', 'my-model');
      final id = await db.insertCardWithState(
        front: 'term',
        back: 'terme',
        exampleFr: '',
        domain: 'personnel',
        now: day,
      );
      final state = await db.reviewStateFor(id);
      await db.insertWritingAttempt(
        promptFr: 'P',
        userText: 'Ma réponse',
        feedback: '{}',
        at: day,
      );
      const oldBlock = SessionBlock(
        id: 'grammarDrillPrimary',
        type: BlockType.grammarDrill,
        minutes: 20,
        titleFr: 'Ancien exercice',
        subtitleFr: 'Ancienne semaine',
        grammarTopics: ['conditionnel'],
      );
      await db.upsertSessionLog(
        day: day,
        blocksPlanned: [oldBlock.id],
        blocksCompleted: [oldBlock.id],
        minutesActive: 20,
        planSnapshot: [oldBlock],
      );
      await restartCourse(db, day);
      expect(await db.getSetting('planStartDate'), '2026-09-11');
      expect(await db.getSetting('llmModel'), 'my-model');
      expect(await db.reviewStateFor(id), state);
      expect((await db.writingHistory()).single.userText, 'Ma réponse');
      final restarted = (await db.sessionLogFor(day))!;
      expect(restarted.minutesActive, 20);
      expect(restarted.blocksCompletedList, ['course-retained-0']);
      expect(restarted.planSnapshotList.first.grammarTopics, ['conditionnel']);
      final primary = restarted.planSnapshotList.singleWhere(
        (b) => b.id == 'grammarDrillPrimary',
      );
      expect(primary.grammarTopics, ['present']);
      expect(await db.currentStreak(day), 1);
      await restartCourse(db, day.add(const Duration(hours: 2)));
      expect(await db.sessionLogFor(day), restarted);
      final updated = await db.toggleSessionBlock(
        day: day,
        blockId: primary.id,
        fallbackPlan: restarted.planSnapshotList,
      );
      expect(updated.minutesActive, 20 + primary.minutes);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          studyDayProvider.overrideWithValue(day),
        ],
      );
      addTearDown(container.dispose);
      expect(
        (await container.read(todayPlanProvider.future)).activeWeek.number,
        1,
      );
    },
  );

  test('missing week one cannot partially reset a course', () async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    await db.setSetting('planStartDate', '2026-07-12');
    await expectLater(
      restartCourse(db, DateTime(2026, 9, 11)),
      throwsStateError,
    );
    expect(await db.getSetting('planStartDate'), '2026-07-12');
    expect(await db.select(db.sessionLogs).get(), isEmpty);
  });

  testWidgets('course reset requires confirmation and refreshes active week', (
    tester,
  ) async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    final day = DateTime(2026, 9, 11);
    for (final number in [1, 2]) {
      await db.upsertWeek(
        weekNumber: number,
        themeFr: 'Semaine $number',
        themeEn: 'Week',
        grammarTopics: ['present'],
        vocabDomain: 'travail',
        resourceSlots: [],
      );
    }
    await db.setSetting('planStartDate', '2026-09-04');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          studyDayProvider.overrideWithValue(day),
        ],
        child: const MaterialApp(home: Scaffold(body: CourseRestartCard())),
      ),
    );
    await tester.tap(find.byKey(const Key('restart-course')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(await db.getSetting('planStartDate'), '2026-09-04');
    await tester.tap(find.byKey(const Key('restart-course')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recommencer'));
    await tester.pumpAndSettle();
    expect(await db.getSetting('planStartDate'), '2026-09-11');
    expect(find.textContaining('Programme redémarré'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CourseRestartCard)),
    );
    expect((await container.read(activeWeekProvider.future)).number, 1);
  });
}
