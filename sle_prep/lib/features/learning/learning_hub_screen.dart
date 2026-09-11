import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import '../../data/db/learning_daos.dart';
import '../../domain/learning/listening_lessons.dart';
import '../../domain/llm/oral_coach.dart';
import '../../domain/llm/writing_coach.dart';
import '../../domain/speech/speech_services.dart';
import '../../providers.dart';
import '../coach/oral_session_screen.dart';
import '../drills/drill_screen.dart';
import '../reading/reading_screen.dart';
import '../vocab/vocab_review_screen.dart';
import '../writing/writing_screen.dart';

class LearningHubScreen extends ConsumerStatefulWidget {
  const LearningHubScreen({super.key});
  @override
  ConsumerState<LearningHubScreen> createState() => _LearningHubState();
}

class _LearningHubState extends ConsumerState<LearningHubScreen> {
  late Future<List<DrillItem>> _mistakes;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _mistakes = ref.read(appDatabaseProvider).unresolvedDrillMistakes();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    setState(_refresh);
    ref.invalidate(dueCardsProvider);
    ref.invalidate(progressSnapshotProvider);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mon espace d’apprentissage')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Apprendre · reprendre · retenir',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Un parcours court : révisez vos cartes dues, reprenez vos erreurs, '
          'puis écoutez un message et reformulez-le à voix haute.',
        ),
        const SizedBox(height: 16),
        _HubTile(
          Icons.style,
          'Réviser mes cartes dues',
          'Vocabulaire du programme et du carnet personnel',
          () => _open(const VocabReviewScreen()),
        ),
        _HubTile(
          Icons.book_outlined,
          'Mon carnet de vocabulaire',
          'Rechercher, écouter et ajouter mes expressions',
          () => _open(const VocabularyNotebookScreen()),
        ),
        FutureBuilder<List<DrillItem>>(
          future: _mistakes,
          builder: (context, snapshot) => _HubTile(
            Icons.auto_fix_high,
            'Reprendre mes erreurs',
            snapshot.hasError
                ? 'Chargement impossible · touchez pour réessayer'
                : !snapshot.hasData
                ? 'Recherche des exercices à reprendre…'
                : snapshot.data!.isEmpty
                ? 'Aucune erreur de grammaire en attente'
                : '${snapshot.data!.length}${snapshot.data!.length == 50 ? '+' : ''} exercices à reprendre · séries de 10',
            () {
              if (snapshot.hasError) {
                setState(_refresh);
                return;
              }
              _open(
                const DrillScreen(
                  topics: [],
                  mistakesOnly: true,
                  title: 'Mes erreurs à reprendre',
                ),
              );
            },
          ),
        ),
        _HubTile(
          Icons.headphones,
          'Atelier d’écoute',
          '4 messages professionnels B/C · questions et transcription',
          () => _open(const ListeningLibraryScreen()),
        ),
        _HubTile(
          Icons.history,
          'Mes rétroactions',
          'Retrouver mes textes, entretiens et conseils sans nouvel appel IA',
          () => _open(const FeedbackHistoryScreen()),
        ),
        const SizedBox(height: 16),
        const Text(
          'Données conservées sur cet appareil ou dans ce navigateur. '
          'Pas encore de synchronisation Android/web. Les évaluations restent non officielles.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}

class _HubTile extends StatelessWidget {
  const _HubTile(this.icon, this.title, this.subtitle, this.onTap);
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class VocabularyNotebookScreen extends ConsumerStatefulWidget {
  const VocabularyNotebookScreen({super.key});
  @override
  ConsumerState<VocabularyNotebookScreen> createState() => _NotebookState();
}

class _NotebookState extends ConsumerState<VocabularyNotebookScreen>
    with WidgetsBindingObserver {
  late Future<List<VocabCard>> _cards;
  late final TtsService _tts;
  String _query = '';
  bool _personalOnly = false;
  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsServiceProvider);
    _cards = ref.read(appDatabaseProvider).vocabularyLibrary();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_tts.stop().catchError((Object _) {}));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(_tts.stop().catchError((Object _) {}));
    }
  }

  Future<void> _say(VocabCard card) async {
    try {
      await _tts.speak(card.exampleFr.isEmpty ? card.back : card.exampleFr);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voix française indisponible sur cet appareil.'),
          ),
        );
      }
    }
  }

  Future<void> _add([VocabCard? card]) async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => _WordDialog(card: card),
    );
    if (!mounted || added != true) return;
    _refreshCards();
  }

  void _refreshCards() {
    setState(() {
      _cards = ref.read(appDatabaseProvider).vocabularyLibrary();
    });
    ref.invalidate(dueCardsProvider);
    ref.invalidate(todayPlanProvider);
    ref.invalidate(progressSnapshotProvider);
  }

  Future<void> _delete(VocabCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette expression ?'),
        content: Text(
          '« ${card.back} » et son historique de révision seront supprimés du carnet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      await ref.read(appDatabaseProvider).deletePersonalWord(card.id);
      if (mounted) _refreshCards();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suppression impossible. Réessayez.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mon carnet de vocabulaire')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _add(),
      icon: const Icon(Icons.add),
      label: const Text('Ajouter une expression'),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Rechercher en français ou en anglais',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
        ),
        FilterChip(
          label: const Text('Mes expressions uniquement'),
          selected: _personalOnly,
          onSelected: (value) => setState(() => _personalOnly = value),
        ),
        Expanded(
          child: FutureBuilder<List<VocabCard>>(
            future: _cards,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: TextButton(
                    onPressed: _refreshCards,
                    child: const Text('Réessayer'),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final cards = snapshot.data!
                  .where(
                    (card) =>
                        (!_personalOnly ||
                            card.domain == personalVocabDomain) &&
                        '${card.front} ${card.back} ${card.exampleFr}'
                            .toLowerCase()
                            .contains(_query),
                  )
                  .toList();
              if (cards.isEmpty) {
                return const Center(
                  child: Text('Aucune expression trouvée. Ajoutez la vôtre.'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return Card(
                    child: ListTile(
                      title: Text(card.back),
                      subtitle: Text(
                        '${card.front}\n${card.exampleFr}'
                        '${card.domain == personalVocabDomain ? '\nCarnet personnel · révision espacée' : ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Écouter l’exemple',
                            icon: const Icon(Icons.volume_up),
                            onPressed: () => _say(card),
                          ),
                          if (card.domain == personalVocabDomain)
                            PopupMenuButton<String>(
                              tooltip: 'Modifier ou supprimer',
                              onSelected: (action) =>
                                  action == 'edit' ? _add(card) : _delete(card),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Modifier'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Supprimer'),
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

class _WordDialog extends ConsumerStatefulWidget {
  const _WordDialog({this.card});
  final VocabCard? card;
  @override
  ConsumerState<_WordDialog> createState() => _WordDialogState();
}

class _WordDialogState extends ConsumerState<_WordDialog> {
  final _front = TextEditingController();
  final _back = TextEditingController();
  final _example = TextEditingController();
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _front.text = widget.card?.front ?? '';
    _back.text = widget.card?.back ?? '';
    _example.text = widget.card?.exampleFr ?? '';
  }

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    _example.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(appDatabaseProvider)
          .addPersonalWord(
            front: _front.text,
            back: _back.text,
            example: _example.text,
            now: DateTime.now(),
            cardId: widget.card?.id,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is FormatException
              ? error.message
              : 'Enregistrement impossible. Vérifiez les champs et réessayez.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(
        widget.card == null
            ? 'Ajouter une expression'
            : 'Modifier l’expression',
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.card == null ? 'La carte sera due immédiatement.' : 'Votre progression de révision sera conservée.'} N’ajoutez pas de renseignements confidentiels.',
              ),
              TextField(
                controller: _front,
                enabled: !_saving,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Sens / indice (anglais)',
                ),
              ),
              TextField(
                controller: _back,
                enabled: !_saving,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Expression française',
                ),
              ),
              TextField(
                controller: _example,
                enabled: !_saving,
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Exemple en français (facultatif)',
                ),
              ),
              if (_error != null) Text(_error!),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
        ),
      ],
    ),
  );
}

class ListeningLibraryScreen extends ConsumerStatefulWidget {
  const ListeningLibraryScreen({super.key});
  @override
  ConsumerState<ListeningLibraryScreen> createState() =>
      _ListeningLibraryState();
}

class _ListeningLibraryState extends ConsumerState<ListeningLibraryScreen> {
  late Future<List<ListeningAttempt>> _history;
  @override
  void initState() {
    super.initState();
    _history = ref.read(appDatabaseProvider).listeningHistory();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Atelier d’écoute')),
    body: FutureBuilder<List<ListeningAttempt>>(
      future: _history,
      builder: (context, snapshot) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Écoutez sans lire, répondez, puis utilisez la transcription pour '
            'repérer les nuances et reformuler. Voix de synthèse française; aucun appel IA requis. '
            'La voix doit être disponible sur votre appareil ou navigateur.',
          ),
          if (snapshot.hasError)
            const Text(
              'Historique indisponible; les leçons restent accessibles.',
            ),
          ...listeningLessons.map((lesson) {
            final last = snapshot.data
                ?.where((a) => a.lessonId == lesson.id.toString())
                .firstOrNull;
            return _HubTile(
              Icons.headphones,
              lesson.title,
              last == null
                  ? '3 questions · idée principale, détails et nuances'
                  : 'Dernier essai : ${last.correct}/${last.total} · ${last.usedTranscript ? 'avec' : 'sans'} transcription',
              () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReadingSessionScreen(
                      readingSet: lesson,
                      listeningMode: true,
                    ),
                  ),
                );
                if (mounted) {
                  setState(() {
                    _history = ref.read(appDatabaseProvider).listeningHistory();
                  });
                }
              },
            );
          }),
        ],
      ),
    ),
  );
}

class FeedbackHistoryScreen extends ConsumerStatefulWidget {
  const FeedbackHistoryScreen({super.key});
  @override
  ConsumerState<FeedbackHistoryScreen> createState() => _HistoryState();
}

class _HistoryEntry {
  const _HistoryEntry(this.date, this.oral, this.writing);
  final DateTime date;
  final OralAttempt? oral;
  final WritingAttempt? writing;
}

class _HistoryState extends ConsumerState<FeedbackHistoryScreen> {
  late Future<List<_HistoryEntry>> _history;
  @override
  void initState() {
    super.initState();
    _history = _load();
  }

  Future<List<_HistoryEntry>> _load() async {
    final db = ref.read(appDatabaseProvider);
    final oral = await db.oralHistory();
    final writing = await db.writingHistory();
    return [
      for (final item in oral) _HistoryEntry(item.answeredAt, item, null),
      for (final item in writing) _HistoryEntry(item.answeredAt, null, item),
    ]..sort((a, b) => b.date.compareTo(a.date));
  }

  void _open(_HistoryEntry entry) {
    Widget report;
    try {
      if (entry.oral case final oral?) {
        report = OralReportView(
          feedback: parseOralFeedback(oral.feedback),
          exchanges: oral.exchangesList,
        );
      } else {
        final writing = entry.writing!;
        report = WritingFeedbackView(
          feedback: parseWritingFeedback(
            writing.feedback,
            sourceText: writing.userText,
          ),
          onRestart: () => Navigator.of(context).pop(),
          restartLabel: 'Fermer le rapport',
        );
      }
    } catch (_) {
      report = const Center(
        child: Text(
          'Ce rapport utilise un format ancien ou incomplet. '
          'Le texte original reste disponible ci-dessus.',
        ),
      );
    }
    var original = entry.writing == null
        ? entry.oral!.exchanges
        : 'Consigne : ${entry.writing!.promptFr}\n\n${entry.writing!.userText}';
    if (entry.oral != null) {
      try {
        original = entry.oral!.exchangesList
            .map(
              (e) =>
                  'Question : ${e['question'] ?? ''}\nRéponse : ${e['answer'] ?? ''}',
            )
            .join('\n\n');
      } catch (_) {
        // Keep the raw saved text readable if an older transcript is malformed.
      }
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Rétroaction enregistrée')),
          body: Column(
            children: [
              ExpansionTile(
                title: const Text('Revoir ma réponse originale'),
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(original),
                    ),
                  ),
                ],
              ),
              Expanded(child: report),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mes rétroactions')),
    body: FutureBuilder<List<_HistoryEntry>>(
      future: _history,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(() {
                _history = _load();
              }),
              child: const Text('Réessayer'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Vos prochaines rétroactions apparaîtront ici.'),
          );
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final item = snapshot.data![index];
            final date = item.date.toLocal();
            return _HubTile(
              item.oral != null ? Icons.mic : Icons.edit_note,
              item.oral != null
                  ? 'Oral · ${item.oral!.mode}'
                  : 'Expression écrite',
              '${date.day}/${date.month}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:'
              '${date.minute.toString().padLeft(2, '0')} · rapport local',
              () => _open(item),
            );
          },
        );
      },
    ),
  );
}
