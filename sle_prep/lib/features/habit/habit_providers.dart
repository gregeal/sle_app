import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/daos.dart';
import '../../data/db/habit_daos.dart';
import '../../domain/habit/habit_settings.dart';
import '../../domain/habit/journey.dart';
import '../../domain/habit/reminder_plan.dart';
import '../../domain/weekly/weekly_report.dart' show studyDateKey;
import '../../providers.dart';
import 'reminder_service.dart';

enum DayType { study, groupClass, rest }

/// Everything the home screen needs to say "here is where you are".
class HabitSnapshot {
  const HabitSnapshot({
    required this.settings,
    required this.dayType,
    required this.streak,
    required this.todaySeconds,
    required this.weekActiveDays,
    required this.keptWeeks,
    required this.journey,
    required this.checkinDue,
  });

  final HabitSettings settings;
  final DayType dayType;
  final int streak;
  final int todaySeconds;

  /// Days kept in the current Monday-to-Sunday week.
  final int weekActiveDays;
  final int keptWeeks;
  final JourneyStage journey;

  /// Last week had activity and has not been reviewed yet.
  final bool checkinDue;

  int get weekPlannedDays => settings.activeWeekdays.length;
}

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => defaultReminderService(),
);

final habitSettingsProvider = FutureProvider<HabitSettings>(
  (ref) => ref.watch(appDatabaseProvider).habitSettings(),
);

DateTime mondayOf(DateTime day) =>
    DateTime(day.year, day.month, day.day - (day.weekday - 1));

final habitSnapshotProvider = FutureProvider<HabitSnapshot>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final today = ref.watch(studyDayProvider);
  final settings = await db.habitSettings();
  final active = await db.activeDayKeys();
  final thisMonday = mondayOf(today);
  final lastMonday = DateTime(
    thisMonday.year,
    thisMonday.month,
    thisMonday.day - 7,
  );
  var lastWeekActive = false;
  for (var offset = 0; offset < 7 && !lastWeekActive; offset++) {
    lastWeekActive = active.contains(
      studyDateKey(
        DateTime(lastMonday.year, lastMonday.month, lastMonday.day + offset),
      ),
    );
  }
  final lastCheckin = await db.getSetting('habit:lastCheckin');
  final keptWeeks = await db.keptWeeks(today, settings);
  return HabitSnapshot(
    settings: settings,
    dayType: settings.isClassDay(today)
        ? DayType.groupClass
        : settings.isStudyDay(today)
        ? DayType.study
        : DayType.rest,
    streak: await db.currentStreak(today),
    todaySeconds: await db.secondsOn(today),
    weekActiveDays: await db.activeDaysInWeekOf(today),
    keptWeeks: keptWeeks,
    journey: journeyFor(keptWeeks: keptWeeks),
    checkinDue:
        lastWeekActive &&
        (lastCheckin == null ||
            lastCheckin.compareTo(studyDateKey(thisMonday)) < 0),
  );
});

/// Recomputes and reschedules the reminders. Safe to call often: it does
/// nothing until the learner has chosen whether to be reminded.
final reminderSyncProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    final db = ref.read(appDatabaseProvider);
    if (await db.getSetting('habit:reminders') == null) return;
    final settings = await db.habitSettings();
    final now = DateTime.now();
    final doneToday = (await db.activeDayKeys()).contains(studyDateKey(now));
    await ref
        .read(reminderServiceProvider)
        .apply(
          planReminders(now: now, settings: settings, doneToday: doneToday),
          dailyMinutes: settings.dailyMinutes,
        );
  },
);

void refreshHabit(ProviderContainer container) {
  container.invalidate(habitSettingsProvider);
  container.invalidate(habitSnapshotProvider);
  container.invalidate(progressSnapshotProvider);
}
