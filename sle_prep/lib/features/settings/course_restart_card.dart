import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/session/restart_course.dart';
import '../../providers.dart';

class CourseRestartCard extends ConsumerStatefulWidget {
  const CourseRestartCard({super.key});
  @override
  ConsumerState<CourseRestartCard> createState() => _CourseRestartState();
}

class _CourseRestartState extends ConsumerState<CourseRestartCard> {
  bool _busy = false;
  Future<void> _restart() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repartir à la semaine 1 ?'),
        content: const SingleChildScrollView(
          child: Text(
            'Le programme de 26 semaines repart aujourd’hui. Le travail déjà terminé aujourd’hui, vos cartes et leur progression, vos résultats, vos rétroactions et vos paramètres IA sont conservés. Les blocs non terminés d’aujourd’hui seront remplacés. Ce changement concerne uniquement cet appareil ou navigateur.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Recommencer'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || _busy) return;
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _busy = true);
    try {
      ref.invalidate(studyDayProvider);
      // Recover any older frozen session before retaining completed blocks.
      await ref.read(todayPlanProvider.future);
      if (!mounted) return;
      await restartCourse(
        ref.read(appDatabaseProvider),
        ref.read(studyDayProvider),
      );
      // A successful write must refresh the shared plan even if this settings
      // card was removed while the database transaction was finishing.
      container.invalidate(activeWeekProvider);
      container.invalidate(todayPlanProvider);
      container.invalidate(todaySessionLogProvider);
      container.invalidate(progressSnapshotProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Programme redémarré : semaine 1. Votre historique est conservé.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Redémarrage impossible. Aucun historique effacé. Réessayez.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mon programme', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Repartir de la semaine 1 sans effacer vos acquis ni vos rétroactions.',
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('restart-course'),
            onPressed: _busy ? null : _restart,
            icon: const Icon(Icons.restart_alt),
            label: Text(_busy ? 'Redémarrage…' : 'Recommencer à la semaine 1'),
          ),
        ],
      ),
    ),
  );
}
