import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/database.dart';
import '../../data/db/daos.dart';
import '../../data/db/habit_daos.dart';
import '../../data/db/weekly_daos.dart';
import '../../domain/course/course_catalog.dart';
import '../../domain/weekly/placement.dart';
import '../../domain/weekly/weekly_plan.dart';
import '../../domain/weekly/weekly_report.dart';
import '../../domain/weekly/weekly_service.dart';
import '../../providers.dart';
import '../habit/habit_providers.dart';
import '../habit/rhythm_screen.dart';
import 'placement_screen.dart';
import 'weekly_class_screen.dart';
import 'weekly_assignment_screen.dart';
import 'weekly_practice_screen.dart';
import 'weekly_report_screen.dart';
import 'weekly_providers.dart';

Future<void> startNextWeek(
  WidgetRef ref,
  PlacementResult placement, {
  String? lessonId,
}) async {
  final db = ref.read(appDatabaseProvider);
  if (await db.activeStudyWeek() != null) return;
  final history = await db.weeklyHistory();
  final lesson = findCourseLesson(
    lessonId ??
        await db.getSetting('placement:startLesson') ??
        courseTracks
            .firstWhere((t) => t.id == placement.trackId)
            .lessons
            .first
            .id,
  );
  final track = courseTrackForLesson(lesson.id);
  WeeklyEmphasis emphasis = const WeeklyEmphasis.balanced();
  if (history.isNotEmpty) {
    final job = await db.weeklyFeedback(history.first.id);
    if (job?.status == 'ready') {
      emphasis = WeeklyEmphasis(
        reinforce: WeeklyReport.parse(job!.reportJson!).reinforce,
      );
    }
  }
  final habit = await db.habitSettings();
  await db.createStudyWeek(
    plan: composeWeeklyPlan(
      weekNumber: history.isEmpty
          ? 1
          : history.map((w) => w.weekNumber).reduce((a, b) => a > b ? a : b) +
                1,
      trackId: track.id,
      lessonId: lesson.id,
      lessonTitleFr: lesson.title,
      studyDays: habit.studyDays.length,
      minutesPerDay: habit.dailyMinutes,
      emphasis: emphasis,
    ),
    startDate: ref.read(studyDayProvider),
    weekdays: habit.studyDays,
  );
  refreshWeekly(ref);
}

/// Brings one earlier missed block into today in place of a block of the same
/// skill and length, so catching up never adds time to the day. The oldest
/// missed block goes first.
Future<void> swapInCatchup(
  AppDatabase db,
  WeeklyStudyPlan weekly, {
  required int todayIndex,
  required String today,
}) async {
  final todays = weekly.assignments
      .where((a) => a.dayIndex == todayIndex + 1 && !a.completed)
      .toList();
  final missed =
      weekly.assignments
          .where(
            (a) =>
                a.dayIndex <= todayIndex &&
                !a.completed &&
                a.skill != 'teaching',
          )
          .toList()
        ..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));
  for (final old in missed) {
    for (final replacement in todays) {
      if (replacement.skill == old.skill &&
          replacement.minutes == old.minutes) {
        await db.swapCatchup(weekly.week!.id, old.id, replacement.id, today);
        return;
      }
    }
  }
  throw StateError(
    'Aucun remplacement de même compétence et durée : le travail manqué '
    'reste facultatif.',
  );
}

String lessonTitleOrId(String lessonId) {
  try {
    return findCourseLesson(lessonId).title;
  } on StateError {
    return lessonId;
  }
}

class WeeklyHomeScreen extends ConsumerStatefulWidget {
  const WeeklyHomeScreen({super.key, this.today = false});
  final bool today;
  @override
  ConsumerState<WeeklyHomeScreen> createState() => _WeeklyHomeState();
}

class _WeeklyHomeState extends ConsumerState<WeeklyHomeScreen> {
  bool _busy = false;
  String? _error;
  int? _autoAttempted;
  Future<void> _action(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) refreshWeekly(ref);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _placement() async {
    final placed = await Navigator.push<PlacementResult>(
      context,
      MaterialPageRoute(builder: (_) => const PlacementScreen()),
    );
    if (placed != null && mounted) await startNextWeek(ref, placed);
  }

  Future<void> _next(List<StudyWeek> history) async {
    final db = ref.read(appDatabaseProvider);
    final placement = await ref.read(placementProvider.future);
    if (placement == null) {
      if (mounted) await _placement();
      return;
    }
    var trackId = history.isEmpty ? placement.trackId : history.first.trackId;
    final recommendation = await db.recommendNextLesson(trackId);
    var lessonId = history.isEmpty
        ? (await db.getSetting('placement:startLesson') ??
              recommendation.lessonId)
        : recommendation.lessonId;
    var reason = recommendation.reason;
    final track = courseTracks.firstWhere((t) => t.id == trackId);
    if (!track.lessons.any((l) => l.id == lessonId)) {
      lessonId = recommendation.lessonId;
    }
    final finishedTrack =
        history.isNotEmpty &&
        history.first.trackId == trackId &&
        history.first.lessonId == track.lessons.last.id;
    if (finishedTrack &&
        trackId == 'a-to-b-v1' &&
        await db.supportsBTransition()) {
      trackId = bToCCourse.id;
      lessonId = bToCCourse.lessons.first.id;
      reason =
          'Deux bilans soutiennent un niveau B de travail dans les quatre compétences. Le parcours B → C est proposé; vous pouvez choisir une révision.';
    } else if (finishedTrack ||
        history
                .where((w) => w.trackId == trackId && w.status == 'closed')
                .map((w) => w.lessonId)
                .toSet()
                .length >=
            track.lessons.length) {
      reason =
          'Les leçons de ce parcours ont été programmées. Choisissez une révision ou le parcours suivant; cela ne certifie pas le niveau.';
    }
    if (!mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => AlertDialog(
          title: Text(
            finishedTrack
                ? 'Fin de parcours · choisir la suite'
                : 'Confirmer la prochaine semaine',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(reason),
                DropdownButtonFormField<String>(
                  initialValue: trackId,
                  items: [
                    for (final t in courseTracks)
                      DropdownMenuItem(value: t.id, child: Text(t.label)),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      update(() {
                        trackId = v;
                        lessonId = courseTracks
                            .firstWhere((t) => t.id == v)
                            .lessons
                            .first
                            .id;
                      });
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey(trackId),
                  initialValue: lessonId,
                  isExpanded: true,
                  items: [
                    for (final l
                        in courseTracks
                            .firstWhere((t) => t.id == trackId)
                            .lessons)
                      DropdownMenuItem(
                        value: l.id,
                        child: Text(
                          l.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) update(() => lessonId = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || !mounted) return;
    await db.setSetting(
      'weekly:progressionChoice',
      jsonEncode({
        'recommended': recommendation.lessonId,
        'selected': lessonId,
        'reason': reason,
        'at': DateTime.now().toIso8601String(),
      }),
    );
    await startNextWeek(ref, placement, lessonId: lessonId);
  }

  Future<void> _rhythm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RhythmScreen()),
    );
    if (mounted) ref.invalidate(habitSettingsProvider);
  }

  /// Closing freezes the week's evidence for good, so it is never one tap.
  Future<void> _close(StudyWeek week, List<WeeklyAssignment> rows) async {
    if (_busy) return;
    final open = rows.where((a) => !a.completed).length;
    final plural = open > 1;
    final status = open == 0
        ? 'Toutes les activités sont enregistrées.'
        : plural
        ? '$open activités ne sont pas terminées.'
        : 'Une activité n’est pas terminée.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Clore cette semaine ?'),
        content: Text(
          '$status Une semaine close ne peut plus être modifiée : ses '
          'preuves sont figées pour le bilan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const Key('weekly-close-confirm'),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Clore la semaine'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _action(
      () => ref
          .read(appDatabaseProvider)
          .closeStudyWeek(week.id, at: DateTime.now()),
    );
  }

  Future<void> _open(StudyWeek week, WeeklyAssignment a) async {
    final Widget screen = switch (a.skill) {
      'teaching' => WeeklyClassScreen(week: week),
      'speaking' => WeeklyPracticeScreen(assignment: a),
      _ => WeeklyAssignmentScreen(assignment: a),
    };
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _automaticReport(StudyWeek closed) async {
    final db = ref.read(appDatabaseProvider);
    if (await db.getSetting('weekly:autoReports') == 'false') return;
    final job = await db.weeklyFeedback(closed.id);
    if (job?.status != 'notRequested') return;
    try {
      final client = await ref.read(llmClientProvider.future);
      await db.generateWeeklyFeedback(closed.id, client);
    } catch (_) {
      /* A failure stays explicit and never loops automatically. */
    }
    if (mounted) refreshWeekly(ref);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyStudyPlanProvider);
    return SafeArea(
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('La semaine ne peut pas être ouverte : $e'),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _action(() async {
                      final db = ref.read(appDatabaseProvider);
                      final active = await db.activeStudyWeek();
                      if (active != null) {
                        await db.archiveInvalidWeek(active.id);
                      }
                    }),
              child: const Text('Archiver la semaine illisible et recréer'),
            ),
          ],
        ),
        data: (plan) {
          final weekly = plan is WeeklyStudyPlan ? plan : null;
          final week = weekly?.week;
          final history = weekly?.history ?? <StudyWeek>[];
          final closed = history.where((w) => w.status == 'closed').toList();
          if (closed.isNotEmpty && _autoAttempted != closed.first.id) {
            _autoAttempted = closed.first.id;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) unawaited(_automaticReport(closed.first));
            });
          }
          final habit = ref.watch(habitSettingsProvider).asData?.value;
          final today = studyDateKey(ref.watch(studyDayProvider));
          final day = weekly?.dates.indexOf(today) ?? -1;
          final rows = widget.today
              ? (week?.paused == true || day < 0
                    ? <WeeklyAssignment>[]
                    : weekly!.assignments
                          .where((a) => a.dayIndex == day + 1)
                          .toList())
              : weekly?.assignments ?? <WeeklyAssignment>[];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.today ? 'Aujourd’hui · $today' : 'Ma classe',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                '${week?.plan.studyDays ?? habit?.studyDays.length ?? 5} jours × '
                '${week?.plan.minutesPerDay ?? habit?.dailyMinutes ?? 20} minutes. '
                'Lecture, écoute, rédaction et expression orale; 20 minutes '
                'en direct par semaine.',
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_busy) const LinearProgressIndicator(),
              if (week == null) ...[
                FilledButton(
                  key: const Key('weekly-placement'),
                  onPressed: _busy ? null : () => _action(_placement),
                  child: const Text('Placement / revoir mon point de départ'),
                ),
                FilledButton(
                  key: const Key('weekly-start'),
                  onPressed: _busy ? null : () => _action(() => _next(history)),
                  child: const Text('Choisir et ouvrir la prochaine semaine'),
                ),
              ] else ...[
                Text(
                  'Semaine ${week.weekNumber} · ${findCourseLesson(week.lessonId).title}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  week.paused
                      ? 'Semaine en pause.'
                      : day < 0
                      ? 'Repos ou prochaine séance à venir.'
                      : 'Jour ${day + 1}',
                ),
                FilledButton(
                  key: const Key('weekly-class'),
                  onPressed: _busy
                      ? null
                      : () => _action(() async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WeeklyClassScreen(week: week),
                            ),
                          );
                        }),
                  child: const Text('Ouvrir / reprendre la classe'),
                ),
                for (final a in rows)
                  ListTile(
                    leading: Icon(
                      a.completed
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(a.titleFr),
                    subtitle: Text(
                      '${weekly!.dates[a.dayIndex - 1]} · ${a.subtitleFr}',
                    ),
                    trailing: Text('${a.minutes} min'),
                    onTap: _busy ? null : () => _action(() => _open(week, a)),
                  ),
                if (widget.today && day > 0 && !week.paused)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _action(
                            () => swapInCatchup(
                              ref.read(appDatabaseProvider),
                              weekly!,
                              todayIndex: day,
                              today: today,
                            ),
                          ),
                    child: const Text(
                      'Un rattrapage en remplacement, sans temps supplémentaire',
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _action(
                              () => ref
                                  .read(appDatabaseProvider)
                                  .pauseStudyWeek(
                                    week.id,
                                    !week.paused,
                                    ref.read(studyDayProvider),
                                  ),
                            ),
                      child: Text(
                        week.paused ? 'Reprendre' : 'Mettre en pause',
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _close(week, weekly!.assignments),
                      child: const Text('Clore et préparer le bilan'),
                    ),
                  ],
                ),
              ],
              OutlinedButton(
                onPressed: _busy ? null : () => _action(_rhythm),
                child: const Text('Mon rythme · jours, durée et rappel'),
              ),
              FutureBuilder<String?>(
                future: ref
                    .read(appDatabaseProvider)
                    .getSetting('weekly:autoReports'),
                builder: (c, s) => SwitchListTile(
                  value: s.data != 'false',
                  title: const Text(
                    'Un bilan IA automatique pour la dernière semaine close',
                  ),
                  subtitle: const Text(
                    'À la prochaine ouverture en ligne · frais possibles · pas de rattrapage de bilans anciens.',
                  ),
                  onChanged: (v) => _action(
                    () => ref
                        .read(appDatabaseProvider)
                        .setSetting('weekly:autoReports', v ? 'true' : 'false'),
                  ),
                ),
              ),
              if (closed.isNotEmpty) const Text('Bilans et historique'),
              for (final w in closed)
                ListTile(
                  title: Text(
                    'Semaine ${w.weekNumber} · ${lessonTitleOrId(w.lessonId)}',
                  ),
                  trailing: const Icon(Icons.assessment_outlined),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WeeklyReportScreen(week: w),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
