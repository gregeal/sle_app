import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/domain/mock/mock_scoring.dart';

import '../support/test_db.dart';

void main() {
  final now = DateTime(2026, 7, 13, 9, 0);

  group('mock results', () {
    test('latestMockPerSkill returns the newest result per skill', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);

      await db.recordMockResult(
        skill: 'reading',
        score: 6,
        total: 10,
        levelEstimate: 'B',
        at: now,
      );
      await db.recordMockResult(
        skill: 'reading',
        score: 8,
        total: 10,
        levelEstimate: 'C',
        at: now.add(const Duration(days: 28)),
      );
      await db.recordMockResult(
        skill: 'oral',
        score: 0,
        total: 0,
        levelEstimate: 'B',
        at: now,
      );

      final latest = await db.latestMockPerSkill();
      expect(latest['reading']!.levelEstimate, 'C');
      expect(latest['oral']!.levelEstimate, 'B');
      expect(latest.containsKey('writing'), isFalse);
    });
  });

  group('supporting stats', () {
    test('totalActiveMinutes sums session logs', () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);

      await db.upsertSessionLog(
        day: DateTime(2026, 7, 12),
        blocksPlanned: const [],
        blocksCompleted: const ['vocabReview'],
        minutesActive: 45,
      );
      await db.upsertSessionLog(
        day: DateTime(2026, 7, 13),
        blocksPlanned: const [],
        blocksCompleted: const ['vocabReview'],
        minutesActive: 30,
      );

      expect(await db.totalActiveMinutes(), 75);
    });

    test(
      'drillStatsSince counts only attempts at or after the cutoff',
      () async {
        final db = inMemoryDatabase();
        addTearDown(db.close);

        final itemId = await db.insertDrillItem(
          topic: 't',
          prompt: 'p',
          options: const ['a', 'b', 'c', 'd'],
          correctIndex: 0,
          explanationFr: 'e',
        );
        await db.recordAttempt(
          itemId,
          wasCorrect: true,
          at: now.subtract(const Duration(days: 1)),
        );
        await db.recordAttempt(itemId, wasCorrect: true, at: now);
        await db.recordAttempt(
          itemId,
          wasCorrect: false,
          at: now.add(const Duration(minutes: 5)),
        );

        final stats = await db.drillStatsSince(now);
        expect(stats.total, 2);
        expect(stats.correct, 1);
      },
    );
  });

  group('mock scoring', () {
    test('maps fractions to approximate SLE levels', () {
      expect(levelForFraction(0.9), 'C');
      expect(levelForFraction(0.78), 'C');
      expect(levelForFraction(0.7), 'B');
      expect(levelForFraction(0.56), 'B');
      expect(levelForFraction(0.4), 'A');
      expect(levelForFraction(0.2), 'X');
      expect(() => levelForFraction(1.1), throwsRangeError);
    });

    test(
      'reads oral levels without inventing a default for corrupt feedback',
      () {
        expect(oralLevelFromFeedback('{"levelEstimate":"C"}'), 'C');
        expect(oralLevelFromFeedback('{"levelEstimate":"E"}'), isNull);
        expect(oralLevelFromFeedback('not-json'), isNull);
      },
    );

    test('nextCheckpoint lands every 28 days after the plan start', () {
      final start = DateTime(2026, 7, 12);
      expect(
        nextCheckpoint(start, DateTime(2026, 7, 13)),
        DateTime(2026, 8, 9),
      );
      expect(nextCheckpoint(start, DateTime(2026, 8, 9)), DateTime(2026, 8, 9));
      expect(
        nextCheckpoint(start, DateTime(2026, 8, 10)),
        DateTime(2026, 9, 6),
      );
    });
  });
}
