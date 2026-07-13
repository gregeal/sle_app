import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import '../../domain/mock/mock_scoring.dart';
import '../../providers.dart';
import '../coach/coach_screen.dart';
import '../coach/oral_session_screen.dart';
import '../drills/drill_screen.dart';
import '../reading/reading_screen.dart';

String skillLabel(String skill) => switch (skill) {
  'reading' => 'Compréhension de l\'écrit',
  'writing' => 'Expression écrite',
  'oral' => 'Expression orale',
  _ => skill,
};

/// Monthly formative checkpoint hub. These deliberately short practice flows
/// are not full-length or psychometrically equivalent to official SLE tests.
class MockExamScreen extends ConsumerStatefulWidget {
  const MockExamScreen({super.key});

  @override
  ConsumerState<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends ConsumerState<MockExamScreen> {
  Map<String, MockResult>? _latest;
  Object? _loadError;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final latest = await ref.read(appDatabaseProvider).latestMockPerSkill();
      if (mounted) {
        setState(() {
          _latest = latest;
          _loadError = null;
        });
      }
    } on Object catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  Future<void> _runFlow(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de lancer ce volet : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _report(String skill, int score, int total) async {
    final level = levelForFraction(total == 0 ? 0 : score / total);
    await ref
        .read(appDatabaseProvider)
        .recordMockResult(
          skill: skill,
          score: score,
          total: total,
          levelEstimate: level,
          at: DateTime.now(),
        );
    await _load();
    ref.invalidate(progressSnapshotProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${skillLabel(skill)} : $score/$total → niveau estimé $level '
            '(non officiel).',
          ),
        ),
      );
    }
  }

  Future<void> _runReading() async {
    final db = ref.read(appDatabaseProvider);
    final sets = await db.allReadingSets();
    if (sets.isEmpty || !mounted) return;
    final set = sets[Random().nextInt(sets.length)];
    final before = await db.readingHistory();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReadingSessionScreen(readingSet: set)),
    );

    final after = await db.readingHistory();
    if (after.length > before.length) {
      final attempt = after.first;
      await _report('reading', attempt.correct, attempt.total);
    }
  }

  Future<void> _runWriting() async {
    final db = ref.read(appDatabaseProvider);
    final weeks = await db.allCurriculumWeeks();
    final topics = weeks
        .expand((week) => week.grammarTopicsList)
        .toSet()
        .toList(growable: false);
    final start = DateTime.now();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DrillScreen(
          topics: topics,
          title: 'Examen blanc — expression écrite',
        ),
      ),
    );

    final stats = await db.drillStatsSince(start);
    if (stats.total > 0) {
      await _report('writing', stats.correct, stats.total);
    }
  }

  Future<void> _runOral() async {
    final db = ref.read(appDatabaseProvider);
    final questions = await pickInterviewQuestions(db);
    if (questions.isEmpty || !mounted) return;
    final before = await db.oralHistory();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            OralSessionScreen(mode: 'interview', questions: questions),
      ),
    );

    final after = await db.oralHistory();
    if (after.length > before.length) {
      final feedback = after.first.feedback;
      // The oral report already carries a validated level estimate. Never
      // invent a default if local data is corrupt or from an incompatible build.
      final level = oralLevelFromFeedback(feedback);
      if (level == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Le rapport oral enregistré est invalide.'),
            ),
          );
        }
        return;
      }
      await ref
          .read(appDatabaseProvider)
          .recordMockResult(
            skill: 'oral',
            score: 0,
            total: 0,
            levelEstimate: level,
            at: DateTime.now(),
          );
      await _load();
      ref.invalidate(progressSnapshotProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = _latest;
    return Scaffold(
      appBar: AppBar(title: const Text('Examen blanc')),
      body: SafeArea(
        child: latest == null && _loadError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Impossible de charger les points de contrôle.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _busy ? null : _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              )
            : latest == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  const Text(
                    'Point de contrôle mensuel formatif : ces trois volets '
                    'raccourcis ne reproduisent pas la durée ni la validité '
                    'd’un test officiel. Les niveaux sont des repères non '
                    'officiels fondés sur des seuils approximatifs.',
                  ),
                  const SizedBox(height: 14),
                  if (_busy) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                  ],
                  _MockCard(
                    icon: Icons.menu_book_outlined,
                    skill: 'reading',
                    subtitle: 'Échantillon court · un texte chronométré · QCM',
                    latest: latest['reading'],
                    onTap: _busy ? null : () => _runFlow(_runReading),
                  ),
                  _MockCard(
                    icon: Icons.edit_note_outlined,
                    skill: 'writing',
                    subtitle: 'Échantillon court · 10 questions de grammaire',
                    latest: latest['writing'],
                    onTap: _busy ? null : () => _runFlow(_runWriting),
                  ),
                  _MockCard(
                    icon: Icons.mic_none,
                    skill: 'oral',
                    subtitle: 'Entrevue guidée courte · 5 questions',
                    latest: latest['oral'],
                    onTap: _busy ? null : () => _runFlow(_runOral),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MockCard extends StatelessWidget {
  const _MockCard({
    required this.icon,
    required this.skill,
    required this.subtitle,
    required this.latest,
    required this.onTap,
  });

  final IconData icon;
  final String skill;
  final String subtitle;
  final MockResult? latest;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      contentPadding: const EdgeInsets.all(18),
      leading: Icon(icon, size: 32),
      title: Text(
        skillLabel(skill),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle),
      ),
      trailing: latest == null
          ? const Icon(Icons.chevron_right)
          : CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                latest!.levelEstimate,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
      onTap: onTap,
    ),
  );
}
