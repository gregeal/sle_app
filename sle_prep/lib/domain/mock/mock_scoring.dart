import 'dart:convert';

/// Approximate, unofficial mapping from a short formative score to an SLE level.
///
/// The common envelope of the published supervised reading/writing cut lines
/// is about 36% for A, 56% for B and 76–78% for C. A short in-app sample is
/// much less reliable than those full tests, so this is only a progress signal.

String levelForFraction(double fraction) {
  if (!fraction.isFinite || fraction < 0 || fraction > 1) {
    throw RangeError.range(fraction, 0, 1, 'fraction');
  }
  return fraction >= 0.78
      ? 'C'
      : fraction >= 0.56
      ? 'B'
      : fraction >= 0.36
      ? 'A'
      : 'X';
}

/// Reads only the canonical level field saved by the oral feedback validator.
/// Corrupt feedback is never silently promoted to a default level.
String? oralLevelFromFeedback(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) return null;
    final level = decoded['levelEstimate'];
    return level is String && const {'A', 'B', 'B+', 'C'}.contains(level)
        ? level
        : null;
  } on FormatException {
    return null;
  }
}

/// Checkpoints run every 28 days from the study plan's start date. Returns
/// the first checkpoint date that is on or after [today].
DateTime nextCheckpoint(DateTime planStart, DateTime today) {
  final start = DateTime(planStart.year, planStart.month, planStart.day);
  final day = DateTime(today.year, today.month, today.day);
  var checkpoint = DateTime(start.year, start.month, start.day + 28);
  while (checkpoint.isBefore(day)) {
    checkpoint = DateTime(
      checkpoint.year,
      checkpoint.month,
      checkpoint.day + 28,
    );
  }
  return checkpoint;
}
