import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/daos.dart';
import '../../data/db/course_daos.dart';
import '../../domain/course/course_catalog.dart';
import '../../domain/weekly/placement.dart';
import '../../domain/weekly/placement_diagnostic.dart';
import '../../providers.dart';
import '../speaking/voice_draft.dart';

class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({super.key});
  @override
  ConsumerState<PlacementScreen> createState() => _PlacementState();
}

class _PlacementState extends ConsumerState<PlacementScreen> {
  final _spoken = TextEditingController(), _written = TextEditingController();
  final _voice = GlobalKey<VoiceDraftState>();
  final _answers = List<int?>.filled(8, null);
  final _listened = <int>{};
  bool _busy = false,
      _voiceBusy = false,
      _captured = false,
      _assisted = false,
      _ready = false;
  String? _error;
  PlacementResult? _result;
  String _track = 'a-to-b-v1', _lesson = 'ab-01-identity';
  Timer? _timer;
  Future<void> _save = Future.value();
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final raw = await ref
          .read(appDatabaseProvider)
          .getSetting('placement:draft:v1');
      if (!mounted) return;
      if (raw != null) {
        final j = jsonDecode(raw);
        _spoken.text = j['spoken'] as String;
        _written.text = j['written'] as String;
        final answers = List<int?>.from(j['answers']);
        if (answers.length == 8) _answers.setAll(0, answers);
        _assisted = j['assisted'] == true;
        _captured = j['captured'] == true;
        _listened.addAll(List<int>.from(j['listened'] ?? []));
      }
    } catch (_) {
      if (mounted) {
        _error = 'Le brouillon est illisible. Vous pouvez recommencer.';
      }
    }
    if (mounted) setState(() => _ready = true);
  }

  void _changed() {
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
    final json = jsonEncode({
      'spoken': _spoken.text,
      'written': _written.text,
      'answers': _answers,
      'assisted': _assisted,
      'captured': _captured,
      'listened': _listened.toList(),
    });
    return _save = _save
        .catchError((Object _) {})
        .then((_) => db.setSetting('placement:draft:v1', json));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _spoken.dispose();
    _written.dispose();
    super.dispose();
  }

  Map<String, dynamic> _diagnostic() {
    int score(int start) => List.generate(4, (i) => i + start)
        .where(
          (i) =>
              _answers[i] == placementPassages[i ~/ 2].questions[i % 2].correct,
        )
        .length;
    return {
      'spokenCaptured': _captured,
      'readingCorrect': score(0),
      'listeningCorrect': score(4),
      'readingAnswered': _answers.take(4).whereType<int>().length,
      'listeningAnswered': _answers.skip(4).whereType<int>().length,
      'listeningAssisted': _assisted || !_listened.containsAll([2, 3]),
      'pronunciation': 'unknown',
      'fluency': 'unknown',
    };
  }

  Future<void> _submit({bool manual = false}) async {
    if (_busy || _voiceBusy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _voice.currentState?.stop();
      await _flush();
      final db = ref.read(appDatabaseProvider);
      final result = manual
          ? PlacementResult(
              trackId: 'a-to-b-v1',
              levelEstimate: 'unknown',
              reasoning:
                  'Choix provisoire. Les compétences sans preuve restent non évaluées.',
              strengths: const ['Vous pouvez avancer à votre rythme.'],
              priorities: const [
                'Recueillir des preuves dans les quatre compétences.',
                'Confirmer le niveau de départ.',
              ],
              decidedAt: DateTime.now(),
            )
          : await requestPlacement(
              db: db,
              client: await ref.read(llmClientProvider.future),
              spokenTranscript: _spoken.text,
              writtenText: _written.text,
              diagnostic: _diagnostic(),
              persist: false,
            );
      final track = courseTracks.firstWhere((t) => t.id == result.trackId);
      final progress = await db.courseOverview(track: track);
      final next = track.lessons.firstWhere(
        (l) => progress[l.id]?.fullCourseCompleted != true,
        orElse: () => track.lessons.last,
      );
      if (mounted) {
        setState(() {
          _result = result;
          _track = result.trackId;
          _lesson = next.id;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = _result!;
      final choice = PlacementResult(
        trackId: _track,
        levelEstimate: result.levelEstimate,
        reasoning: '${result.reasoning}\nDépart confirmé : $_lesson.',
        strengths: result.strengths,
        priorities: result.priorities,
        decidedAt: result.decidedAt,
      );
      final db = ref.read(appDatabaseProvider);
      await db.transaction(() async {
        await db.setSetting(placementSettingKey, jsonEncode(choice.toJson()));
        await db.setSetting('placement:startLesson', _lesson);
        await db.setSetting('placement:evidence:v1', jsonEncode(_diagnostic()));
      });
      ref.invalidate(placementProvider);
      if (mounted) Navigator.pop(context, choice);
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
      if (didPop) unawaited(_flush().catchError((Object _) {}));
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Placement · quatre compétences')),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Un point de départ provisoire. Vous pouvez sauter une partie; elle restera non évaluée. Aucune estimation officielle. Vos brouillons restent sur cet appareil.',
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_result == null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Parler : présentez votre travail, racontez une difficulté récente et proposez une amélioration. Objectif : environ 80 mots.',
                  ),
                  VoiceDraft(
                    key: _voice,
                    maxCharacters: 8000,
                    controller: _spoken,
                    enabled: !_busy,
                    onSpeechCaptured: () {
                      _captured = true;
                      _changed();
                    },
                    onChanged: (_) {
                      _changed();
                    },
                    onBusy: (busy) {
                      if (mounted) {
                        setState(() {
                          _voiceBusy = busy;
                        });
                      }
                      _changed();
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Écrire : annoncez un changement de réunion et proposez une solution. Objectif : au moins 50 mots.',
                  ),
                  TextField(
                    key: const Key('placement-written'),
                    controller: _written,
                    enabled: !_busy && !_voiceBusy,
                    maxLength: 8000,
                    minLines: 4,
                    maxLines: 8,
                    onChanged: (_) => _changed(),
                  ),
                  for (var p = 0; p < placementPassages.length; p++) ...[
                    const Divider(),
                    Text(
                      '${p < 2 ? 'Lecture' : 'Écoute'} · ${placementPassages[p].band}',
                    ),
                    if (p < 2)
                      Text(placementPassages[p].text)
                    else ...[
                      OutlinedButton.icon(
                        onPressed: _voiceBusy
                            ? null
                            : () async {
                                try {
                                  await ref
                                      .read(ttsServiceProvider)
                                      .speak(placementPassages[p].text);
                                  _listened.add(p);
                                  _changed();
                                } catch (e) {
                                  if (mounted) {
                                    setState(
                                      () => _error =
                                          'Audio indisponible : vous pouvez continuer avec une preuve assistée.',
                                    );
                                  }
                                }
                              },
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Écouter'),
                      ),
                      ExpansionTile(
                        title: const Text(
                          'Voir la transcription · écoute assistée',
                        ),
                        onExpansionChanged: (open) {
                          if (open) {
                            setState(() => _assisted = true);
                            _changed();
                          }
                        },
                        children: [Text(placementPassages[p].text)],
                      ),
                    ],
                    for (var q = 0; q < 2; q++) ...[
                      Text(placementPassages[p].questions[q].prompt),
                      RadioGroup<int>(
                        groupValue: _answers[p * 2 + q],
                        onChanged: (v) {
                          if (!_busy && !_voiceBusy) {
                            setState(() => _answers[p * 2 + q] = v);
                            _changed();
                          }
                        },
                        child: Column(
                          children: [
                            for (
                              var o = 0;
                              o <
                                  placementPassages[p]
                                      .questions[q]
                                      .options
                                      .length;
                              o++
                            )
                              RadioListTile<int>(
                                value: o,
                                enabled: !_busy && !_voiceBusy,
                                title: Text(
                                  placementPassages[p].questions[q].options[o],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  FilledButton(
                    key: const Key('placement-submit'),
                    onPressed: _busy || _voiceBusy ? null : () => _submit(),
                    child: Text(
                      _busy ? 'Analyse…' : 'Obtenir une recommandation IA',
                    ),
                  ),
                  TextButton(
                    onPressed: _busy || _voiceBusy
                        ? null
                        : () => _submit(manual: true),
                    child: const Text(
                      'Choisir mon départ sans IA / terminer plus tard',
                    ),
                  ),
                ] else ...[
                  Text(_result!.reasoning),
                  Text(
                    'Lecture : ${_diagnostic()['readingCorrect']}/4 · écoute : ${_diagnostic()['listeningCorrect']}/4${_assisted ? ' (assistée)' : ''}',
                  ),
                  const Text(
                    'Prononciation et aisance : non évaluées à partir du texte. Le travail déjà enregistré sert à proposer une leçon, sans effacer votre historique.',
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _track,
                    items: [
                      for (final t in courseTracks)
                        DropdownMenuItem(value: t.id, child: Text(t.label)),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _track = v;
                          _lesson = courseTracks
                              .firstWhere((t) => t.id == v)
                              .lessons
                              .first
                              .id;
                        });
                      }
                    },
                  ),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_track),
                    initialValue: _lesson,
                    isExpanded: true,
                    items: [
                      for (final l
                          in courseTracks
                              .firstWhere((t) => t.id == _track)
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
                      if (v != null) setState(() => _lesson = v);
                    },
                  ),
                  FilledButton(
                    key: const Key('placement-continue'),
                    onPressed: _busy ? null : _confirm,
                    child: const Text('Confirmer mon départ'),
                  ),
                ],
              ],
            ),
    ),
  );
}
