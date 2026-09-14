import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/database.dart';
import '../../data/db/daos.dart';
import '../../data/db/speaking_daos.dart';
import '../../providers.dart';
import 'speaking_session_screen.dart';
import 'speaking_mistakes_screen.dart';

const speakingTopics = <String, String>{
  'Mon travail':
      'Présentez votre rôle et une difficulté récente au travail. Expliquez comment vous l’avez abordée.',
  'Défendre une opinion':
      'Votre équipe hésite entre télétravail et présence au bureau. Quelle approche recommandez-vous, et pourquoi ?',
  'Gérer un désaccord':
      'Un collègue n’est pas d’accord avec votre recommandation. Comment ouvririez-vous la discussion ?',
  'Nuancer une décision':
      'Un projet doit aller plus vite, mais la qualité pourrait en souffrir. Quel compromis proposeriez-vous ?',
  'Raconter et expliquer':
      'Racontez un changement auquel vous avez dû vous adapter. Qu’avez-vous appris de cette expérience ?',
  'Imaginer les conséquences':
      'Si votre équipe disposait de deux fois plus de temps, que changeriez-vous et quelles en seraient les conséquences ?',
};

class SpeakingHomeScreen extends ConsumerStatefulWidget {
  const SpeakingHomeScreen({super.key});
  @override
  ConsumerState<SpeakingHomeScreen> createState() => _SpeakingHomeState();
}

class _SpeakingHomeState extends ConsumerState<SpeakingHomeScreen> {
  late Future<List<SpeakingSession>> _sessions;
  String _topic = speakingTopics.keys.first;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _sessions = ref.read(appDatabaseProvider).recentSpeakingSessions();
  }

  Future<void> _open(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SpeakingSessionScreen(sessionId: id)),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _new({bool repair = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final focus = await db.speakingMistakeLibrary(
        dueBy: DateTime.now(),
        limit: 3,
      );
      final first = focus.firstOrNull;
      final prompt = repair && first != null
          ? 'Reprenons une expression de votre carnet : « ${first.original} ». Comment la reformuleriez-vous ? Expliquez votre choix.'
          : speakingTopics[_topic]!;
      final id = await db.createSpeakingSession(
        topic: repair ? 'Réparation ciblée' : _topic,
        prompt: prompt,
        now: DateTime.now(),
        repairMode: repair,
        focusMistakeId: repair ? first?.id : null,
      );
      if (mounted) await _open(id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d’ouvrir la conversation. Réessayez.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importCoachAnswer() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final attempts = await db.oralHistory();
      final answers = <({String question, String answer})>[];
      for (final attempt in attempts.take(20)) {
        try {
          for (final pair in attempt.exchangesList) {
            final question = pair['question'];
            final answer = pair['answer'];
            if (question is String &&
                answer is String &&
                question.isNotEmpty &&
                answer.trim().isNotEmpty &&
                question.length <= 1200 &&
                answer.length <= 20000) {
              answers.add((question: question, answer: answer));
            }
          }
        } catch (_) {
          /* Skip an incompatible historical transcript. */
        }
        if (answers.length >= 30) break;
      }
      if (!mounted) return;
      if (answers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aucune réponse enregistrée compatible. Essayez une conversation avec le partenaire.',
            ),
          ),
        );
        return;
      }
      final selected = await showDialog<int>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Reprendre une réponse du Coach'),
          children: [
            for (final (index, item) in answers.take(30).indexed)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, index),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.answer,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
      if (selected == null || !mounted) return;
      final item = answers[selected];
      final id = await db.transaction(() async {
        final id = await db.createSpeakingSession(
          topic: 'Reprise d’une réponse du Coach',
          prompt: item.question,
          now: DateTime.now(),
          repairMode: true,
        );
        await db.saveSpeakingDraft(
          id,
          item.answer,
          DateTime.now(),
          expectedTurnCount: 0,
        );
        return id;
      });
      if (mounted) await _open(id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Import impossible. Votre réponse originale reste dans l’historique du Coach.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mon partenaire de français')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Parler · réparer · réutiliser',
          style: TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 8),
        const Text(
          'Prenez le temps de finir votre pensée, arrêtez la dictée, vérifiez le texte puis envoyez-la. Le partenaire répond à voix haute et propose jusqu’à trois corrections. Les silences n’envoient rien.',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _topic,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Situation professionnelle',
          ),
          items: speakingTopics.keys
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: _busy ? null : (value) => setState(() => _topic = value!),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _busy ? null : _importCoachAnswer,
          icon: const Icon(Icons.history),
          label: const Text('Reprendre une réponse du Coach'),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _new,
          icon: const Icon(Icons.record_voice_over),
          label: const Text('Nouvelle conversation'),
        ),
        OutlinedButton(
          onPressed: _busy ? null : () => _new(repair: true),
          child: const Text('Réparer mes erreurs avec le partenaire'),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.psychology_outlined),
            title: const Text('Mon carnet d’erreurs orales'),
            subtitle: const Text(
              'Rappel actif en solo · répétition espacée · suggestions à vérifier',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SpeakingMistakesScreen()),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Reprendre une conversation',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        FutureBuilder<List<SpeakingSession>>(
          future: _sessions,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return TextButton(
                onPressed: () => setState(_reload),
                child: const Text('Réessayer le chargement'),
              );
            }
            if (!snapshot.hasData) return const LinearProgressIndicator();
            if (snapshot.data!.isEmpty) {
              return const Text('Votre première conversation apparaîtra ici.');
            }
            return Column(
              children: snapshot.data!
                  .map(
                    (s) => ListTile(
                      title: Text(s.topic),
                      subtitle: Text(
                        '${s.finished ? 'Terminée · consulter' : 'À poursuivre'} · ${s.updatedAt.toLocal().day}/${s.updatedAt.toLocal().month}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _busy ? null : () => _open(s.id),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Les corrections sont des suggestions IA fondées sur la transcription, pas des mesures de prononciation ni un niveau ÉLS. Vérifiez-les et écartez les erreurs de dictée. Les sessions restent sur cet appareil/navigateur. Les réponses soumises et un contexte limité vont au fournisseur IA pour le feedback. Si vous activez la dictée OpenAI, l’audio est aussi envoyé à OpenAI pendant la capture. Coût selon votre fournisseur.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}
