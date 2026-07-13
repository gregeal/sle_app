import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import 'oral_session_screen.dart';
import 'realtime_interview_screen.dart';

const coachAccent = Color(0xffa93b44);
const officialOralAssessmentUrl =
    'https://www.canada.ca/fr/commission-fonction-publique/services/'
    'evaluation-langue-seconde/gestionnaires/evaluation-linguistique-oral-sle.html';

/// OLA-style interview: 1 warm-up (A), then 2 B and 2 C questions.
Future<List<OralQuestion>> pickInterviewQuestions(AppDatabase db) async {
  final questions = <OralQuestion>[];
  for (final entry in const [('A', 1), ('B', 2), ('C', 2)]) {
    final pool = await db.oralQuestionsByTier(entry.$1)
      ..shuffle();
    questions.addAll(pool.take(entry.$2));
  }
  return questions;
}

class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  /// Daily-question tier follows the 26-week arc: concrete first, then
  /// narration, then opinion/hypothesis territory.
  static String tierForWeek(int weekNumber) =>
      weekNumber <= 6 ? 'A' : (weekNumber <= 16 ? 'B' : 'C');

  Future<List<OralQuestion>> _pickDaily(
    AppDatabase db,
    int weekNumber,
    DateTime day,
  ) async {
    final tier = tierForWeek(weekNumber);
    final pool = await db.oralQuestionsByTier(tier);
    if (pool.isEmpty) return const [];
    // Deterministic per day so re-opening shows the same question.
    final dayIndex = calendarDayDifference(DateTime(2026), day);
    return [pool[dayIndex % pool.length]];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWeek = ref.watch(activeWeekProvider);
    final db = ref.watch(appDatabaseProvider);
    final day = ref.watch(studyDayProvider);

    return SafeArea(
      child: activeWeek.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (week) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Text(
              'Coach oral',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Simulation de l\'évaluation de langue orale (ELO) · '
              'reconnaissance vocale sur l\'appareil.',
            ),
            const SizedBox(height: 16),
            _CoachCard(
              icon: Icons.graphic_eq,
              title: 'Entrevue Realtime',
              subtitle: 'Voix-à-voix · relances adaptatives · paliers A → C',
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RealtimeInterviewScreen(),
                  ),
                );
              },
            ),
            _CoachCard(
              icon: Icons.mic_none,
              title: 'Question du jour',
              subtitle:
                  'Palier ${tierForWeek(week.number)} · une question, '
                  'rétroaction immédiate',
              onTap: () async {
                final questions = await _pickDaily(db, week.number, day);
                if (!context.mounted || questions.isEmpty) return;
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        OralSessionScreen(mode: 'daily', questions: questions),
                  ),
                );
              },
            ),
            _CoachCard(
              icon: Icons.record_voice_over_outlined,
              title: 'Entrevue guidée',
              subtitle:
                  'STT/TTS sur l’appareil · 5 questions · rapport selon les '
                  '5 dimensions alignées sur les critères CFP',
              onTap: () async {
                final questions = await pickInterviewQuestions(db);
                if (!context.mounted || questions.isEmpty) return;
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OralSessionScreen(
                      mode: 'interview',
                      questions: questions,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vos réponses sont transcrites par votre appareil, puis '
                      'évaluées par votre fournisseur IA selon cinq dimensions '
                      'pédagogiques alignées sur les critères publiés. Les '
                      'estimations sont non officielles; la prononciation '
                      'n’est qu’approximée à partir de la transcription.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'La vraie évaluation CFP dure actuellement de 20 à 40 '
                      'minutes. Cette app sert uniquement à vous préparer : '
                      'les outils d’IA sont interdits pendant le test officiel.',
                      style: TextStyle(fontSize: 13),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _openOfficialCriteria(context),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Voir les critères officiels CFP'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openOfficialCriteria(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(officialOralAssessmentUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir la page de la CFP.')),
      );
    }
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      contentPadding: const EdgeInsets.all(18),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: coachAccent.withValues(alpha: 0.12),
        child: Icon(icon, color: coachAccent),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
