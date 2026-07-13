import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/llm/oral_coach.dart' show levelProgress;
import '../../providers.dart';
import '../mocks/mock_exam_screen.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressSnapshotProvider);
    return SafeArea(
      child: progress.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (snapshot) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Text('Progrès', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            const Text(
              'Estimations non officielles, fondées sur vos examens blancs.',
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRAJECTOIRE PAR COMPÉTENCE',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 14),
                    for (final skill in const ['reading', 'writing', 'oral'])
                      _TrajectoryRow(
                        label: skillLabel(skill),
                        level: snapshot.latestMocks[skill]?.levelEstimate,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.all(18),
                leading: const Icon(Icons.flag_outlined, size: 32),
                title: const Text('Examen blanc'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_checkpointLabel(snapshot.nextCheckpoint)),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MockExamScreen()),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _MetricCard(
                  icon: Icons.local_fire_department_outlined,
                  value: '${snapshot.streak}',
                  label: 'jours de série',
                ),
                const SizedBox(width: 10),
                _MetricCard(
                  icon: Icons.schedule_outlined,
                  value: _hoursLabel(snapshot.totalMinutes),
                  label: 'd\'étude au total',
                ),
                const SizedBox(width: 10),
                _MetricCard(
                  icon: Icons.style_outlined,
                  value: '${snapshot.studiedCards}',
                  label: 'cartes étudiées',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Précision par thème',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (snapshot.topicAccuracy.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Faites un exercice de grammaire pour voir vos résultats ici.',
                  ),
                ),
              )
            else
              ...snapshot.topicAccuracy.entries.map(
                (entry) =>
                    _AccuracyRow(topic: entry.key, accuracy: entry.value),
              ),
          ],
        ),
      ),
    );
  }
}

String _hoursLabel(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return remainder == 0 ? '$hours h' : '$hours h $remainder min';
}

String _checkpointLabel(DateTime checkpoint) {
  final today = DateTime.now();
  final days = calendarDayDifference(today, checkpoint);
  final when = days <= 0
      ? 'C\'est aujourd\'hui !'
      : days == 1
      ? 'Demain'
      : 'Dans $days jours';
  return '$when · lecture + écriture + entrevue simulée';
}

class _TrajectoryRow extends StatelessWidget {
  const _TrajectoryRow({required this.label, required this.level});

  final String label;
  final String? level;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        SizedBox(width: 168, child: Text(label)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: level == null ? 0 : levelProgress(level!),
              minHeight: 10,
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            level ?? '—',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}

class _AccuracyRow extends StatelessWidget {
  const _AccuracyRow({required this.topic, required this.accuracy});

  final String topic;
  final double accuracy;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(topic), Text('${(accuracy * 100).round()} %')],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: accuracy),
      ],
    ),
  );
}
