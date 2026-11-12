/// Where the learner is on the way to fluency, expressed as a habit to keep
/// rather than a date to hit.
library;

/// Weeks that must be kept before any level goal is shown.
const kHabitStageWeeks = 4;

class JourneyStage {
  const JourneyStage({
    required this.number,
    required this.title,
    required this.detail,
  });
  final int number;
  final String title;
  final String detail;
}

/// A week is kept when the learner showed up on most planned days. One
/// missed day never fails a week.
int keptDaysNeeded(int plannedDays) => plannedDays < 4 ? plannedDays : 4;

JourneyStage journeyFor({required int keptWeeks}) {
  if (keptWeeks < kHabitStageWeeks) {
    final remaining = kHabitStageWeeks - keptWeeks;
    final plural = keptWeeks > 1 ? 's' : '';
    return JourneyStage(
      number: 1,
      title: 'Étape 1 · Installer l’habitude',
      detail: keptWeeks == 0
          ? 'Seul objectif pour l’instant : ouvrir l’application la plupart '
                'des jours prévus. Aucun objectif de niveau.'
          : '$keptWeeks semaine$plural tenue$plural sur $kHabitStageWeeks. '
                'Encore $remaining, sans objectif de niveau.',
    );
  }
  return const JourneyStage(
    number: 2,
    title: 'Étape 2 · Construire un B solide à l’oral',
    detail:
        'Parler un peu chaque jour prévu. Le niveau C vient ensuite, sans '
        'date limite.',
  );
}
