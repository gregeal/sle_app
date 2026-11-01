import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/database.dart';
import '../../data/db/weekly_daos.dart';
import '../../domain/weekly/weekly_report.dart';
import '../../domain/weekly/weekly_service.dart';
import '../../providers.dart';

class WeeklyReportScreen extends ConsumerStatefulWidget {
  const WeeklyReportScreen({super.key, required this.week});
  final StudyWeek week;
  @override
  ConsumerState<WeeklyReportScreen> createState() => _ReportState();
}

class _ReportState extends ConsumerState<WeeklyReportScreen> {
  WeeklyFeedbackJob? _job;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final j = await ref
          .read(appDatabaseProvider)
          .ensureWeeklyFeedback(widget.week.id);
      if (mounted) setState(() => _job = j);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _generate() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(appDatabaseProvider)
          .generateWeeklyFeedback(
            widget.week.id,
            await ref.read(llmClientProvider.future),
          );
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    WeeklyReport? report;
    String? parsingError;
    try {
      if (_job?.reportJson != null) {
        report = WeeklyReport.parse(_job!.reportJson!);
      }
    } catch (_) {
      parsingError =
          'Le bilan est illisible. Vos activités restent conservées.';
    }
    final snapshot = _job == null
        ? null
        : jsonDecode(_job!.snapshotJson) as Map<String, dynamic>;
    final assignments = snapshot == null
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(snapshot['assignments']);
    final evidence = snapshot == null
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(snapshot['evidence']);
    return Scaffold(
      appBar: AppBar(title: Text('Bilan · semaine ${widget.week.weekNumber}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Bilan pédagogique non officiel. Les durées prévues, les activités créditées et le temps observé sont distincts. Une preuve autonome ou assistée ne suffit pas à certifier un niveau.',
          ),
          for (final skill in [
            'speaking',
            'listening',
            'reading',
            'writing',
            'vocabulary',
            'teaching',
          ]) ...[
            ListTile(
              title: Text(weeklySkillLabel(skill)),
              subtitle: Text(
                '${assignments.where((a) => a['skill'] == skill).fold<int>(0, (n, a) => n + a['minutes'] as int)} min prévues · ${assignments.where((a) => a['skill'] == skill && a['completed'] == true && a['verified'] == true).fold<int>(0, (n, a) => n + a['minutes'] as int)} min créditées',
              ),
              trailing: Text(
                '${evidence.where((e) => e['skill'] == skill).fold<int>(0, (n, e) => n + ((e['observedSeconds'] as int?) ?? 0)) ~/ 60} min observées',
              ),
            ),
          ],
          if (report != null) ...[
            for (final entry in report.skills.entries)
              ListTile(
                title: Text(
                  '${weeklySkillLabel(entry.key)} · ${entry.value['level'] ?? 'non évalué'}',
                ),
                subtitle: Text(
                  '${entry.value['observation']}\nConfiance : ${entry.value['confidence']}',
                ),
              ),
            const Text('Points d’appui'),
            for (final s in report.strengths) Text('• $s'),
            const Text('Priorités'),
            for (final p in report.priorities) Text('• $p'),
          ],
          if (_error != null || parsingError != null)
            Text(_error ?? parsingError!),
          if (report == null)
            FilledButton(
              onPressed: _busy ? null : _generate,
              child: Text(
                _busy
                    ? 'Préparation…'
                    : 'Demander / réessayer le bilan IA · frais possibles',
              ),
            ),
          if (_job?.status == 'pending')
            TextButton(
              onPressed: () async {
                final accepted = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Récupérer une demande interrompue ?'),
                    content: const Text(
                      'Faites ceci seulement si aucune autre fenêtre ne prépare ce bilan. Une nouvelle demande peut entraîner des frais.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Annuler'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Récupérer'),
                      ),
                    ],
                  ),
                );
                if (accepted == true) {
                  await ref
                      .read(appDatabaseProvider)
                      .recoverWeeklyFeedback(widget.week.id);
                  await _load();
                }
              },
              child: const Text('Demande interrompue ?'),
            ),
        ],
      ),
    );
  }
}
