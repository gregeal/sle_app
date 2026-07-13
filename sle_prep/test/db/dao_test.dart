import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/database.dart';
import 'package:sle_prep/data/db/daos.dart';

import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 7, 12, 9, 0);

  setUp(() => db = inMemoryDatabase());
  tearDown(() => db.close());

  group('vocab cards and review states', () {
    test(
      'inserting a card creates a default review state due immediately',
      () async {
        final id = await db.insertCardWithState(
          front: 'the deadline',
          back: "l'échéance (n. f.)",
          exampleFr: 'Il faut respecter l\'échéance.',
          domain: 'gestion_projet',
          now: now,
        );

        final state = await db.reviewStateFor(id);
        expect(state.easeFactor, 2.5);
        expect(state.intervalDays, 0);
        expect(state.repetitions, 0);
        expect(state.lapses, 0);

        final due = await db.dueCards(now);
        expect(due.map((c) => c.card.id), contains(id));
      },
    );

    test('dueCards excludes cards scheduled in the future', () async {
      final id = await db.insertCardWithState(
        front: 'a',
        back: 'b',
        exampleFr: 'c',
        domain: 'd',
        now: now,
      );
      await db.applyReview(
        cardId: id,
        easeFactor: 2.5,
        intervalDays: 6,
        repetitions: 2,
        lapses: 0,
        dueDate: now.add(const Duration(days: 6)),
      );

      expect(await db.dueCards(now), isEmpty);
      final later = await db.dueCards(now.add(const Duration(days: 6)));
      expect(later.map((c) => c.card.id), contains(id));
    });

    test('applyReview persists the new scheduling state', () async {
      final id = await db.insertCardWithState(
        front: 'a',
        back: 'b',
        exampleFr: 'c',
        domain: 'd',
        now: now,
      );
      await db.applyReview(
        cardId: id,
        easeFactor: 2.36,
        intervalDays: 1,
        repetitions: 1,
        lapses: 1,
        dueDate: now.add(const Duration(days: 1)),
      );
      final state = await db.reviewStateFor(id);
      expect(state.easeFactor, closeTo(2.36, 1e-9));
      expect(state.intervalDays, 1);
      expect(state.repetitions, 1);
      expect(state.lapses, 1);
    });
  });

  group('drill items and attempts', () {
    Future<int> seedItem(String topic) => db.insertDrillItem(
      topic: topic,
      prompt: 'La gestionnaire exige que le rapport ___ remis.',
      options: const ['est', 'soit', 'sera', 'serait'],
      correctIndex: 1,
      explanationFr: 'Exiger que déclenche le subjonctif.',
    );

    test('randomDrillItems filters by topic and respects the limit', () async {
      for (var i = 0; i < 5; i++) {
        await seedItem('subjonctif_present');
      }
      await seedItem('pronoms_y_en');

      final items = await db.randomDrillItems(['subjonctif_present'], 3);
      expect(items, hasLength(3));
      expect(items.every((i) => i.topic == 'subjonctif_present'), isTrue);

      final decoded = items.first.optionsList;
      expect(decoded, hasLength(4));
      expect(decoded[1], 'soit');
    });

    test('topicAccuracy aggregates attempts per topic', () async {
      final a = await seedItem('subjonctif_present');
      final b = await seedItem('subjonctif_present');
      final c = await seedItem('pronoms_y_en');

      await db.recordAttempt(a, wasCorrect: true, at: now);
      await db.recordAttempt(b, wasCorrect: false, at: now);
      await db.recordAttempt(c, wasCorrect: true, at: now);

      final acc = await db.topicAccuracy();
      expect(acc['subjonctif_present'], closeTo(0.5, 1e-9));
      expect(acc['pronoms_y_en'], closeTo(1.0, 1e-9));
    });
  });

  group('curriculum weeks', () {
    test('weekByNumber round-trips JSON fields', () async {
      await db.upsertWeek(
        weekNumber: 8,
        themeFr: "Réunions d'équipe",
        themeEn: 'Team meetings',
        grammarTopics: const ['subjonctif_present', 'verbes_volonte'],
        vocabDomain: 'gestion_projet',
        resourceSlots: const [
          {'label': 'Mauril', 'url': 'https://mauril.ca'},
        ],
      );

      final week = await db.weekByNumber(8);
      expect(week, isNotNull);
      expect(week!.grammarTopicsList, ['subjonctif_present', 'verbes_volonte']);
      expect(week.resourceSlotsList.single['label'], 'Mauril');
      expect(await db.weekByNumber(9), isNull);
    });
  });

  group('session logs and streak', () {
    test('upsertSessionLog is idempotent per date', () async {
      await db.upsertSessionLog(
        day: DateTime(2026, 7, 12),
        blocksPlanned: const ['vocabReview', 'grammarDrill'],
        blocksCompleted: const ['vocabReview'],
        minutesActive: 15,
      );
      await db.upsertSessionLog(
        day: DateTime(2026, 7, 12),
        blocksPlanned: const ['vocabReview', 'grammarDrill'],
        blocksCompleted: const ['vocabReview', 'grammarDrill'],
        minutesActive: 30,
      );

      final log = await db.sessionLogFor(DateTime(2026, 7, 12));
      expect(log, isNotNull);
      expect(log!.blocksCompletedList, hasLength(2));
      expect(log.minutesActive, 30);
    });

    test(
      'currentStreak counts consecutive active days ending today or yesterday',
      () async {
        Future<void> logDay(DateTime d) => db.upsertSessionLog(
          day: d,
          blocksPlanned: const ['vocabReview'],
          blocksCompleted: const ['vocabReview'],
          minutesActive: 20,
        );

        final today = DateTime(2026, 7, 12);
        await logDay(today);
        await logDay(today.subtract(const Duration(days: 1)));
        await logDay(today.subtract(const Duration(days: 2)));
        // gap at day -3
        await logDay(today.subtract(const Duration(days: 4)));

        expect(await db.currentStreak(today), 3);
      },
    );

    test('streak survives when today has no session yet', () async {
      final today = DateTime(2026, 7, 12);
      await db.upsertSessionLog(
        day: today.subtract(const Duration(days: 1)),
        blocksPlanned: const ['vocabReview'],
        blocksCompleted: const ['vocabReview'],
        minutesActive: 20,
      );
      expect(await db.currentStreak(today), 1);
    });

    test('streak is zero with no recent activity', () async {
      expect(await db.currentStreak(DateTime(2026, 7, 12)), 0);
    });
  });

  group('app settings', () {
    test('setSetting/getSetting round-trip and overwrite', () async {
      expect(await db.getSetting('seedVersion'), isNull);
      await db.setSetting('seedVersion', '1');
      await db.setSetting('seedVersion', '2');
      expect(await db.getSetting('seedVersion'), '2');
    });
  });
}
