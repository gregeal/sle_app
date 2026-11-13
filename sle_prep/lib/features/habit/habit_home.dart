import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import '../../data/db/weekly_daos.dart';
import '../../domain/habit/streak.dart';
import '../../domain/weekly/weekly_report.dart';
import '../../providers.dart';
import '../course/course_library_screen.dart';
import '../../domain/grammar/grammar_course.dart';
import '../drills/drill_screen.dart';
import '../grammar/grammar_screens.dart';
import '../learning/learning_hub_screen.dart';
import '../vocab/vocab_review_screen.dart';
import '../weekly/weekly_assignment_screen.dart';
import '../weekly/weekly_class_screen.dart';
import '../weekly/weekly_home_screen.dart';
import '../weekly/weekly_practice_screen.dart';
import '../weekly/weekly_providers.dart';
import 'group_class_screens.dart';
import 'habit_providers.dart';
import 'rhythm_screen.dart';
import 'weekly_checkin_screen.dart';

/// The home screen: where the learner is, and the one thing to do next.
///
/// It deliberately offers a single primary action. Everything else in the
/// app stays reachable from the tabs, but nothing here asks for a decision
/// before starting.
class HabitHome extends ConsumerStatefulWidget {
  const HabitHome({super.key, required this.plan, required this.legacyBuilder});

  final DailyStudyPlan plan;

  /// The original 26-week daily session, kept one tap away for learners who
  /// have not opened a weekly class yet.
  final WidgetBuilder legacyBuilder;

  @override
  ConsumerState<HabitHome> createState() => _HabitHomeState();
}

class _HabitHomeState extends ConsumerState<HabitHome> {
  var _busy = false;
  String? _error;

  void _refresh() {
    if (!mounted) return;
    refreshWeekly(ref);
    refreshHabit(ProviderScope.containerOf(context, listen: false));
    ref.invalidate(todayClassNoteProvider);
    ref.invalidate(grammarProgressProvider);
  }

  /// Runs [action], then refreshes: every route opened from here can change
  /// the plan, the streak or the minutes.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object {
      if (mounted) {
        setState(() => _error = 'Action impossible pour l’instant. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      _refresh();
    }
  }

  Future<void> _push(Widget screen) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));

  Future<void> _openBlock(StudyWeek week, WeeklyAssignment block) =>
      _push(switch (block.skill) {
        'teaching' => WeeklyClassScreen(week: week),
        'speaking' => WeeklyPracticeScreen(assignment: block),
        _ => WeeklyAssignmentScreen(assignment: block),
      });

  /// The five-minute floor: vocabulary when cards are due, otherwise a short
  /// grammar drill. Both work offline and need no setup.
  Future<void> _quickSession() async {
    final db = ref.read(appDatabaseProvider);
    if (await db.dueCardCount(DateTime.now()) > 0) {
      if (mounted) await _push(const VocabReviewScreen());
      return;
    }
    final week = await ref.read(activeWeekProvider.future);
    if (mounted) {
      await _push(
        DrillScreen(
          topics: week.week.grammarTopicsList,
          title: 'Séance éclair',
        ),
      );
    }
  }

  Future<void> _openClasse() => _push(
    Scaffold(
      appBar: AppBar(title: const Text('Ma classe')),
      body: const WeeklyHomeScreen(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = ref.watch(studyDayProvider);
    final todayKey = studyDateKey(today);
    final habit = ref.watch(habitSnapshotProvider).asData?.value;
    final plan = widget.plan;
    final weekly = plan is WeeklyStudyPlan ? plan : null;
    final week = weekly?.week;
    final dayIndex = weekly?.dates.indexOf(todayKey) ?? -1;
    final blocks = week == null || week.paused || dayIndex < 0
        ? const <WeeklyAssignment>[]
        : weekly!.assignments.where((a) => a.dayIndex == dayIndex + 1).toList();
    final done = blocks.where((a) => a.completed).length;
    final next = blocks.where((a) => !a.completed).firstOrNull;
    final plannedMinutes = blocks.fold<int>(0, (sum, a) => sum + a.minutes);
    final missed = week == null || week.paused || dayIndex < 1
        ? 0
        : weekly!.assignments
              .where(
                (a) =>
                    a.dayIndex <= dayIndex &&
                    !a.completed &&
                    a.skill != 'teaching',
              )
              .length;
    final classDay = habit?.dayType == DayType.groupClass;
    final grammar = ref.watch(grammarProgressProvider).asData?.value;
    // Before any rhythm exists the original daily plan has no rest days.
    final restDay =
        habit?.dayType == DayType.rest &&
        (habit!.settings.configured || weekly != null);

    return SafeArea(
      top: false,
      // A column rather than a lazy list: the home is short, so it is built
      // whole and nothing has to be scrolled into existence.
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_dateLabel(today), style: theme.textTheme.titleSmall),
                if ((habit?.streak ?? 0) > 0)
                  Chip(
                    avatar: const Icon(Icons.local_fire_department_outlined),
                    label: Text('${habit!.streak} j'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Bonjour', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),
            if (habit != null) _JourneyCard(habit: habit),
            if (habit != null && !habit.settings.configured)
              Card(
                color: theme.colorScheme.primaryContainer,
                child: ListTile(
                  key: const Key('habit-setup'),
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Choisir mon rythme et mon rappel'),
                  subtitle: const Text(
                    'Vos jours, la durée, l’heure du rappel · 2 minutes',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _busy
                      ? null
                      : () => _run(() => _push(const RhythmScreen())),
                ),
              )
            else if (habit != null && !habit.settings.remindersEnabled)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_off_outlined),
                  title: const Text('Aucun rappel actif'),
                  subtitle: const Text('Activer un rappel les jours prévus'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _busy
                      ? null
                      : () => _run(() => _push(const RhythmScreen())),
                ),
              ),
            if (habit?.checkinDue ?? false)
              Card(
                child: ListTile(
                  key: const Key('habit-checkin'),
                  leading: const Icon(Icons.fact_check_outlined),
                  title: const Text('Bilan de la semaine dernière'),
                  subtitle: const Text('Trois minutes · ajuster si besoin'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _busy
                      ? null
                      : () => _run(() => _push(const WeeklyCheckinScreen())),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (classDay) _ClassDayCard(busy: _busy, run: _run, push: _push),
            if (blocks.isNotEmpty) ...[
              const SizedBox(height: 4),
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Séance d’aujourd’hui',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$plannedMinutes minutes · $done bloc'
                        '${done > 1 ? 's' : ''} sur ${blocks.length} '
                        'terminé${done > 1 ? 's' : ''}',
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: done / blocks.length),
                      const SizedBox(height: 14),
                      if (next == null)
                        const Text(
                          'Séance terminée. C’est assez pour aujourd’hui : à '
                          'la prochaine.',
                        )
                      else
                        FilledButton.icon(
                          key: const Key('habit-start'),
                          onPressed: _busy
                              ? null
                              : () => _run(() => _openBlock(week!, next)),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(
                            done == 0
                                ? 'Commencer · $plannedMinutes min'
                                : 'Continuer · ${next.titleFr}',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              for (final block in blocks)
                ListTile(
                  leading: Icon(
                    block.completed
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: block.completed ? theme.colorScheme.primary : null,
                  ),
                  title: Text(block.titleFr),
                  subtitle: Text(block.subtitleFr),
                  trailing: Text('${block.minutes} min'),
                  onTap: _busy
                      ? null
                      : () => _run(() => _openBlock(week!, block)),
                ),
              if (missed > 0)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _run(
                          () => swapInCatchup(
                            ref.read(appDatabaseProvider),
                            weekly!,
                            todayIndex: dayIndex,
                            today: todayKey,
                          ),
                        ),
                  child: const Text(
                    'Rattraper un bloc manqué à la place d’un bloc du jour',
                  ),
                ),
            ] else if (week != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  week.paused
                      ? 'Semaine en pause. Reprenez-la depuis l’onglet Classe.'
                      : 'Repos ou prochaine séance à venir.',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ] else ...[
              Card(
                child: ListTile(
                  key: const Key('habit-open-week'),
                  leading: const Icon(Icons.cast_for_education_outlined),
                  title: Text(
                    weekly == null
                        ? 'Découvrir ma classe de la semaine'
                        : 'Ouvrir ma prochaine semaine',
                  ),
                  subtitle: const Text(
                    'Une leçon, puis de courtes séances réparties sur vos jours',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _busy ? null : () => _run(_openClasse),
                ),
              ),
              if (weekly == null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.today_outlined),
                    title: const Text(
                      'Séance du jour · programme de 26 semaines',
                    ),
                    subtitle: const Text('Vocabulaire, grammaire et ressource'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _busy
                        ? null
                        : () => _run(
                            () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) => Scaffold(
                                  appBar: AppBar(
                                    title: const Text('Séance du jour'),
                                  ),
                                  body: widget.legacyBuilder(context),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
            ],
            if (restDay && blocks.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Jour de repos. Rien à faire aujourd’hui : le repos fait '
                  'partie du plan.',
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('habit-quick'),
              onPressed: _busy ? null : () => _run(_quickSession),
              icon: const Icon(Icons.bolt_outlined),
              label: const Text('Je n’ai que cinq minutes'),
            ),
            const SizedBox(height: 4),
            Text(
              'Cinq minutes suffisent pour que la journée compte.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _run(() => _push(const RhythmScreen())),
              child: const Text('Mon rythme · jours, durée et rappel'),
            ),
            const SizedBox(height: 8),
            Text('PLUS', style: theme.textTheme.labelLarge),
            ListTile(
              key: const Key('home-grammar'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.auto_stories_outlined),
              title: const Text('Grammaire pas à pas'),
              subtitle: Text(
                grammar == null
                    ? 'Vingt leçons dans l’ordre d’une classe'
                    : '${acquiredGrammarLessons(grammar)} sur '
                          '${grammarLessons.length} · à suivre : '
                          '${nextGrammarLesson(grammar).title}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy
                  ? null
                  : () => _run(() => _push(const GrammarPathScreen())),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.route_outlined),
              title: const Text('Mes parcours · A → B et B → C'),
              subtitle: const Text('Toutes les classes, à votre rythme'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy
                  ? null
                  : () => _run(() => _push(const CourseLibraryScreen())),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.school_outlined),
              title: const Text('Mon espace d’apprentissage'),
              subtitle: const Text('Carnet, erreurs, écoute et rétroactions'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy
                  ? null
                  : () => _run(() => _push(const LearningHubScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.habit});

  final HabitSnapshot habit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planned = habit.weekPlannedDays;
    final kept = habit.weekActiveDays;
    final minutes = habit.todaySeconds ~/ 60;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(habit.journey.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(habit.journey.detail),
            const SizedBox(height: 12),
            Text(
              'Cette semaine : $kept jour${kept > 1 ? 's' : ''} sur $planned',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: planned == 0 ? 0 : (kept / planned).clamp(0, 1).toDouble(),
            ),
            const SizedBox(height: 8),
            Text(
              habit.todaySeconds >= kDailyFloorSeconds
                  ? 'Aujourd’hui : $minutes min · la journée compte.'
                  : minutes == 0
                  ? 'Aujourd’hui : pas encore commencé.'
                  : 'Aujourd’hui : $minutes min.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// On a group-class day the app steps back: a short warm-up before the
/// class and a short note after it, nothing more.
class _ClassDayCard extends ConsumerWidget {
  const _ClassDayCard({
    required this.busy,
    required this.run,
    required this.push,
  });

  final bool busy;
  final Future<void> Function(Future<void> Function()) run;
  final Future<void> Function(Widget) push;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noted = ref.watch(todayClassNoteProvider).asData?.value != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Jour de cours',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                'Votre cours en groupe est le travail du jour. '
                'L’application ne demande que ceci :',
              ),
            ),
            ListTile(
              key: const Key('habit-class-warmup'),
              leading: const Icon(Icons.wb_sunny_outlined),
              title: const Text('Avant le cours · échauffement'),
              trailing: const Text('10 min'),
              onTap: busy
                  ? null
                  : () => run(() => push(const GroupClassWarmupScreen())),
            ),
            ListTile(
              key: const Key('habit-class-capture'),
              leading: Icon(
                noted ? Icons.check_circle : Icons.edit_note_outlined,
                color: noted ? Theme.of(context).colorScheme.primary : null,
              ),
              title: const Text('Après le cours · ce que je retiens'),
              trailing: const Text('5 min'),
              onTap: busy
                  ? null
                  : () => run(() => push(const GroupClassCaptureScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

String _dateLabel(DateTime date) {
  const days = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
}
