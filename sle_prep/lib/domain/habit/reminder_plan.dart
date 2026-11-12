/// Decides which reminders exist and when each one first fires. Pure Dart:
/// the platform layer only turns these into scheduled notifications.
library;

import 'habit_settings.dart';

/// No second nudge is ever sent after this time: evenings stay free.
const kLatestNudgeMinutes = 21 * 60;
const kNudgeDelayMinutes = 180;

enum ReminderKind { primary, nudge }

class ReminderSpec {
  const ReminderSpec({
    required this.id,
    required this.weekday,
    required this.kind,
    required this.classDay,
    required this.firstFire,
  });

  /// Stable per weekday and kind, so rescheduling replaces rather than adds.
  final int id;
  final int weekday;
  final ReminderKind kind;
  final bool classDay;

  /// First occurrence, local time. It then repeats every seven days.
  final DateTime firstFire;
}

int reminderId(int weekday, ReminderKind kind) =>
    (kind == ReminderKind.primary ? 100 : 200) + weekday;

/// Every id this planner can ever produce, for cancelling stale schedules.
List<int> get allReminderIds => [
  for (final kind in ReminderKind.values)
    for (var weekday = 1; weekday <= 7; weekday++) reminderId(weekday, kind),
];

/// One weekly-repeating reminder per active weekday, plus a gentler nudge
/// three hours later when that still falls before [kLatestNudgeMinutes].
///
/// When [doneToday] is true, today's occurrences are pushed to next week so
/// a learner who already studied is not asked again.
List<ReminderSpec> planReminders({
  required DateTime now,
  required HabitSettings settings,
  required bool doneToday,
}) {
  if (!settings.remindersEnabled) return const [];
  final specs = <ReminderSpec>[];
  for (final weekday in settings.activeWeekdays.toList()..sort()) {
    final classDay = settings.classDays.contains(weekday);
    final times = <ReminderKind, int>{
      ReminderKind.primary: settings.reminderMinutes,
      if (settings.reminderMinutes + kNudgeDelayMinutes <= kLatestNudgeMinutes)
        ReminderKind.nudge: settings.reminderMinutes + kNudgeDelayMinutes,
    };
    for (final entry in times.entries) {
      specs.add(
        ReminderSpec(
          id: reminderId(weekday, entry.key),
          weekday: weekday,
          kind: entry.key,
          classDay: classDay,
          firstFire: _nextOccurrence(
            now: now,
            weekday: weekday,
            minutes: entry.value,
            skipToday: doneToday,
          ),
        ),
      );
    }
  }
  return specs;
}

DateTime _nextOccurrence({
  required DateTime now,
  required int weekday,
  required int minutes,
  required bool skipToday,
}) {
  for (var offset = 0; offset <= 7; offset++) {
    // Built from calendar fields so a DST change keeps the wall-clock time.
    final candidate = DateTime(
      now.year,
      now.month,
      now.day + offset,
      minutes ~/ 60,
      minutes % 60,
    );
    if (candidate.weekday != weekday) continue;
    if (offset == 0 && (skipToday || !candidate.isAfter(now))) continue;
    return candidate;
  }
  throw StateError('A weekday always recurs within eight days.');
}

String reminderTitle(ReminderSpec spec) => spec.classDay
    ? 'Jour de cours · 10 minutes pour vous préparer'
    : spec.kind == ReminderKind.primary
    ? 'Votre séance de français vous attend'
    : 'Encore le temps pour cinq minutes';

String reminderBody(ReminderSpec spec, int dailyMinutes) => spec.classDay
    ? 'Un court échauffement avant le cours, puis notez ce que vous en '
          'retenez.'
    : spec.kind == ReminderKind.primary
    ? '$dailyMinutes minutes aujourd’hui. Même cinq minutes comptent.'
    : 'Cinq minutes suffisent pour garder le rythme. Sans pression.';
