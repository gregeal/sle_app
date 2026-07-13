import 'package:flutter/material.dart';

/// Placeholder for the P2 oral coach (simulated OLA interview + daily
/// question). Keeps the design's four-tab navigation in place now so the
/// habit of reaching for it is already formed when the feature lands.
class CoachScreen extends StatelessWidget {
  const CoachScreen({super.key});

  static const _accent = Color(0xffa93b44);

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text('Coach oral', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        const Text('Simulation de l’évaluation de langue orale (ELO).'),
        const SizedBox(height: 16),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic_none, color: _accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'À venir — phase 2',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cette section accueillera la question orale du jour '
                  '(rétroaction instantanée) et l’entrevue ELO simulée '
                  'complète, avec une rétroaction selon les cinq critères '
                  'officiels : aisance, compréhension, vocabulaire, grammaire '
                  'et prononciation.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'En attendant, pratiquez l’oral avec le bloc « Production '
                  'libre » de votre séance quotidienne.',
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
