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

/// Monthly checkpoint hub: runs each skill through its existing practice
/// flow, then scores the outcome against approximate SLE cut lines.
class MockExamScreen extends ConsumerStatefulWidget {
  const MockExamScreen({super.key});

  @override
  ConsumerState<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends ConsumerState<MockExamScreen> {
  Map<String, MockResult>? _latest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final latest = await ref.read(appDatabaseProvider).latestMockPerSkill();
    if (mounted) setState(() => _latest = latest);
  }

  Future<void> _report(String skill, int score, int total) async {
    final level = levelForFraction(total == 0 ? 0 : score / total);
    await ref.read(appDatabaseProvider).recordMockResult(
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
      // The oral report already carries a level estimate; reuse it.
      final match = RegExp('"levelEstimate"\\s*:\\s*"([^"]+)"')
          .firstMatch(feedback);
      final level = match?.group(1) ?? 'B';
      await ref.read(appDatabaseProvider).recordMockResult(
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
        child: latest == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  const Text(
                    'Point de contrôle mensuel : passez les trois volets en '
                    'conditions d\'examen. Les niveaux sont des estimations '
                    'non officielles fondées sur des seuils approximatifs.',
                  ),
                  const SizedBox(height: 14),
                  _MockCard(
                    icon: Icons.menu_book_outlined,
                    skill: 'reading',
                    subtitle: 'Un texte chronométré · QCM',
                    latest: latest['reading'],
                    onTap: _runReading,
                  ),
                  _MockCard(
                    icon: Icons.edit_note_outlined,
                    skill: 'writing',
                    subtitle: '10 questions · tous les thèmes vus',
                    latest: latest['writing'],
                    onTap: _runWriting,
                  ),
                  _MockCard(
                    icon: Icons.mic_none,
                    skill: 'oral',
                    subtitle: 'Entrevue simulée complète · 5 questions',
                    latest: latest['oral'],
                    onTap: _runOral,
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
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.all(18),
          leading: Icon(icon, size: 32),
          title: Text(skillLabel(skill),
              style: Theme.of(context).textTheme.titleLarge),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle),
          ),
          trailing: latest == null
              ? const Icon(Icons.chevron_right)
              : CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    latest!.levelEstimate,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
          onTap: onTap,
        ),
      );
}
