import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

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
              'Les estimations de niveau seront ajoutées après les examens blancs.',
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
                  icon: Icons.style_outlined,
                  value: '${snapshot.studiedCards}',
                  label: 'cartes étudiées',
                ),
                const SizedBox(width: 10),
                _MetricCard(
                  icon: Icons.schedule_outlined,
                  value: '${snapshot.dueCards}',
                  label: 'cartes dues',
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
