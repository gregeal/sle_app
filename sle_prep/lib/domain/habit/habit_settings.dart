/// The learner's weekly rhythm: which days, how long, and when to be reminded.
library;

import '../course/course_catalog.dart';
import '../weekly/weekly_plan.dart';

const kDailyMinuteChoices = [20, 40, 60];
const kDefaultDailyMinutes = 20;

class HabitSettings {
  const HabitSettings({
    this.configured = false,
    this.remindersEnabled = false,
    this.reminderMinutes = 12 * 60 + 15,
    this.studyDays = const [1, 2, 3, 4, 5],
    this.classDays = const [],
    this.dailyMinutes = kDefaultDailyMinutes,
    this.workStartMinutes,
    this.workEndMinutes,
  });

  /// False until the learner has been through the rhythm screen once.
  final bool configured;
  final bool remindersEnabled;

  /// Reminder time as minutes after midnight, local time.
  final int reminderMinutes;

  /// ISO weekdays (1 = Monday) with a planned app session.
  final List<int> studyDays;

  /// ISO weekdays with an in-person group class. The app only asks for a
  /// short warm-up and a capture on those days.
  final List<int> classDays;
  final int dailyMinutes;
  final int? workStartMinutes;
  final int? workEndMinutes;

  Set<int> get activeWeekdays => {...studyDays, ...classDays};

  bool isStudyDay(DateTime day) => studyDays.contains(day.weekday);
  bool isClassDay(DateTime day) => classDays.contains(day.weekday);
  bool isRestDay(DateTime day) => !activeWeekdays.contains(day.weekday);

  HabitSettings copyWith({
    bool? configured,
    bool? remindersEnabled,
    int? reminderMinutes,
    List<int>? studyDays,
    List<int>? classDays,
    int? dailyMinutes,
    int? workStartMinutes,
    int? workEndMinutes,
  }) => HabitSettings(
    configured: configured ?? this.configured,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    studyDays: studyDays ?? this.studyDays,
    classDays: classDays ?? this.classDays,
    dailyMinutes: dailyMinutes ?? this.dailyMinutes,
    workStartMinutes: workStartMinutes ?? this.workStartMinutes,
    workEndMinutes: workEndMinutes ?? this.workEndMinutes,
  );

  /// Null when the rhythm is usable, otherwise the reason in French.
  String? get problem {
    bool validDays(List<int> days) =>
        days.toSet().length == days.length &&
        days.every((d) => d >= 1 && d <= 7);
    if (!validDays(studyDays) || !validDays(classDays)) {
      return 'Les jours choisis sont invalides.';
    }
    if (studyDays.any(classDays.contains)) {
      return 'Un jour ne peut pas être à la fois un jour d’étude et un jour '
          'de cours.';
    }
    if (studyDays.length < 3) {
      return 'Choisissez au moins trois jours d’étude.';
    }
    if (activeWeekdays.length > 6) {
      return 'Gardez au moins un jour de repos complet.';
    }
    if (!kDailyMinuteChoices.contains(dailyMinutes)) {
      return 'Choisissez 20, 40 ou 60 minutes.';
    }
    if (reminderMinutes < 0 || reminderMinutes >= 24 * 60) {
      return 'L’heure du rappel est invalide.';
    }
    if (!weeklyBudgetIsFeasible(studyDays.length, dailyMinutes)) {
      return 'Avec ${studyDays.length} jours de $dailyMinutes minutes, la '
          'semaine ne peut pas couvrir les quatre compétences. Ajoutez un '
          'jour ou choisissez une séance plus longue.';
    }
    return null;
  }
}

/// Whether the weekly contract can be honoured with this budget.
bool weeklyBudgetIsFeasible(int studyDays, int minutesPerDay) {
  final lesson = courseTracks.first.lessons.first;
  try {
    composeWeeklyPlan(
      weekNumber: 1,
      trackId: courseTracks.first.id,
      lessonId: lesson.id,
      lessonTitleFr: lesson.title,
      studyDays: studyDays,
      minutesPerDay: minutesPerDay,
    );
    return true;
  } on ArgumentError {
    return false;
  } on FormatException {
    return false;
  }
}

/// "07 h 15", the form used across the app for a time of day.
String formatClock(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')} h '
    '${(minutes % 60).toString().padLeft(2, '0')}';
