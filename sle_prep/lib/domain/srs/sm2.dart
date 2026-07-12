/// SM-2 spaced-repetition scheduler. Pure Dart — no Flutter imports.
library;

/// User grade for a review, mapped to SM-2 quality scores.
enum ReviewGrade {
  again(1),
  hard(3),
  good(4),
  easy(5);

  const ReviewGrade(this.quality);

  final int quality;
}

class Sm2State {
  const Sm2State({
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.lapses,
  });

  static const initial = Sm2State(
    easeFactor: 2.5,
    intervalDays: 0,
    repetitions: 0,
    lapses: 0,
  );

  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final int lapses;
}

const _minEaseFactor = 1.3;

Sm2State applyGrade(Sm2State s, ReviewGrade g) {
  final q = g.quality;
  final ef = (s.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))
      .clamp(_minEaseFactor, double.infinity)
      .toDouble();

  if (g == ReviewGrade.again) {
    return Sm2State(
      easeFactor: ef,
      intervalDays: 1,
      repetitions: 0,
      lapses: s.lapses + 1,
    );
  }

  final repetitions = s.repetitions + 1;
  final int interval;
  if (repetitions == 1) {
    interval = 1;
  } else if (repetitions == 2) {
    interval = 6;
  } else {
    interval = (s.intervalDays * ef).round();
  }

  return Sm2State(
    easeFactor: ef,
    intervalDays: interval,
    repetitions: repetitions,
    lapses: s.lapses,
  );
}

DateTime nextDue(DateTime now, Sm2State s) =>
    now.add(Duration(days: s.intervalDays));
