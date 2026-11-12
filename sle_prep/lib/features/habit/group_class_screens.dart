import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/habit_daos.dart';
import '../../data/db/weekly_daos.dart';
import '../../domain/course/course_catalog.dart';
import '../../providers.dart';
import '../vocab/vocab_review_screen.dart';
import 'activity_tracker.dart';

/// Today's note from the in-person class, or null when nothing was captured.
final todayClassNoteProvider = FutureProvider.autoDispose<GroupClassNote?>(
  (ref) => ref
      .watch(appDatabaseProvider)
      .groupClassNoteFor(ref.watch(studyDayProvider)),
);

/// Ten minutes before the in-person class: reactivate what the last class
/// covered and arrive with one sentence ready to say.
class GroupClassWarmupScreen extends ConsumerStatefulWidget {
  const GroupClassWarmupScreen({super.key});

  @override
  ConsumerState<GroupClassWarmupScreen> createState() => _WarmupState();
}

class _WarmupState extends ConsumerState<GroupClassWarmupScreen>
    with ActivityTracking<GroupClassWarmupScreen> {
  @override
  String get activityKind => 'groupClass';
  @override
  String? get activitySkill => null;

  GroupClassNote? _lastNote;
  List<String> _phrases = const [];
  var _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final db = ref.read(appDatabaseProvider);
    try {
      final notes = await db.recentGroupClassNotes(limit: 1);
      final week = await db.activeStudyWeek();
      var phrases = const <String>[];
      if (week != null) {
        try {
          phrases = findCourseLesson(week.lessonId).phrases;
        } on StateError {
          phrases = const [];
        }
      }
      if (!mounted) return;
      setState(() {
        _lastNote = notes.isEmpty ? null : notes.first;
        _phrases = phrases;
        _ready = true;
      });
    } on Object {
      if (mounted) setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = _lastNote;
    return Scaffold(
      appBar: AppBar(title: const Text('Avant le cours')),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const Text(
                  'Dix minutes pour arriver en classe déjà en français. '
                  'Dites tout à voix haute : c’est la bouche qu’on échauffe.',
                ),
                const SizedBox(height: 20),
                Text('1 · AU DERNIER COURS', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                if (note == null)
                  const Text(
                    'Aucune note pour l’instant. Après le cours d’aujourd’hui, '
                    'notez ce que vous en retenez : elle apparaîtra ici.',
                  )
                else ...[
                  Text(note.covered),
                  if (note.corrections.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Corrections reçues',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(note.corrections),
                    const SizedBox(height: 4),
                    Text(
                      'Redites chaque phrase corrigée deux fois.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
                if (_phrases.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    '2 · À DIRE À VOIX HAUTE',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  for (final phrase in _phrases.take(6))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $phrase'),
                    ),
                ],
                const SizedBox(height: 20),
                Text(
                  '3 · MA PREMIÈRE PHRASE',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Préparez une phrase que vous direz en premier pendant le '
                  'cours, avant que quelqu’un d’autre ne parle. Répétez-la '
                  'trois fois maintenant.',
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VocabReviewScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.style_outlined),
                  label: const Text('Réviser quelques cartes'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Je suis prêt'),
                ),
              ],
            ),
    );
  }
}

/// Five minutes after the class: keep what was covered and the corrections
/// received, so the next practice can reuse them.
class GroupClassCaptureScreen extends ConsumerStatefulWidget {
  const GroupClassCaptureScreen({super.key});

  @override
  ConsumerState<GroupClassCaptureScreen> createState() => _CaptureState();
}

class _CaptureState extends ConsumerState<GroupClassCaptureScreen>
    with ActivityTracking<GroupClassCaptureScreen> {
  @override
  String get activityKind => 'groupClass';
  @override
  String? get activitySkill => null;

  final _covered = TextEditingController();
  final _corrections = TextEditingController();
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final note = await ref
          .read(appDatabaseProvider)
          .groupClassNoteFor(ref.read(studyDayProvider));
      if (!mounted || note == null) return;
      _covered.text = note.covered;
      _corrections.text = note.corrections;
    } on Object {
      return;
    }
  }

  @override
  void dispose() {
    _covered.dispose();
    _corrections.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(appDatabaseProvider)
          .saveGroupClassNote(
            day: ref.read(studyDayProvider),
            covered: _covered.text,
            corrections: _corrections.text,
            at: DateTime.now(),
          );
      ref.invalidate(todayClassNoteProvider);
      if (mounted) Navigator.pop(context, true);
    } on ArgumentError catch (error) {
      if (mounted) setState(() => _error = '${error.message}');
    } on Object {
      if (mounted) {
        setState(() => _error = 'Enregistrement impossible. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Après le cours')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const Text(
          'Cinq minutes pendant que c’est frais. Quelques mots suffisent; '
          'vous les retrouverez avant le prochain cours.',
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('class-note-covered'),
          controller: _covered,
          minLines: 3,
          maxLines: 8,
          maxLength: 2000,
          decoration: const InputDecoration(
            labelText: 'Ce qu’on a vu aujourd’hui',
            hintText: 'Le thème, une règle, des mots nouveaux…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('class-note-corrections'),
          controller: _corrections,
          minLines: 3,
          maxLines: 8,
          maxLength: 2000,
          decoration: const InputDecoration(
            labelText: 'Les corrections qu’on m’a faites · facultatif',
            hintText: 'Ce que j’ai dit → ce qu’il fallait dire',
            border: OutlineInputBorder(),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('class-note-save'),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Enregistrement…' : 'Enregistrer ma note'),
        ),
      ],
    ),
  );
}
