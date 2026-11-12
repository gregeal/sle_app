import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/habit/habit_settings.dart';
import '../../domain/habit/journey.dart';
import '../../domain/habit/slot_analysis.dart';
import '../../domain/habit/streak.dart';
import '../../domain/weekly/weekly_report.dart' show studyDateKey;
import 'daos.dart';
import 'database.dart';

/// Stretches shorter than this are navigation, not study.
const kMinimumLoggedSeconds = 20;

const _maximumLoggedSeconds = 90 * 60;

extension HabitDaos on AppDatabase {
  /// Records real study time. Silently ignores stretches too short to mean
  /// anything, so callers can report every screen visit.
  Future<void> logActivity({
    required DateTime startedAt,
    required int seconds,
    required String kind,
    String? skill,
  }) async {
    if (seconds < kMinimumLoggedSeconds) return;
    await into(activityLogs).insert(
      ActivityLogsCompanion.insert(
        startedAt: startedAt,
        seconds: seconds > _maximumLoggedSeconds
            ? _maximumLoggedSeconds
            : seconds,
        kind: kind,
        skill: Value(skill),
      ),
    );
  }

  /// Rows starting at or after [from], oldest first.
  Future<List<ActivityLog>> activitySince(DateTime from) =>
      (select(activityLogs)
            ..where((a) => a.startedAt.isBiggerOrEqualValue(from))
            ..orderBy([(a) => OrderingTerm.asc(a.startedAt)]))
          .get();

  /// Logged seconds per local calendar day (yyyy-MM-dd).
  ///
  /// Grouped in Dart rather than SQL: the web build's SQLite has no time-zone
  /// database, so `localtime` there would silently mean UTC.
  Future<Map<String, int>> secondsByDay({DateTime? from}) async {
    final rows = from == null
        ? await select(activityLogs).get()
        : await activitySince(from);
    final totals = <String, int>{};
    for (final row in rows) {
      final key = studyDateKey(row.startedAt);
      totals[key] = (totals[key] ?? 0) + row.seconds;
    }
    return totals;
  }

  Future<int> secondsOn(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    return (await secondsByDay(from: start))[studyDateKey(start)] ?? 0;
  }

  /// Logged seconds per skill from [from] (inclusive) to [to] (exclusive).
  /// Time that trains no single skill is reported under `other`.
  Future<Map<String, int>> secondsBySkill(DateTime from, DateTime to) async {
    final totals = <String, int>{};
    for (final row in await activitySince(from)) {
      if (!row.startedAt.isBefore(to)) continue;
      final skill = row.skill ?? 'other';
      totals[skill] = (totals[skill] ?? 0) + row.seconds;
    }
    return totals;
  }

  /// Days that count toward the streak: a completed legacy block, a verified
  /// weekly assignment, or at least [kDailyFloorSeconds] of logged study.
  Future<Set<String>> activeDayKeys() async {
    final days = <String>{
      for (final log in await select(sessionLogs).get())
        if (log.blocksCompletedList.isNotEmpty) log.date,
    };
    final completed =
        await (select(weeklyAssignments)..where(
              (a) =>
                  a.completedAt.isNotNull() &
                  a.evidenceKind.equals('weeklyEvidence'),
            ))
            .get();
    days.addAll(completed.map((a) => studyDateKey(a.completedAt!)));
    (await secondsByDay()).forEach((day, seconds) {
      if (seconds >= kDailyFloorSeconds) days.add(day);
    });
    return days;
  }

  Future<HabitSettings> habitSettings() async {
    List<int> days(String? raw, List<int> fallback) {
      if (raw == null) return fallback;
      try {
        return List<int>.from(jsonDecode(raw) as List);
      } on Object {
        return fallback;
      }
    }

    const defaults = HabitSettings();
    return HabitSettings(
      configured: await getSetting('habit:configured') == 'true',
      remindersEnabled: await getSetting('habit:reminders') == 'true',
      reminderMinutes:
          int.tryParse(await getSetting('habit:reminderMinutes') ?? '') ??
          defaults.reminderMinutes,
      // The weekly planner already owns this key; the rhythm shares it so
      // there is a single answer to "which days do I study".
      studyDays: days(await getSetting('weekly:weekdays'), defaults.studyDays),
      classDays: days(await getSetting('habit:classDays'), defaults.classDays),
      dailyMinutes:
          int.tryParse(await getSetting('habit:dailyMinutes') ?? '') ??
          defaults.dailyMinutes,
      workStartMinutes: int.tryParse(await getSetting('habit:workStart') ?? ''),
      workEndMinutes: int.tryParse(await getSetting('habit:workEnd') ?? ''),
    );
  }

  /// Saves a validated rhythm. An unusable one is refused rather than stored,
  /// because the next week is composed from it.
  Future<void> saveHabitSettings(HabitSettings settings) async {
    final problem = settings.problem;
    if (problem != null) throw ArgumentError(problem);
    await transaction(() async {
      await setSetting('habit:configured', 'true');
      await setSetting('habit:reminders', '${settings.remindersEnabled}');
      await setSetting('habit:reminderMinutes', '${settings.reminderMinutes}');
      await setSetting(
        'weekly:weekdays',
        jsonEncode(settings.studyDays.toList()..sort()),
      );
      await setSetting(
        'habit:classDays',
        jsonEncode(settings.classDays.toList()..sort()),
      );
      await setSetting('habit:dailyMinutes', '${settings.dailyMinutes}');
      await setSetting('habit:workStart', '${settings.workStartMinutes ?? ''}');
      await setSetting('habit:workEnd', '${settings.workEndMinutes ?? ''}');
    });
  }

  /// Calendar days (Monday to Sunday) of the week containing [day] that
  /// count as active.
  Future<int> activeDaysInWeekOf(DateTime day) async {
    final monday = DateTime(day.year, day.month, day.day - (day.weekday - 1));
    final active = await activeDayKeys();
    var count = 0;
    for (var offset = 0; offset < 7; offset++) {
      final date = DateTime(monday.year, monday.month, monday.day + offset);
      if (active.contains(studyDateKey(date))) count++;
    }
    return count;
  }

  /// Completed past weeks in which the learner showed up on most planned
  /// days. The current week is not counted until it is over.
  Future<int> keptWeeks(DateTime today, HabitSettings settings) async {
    final active = await activeDayKeys();
    if (active.isEmpty) return 0;
    final needed = keptDaysNeeded(settings.activeWeekdays.length);
    final first = DateTime.parse((active.toList()..sort()).first);
    var monday = DateTime(
      first.year,
      first.month,
      first.day - (first.weekday - 1),
    );
    final thisMonday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );
    var kept = 0;
    while (monday.isBefore(thisMonday)) {
      var days = 0;
      for (var offset = 0; offset < 7; offset++) {
        final date = DateTime(monday.year, monday.month, monday.day + offset);
        if (active.contains(studyDateKey(date))) days++;
      }
      if (days >= needed) kept++;
      monday = DateTime(monday.year, monday.month, monday.day + 7);
    }
    return kept;
  }

  /// Completion by time of day over the last [days] days.
  Future<List<SlotStat>> slotStats(
    DateTime today,
    HabitSettings settings, {
    int days = 28,
  }) async {
    final from = DateTime(today.year, today.month, today.day - days);
    final rows = await activitySince(from);
    return analyzeSlots(
      [for (final row in rows) StudyStretch(row.startedAt, row.seconds)],
      // Three quarters of the planned session counts as finishing it.
      targetSeconds: settings.dailyMinutes * 60 * 3 ~/ 4,
    );
  }

  Future<GroupClassNote?> groupClassNoteFor(DateTime day) =>
      (select(groupClassNotes)
            ..where((n) => n.day.equals(studyDateKey(day)))
            ..orderBy([(n) => OrderingTerm.desc(n.id)])
            ..limit(1))
          .getSingleOrNull();

  /// Newest first.
  Future<List<GroupClassNote>> recentGroupClassNotes({int limit = 5}) =>
      (select(groupClassNotes)
            ..orderBy([(n) => OrderingTerm.desc(n.id)])
            ..limit(limit))
          .get();

  /// One note per class day: saving again replaces that day's note.
  Future<void> saveGroupClassNote({
    required DateTime day,
    required String covered,
    required String corrections,
    required DateTime at,
  }) async {
    final cleanCovered = covered.trim();
    final cleanCorrections = corrections.trim();
    if (cleanCovered.length < 3) {
      throw ArgumentError('Notez au moins ce qui a été vu en classe.');
    }
    if (cleanCovered.length > 2000 || cleanCorrections.length > 2000) {
      throw ArgumentError('La note est trop longue.');
    }
    final key = studyDateKey(day);
    await transaction(() async {
      await (delete(groupClassNotes)..where((n) => n.day.equals(key))).go();
      await into(groupClassNotes).insert(
        GroupClassNotesCompanion.insert(
          day: key,
          covered: cleanCovered,
          corrections: Value(cleanCorrections),
          createdAt: at,
        ),
      );
    });
  }
}
