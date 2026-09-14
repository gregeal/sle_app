import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/database.dart';
import '../../data/db/speaking_daos.dart';
import '../../domain/speech/speech_services.dart';
import '../../domain/srs/sm2.dart';
import '../../providers.dart';
import 'speaking_session_screen.dart';
import 'voice_draft.dart';

class SpeakingMistakesScreen extends ConsumerStatefulWidget {
  const SpeakingMistakesScreen({super.key});
  @override
  ConsumerState<SpeakingMistakesScreen> createState() => _MistakesState();
}

class _MistakesState extends ConsumerState<SpeakingMistakesScreen> {
  late Future<List<SpeakingMistake>> _cards;
  bool _dueOnly = true, _busy = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _cards = ref
        .read(appDatabaseProvider)
        .speakingMistakeLibrary(dueBy: _dueOnly ? DateTime.now() : null);
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(_reload);
  }

  Future<void> _repair(SpeakingMistake card) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final id = await ref
          .read(appDatabaseProvider)
          .createSpeakingSession(
            topic: 'Réparation · ${card.category}',
            prompt:
                'Reprenons votre expression : « ${card.original} ». Reformulez-la, puis expliquez votre choix.',
            now: DateTime.now(),
            repairMode: true,
            focusMistakeId: card.id,
          );
      if (mounted) await _open(SpeakingSessionScreen(sessionId: id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de démarrer la réparation. Réessayez.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _dismiss(SpeakingMistake card) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Écarter cette suggestion ?'),
        content: const Text(
          'Utilisez ceci pour une erreur de transcription ou une correction inexacte. Elle ne reviendra plus dans la file de révision. Les échanges originaux restent conservés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Écarter'),
          ),
        ],
      ),
    );
    if (!mounted || yes != true) return;
    try {
      await ref.read(appDatabaseProvider).dismissSpeakingMistake(card.id);
      if (mounted) setState(_reload);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modification non enregistrée. Réessayez.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mes erreurs orales')),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Ces suggestions viennent de vos propres réponses. Vérifiez qu’elles correspondent bien à ce que vous avez dit. Une bonne répétition ne garantit pas encore un usage spontané.',
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('À revoir maintenant'),
              selected: _dueOnly,
              onSelected: (value) => setState(() {
                _dueOnly = value;
                _reload();
              }),
            ),
            FilledButton.icon(
              onPressed: _busy ? null : () => _open(const SpeakingSoloScreen()),
              icon: const Icon(Icons.school),
              label: const Text('Pratiquer en solo'),
            ),
          ],
        ),
        Expanded(
          child: FutureBuilder<List<SpeakingMistake>>(
            future: _cards,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: TextButton(
                    onPressed: () => setState(_reload),
                    child: const Text('Réessayer'),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    _dueOnly
                        ? 'Aucune erreur due. Désactivez le filtre pour revoir le carnet.'
                        : 'Vos prochaines suggestions apparaîtront ici.',
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final card = snapshot.data![index];
                  final due = card.dueAt.toLocal();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '« ${card.original} » → ${card.corrected}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(card.explanation),
                          Text('Transfert : ${card.exercise}'),
                          Text(
                            '${card.occurrences} occurrence(s) · ${card.repetitions} rappel(s) réussi(s) · retour ${due.day}/${due.month} à ${due.hour.toString().padLeft(2, '0')}:${due.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: _busy ? null : () => _repair(card),
                                child: const Text('Revoir avec le partenaire'),
                              ),
                              TextButton(
                                onPressed: _busy ? null : () => _dismiss(card),
                                child: const Text('Erreur de dictée / écarter'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

class SpeakingSoloScreen extends ConsumerStatefulWidget {
  const SpeakingSoloScreen({super.key});
  @override
  ConsumerState<SpeakingSoloScreen> createState() => _SoloState();
}

class _SoloState extends ConsumerState<SpeakingSoloScreen>
    with WidgetsBindingObserver {
  late Future<List<SpeakingMistake>> _cards;
  late final TtsService _tts;
  final _answer = TextEditingController();
  bool _revealed = false, _voiceBusy = false, _saving = false;
  int _index = 0;
  String? _error;
  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsServiceProvider);
    _cards = ref
        .read(appDatabaseProvider)
        .speakingMistakeLibrary(dueBy: DateTime.now(), limit: 20);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(_tts.stop().catchError((Object _) {}));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_tts.stop().catchError((Object _) {}));
    _answer.dispose();
    super.dispose();
  }

  Future<void> _grade(SpeakingMistake card, ReviewGrade grade) async {
    if (_saving || _voiceBusy || !_revealed) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(appDatabaseProvider)
          .gradeSpeakingMistake(card: card, grade: grade, now: DateTime.now());
      await _tts.stop().catchError((Object _) {});
      if (mounted) {
        setState(() {
          _index++;
          _revealed = false;
          _answer.clear();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Révision non enregistrée ou carte modifiée ailleurs. Revenez au carnet puis réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Rappel actif · mes erreurs')),
    body: FutureBuilder<List<SpeakingMistake>>(
      future: _cards,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(() {
                _cards = ref
                    .read(appDatabaseProvider)
                    .speakingMistakeLibrary(dueBy: DateTime.now(), limit: 20);
              }),
              child: const Text('Réessayer'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_index >= snapshot.data!.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Révision terminée ou aucune carte due. Les cartes « À reprendre » reviennent dans 10 minutes; les autres selon votre rappel. Revenez régulièrement pour les réutiliser dans une conversation.',
              ),
            ),
          );
        }
        final card = snapshot.data![_index];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Carte ${_index + 1}/${snapshot.data!.length} · sans appel IA',
            ),
            const SizedBox(height: 12),
            const Text(
              'Corrigez cette expression de mémoire, à voix haute. Essayez avant de révéler.',
            ),
            Text(
              '« ${card.original} »',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            VoiceDraft(
              key: ValueKey(card.id),
              controller: _answer,
              enabled: !_saving,
              onChanged: (_) {},
              onBusy: (value) {
                if (mounted) setState(() => _voiceBusy = value);
              },
            ),
            if (!_revealed)
              FilledButton(
                onPressed: _voiceBusy
                    ? null
                    : () => setState(() => _revealed = true),
                child: const Text('Révéler après mon essai'),
              ),
            if (_revealed) ...[
              Text(
                card.corrected,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(card.explanation),
              const SizedBox(height: 10),
              Text('Maintenant, dites une NOUVELLE phrase : ${card.exercise}'),
              TextButton.icon(
                onPressed: _voiceBusy
                    ? null
                    : () async {
                        try {
                          await _tts.speak(card.corrected);
                        } catch (_) {
                          if (mounted) {
                            setState(() => _error = 'Voix indisponible.');
                          }
                        }
                      },
                icon: const Icon(Icons.volume_up),
                label: const Text('Écouter le modèle'),
              ),
              const Text(
                'Auto-évaluation : jugez votre rappel avant de lire, puis votre nouvelle phrase. Aucune note automatique de prononciation.',
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final entry in const [
                    (ReviewGrade.again, 'À reprendre'),
                    (ReviewGrade.hard, 'Difficile'),
                    (ReviewGrade.good, 'Bien'),
                    (ReviewGrade.easy, 'Facile'),
                  ])
                    OutlinedButton(
                      onPressed: _saving || _voiceBusy
                          ? null
                          : () => _grade(card, entry.$1),
                      child: Text(entry.$2),
                    ),
                ],
              ),
            ],
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        );
      },
    ),
  );
}
