import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/domain/session/session_composer.dart';
import 'package:sle_prep/providers.dart';

import '../support/test_db.dart';

void main() {
  test('fresh-install cards due later today appear in day-one plan', () async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    final studyDay = DateTime(2026, 7, 13);

    await db.upsertWeek(
      weekNumber: 1,
      themeFr: 'Bienvenue',
      themeEn: 'Welcome',
      grammarTopics: const ['present'],
      vocabDomain: 'travail',
      resourceSlots: const [],
    );
    await db.insertCardWithState(
      front: 'a deadline',
      back: 'une échéance',
      exampleFr: 'Il faut respecter cette échéance.',
      domain: 'travail',
      now: studyDay.add(const Duration(hours: 14)),
    );

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        studyDayProvider.overrideWithValue(studyDay),
      ],
    );
    addTearDown(container.dispose);

    final plan = await container.read(todayPlanProvider.future);
    expect(
      plan.blocks.map((block) => block.type),
      contains(BlockType.vocabReview),
    );
  });

  test(
    'the day plan keeps vocabulary after the due queue is reviewed',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final studyDay = DateTime(2026, 7, 13);
      await db.upsertWeek(
        weekNumber: 1,
        themeFr: 'Bienvenue',
        themeEn: 'Welcome',
        grammarTopics: const ['accord', 'subjonctif'],
        vocabDomain: 'travail',
        resourceSlots: const [],
      );
      final cardIds = <int>[];
      for (var index = 0; index < 15; index++) {
        cardIds.add(
          await db.insertCardWithState(
            front: 'term $index',
            back: 'terme $index',
            exampleFr: 'Exemple $index.',
            domain: 'travail',
            now: studyDay.add(const Duration(hours: 9)),
          ),
        );
      }
      final accordItem = await db.insertDrillItem(
        topic: 'accord',
        prompt: 'p',
        options: const ['a', 'b', 'c', 'd'],
        correctIndex: 0,
        explanationFr: 'e',
      );
      await db.recordAttempt(accordItem, wasCorrect: true, at: studyDay);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          studyDayProvider.overrideWithValue(studyDay),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(todayPlanProvider.future);
      final initialVocab = initial.blocks.singleWhere(
        (block) => block.id == 'vocabReview',
      );
      final initialTopics = initial.blocks
          .singleWhere((block) => block.id == 'grammarDrillPrimary')
          .grammarTopics;
      expect(initialVocab.minutes, 15);
      for (final cardId in cardIds) {
        final state = await db.reviewStateFor(cardId);
        await db.applyReview(
          cardId: cardId,
          easeFactor: state.easeFactor,
          intervalDays: 1,
          repetitions: 1,
          lapses: 0,
          dueDate: studyDay.add(const Duration(days: 1)),
        );
      }
      await db.recordAttempt(
        accordItem,
        wasCorrect: false,
        at: studyDay.add(const Duration(minutes: 1)),
      );
      await db.recordAttempt(
        accordItem,
        wasCorrect: false,
        at: studyDay.add(const Duration(minutes: 2)),
      );
      container.invalidate(todayPlanProvider);

      final refreshed = await container.read(todayPlanProvider.future);
      final refreshedVocab = refreshed.blocks.singleWhere(
        (block) => block.id == 'vocabReview',
      );
      final refreshedTopics = refreshed.blocks
          .singleWhere((block) => block.id == 'grammarDrillPrimary')
          .grammarTopics;
      expect(refreshedVocab.minutes, 15);
      expect(refreshedTopics, initialTopics);
    },
  );

  test(
    'block toggles read latest state and preserve both quick updates',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final day = DateTime(2026, 7, 13);
      const plan = [
        SessionBlock(
          id: 'vocabReview',
          type: BlockType.vocabReview,
          minutes: 10,
          titleFr: 'Vocabulaire',
          subtitleFr: 'Révision',
        ),
        SessionBlock(
          id: 'grammarDrillPrimary',
          type: BlockType.grammarDrill,
          minutes: 15,
          titleFr: 'Grammaire',
          subtitleFr: 'Accord',
          grammarTopics: ['accord'],
        ),
      ];
      await db.ensureSessionPlan(day: day, blocks: plan);

      await Future.wait([
        db.toggleSessionBlock(
          day: day,
          blockId: 'vocabReview',
          fallbackPlan: plan,
        ),
        db.toggleSessionBlock(
          day: day,
          blockId: 'grammarDrillPrimary',
          fallbackPlan: plan,
        ),
      ]);

      final log = await db.sessionLogFor(day);
      expect(log!.blocksCompletedList.toSet(), {
        'vocabReview',
        'grammarDrillPrimary',
      });
      expect(log.minutesActive, 25);
    },
  );

  test('calendar day differences do not depend on elapsed DST hours', () {
    expect(
      calendarDayDifference(DateTime(2026, 3, 7, 23), DateTime(2026, 3, 9, 1)),
      2,
    );
    expect(
      calendarDayDifference(
        DateTime(2026, 10, 31, 23),
        DateTime(2026, 11, 2, 1),
      ),
      2,
    );
  });
}
