/// Approximate, unofficial mapping from a mock score to an SLE level.
///
/// Anchored loosely on published supervised cut-scores (e.g. ~43/55 for a C
/// on reading) — treated as rough guidance, never an official claim.
library;

String levelForFraction(double fraction) =>
    fraction >= 0.78 ? 'C' : (fraction >= 0.55 ? 'B' : 'A');

/// Checkpoints run every 28 days from the study plan's start date. Returns
/// the first checkpoint date that is on or after [today].
DateTime nextCheckpoint(DateTime planStart, DateTime today) {
  final start = DateTime(planStart.year, planStart.month, planStart.day);
  final day = DateTime(today.year, today.month, today.day);
  var checkpoint = start.add(const Duration(days: 28));
  while (checkpoint.isBefore(day)) {
    checkpoint = checkpoint.add(const Duration(days: 28));
  }
  return checkpoint;
}
