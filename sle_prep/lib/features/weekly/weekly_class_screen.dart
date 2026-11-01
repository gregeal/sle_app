import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/weekly_daos.dart';
import '../../domain/course/course_catalog.dart';
import '../../domain/speech/speech_services.dart';
import '../../domain/weekly/weekly_plan.dart';
import '../../domain/weekly/weekly_report.dart';
import '../../providers.dart';
import 'weekly_practice_screen.dart';

/// The weekly class: the teacher explains, checks understanding, practises
/// out loud with the learner, then hands over the week's assignments.
///
/// The explanation and the check work offline; only the guided practice needs
/// the network, and the class still completes without it.
class WeeklyClassScreen extends ConsumerStatefulWidget {
  const WeeklyClassScreen({super.key, required this.week});

  final StudyWeek week;

  @override
  ConsumerState<WeeklyClassScreen> createState() => _WeeklyClassScreenState();
}

class _WeeklyClassScreenState extends ConsumerState<WeeklyClassScreen>
    with WidgetsBindingObserver {
  var _step = 0;
  List<int?> _answers = const [];
  var _quizChecked = false;
  var _practiceDone = false;
  var _speaking = false;
  late final TtsService _tts;
  bool _loading = true, _saving = false;
  String? _error;
  int? _practiceEvidence;
  List<int> _skips = [];
  Future<void> _writes = Future.value();

  CourseLesson get _lesson => findCourseLesson(widget.week.lessonId);
  WeeklyPlan get _plan => widget.week.plan;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsServiceProvider);
    WidgetsBinding.instance.addObserver(this);
    _answers = List<int?>.filled(_lesson.questions.length, null);
    unawaited(_restore());
  }

  Future<void> _restore() async {
    try {
      final state = await ref
          .read(appDatabaseProvider)
          .classProgress(widget.week.id);
      _step = state.stage;
      _quizChecked = state.checked;
      _skips = state.skips;
      _practiceEvidence = state.practiceEvidenceId;
      _practiceDone = _practiceEvidence != null;
      if (state.answers.length == _answers.length &&
          state.answers.indexed.every(
            (e) =>
                e.$2 == null || e.$2! < _lesson.questions[e.$1].options.length,
          )) {
        _answers = state.answers.toList();
      }
    } catch (e) {
      _error = 'Progression illisible : $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _persist({int? stage}) {
    final db = ref.read(appDatabaseProvider);
    final state = ClassProgress(
      stage: stage ?? _step,
      answers: _answers.toList(),
      checked: _quizChecked,
      practiceEvidenceId: _practiceEvidence,
      skips: _skips.toList(),
    );
    return _writes = _writes
        .catchError((Object _) {})
        .then((_) => db.saveClassProgress(widget.week.id, state));
  }

  Future<void> _move(int step, {bool skip = false}) async {
    if (_saving) return;
    if (step > _step &&
        !skip &&
        ((_step == 1 && !_quizChecked) || (_step == 2 && !_practiceDone))) {
      setState(
        () => _error =
            'Terminez cette étape ou choisissez explicitement de la reporter.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _tts.stop();
      if (skip && !_skips.contains(_step)) _skips.add(_step);
      await _persist(stage: step);
      if (mounted) {
        setState(() {
          _step = step;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Enregistrement impossible : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_tts.stop().catchError((Object _) {}));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_tts.stop().catchError((Object _) {}));
    }
  }

  String get _spokenLesson => [
    _lesson.objective,
    ..._lesson.teaching,
    _lesson.simpleExample,
    _lesson.developedExample,
  ].join(' ');

  Future<void> _speakLesson() async {
    final tts = _tts;
    if (_speaking) {
      await tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    try {
      await tts.speak(_spokenLesson);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voix française indisponible sur cet appareil.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  /// The teaching block counts as done once understanding has been checked.
  Future<void> _completeTeaching() async {
    await _complete(SkillKind.teaching);
  }

  Future<void> _complete(SkillKind skill) async {
    final db = ref.read(appDatabaseProvider);
    final rows = await db.assignmentsForWeek(widget.week.id);
    final match = rows.where(
      (row) => row.skill == skill.name && row.dayIndex == 1,
    );
    if (match.isEmpty) return;
    if (skill != SkillKind.teaching) return;
    await db.saveAssignmentEvidence(
      match.first.id,
      AssignmentEvidence(
        kind: EvidenceKind.quiz,
        data: {'answers': _answers.cast<int>()},
      ),
      at: DateTime.now(),
    );
    ref.invalidate(activeWeekAssignmentsProvider);
  }

  Future<void> _startPractice() async {
    try {
      await _tts.stop();
      final db = ref.read(appDatabaseProvider);
      final rows = await db.assignmentsForWeek(widget.week.id);
      final assignment = rows.firstWhere(
        (a) => a.dayIndex == 1 && a.skill == 'speaking',
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WeeklyPracticeScreen(assignment: assignment),
        ),
      );
      final saved = await db.weeklyAssignment(assignment.id);
      if (!mounted) return;
      _practiceDone = saved.completed && saved.evidenceKind == 'weeklyEvidence';
      _practiceEvidence = _practiceDone ? saved.evidenceId : null;
      await _persist();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    return Scaffold(
      appBar: AppBar(title: Text('Semaine ${_plan.weekNumber} · classe')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_error!),
                    ),
                  Expanded(
                    child: Stepper(
                      currentStep: _step,
                      onStepTapped: (step) {
                        if (step <= _step) unawaited(_move(step));
                      },
                      controlsBuilder: (context, details) => Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            if (details.stepIndex < 3)
                              FilledButton(
                                key: Key('class-continue-${details.stepIndex}'),
                                onPressed: _saving
                                    ? null
                                    : details.onStepContinue,
                                child: const Text('Continuer'),
                              ),
                            if (details.stepIndex > 0) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: details.onStepCancel,
                                child: const Text('Retour'),
                              ),
                            ],
                            if (details.stepIndex == 1 ||
                                details.stepIndex == 2)
                              TextButton(
                                onPressed: _saving
                                    ? null
                                    : () => _move(
                                        (_step + 1).clamp(0, 3),
                                        skip: true,
                                      ),
                                child: const Text('Reporter'),
                              ),
                          ],
                        ),
                      ),
                      onStepContinue: () =>
                          unawaited(_move((_step + 1).clamp(0, 3))),
                      onStepCancel: () =>
                          unawaited(_move((_step - 1).clamp(0, 3))),
                      steps: [
                        Step(
                          title: const Text('Explication'),
                          isActive: _step >= 0,
                          content: _explanation(lesson),
                        ),
                        Step(
                          title: const Text('Vérification'),
                          isActive: _step >= 1,
                          content: _quiz(lesson),
                        ),
                        Step(
                          title: const Text('Pratique guidée'),
                          isActive: _step >= 2,
                          content: _practice(),
                        ),
                        Step(
                          title: const Text('Devoirs de la semaine'),
                          isActive: _step >= 3,
                          content: _homework(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _explanation(CourseLesson lesson) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(lesson.title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 6),
      Text('Objectif : ${lesson.objective}'),
      const SizedBox(height: 12),
      for (final point in lesson.teaching)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('• $point'),
        ),
      const SizedBox(height: 10),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Exemple simple'),
              Text(
                lesson.simpleExample,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              const Text('Exemple développé'),
              Text(
                lesson.developedExample,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      const Text('Expressions à réutiliser'),
      Wrap(
        spacing: 6,
        children: [
          for (final phrase in lesson.phrases) Chip(label: Text(phrase)),
        ],
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        key: const Key('class-listen'),
        onPressed: _speakLesson,
        icon: Icon(_speaking ? Icons.stop : Icons.volume_up),
        label: Text(_speaking ? 'Arrêter' : 'Écouter l’explication'),
      ),
    ],
  );

  Widget _quiz(CourseLesson lesson) {
    final questions = lesson.questions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vérifions la compréhension. Une erreur n’arrête pas la classe : '
          'l’explication apparaît tout de suite.',
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < questions.length; i++) ...[
          Text(
            questions[i].prompt,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          for (var option = 0; option < questions[i].options.length; option++)
            RadioListTile<int>(
              key: Key('class-q$i-o$option'),
              dense: true,
              value: option,
              // ignore: deprecated_member_use
              groupValue: _answers[i],
              title: Text(questions[i].options[option]),
              // ignore: deprecated_member_use
              onChanged: _quizChecked
                  ? null
                  : (value) {
                      setState(() => _answers[i] = value);
                      unawaited(
                        _persist().catchError((Object e) {
                          if (mounted) setState(() => _error = '$e');
                        }),
                      );
                    },
            ),
          if (_quizChecked)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _answers[i] == questions[i].correct
                    ? '✔ ${questions[i].explanation}'
                    : '✘ ${questions[i].explanation}',
              ),
            ),
        ],
        if (!_quizChecked)
          FilledButton(
            key: const Key('class-check'),
            onPressed: _answers.contains(null)
                ? null
                : () async {
                    try {
                      await _completeTeaching();
                      _quizChecked = true;
                      await _persist();
                      if (mounted) setState(() {});
                    } catch (e) {
                      _quizChecked = false;
                      if (mounted) {
                        setState(
                          () => _error = 'Enregistrement impossible : $e',
                        );
                      }
                    }
                  },
            child: const Text('Vérifier'),
          )
        else
          Text(
            '${_score(lesson)} / ${questions.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
      ],
    );
  }

  int _score(CourseLesson lesson) {
    var score = 0;
    for (var i = 0; i < lesson.questions.length; i++) {
      if (_answers[i] == lesson.questions[i].correct) score++;
    }
    return score;
  }

  Widget _practice() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Votre enseignante vous fait pratiquer à voix haute les structures de '
        'la classe. Elle corrige doucement pendant l’échange et ne donne '
        'aucune note.',
      ),
      const SizedBox(height: 8),
      Text('Tâche : ${_lesson.speakingTask}'),
      const SizedBox(height: 12),
      FilledButton.icon(
        key: const Key('class-practice'),
        onPressed: _startPractice,
        icon: const Icon(Icons.headset_mic),
        label: Text(
          _practiceDone ? 'Reprendre la pratique' : 'Commencer la pratique',
        ),
      ),
      if (_practiceDone)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('✔ Pratique enregistrée dans vos rétroactions.'),
        ),
      const SizedBox(height: 8),
      const Text(
        'Sans réseau, passez aux devoirs : la pratique guidée pourra se faire '
        'plus tard dans la semaine.',
        style: TextStyle(fontSize: 12.5),
      ),
    ],
  );

  Widget _homework() {
    final plan = _plan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voici votre semaine : ${plan.studyDays} jours de '
          '${plan.minutesPerDay} minutes.',
        ),
        const SizedBox(height: 4),
        Text(
          'Expression orale ${_share(plan, SkillKind.speaking)} · '
          'écoute ${_share(plan, SkillKind.listening)} · '
          'lecture ${_share(plan, SkillKind.reading)} · '
          'écriture ${_share(plan, SkillKind.writing)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (var day = 1; day <= plan.studyDays; day++) ...[
          Text('Jour $day', style: Theme.of(context).textTheme.titleSmall),
          for (final block in plan.assignmentsForDay(day))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(_iconFor(block.skill), size: 20),
              title: Text(block.titleFr),
              subtitle: Text(block.subtitleFr),
              trailing: Text('${block.minutes} min'),
            ),
          const SizedBox(height: 8),
        ],
        FilledButton(
          key: const Key('class-done'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Commencer la semaine'),
        ),
      ],
    );
  }

  String _share(WeeklyPlan plan, SkillKind skill) =>
      '${(plan.shareOf(skill) * 100).round()} %';

  IconData _iconFor(SkillKind skill) => switch (skill) {
    SkillKind.teaching => Icons.school_outlined,
    SkillKind.speaking => Icons.mic_none,
    SkillKind.listening => Icons.headphones_outlined,
    SkillKind.reading => Icons.menu_book_outlined,
    SkillKind.writing => Icons.edit_note_outlined,
    SkillKind.vocabulary => Icons.style_outlined,
  };
}
