import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/database.dart';
import '../../data/db/daos.dart';
import '../../data/db/weekly_daos.dart';
import '../../providers.dart';

sealed class DailyStudyPlan {
  const DailyStudyPlan();
}

class LegacyStudyPlan extends DailyStudyPlan {
  const LegacyStudyPlan();
}

class WeeklyStudyPlan extends DailyStudyPlan {
  const WeeklyStudyPlan(this.week, this.assignments, this.dates, this.history);
  final StudyWeek? week;
  final List<WeeklyAssignment> assignments;
  final List<String> dates;
  final List<StudyWeek> history;
}

final dailyStudyPlanProvider = FutureProvider<DailyStudyPlan>((ref) async {
  final day = ref.watch(studyDayProvider);
  ref.watch(activeStudyWeekProvider);
  ref.watch(activeWeekAssignmentsProvider);
  ref.watch(placementProvider);
  final db = ref.watch(appDatabaseProvider);
  if (await db.getSetting('weekly:enabled') != 'true' &&
      await db.activeStudyWeek() == null &&
      (await db.weeklyHistory()).isEmpty) {
    return const LegacyStudyPlan();
  }
  await db.reconcileStudyCalendar(day);
  final week = await db.activeStudyWeek();
  return WeeklyStudyPlan(
    week,
    week == null ? [] : await db.assignmentsForWeek(week.id),
    week == null ? [] : await db.studyDates(week),
    await db.weeklyHistory(),
  );
});
void refreshWeekly(WidgetRef ref) {
  ref.invalidate(activeStudyWeekProvider);
  ref.invalidate(activeWeekAssignmentsProvider);
  ref.invalidate(dailyStudyPlanProvider);
  ref.invalidate(progressSnapshotProvider);
}
