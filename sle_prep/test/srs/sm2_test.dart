import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/domain/srs/sm2.dart';

void main() {
  const fresh = Sm2State.initial;
  final now = DateTime(2026, 7, 12, 9, 0);

  group('applyGrade — successful reviews', () {
    test('first good review schedules 1 day out', () {
      final s = applyGrade(fresh, ReviewGrade.good);
      expect(s.repetitions, 1);
      expect(s.intervalDays, 1);
      expect(s.lapses, 0);
    });

    test('second good review schedules 6 days out', () {
      final s1 = applyGrade(fresh, ReviewGrade.good);
      final s2 = applyGrade(s1, ReviewGrade.good);
      expect(s2.repetitions, 2);
      expect(s2.intervalDays, 6);
    });

    test('third good review multiplies by ease factor', () {
      var s = fresh;
      for (var i = 0; i < 3; i++) {
        s = applyGrade(s, ReviewGrade.good);
      }
      expect(s.repetitions, 3);
      expect(s.intervalDays, (6 * s.easeFactor).round());
    });

    test('easy raises the ease factor, hard lowers it', () {
      final easy = applyGrade(fresh, ReviewGrade.easy);
      final good = applyGrade(fresh, ReviewGrade.good);
      final hard = applyGrade(fresh, ReviewGrade.hard);
      expect(easy.easeFactor, greaterThan(good.easeFactor));
      expect(hard.easeFactor, lessThan(good.easeFactor));
    });

    test('hard keeps progress (repetitions still advance)', () {
      final s = applyGrade(fresh, ReviewGrade.hard);
      expect(s.repetitions, 1);
      expect(s.lapses, 0);
    });
  });

  group('applyGrade — lapses', () {
    test('again resets repetitions and interval, counts a lapse', () {
      var s = fresh;
      for (var i = 0; i < 3; i++) {
        s = applyGrade(s, ReviewGrade.good);
      }
      final lapsed = applyGrade(s, ReviewGrade.again);
      expect(lapsed.repetitions, 0);
      expect(lapsed.intervalDays, 1);
      expect(lapsed.lapses, 1);
    });

    test('ease factor never drops below 1.3', () {
      var s = fresh;
      for (var i = 0; i < 20; i++) {
        s = applyGrade(s, ReviewGrade.again);
      }
      expect(s.easeFactor, greaterThanOrEqualTo(1.3));
    });
  });

  group('nextDue', () {
    test('schedules intervalDays after now', () {
      final s = applyGrade(fresh, ReviewGrade.good);
      expect(nextDue(now, s), now.add(const Duration(days: 1)));
    });

    test('again is due again within the same day (interval 1 → tomorrow)', () {
      final s = applyGrade(fresh, ReviewGrade.again);
      expect(nextDue(now, s), now.add(const Duration(days: 1)));
    });
  });
}
