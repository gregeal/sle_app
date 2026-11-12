/// Finds the time of day at which the learner actually finishes sessions.
library;

import '../weekly/weekly_report.dart' show studyDateKey;

enum DaySlot {
  earlyMorning('Tôt le matin', 5, 9),
  morning('En matinée', 9, 12),
  midday('Le midi', 12, 14),
  afternoon('L’après-midi', 14, 18),
  evening('En soirée', 18, 22),
  night('Tard le soir', 22, 29);

  const DaySlot(this.label, this.startHour, this.endHour);
  final String label;
  final int startHour;
  final int endHour;

  static DaySlot of(DateTime time) {
    final hour = time.hour < 5 ? time.hour + 24 : time.hour;
    return values.firstWhere((s) => hour >= s.startHour && hour < s.endHour);
  }
}

class StudyStretch {
  const StudyStretch(this.startedAt, this.seconds);
  final DateTime startedAt;
  final int seconds;
}

class SlotStat {
  const SlotStat({
    required this.slot,
    required this.days,
    required this.keptDays,
    required this.medianStartMinutes,
  });

  final DaySlot slot;

  /// Days whose first session started in this slot.
  final int days;

  /// Of those, the days that reached the daily target.
  final int keptDays;
  final int medianStartMinutes;

  double get rate => days == 0 ? 0 : keptDays / days;
}

/// Groups days by the slot of their first session and measures how often
/// such a day reached [targetSeconds].
List<SlotStat> analyzeSlots(
  List<StudyStretch> stretches, {
  required int targetSeconds,
}) {
  final byDay = <String, List<StudyStretch>>{};
  for (final stretch in stretches) {
    byDay.putIfAbsent(studyDateKey(stretch.startedAt), () => []).add(stretch);
  }
  final starts = <DaySlot, List<int>>{};
  final kept = <DaySlot, int>{};
  for (final day in byDay.values) {
    day.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final first = day.first.startedAt;
    final slot = DaySlot.of(first);
    starts.putIfAbsent(slot, () => []).add(first.hour * 60 + first.minute);
    final total = day.fold<int>(0, (sum, s) => sum + s.seconds);
    if (total >= targetSeconds) kept[slot] = (kept[slot] ?? 0) + 1;
  }
  return [
    for (final slot in DaySlot.values)
      if (starts[slot] case final minutes?)
        SlotStat(
          slot: slot,
          days: minutes.length,
          keptDays: kept[slot] ?? 0,
          medianStartMinutes: (minutes..sort())[minutes.length ~/ 2],
        ),
  ];
}

/// The slot with the best completion rate, once there is enough evidence to
/// say anything. More days breaks a tie.
SlotStat? bestSlot(List<SlotStat> stats, {int minimumDays = 3}) {
  SlotStat? best;
  for (final stat in stats) {
    if (stat.days < minimumDays || stat.keptDays == 0) continue;
    if (best == null ||
        stat.rate > best.rate ||
        (stat.rate == best.rate && stat.days > best.days)) {
      best = stat;
    }
  }
  return best;
}

class SlotSuggestion {
  const SlotSuggestion(this.label, this.minutes);
  final String label;
  final int minutes;
}

/// Starting points built around the working day, before any data exists.
/// None falls late in the evening: that time stays the learner's own.
List<SlotSuggestion> suggestSlots({
  required int workStartMinutes,
  required int workEndMinutes,
}) {
  int round5(int value) => (value / 5).round() * 5;
  const lunch = 12 * 60 + 15;
  final before = round5(workStartMinutes - 45);
  final after = round5(workEndMinutes + 30);
  return [
    if (before >= 5 * 60 + 30) SlotSuggestion('Avant le travail', before),
    if (workStartMinutes < lunch && lunch < workEndMinutes)
      const SlotSuggestion('À la pause du midi', lunch),
    if (after <= 20 * 60 + 30) SlotSuggestion('Après le travail', after),
  ];
}
