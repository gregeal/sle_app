import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/db/grammar_daos.dart';
import '../../domain/grammar/grammar_course.dart';
import '../../domain/speech/speech_services.dart';
import '../../providers.dart';
import '../drills/drill_screen.dart';
import '../habit/activity_tracker.dart';

final grammarProgressProvider = FutureProvider<Map<String, GrammarProgress>>(
  (ref) => ref.watch(appDatabaseProvider).grammarProgress(),
);

/// The first lesson not yet acquired, in class order.
GrammarLesson nextGrammarLesson(Map<String, GrammarProgress> progress) =>
    grammarLessons.firstWhere(
      (lesson) => !(progress[lesson.id]?.acquired ?? false),
      orElse: () => grammarLessons.last,
    );

int acquiredGrammarLessons(Map<String, GrammarProgress> progress) =>
    grammarLessons
        .where((lesson) => progress[lesson.id]?.acquired ?? false)
        .length;

/// The grammar syllabus, in the order a classroom teacher would follow.
class GrammarPathScreen extends ConsumerWidget {
  const GrammarPathScreen({super.key});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    GrammarLesson lesson,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => GrammarLessonScreen(lesson: lesson),
      ),
    );
    ref.invalidate(grammarProgressProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress =
        ref.watch(grammarProgressProvider).asData?.value ??
        const <String, GrammarProgress>{};
    final acquired = acquiredGrammarLessons(progress);
    final next = nextGrammarLesson(progress);
    return Scaffold(
      appBar: AppBar(title: const Text('Grammaire pas à pas')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text(
            'Vingt leçons dans l’ordre d’une classe : la règle, les '
            'tableaux, des exemples, les pièges, puis un court quiz. '
            'Faites-en une à la fois.',
          ),
          const SizedBox(height: 12),
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '$acquired leçon${acquired > 1 ? 's' : ''} '
                    'acquise${acquired > 1 ? 's' : ''} sur '
                    '${grammarLessons.length}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: acquired / grammarLessons.length,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('grammar-continue'),
                    onPressed: () => _open(context, ref, next),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      acquired == 0
                          ? 'Commencer · ${next.title}'
                          : 'Continuer · ${next.title}',
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final unit in grammarUnits) ...[
            const SizedBox(height: 20),
            Text(
              'PARTIE ${unit.number} · ${unit.title.toUpperCase()}',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 2),
            Text(unit.goal, style: theme.textTheme.bodySmall),
            for (final lesson in grammarLessons.where(
              (l) => l.unit == unit.number,
            ))
              ListTile(
                key: Key('grammar-lesson-${lesson.id}'),
                contentPadding: EdgeInsets.zero,
                leading: _statusIcon(context, progress[lesson.id]),
                title: Text(
                  '${grammarLessons.indexOf(lesson) + 1}. ${lesson.title}',
                ),
                subtitle: Text(lesson.summary),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(context, ref, lesson),
              ),
          ],
          const SizedBox(height: 16),
          Text(
            'Votre cours en groupe aborde un autre point cette semaine ? '
            'Allez-y directement : chaque leçon est indépendante.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _statusIcon(BuildContext context, GrammarProgress? progress) {
    if (progress?.acquired ?? false) {
      return Icon(
        Icons.check_circle,
        color: Theme.of(context).colorScheme.primary,
      );
    }
    if (progress?.opened ?? false) return const Icon(Icons.timelapse);
    return const Icon(Icons.radio_button_unchecked);
  }
}

/// One grammar lesson, laid out the way a class runs: understand the rule,
/// see it formed, read examples, learn the traps, check, then say it aloud.
class GrammarLessonScreen extends ConsumerStatefulWidget {
  const GrammarLessonScreen({super.key, required this.lesson});

  final GrammarLesson lesson;

  @override
  ConsumerState<GrammarLessonScreen> createState() => _GrammarLessonState();
}

class _GrammarLessonState extends ConsumerState<GrammarLessonScreen>
    with ActivityTracking<GrammarLessonScreen> {
  @override
  String get activityKind => 'grammar';

  // Grammar is what the written-expression test measures.
  @override
  String? get activitySkill => 'writing';

  late final TtsService _tts;
  late List<int?> _answers;

  /// Display order of each question's options. The authored order tends to
  /// favour some positions, so it is reshuffled on every attempt.
  late List<List<int>> _order;
  var _attempt = 0;
  var _checked = false;
  var _saving = false;
  String? _error;

  GrammarLesson get _lesson => widget.lesson;

  int get _score {
    var score = 0;
    for (var i = 0; i < _lesson.questions.length; i++) {
      if (_answers[i] == _lesson.questions[i].correct) score++;
    }
    return score;
  }

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsServiceProvider);
    _answers = List<int?>.filled(_lesson.questions.length, null);
    _order = _shuffledOptions();
    unawaited(
      ref
          .read(appDatabaseProvider)
          .markGrammarOpened(_lesson.id)
          .catchError((Object _) {}),
    );
  }

  @override
  void dispose() {
    unawaited(_tts.stop().catchError((Object _) {}));
    super.dispose();
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.speak(text);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voix française indisponible sur cet appareil.'),
        ),
      );
    }
  }

  Future<void> _check() async {
    if (_saving || _answers.contains(null)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(appDatabaseProvider)
          .saveGrammarQuiz(_lesson.id, score: _score);
      ref.invalidate(grammarProgressProvider);
      if (mounted) setState(() => _checked = true);
    } on Object {
      if (mounted) {
        setState(() {
          // The explanations are still worth showing; only the record of
          // the result is missing.
          _checked = true;
          _error = 'Résultat non enregistré. Refaites le quiz plus tard.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<List<int>> _shuffledOptions() => [
    for (var i = 0; i < _lesson.questions.length; i++)
      List<int>.generate(_lesson.questions[i].options.length, (o) => o)
        ..shuffle(Random(Object.hash(_lesson.id, i, _attempt))),
  ];

  void _retry() => setState(() {
    _attempt++;
    _answers = List<int?>.filled(_lesson.questions.length, null);
    _order = _shuffledOptions();
    _checked = false;
    _error = null;
  });

  Future<void> _openLink(GrammarLink link) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(link.url),
        mode: LaunchMode.externalApplication,
      );
    } on Object {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir ce lien.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lesson = _lesson;
    final index = grammarLessons.indexOf(lesson);
    final following = index + 1 < grammarLessons.length
        ? grammarLessons[index + 1]
        : null;
    final passed = _checked && _score >= lesson.passMark;
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Leçon ${index + 1} sur ${grammarLessons.length} · '
              '${unitOf(lesson).title}',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Text(lesson.summary, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Card(
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'L’essentiel, en anglais',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(lesson.englishKey),
                  ],
                ),
              ),
            ),
            _SectionTitle('1 · Quand l’utiliser'),
            for (final point in lesson.whenToUse) _Bullet(point),
            _SectionTitle('2 · Comment le former'),
            for (final point in lesson.howToForm) _Bullet(point),
            for (final table in lesson.tables) _TableCard(table: table),
            _SectionTitle('3 · Exemples'),
            Text(
              'Touchez le haut-parleur, écoutez, puis répétez à voix haute.',
              style: theme.textTheme.bodySmall,
            ),
            for (final (fr, en) in lesson.examplePairs)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(fr),
                subtitle: Text(en),
                trailing: IconButton(
                  tooltip: 'Écouter',
                  icon: const Icon(Icons.volume_up_outlined),
                  onPressed: () => _speak(fr),
                ),
              ),
            _SectionTitle('4 · Les pièges'),
            for (final (wrong, right, why) in lesson.pitfallTriples)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✘ $wrong',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '✔ $right',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(why, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            _SectionTitle('5 · Vérifier'),
            for (var i = 0; i < lesson.questions.length; i++) ...[
              const SizedBox(height: 6),
              Text(
                lesson.questions[i].prompt,
                style: theme.textTheme.titleSmall,
              ),
              RadioGroup<int>(
                groupValue: _answers[i],
                onChanged: (value) {
                  if (!_checked) setState(() => _answers[i] = value);
                },
                child: Column(
                  children: [
                    for (final option in _order[i])
                      RadioListTile<int>(
                        key: Key('grammar-q$i-o$option'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: option,
                        enabled: !_checked,
                        title: Text(lesson.questions[i].options[option]),
                      ),
                  ],
                ),
              ),
              if (_checked)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${_answers[i] == lesson.questions[i].correct ? '✔' : '✘'} '
                    '${lesson.questions[i].explanation}',
                  ),
                ),
            ],
            const SizedBox(height: 8),
            if (!_checked)
              FilledButton(
                key: const Key('grammar-check'),
                onPressed: _saving || _answers.contains(null) ? null : _check,
                child: const Text('Vérifier mes réponses'),
              )
            else ...[
              Text(
                passed
                    ? '$_score / ${lesson.questions.length} · leçon acquise.'
                    : '$_score / ${lesson.questions.length} · relisez les '
                          'pièges, puis réessayez. Rien ne presse.',
                key: const Key('grammar-result'),
                style: theme.textTheme.titleMedium,
              ),
              TextButton(
                key: const Key('grammar-retry'),
                onPressed: _retry,
                child: const Text('Refaire le quiz'),
              ),
            ],
            if (_error != null)
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            _SectionTitle('6 · À voix haute'),
            Text(
              'La règle ne devient utile qu’une fois dite. Répondez d’abord '
              'à voix haute, puis comparez avec le modèle.',
              style: theme.textTheme.bodySmall,
            ),
            for (final (prompt, model) in lesson.speakingTasks)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(prompt),
                subtitle: const Text('Voir et écouter un modèle'),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _speak(model),
                      icon: const Icon(Icons.volume_up_outlined),
                      label: const Text('Écouter le modèle'),
                    ),
                  ),
                ],
              ),
            if (lesson.drillTopics.isNotEmpty) ...[
              _SectionTitle('7 · S’exercer'),
              FilledButton.tonalIcon(
                key: const Key('grammar-drills'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => DrillScreen(
                      topics: lesson.drillTopics,
                      title: lesson.title,
                    ),
                  ),
                ),
                icon: const Icon(Icons.edit_note_outlined),
                label: const Text('Exercices sur ce point'),
              ),
            ],
            _SectionTitle('Pour aller plus loin'),
            Text(
              'Facultatif. Ces pages s’ouvrent dans votre navigateur.',
              style: theme.textTheme.bodySmall,
            ),
            for (final link in lesson.links)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.open_in_new),
                title: Text(link.label),
                onTap: () => _openLink(link),
              ),
            if (following != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('grammar-next'),
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => GrammarLessonScreen(lesson: following),
                  ),
                ),
                child: Text('Leçon suivante · ${following.title}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 6),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  '),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.table});

  final GrammarTable table;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(table.title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
              },
              children: [
                for (final (left, right) in table.cells)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          left,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          right,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
