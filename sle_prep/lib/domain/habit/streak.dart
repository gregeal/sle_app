/// The study streak. Pure Dart so the rest-day rule can be tested directly.
library;

import '../weekly/weekly_report.dart' show studyDateKey;

/// A day counts once this much real study time has been logged. It is the
/// "I only have five minutes" floor: small enough to keep on a bad day.
const kDailyFloorSeconds = 5 * 60;

/// Consecutive kept days ending today, or yesterday while today is still open.
///
/// A scheduled rest day never breaks the chain. It only adds to the count if
/// the learner studied anyway.
int computeStreak({
  required DateTime today,
  required Set<String> activeDays,
  required bool Function(DateTime day) isRestDay,
  int lookbackDays = 3660,
}) {
  var day = DateTime(today.year, today.month, today.day);
  if (!activeDays.contains(studyDateKey(day))) {
    day = DateTime(day.year, day.month, day.day - 1);
  }
  var streak = 0;
  for (var i = 0; i < lookbackDays; i++) {
    if (activeDays.contains(studyDateKey(day))) {
      streak++;
    } else if (!isRestDay(day)) {
      break;
    }
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return streak;
}
