import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/db/database.dart';
import '../../data/db/course_daos.dart';
import '../../domain/course/course_catalog.dart';
import '../../domain/speech/speech_services.dart';
import '../../providers.dart';
import '../speaking/speaking_session_screen.dart';
import '../speaking/speaking_mistakes_screen.dart';
import '../word_help/app_text_selection.dart';

class CourseScreen extends ConsumerStatefulWidget {
  const CourseScreen({super.key, this.track = bToCCourse});
  final CourseTrack track;
  @override
  ConsumerState<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends ConsumerState<CourseScreen>
    with WidgetsBindingObserver {
  late Future<Map<String, CourseProgress>> _overview;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(_reload);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _reload() {
    _overview = ref
        .read(appDatabaseProvider)
        .courseOverview(track: widget.track);
  }

  Future<void> _open(CourseLesson lesson, {bool recall = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseLessonScreen(lesson: lesson, recall: recall),
      ),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Parcours ${widget.track.label}')),
    body: FutureBuilder<Map<String, CourseProgress>>(
      future: _overview,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(_reload),
              child: const Text('Progression indisponible · réessayer'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final progress = snapshot.data!;
        final completed = progress.values
            .where((p) => p.fullCourseCompleted)
            .length;
        final next = widget.track.lessons
            .where((l) => !(progress[l.id]?.fullCourseCompleted ?? false))
            .firstOrNull;
        final due = widget.track.lessons
            .where((l) => progress[l.id]?.due(DateTime.now()) ?? false)
            .toList();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Des classes, puis de la pratique',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(widget.track.description),
            const Text(
              'Niveaux de l’ÉLS canadienne, pas équivalences A1/B2/C1. Chaque classe comprend lecture, écoute, rédaction et échange oral. Les durées et longueurs sont des repères pédagogiques, pas des exigences officielles.',
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: completed / widget.track.lessons.length,
              semanticsLabel: 'Progression du parcours',
            ),
            Text(
              '$completed / ${widget.track.lessons.length} leçons terminées · ${widget.track.modules.length} modules',
            ),
            const Text(
              'Progression d’étude des quatre compétences, pas certification de niveau. Toutes les classes restent accessibles; vos anciennes activités restent enregistrées.',
            ),
            const SizedBox(height: 12),
            if (next != null)
              FilledButton.icon(
                key: const Key('course-continue'),
                onPressed: () => _open(next),
                icon: const Icon(Icons.play_arrow),
                label: Text('Continuer : ${next.title}'),
              )
            else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Parcours réalisé ! Continuez les rappels et les conversations nouvelles. Un résultat officiel ne peut être déduit de ces activités.',
                  ),
                ),
              ),
            if (due.isNotEmpty)
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.update),
                      title: Text('${due.length} rappel(s) à faire sans notes'),
                      subtitle: const Text(
                        'À 2 jours, puis 7, 21 et 60 jours après un rappel validé.',
                      ),
                    ),
                    for (final lesson in due)
                      ListTile(
                        title: Text(lesson.title),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _open(lesson, recall: true),
                      ),
                  ],
                ),
              ),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Rythme suggéré, adaptable : un module par semaine.\n'
                  'Pour chaque classe : comprendre, lire et écouter (20–30 min), puis écrire, réviser et parler (20–30 min).\n'
                  'Ajoutez une séance de rappel sans notes et de correction personnelle.\n'
                  'Avancez à votre rythme : aucune durée ne garantit un niveau officiel.',
                ),
              ),
            ),
            for (final module in widget.track.modules)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          '${module.number}. ${module.title}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(module.goal),
                      ),
                      for (final lesson in widget.track.lessons.where(
                        (l) => l.module == module.number,
                      ))
                        ListTile(
                          leading: Icon(
                            progress[lesson.id]?.fullCourseCompleted == true
                                ? Icons.check_circle
                                : Icons.menu_book_outlined,
                          ),
                          title: Text(lesson.title),
                          subtitle: Text(
                            _status(
                              progress[lesson.id] ?? const CourseProgress(),
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _open(lesson),
                        ),
                    ],
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SpeakingMistakesScreen(),
                ),
              ),
              icon: const Icon(Icons.psychology),
              label: const Text('Réparer mes erreurs personnelles'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  if (!await launchUrl(
                    Uri.parse(
                      'https://www.canada.ca/en/treasury-board-secretariat/services/staffing/qualification-standards/relation-official-languages.html',
                    ),
                    mode: LaunchMode.externalApplication,
                  )) {
                    throw StateError('Not opened');
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Impossible d’ouvrir les critères officiels.',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Consulter les critères officiels de l’ÉLS'),
            ),
            const Text(
              'Contenu original d’entraînement, non officiel. Les notes et la progression restent sur cet appareil/navigateur. '
              'Le plan de 26 semaines et ses résultats ne sont pas modifiés. Les cours et quiz ne nécessitent aucun appel IA.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        );
      },
    ),
  );

  String _status(CourseProgress p) => p.fullCourseCompleted
      ? 'Terminée · revoir librement'
      : '${p.read ? '✓' : '○'} Cours · ${p.quizPassed ? '✓' : '○'} Quiz · ${p.practised ? '✓' : '○'} Oral\n'
            '${p.skills[0] ? '✓' : '○'} Lecture · ${p.skills[1] ? '✓' : '○'} Écoute · ${p.skills[2] ? '✓' : '○'} Écriture';
}

class CourseLessonScreen extends ConsumerStatefulWidget {
  const CourseLessonScreen({
    super.key,
    required this.lesson,
    this.recall = false,
  });
  final CourseLesson lesson;
  final bool recall;
  @override
  ConsumerState<CourseLessonScreen> createState() => _CourseLessonState();
}

class _CourseLessonState extends ConsumerState<CourseLessonScreen>
    with WidgetsBindingObserver {
  late final AppDatabase _db;
  late final TtsService _tts;
  final _notes = TextEditingController();
  final _writing = TextEditingController();
  final List<int?> _comprehension = [null, null];
  final List<bool> _revision = [false, false, false];
  bool _workshopChecked = false;
  CourseWorkshop get workshop => workshopForLesson(lesson.id);
  CourseProgress? _progress;
  late List<int?> _answers;
  late List<bool> _criteria;
  bool _busy = false, _revealed = false, _background = false, _leaving = false;
  int? _score;
  String? _error;
  Timer? _debounce;
  Future<void> _notesWrite = Future.value();
  CourseLesson get lesson => widget.lesson;

  @override
  void initState() {
    super.initState();
    _db = ref.read(appDatabaseProvider);
    _tts = ref.read(ttsServiceProvider);
    _answers = List.filled(lesson.questions.length, null);
    _criteria = List.filled(lesson.criteria.length, false);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final value = await _db.courseProgress(lesson.id);
      if (!mounted) return;
      setState(() {
        _progress = value;
        _notes.text = value.notes;
        _writing.text = value.writing;
        if (!widget.recall && value.skills[2]) _revision.fillRange(0, 3, true);
        if (!widget.recall && value.practice.isNotEmpty) {
          _criteria = List.of(value.practice);
        }
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Chargement impossible. Votre progression n’a pas été remplacée.',
        );
      }
    }
  }

  void _notesChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => unawaited(
        _flushNotes().catchError((Object _) {
          if (mounted) {
            setState(
              () => _error =
                  'Notes non enregistrées. Réessayez avant de quitter.',
            );
          }
        }),
      ),
    );
  }

  Future<void> _flushNotes() {
    _debounce?.cancel();
    if (_progress == null) return _notesWrite;
    final text = _notes.text;
    final writing = _writing.text;
    _notesWrite = _notesWrite
        .catchError((Object _) {})
        .then((_) => _db.saveCourseNotes(lesson.id, text, writing: writing));
    return _notesWrite;
  }

  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _flushNotes();
      await action();
      final progress = await _db.courseProgress(lesson.id);
      if (mounted) setState(() => _progress = progress);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Enregistrement impossible ou rappel déjà validé. Réessayez; vos autres résultats sont conservés.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _quiz() => _act(() async {
    final answers = _answers.cast<int>();
    final score = widget.recall
        ? courseQuizScore(lesson, answers)
        : await _db.submitCourseQuiz(lesson.id, answers);
    if (mounted) setState(() => _score = score);
  });

  Future<void> _partner() => _act(() async {
    await _tts.stop().catchError((Object _) {});
    final id = await _db.courseSpeakingSession(lesson.id);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SpeakingSessionScreen(sessionId: id)),
    );
  });

  Future<void> _listen([String? text]) async {
    if (_background) return;
    try {
      await _tts.speak(text ?? lesson.developedExample);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Voix indisponible; l’exemple écrit reste accessible.',
        );
      }
    }
  }

  Future<void> _leave() async {
    if (_busy || _leaving) return;
    _leaving = true;
    try {
      await _tts.stop().catchError((Object _) {});
      await _flushNotes();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Notes non enregistrées. Réessayez ou copiez-les avant de quitter.',
        );
      }
    } finally {
      _leaving = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _background =
        state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
    if (_background) {
      unawaited(_tts.stop().catchError((Object _) {}));
      unawaited(_flushNotes().catchError((Object _) {}));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    unawaited(_flushNotes().catchError((Object _) {}));
    unawaited(_tts.stop().catchError((Object _) {}));
    _notes.dispose();
    _writing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) unawaited(_leave());
      },
      child: Scaffold(
        appBar: AppBar(title: Text(lesson.title)),
        body: progress == null
            ? Center(
                child: _error == null
                    ? const CircularProgressIndicator()
                    : TextButton(onPressed: _load, child: Text(_error!)),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '${courseTrackForLesson(lesson.id).label} · Module ${lesson.module} · ${widget.recall ? 'Rappel sans notes' : 'Classe en deux séances'}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    lesson.objective,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (widget.recall)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Avant d’ouvrir le cours : expliquez la règle de mémoire, faites la vérification et réutilisez-la dans une NOUVELLE situation. Cochez ensuite votre pratique.',
                      ),
                    ),
                  if (progress.completed)
                    Chip(
                      label: Text(
                        progress.fullCourseCompleted
                            ? 'Quatre compétences pratiquées · niveau non certifié'
                            : 'Anciennes activités conservées · ateliers à compléter',
                      ),
                    ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ExpansionTile(
                    title: const Text('1. Comprendre le cours'),
                    initiallyExpanded: !widget.recall,
                    children: [
                      for (final paragraph in lesson.teaching)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(paragraph),
                        ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: _busy ? null : _listen,
                        icon: const Icon(Icons.volume_up),
                        label: const Text(
                          'Écouter l’exemple · voix synthétique',
                        ),
                      ),
                      TextButton(
                        onPressed: () => _tts.stop().catchError((Object _) {}),
                        child: const Text('Arrêter l’audio'),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text('Exemples et expressions utiles'),
                    children: [
                      _section(
                        'Réponse courte (pas une note de niveau)',
                        lesson.simpleExample,
                      ),
                      _section(
                        'Réponse développée possible',
                        lesson.developedExample,
                      ),
                      for (final phrase in lesson.phrases)
                        ListTile(dense: true, title: Text(phrase)),
                    ],
                  ),
                  _section('2. Reformuler avant de regarder', lesson.exercise),
                  TextButton(
                    onPressed: () => setState(() => _revealed = !_revealed),
                    child: Text(
                      _revealed
                          ? 'Masquer la proposition'
                          : 'Voir une proposition après mon essai',
                    ),
                  ),
                  if (_revealed)
                    SelectableText(
                      lesson.modelAnswer,
                      contextMenuBuilder: learningTextContextMenu,
                    ),
                  if (!widget.recall)
                    OutlinedButton(
                      key: const Key('course-read'),
                      onPressed: _busy
                          ? null
                          : () => _act(() => _db.markCourseRead(lesson.id)),
                      child: Text(
                        progress.read
                            ? 'Cours étudié ✓'
                            : 'J’ai étudié et essayé la reformulation',
                      ),
                    ),
                  ..._workshopWidgets(),
                  const SizedBox(height: 12),
                  Text(
                    '3. Vérifier ma compréhension',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Text(
                    'Un contrôle formatif : deux réponses correctes pour valider. Vous pouvez relire et recommencer; ce score n’est pas un niveau ÉLS.',
                  ),
                  for (var i = 0; i < lesson.questions.length; i++)
                    _question(i),
                  FilledButton(
                    key: const Key('course-quiz'),
                    onPressed:
                        _busy || _answers.contains(null) || _score != null
                        ? null
                        : _quiz,
                    child: const Text('Vérifier mes réponses'),
                  ),
                  if (_score != null) ...[
                    Text('Résultat : $_score / ${lesson.questions.length}'),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _answers = List.filled(
                                lesson.questions.length,
                                null,
                              );
                              _score = null;
                            }),
                      child: const Text('Refaire sans les réponses'),
                    ),
                  ],
                  _section('4. Transférer à l’oral', lesson.speakingTask),
                  const Text(
                    'Travaillez seul à voix haute ou avec le partenaire. Préparez quelques mots-clés, pas un texte à réciter. '
                    'Le partenaire peut corriger vos réponses; ses suggestions restent à vérifier. Aucun appel IA n’est fait en ouvrant la pratique.',
                  ),
                  OutlinedButton.icon(
                    key: const Key('course-partner'),
                    onPressed: _busy ? null : _partner,
                    icon: const Icon(Icons.forum_outlined),
                    label: const Text('Pratiquer avec mon partenaire'),
                  ),
                  const Text(
                    'Après votre essai, autoévaluez les éléments suivants. Ne les cochez pas simplement parce que vous avez lu le modèle.',
                  ),
                  for (var i = 0; i < lesson.criteria.length; i++)
                    CheckboxListTile(
                      key: Key('course-criterion-$i'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(lesson.criteria[i]),
                      value: _criteria[i],
                      onChanged: _busy
                          ? null
                          : (value) =>
                                setState(() => _criteria[i] = value ?? false),
                    ),
                  if (!widget.recall)
                    FilledButton(
                      key: const Key('course-practice'),
                      onPressed: _busy
                          ? null
                          : () => _act(
                              () =>
                                  _db.saveCoursePractice(lesson.id, _criteria),
                            ),
                      child: const Text('Enregistrer ma pratique'),
                    )
                  else
                    FilledButton(
                      key: const Key('course-recall'),
                      onPressed:
                          _busy ||
                              _score != lesson.questions.length ||
                              !_criteria.every((v) => v) ||
                              !_workshopChecked ||
                              _comprehension.contains(null) ||
                              !workshop.answersCorrect(
                                _comprehension.cast<int>(),
                              ) ||
                              !_revision.every((v) => v) ||
                              _writing.text.trim().length < 30 ||
                              !progress.due(DateTime.now())
                          ? null
                          : () => _act(
                              () => _db.completeCourseRecall(
                                lesson.id,
                                answers: _answers.cast<int>(),
                                criteria: _criteria,
                                expectedCount: progress.reviewCount,
                                now: DateTime.now(),
                                comprehensionAnswers: _comprehension
                                    .cast<int>(),
                                writingRevised: _revision.every((v) => v),
                              ),
                            ),
                      child: Text(
                        progress.due(DateTime.now())
                            ? 'Valider ce rappel'
                            : 'Rappel enregistré ✓',
                      ),
                    ),
                  if (progress.fullCourseCompleted && !widget.recall)
                    const Text(
                      'Les activités des quatre compétences sont réalisées. Un rappel sera proposé; la maîtrise reste à vérifier dans de nouvelles situations.',
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('course-notes'),
                    contextMenuBuilder: learningTextContextMenu,
                    controller: _notes,
                    readOnly: _busy,
                    minLines: 3,
                    maxLines: 8,
                    maxLength: 3000,
                    onChanged: _notesChanged,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText:
                          'Mes mots-clés, mon essai écrit et ce que je dois reprendre',
                      helperText:
                          'Enregistrement automatique local · évitez les détails confidentiels',
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _act(() async {}),
                    child: const Text('Enregistrer mes notes maintenant'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _busy ? null : _leave,
                    child: const Text('Retour au parcours'),
                  ),
                ],
              ),
      ),
    );
  }

  List<Widget> _workshopWidgets() => [
    const Divider(),
    Text(
      'Atelier des quatre compétences',
      style: Theme.of(context).textTheme.titleLarge,
    ),
    const Text(
      'Lecture et écoute : répondez avant de consulter les explications. Rédaction : produisez votre propre texte puis révisez-le. Les modèles illustrent une approche; ils ne sont pas à recopier.',
    ),
    ExpansionTile(
      title: const Text('Lire le texte'),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(workshop.reading),
        ),
      ],
    ),
    _workshopQuestion(0, workshop.readingQuestion),
    OutlinedButton.icon(
      key: const Key('course-listen-workshop'),
      onPressed: _busy ? null : () => _listen(workshop.listening),
      icon: const Icon(Icons.headphones),
      label: const Text('Écouter le message · voix synthétique'),
    ),
    TextButton(
      onPressed: () => _tts.stop().catchError((Object _) {}),
      child: const Text('Arrêter le message'),
    ),
    ExpansionTile(
      title: const Text('Transcription · après mon écoute'),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(workshop.listening),
        ),
      ],
    ),
    const Text(
      'Si la voix est indisponible, le texte reste accessible; reprenez une vraie écoute avant de valider votre pratique personnelle.',
    ),
    _workshopQuestion(1, workshop.listeningQuestion),
    TextButton(
      key: const Key('course-check-comprehension'),
      onPressed: _busy || _comprehension.contains(null)
          ? null
          : () => setState(() => _workshopChecked = true),
      child: const Text('Vérifier lecture et écoute'),
    ),
    if (_workshopChecked)
      TextButton(
        onPressed: _busy
            ? null
            : () => setState(() {
                _workshopChecked = false;
                _comprehension.fillRange(0, 2, null);
              }),
        child: const Text('Refaire la compréhension'),
      ),
    _section('Écrire avec mes propres mots', workshop.writingTask),
    TextField(
      key: const Key('course-writing'),
      contextMenuBuilder: learningTextContextMenu,
      controller: _writing,
      readOnly: _busy,
      minLines: 5,
      maxLines: 12,
      maxLength: 6000,
      onChanged: (text) {
        _notesChanged(text);
        setState(() {});
      },
      decoration: const InputDecoration(
        labelText: 'Mon texte · sauvegarde locale automatique',
        border: OutlineInputBorder(),
      ),
    ),
    ExpansionTile(
      title: const Text('Après mon essai : exemple de formulation (extrait)'),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(workshop.writingModel),
        ),
      ],
    ),
    for (var i = 0; i < 3; i++)
      CheckboxListTile(
        key: Key('course-revision-$i'),
        value: _revision[i],
        title: Text(
          const [
            'Mon texte répond à la consigne avec mes propres idées.',
            'J’ai vérifié les faits, les liens entre les phrases et la structure étudiée.',
            'J’ai relu et corrigé mon texte; je peux expliquer un changement.',
          ][i],
        ),
        onChanged: _busy
            ? null
            : (value) => setState(() => _revision[i] = value ?? false),
      ),
    const Text(
      'Autoévaluation de rédaction, sans note officielle. Le modèle est un extrait, pas nécessairement un texte de la longueur demandée. Pour un retour IA, sélectionnez un passage et choisissez « Poser une question ». La qualité ne se déduit pas du nombre de mots.',
    ),
    if (!widget.recall)
      FilledButton(
        key: const Key('course-save-workshop'),
        onPressed:
            _busy ||
                !_workshopChecked ||
                _comprehension.contains(null) ||
                !workshop.answersCorrect(_comprehension.cast<int>()) ||
                !_revision.every((v) => v) ||
                _writing.text.trim().length < 30
            ? null
            : () => _act(
                () => _db.saveCourseWorkshop(
                  lesson.id,
                  answers: _comprehension.cast<int>(),
                  writingRevised: _revision.every((v) => v),
                ),
              ),
        child: Text(
          _progress!.skills.every((v) => v)
              ? 'Atelier enregistré ✓'
              : 'Enregistrer lecture, écoute et rédaction',
        ),
      ),
    const Divider(),
  ];

  Widget _workshopQuestion(int index, CourseQuestion question) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${index == 0 ? 'Lecture' : 'Écoute'} : ${question.prompt}'),
          for (var option = 0; option < question.options.length; option++)
            OutlinedButton.icon(
              key: Key('course-comprehension-$index-$option'),
              onPressed: _busy || _workshopChecked
                  ? null
                  : () => setState(() => _comprehension[index] = option),
              icon: Icon(
                _comprehension[index] == option
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              label: Text(question.options[option]),
            ),
          if (_workshopChecked)
            Text(
              '${_comprehension[index] == question.correct ? '✓' : 'À revoir'} ${question.explanation}',
            ),
        ],
      ),
    ),
  );

  Widget _section(String title, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        SelectableText(text, contextMenuBuilder: learningTextContextMenu),
      ],
    ),
  );

  Widget _question(int index) {
    final question = lesson.questions[index];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(question.prompt),
            for (var option = 0; option < question.options.length; option++)
              OutlinedButton.icon(
                key: Key('course-q$index-o$option'),
                onPressed: _busy || _score != null
                    ? null
                    : () => setState(() => _answers[index] = option),
                icon: Icon(
                  _answers[index] == option
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                label: Text(question.options[option]),
              ),
            if (_score != null)
              Text(
                '${_answers[index] == question.correct ? '✓' : 'À revoir'} ${question.explanation}',
              ),
          ],
        ),
      ),
    );
  }
}
