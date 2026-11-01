import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/database.dart';
import '../../data/db/daos.dart';
import '../../data/db/weekly_daos.dart';
import '../../domain/course/course_catalog.dart';
import '../../domain/weekly/weekly_report.dart';
import '../../providers.dart';
import '../speaking/voice_draft.dart';
import '../vocab/vocab_review_screen.dart';
import '../word_help/app_text_selection.dart';
import '../word_help/word_help_screen.dart';

class WeeklyAssignmentScreen extends ConsumerStatefulWidget {
  const WeeklyAssignmentScreen({super.key, required this.assignment});
  final WeeklyAssignment assignment;
  @override
  ConsumerState<WeeklyAssignmentScreen> createState() => _AssignmentState();
}

class _AssignmentState extends ConsumerState<WeeklyAssignmentScreen>
    with WidgetsBindingObserver {
  final _editor = TextEditingController();
  final _voice = GlobalKey<VoiceDraftState>();
  final _watch = Stopwatch();
  bool _audioPlayed = false;
  Timer? _timer;
  Future<void> _writes = Future.value();
  bool _ready = false,
      _busy = false,
      _voiceBusy = false,
      _assisted = false,
      _revised = false,
      _spoken = false;
  int? _answer;
  String? _error;
  String _lessonId = '';
  WeeklyAssignment get a => widget.assignment;
  CourseLesson get lesson => findCourseLesson(_lessonId);
  CourseWorkshop get workshop => workshopForLesson(_lessonId);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final week = await db.studyWeek(a.weekId);
      if (week == null) throw StateError('Semaine absente.');
      _lessonId = week.lessonId;
      final raw = await db.getSetting('weekly:draft:${a.id}');
      if (!mounted) return;
      if (raw != null) {
        final j = jsonDecode(raw);
        _editor.text = j['text'];
        _answer = j['answer'];
        _assisted = j['assisted'] == true;
        _revised = j['revised'] == true;
        _spoken = j['spoken'] == true;
        _audioPlayed = j['audioPlayed'] == true;
      }
      _watch.start();
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _ready = true);
  }

  void _change() {
    _timer?.cancel();
    _timer = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(
        _flush().catchError((Object e) {
          if (mounted) setState(() => _error = 'Brouillon non enregistré : $e');
        }),
      ),
    );
  }

  Future<void> _flush() {
    _timer?.cancel();
    final db = ref.read(appDatabaseProvider);
    final value = jsonEncode({
      'text': _editor.text,
      'answer': _answer,
      'assisted': _assisted,
      'revised': _revised,
      'spoken': _spoken,
      'audioPlayed': _audioPlayed,
    });
    return _writes = _writes
        .catchError((Object _) {})
        .then((_) => db.setSetting('weekly:draft:${a.id}', value));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _watch.start();
    } else {
      _watch.stop();
      unawaited(_flush());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _watch.stop();
    _editor.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || _voiceBusy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _flush();
      final data = <String, dynamic>{};
      late EvidenceKind kind;
      var self = false;
      if (a.skill == 'reading' || a.skill == 'listening') {
        if (_answer == null) throw StateError('Répondez à la question.');
        kind = a.skill == 'reading'
            ? EvidenceKind.readingAttempt
            : EvidenceKind.listeningAttempt;
        data['answer'] = _answer;
        data['justification'] = _editor.text;
      } else if (a.skill == 'writing') {
        kind = EvidenceKind.writingAttempt;
        data.addAll({'draft': _editor.text, 'revised': _revised});
      } else {
        if (!_revised) throw StateError('Confirmez votre pratique.');
        self = true;
        kind = EvidenceKind.solo;
        data['reflection'] = _editor.text;
        data['spokenCaptured'] = _spoken;
      }
      await ref
          .read(appDatabaseProvider)
          .saveAssignmentEvidence(
            a.id,
            AssignmentEvidence(
              kind: kind,
              data: data,
              assisted: _assisted || (a.skill == 'listening' && !_audioPlayed),
              selfReported: self,
              observedSeconds: _watch.elapsed.inSeconds,
            ),
            at: DateTime.now(),
          );
      ref.invalidate(activeWeekAssignmentsProvider);
      if (mounted) {
        if (a.skill == 'reading' || a.skill == 'listening') {
          final question = a.skill == 'reading'
              ? workshop.readingQuestion
              : workshop.listeningQuestion;
          await showDialog<void>(
            context: context,
            builder: (c) => AlertDialog(
              title: Text(
                _answer == question.correct ? 'Bonne réponse' : 'À revoir',
              ),
              content: Text(question.explanation),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Continuer'),
                ),
              ],
            ),
          );
        }
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_voiceBusy && !_busy,
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) unawaited(_flush());
    },
    child: Scaffold(
      appBar: AppBar(title: Text(a.titleFr)),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : _lessonId.isEmpty
          ? Center(child: Text(_error ?? 'Activité indisponible.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  lesson.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${a.minutes} minutes prévues · les durées observées ne mesurent pas la qualité.',
                ),
                if (a.completed)
                  const Text(
                    'Activité déjà enregistrée. Vous pouvez relire votre travail.',
                  ),
                if (a.skill == 'reading' || a.skill == 'listening') ...[
                  if (a.skill == 'reading')
                    Text(workshop.reading)
                  else ...[
                    FilledButton.icon(
                      onPressed: _voiceBusy
                          ? null
                          : () async {
                              try {
                                await ref
                                    .read(ttsServiceProvider)
                                    .speak(workshop.listening);
                                _audioPlayed = true;
                                _change();
                              } catch (e) {
                                if (mounted) {
                                  setState(
                                    () => _error =
                                        'Voix indisponible. La transcription reste accessible comme travail assisté.',
                                  );
                                }
                              }
                            },
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Écouter le passage'),
                    ),
                    ExpansionTile(
                      title: const Text('Transcription · preuve assistée'),
                      onExpansionChanged: (v) {
                        if (v) {
                          setState(() => _assisted = true);
                          _change();
                        }
                      },
                      children: [Text(workshop.listening)],
                    ),
                  ],
                  Text(
                    (a.skill == 'reading'
                            ? workshop.readingQuestion
                            : workshop.listeningQuestion)
                        .prompt,
                  ),
                  RadioGroup<int>(
                    groupValue: _answer,
                    onChanged: (v) {
                      if (!_busy) {
                        setState(() => _answer = v);
                        _change();
                      }
                    },
                    child: Column(
                      children: [
                        for (
                          var i = 0;
                          i <
                              (a.skill == 'reading'
                                      ? workshop.readingQuestion
                                      : workshop.listeningQuestion)
                                  .options
                                  .length;
                          i++
                        )
                          RadioListTile<int>(
                            value: i,
                            enabled: !_busy,
                            title: Text(
                              (a.skill == 'reading'
                                      ? workshop.readingQuestion
                                      : workshop.listeningQuestion)
                                  .options[i],
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextField(
                    controller: _editor,
                    contextMenuBuilder: learningTextContextMenu,
                    maxLength: 2000,
                    minLines: 2,
                    maxLines: 5,
                    onChanged: (_) => _change(),
                    decoration: const InputDecoration(
                      labelText:
                          'Résumez le passage et expliquez votre réponse (facultatif)',
                    ),
                  ),
                ] else if (a.skill == 'writing') ...[
                  Text(workshop.writingTask),
                  TextField(
                    controller: _editor,
                    contextMenuBuilder: learningTextContextMenu,
                    minLines: 6,
                    maxLines: 15,
                    maxLength: 6000,
                    onChanged: (_) => _change(),
                  ),
                  ExpansionTile(
                    title: const Text('Exemple de formulation · extrait'),
                    children: [Text(workshop.writingModel)],
                  ),
                  CheckboxListTile(
                    value: _revised,
                    onChanged: (v) {
                      setState(() => _revised = v == true);
                      _change();
                    },
                    title: const Text(
                      'J’ai couvert la tâche, vérifié la langue et révisé mon texte.',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WordHelpScreen(
                          selection: _editor.text.length > 1000
                              ? _editor.text.substring(0, 1000)
                              : _editor.text,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Demander une explication IA sur mon extrait',
                    ),
                  ),
                ] else if (a.skill == 'vocabulary') ...[
                  const Text(
                    'Révisez les cartes dues. Si aucune carte n’est due, reformulez les expressions de la leçon à voix haute.',
                  ),
                  for (final phrase in lesson.phrases) Text(phrase),
                  OutlinedButton(
                    onPressed: () async {
                      final db = ref.read(appDatabaseProvider);
                      final reviewed = <int>[];
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VocabReviewScreen(
                            onReviewed: (id) => reviewed.add(id),
                          ),
                        ),
                      );
                      if (reviewed.isNotEmpty) {
                        await db.saveAssignmentEvidence(
                          a.id,
                          AssignmentEvidence(
                            kind: EvidenceKind.vocabulary,
                            data: {
                              'reviewed': reviewed.toSet().length,
                              'cardIds': reviewed.toSet().toList(),
                            },
                            observedSeconds: _watch.elapsed.inSeconds,
                          ),
                          at: DateTime.now(),
                        );
                        ref.invalidate(activeWeekAssignmentsProvider);
                        if (context.mounted) Navigator.pop(context, true);
                      }
                    },
                    child: const Text('Réviser mes cartes'),
                  ),
                  TextField(
                    controller: _editor,
                    minLines: 2,
                    maxLines: 6,
                    maxLength: 2000,
                    onChanged: (_) => _change(),
                    decoration: const InputDecoration(
                      labelText: 'Ma pratique des expressions',
                    ),
                  ),
                  CheckboxListTile(
                    value: _revised,
                    onChanged: (v) {
                      setState(() => _revised = v == true);
                      _change();
                    },
                    title: const Text(
                      'J’ai pratiqué ces expressions · auto-déclaration',
                    ),
                  ),
                ] else ...[
                  Text(lesson.speakingTask),
                  const Text(
                    'Parlez d’abord, puis notez ce que vous avez amélioré. Cette pratique autonome ne produit pas une note de niveau.',
                  ),
                  VoiceDraft(
                    key: _voice,
                    controller: _editor,
                    onChanged: (_) => _change(),
                    onBusy: (v) {
                      if (mounted) {
                        setState(() {
                          if (_voiceBusy && !v) _spoken = true;
                          _voiceBusy = v;
                        });
                      }
                    },
                  ),
                  CheckboxListTile(
                    value: _revised,
                    onChanged: _voiceBusy
                        ? null
                        : (v) {
                            setState(() => _revised = v == true);
                            _change();
                          },
                    title: const Text(
                      'J’ai réellement pratiqué à voix haute · auto-déclaration',
                    ),
                  ),
                ],
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                FilledButton(
                  onPressed: _busy || _voiceBusy || a.completed ? null : _save,
                  child: Text(
                    _busy ? 'Enregistrement…' : 'Enregistrer mon travail',
                  ),
                ),
              ],
            ),
    ),
  );
}
