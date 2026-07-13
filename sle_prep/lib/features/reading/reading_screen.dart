import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import '../../domain/llm/llm_client.dart';
import '../../domain/llm/reading_generator.dart';
import '../../providers.dart';

String kindLabel(String kind) => switch (kind) {
  'note_service' => 'Note de service',
  'courriel' => 'Courriel',
  'politique' => 'Politique',
  'article' => 'Article',
  _ => kind,
};

class ReadingListScreen extends ConsumerStatefulWidget {
  const ReadingListScreen({super.key, required this.themeFr});

  final String themeFr;

  @override
  ConsumerState<ReadingListScreen> createState() => _ReadingListScreenState();
}

class _ReadingListScreenState extends ConsumerState<ReadingListScreen> {
  List<ReadingSet>? _sets;
  Object? _error;
  var _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sets = await ref.read(appDatabaseProvider).allReadingSets();
      if (mounted) setState(() => _sets = sets.reversed.toList());
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    try {
      final client = await ref.read(llmClientProvider.future);
      final kind =
          readingKinds[DateTime.now().millisecond % readingKinds.length];
      final title = await generateReadingSet(
        db: ref.read(appDatabaseProvider),
        client: client,
        themeFr: widget.themeFr,
        kind: kind,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nouvelle lecture ajoutée : $title')),
        );
      }
    } on LlmException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Génération impossible : $error')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Génération impossible : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sets = _sets;
    return Scaffold(
      appBar: AppBar(title: const Text('Lecture chronométrée')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGenerating ? null : _generate,
        icon: _isGenerating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome_outlined),
        label: Text(_isGenerating ? 'Génération…' : 'Nouvelle lecture (IA)'),
      ),
      body: SafeArea(
        child: _error != null
            ? Center(child: Text('$_error'))
            : sets == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                children: [
                  const Text(
                    'Textes administratifs de type ELS · questions à '
                    'choix multiple · durée cible : 10 minutes.',
                  ),
                  const SizedBox(height: 12),
                  ...sets.map(
                    (set) => Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        leading: const Icon(Icons.menu_book_outlined, size: 30),
                        title: Text(set.title),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${kindLabel(set.kind)} · '
                            '${set.questionsList.length} questions'
                            '${set.source == 'generated' ? ' · IA' : ''}',
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReadingSessionScreen(readingSet: set),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class ReadingSessionScreen extends ConsumerStatefulWidget {
  const ReadingSessionScreen({super.key, required this.readingSet});

  final ReadingSet readingSet;

  @override
  ConsumerState<ReadingSessionScreen> createState() =>
      _ReadingSessionScreenState();
}

class _ReadingSessionScreenState extends ConsumerState<ReadingSessionScreen> {
  final _stopwatch = Stopwatch()..start();
  Timer? _ticker;
  var _readingPhase = true;
  var _index = 0;
  var _selectedIndex = -1;
  var _correctAnswers = 0;
  var _done = false;
  var _saving = false;

  List<Map<String, dynamic>> get _questions => widget.readingSet.questionsList;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _elapsed {
    final seconds = _stopwatch.elapsed.inSeconds;
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
  }

  void _selectAnswer(Map<String, dynamic> question, int optionIndex) {
    if (_selectedIndex >= 0) return;
    setState(() {
      _selectedIndex = optionIndex;
      if (optionIndex == question['correctIndex']) _correctAnswers++;
    });
  }

  Future<void> _next() async {
    if (_saving) return;
    if (_index + 1 < _questions.length) {
      setState(() {
        _index++;
        _selectedIndex = -1;
      });
      return;
    }

    _stopwatch.stop();
    _ticker?.cancel();
    setState(() => _saving = true);
    try {
      await ref
          .read(appDatabaseProvider)
          .recordReadingAttempt(
            setId: widget.readingSet.id,
            correct: _correctAnswers,
            total: _questions.length,
            seconds: _stopwatch.elapsed.inSeconds,
            at: DateTime.now(),
          );
      if (mounted) setState(() => _done = true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Résultat non enregistré : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(kindLabel(widget.readingSet.kind)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              _elapsed,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: _done
          ? _ReadingSummary(
              correct: _correctAnswers,
              total: _questions.length,
              elapsed: _elapsed,
            )
          : _readingPhase
          ? _buildPassage(context)
          : _buildQuestion(context),
    ),
  );

  Widget _buildPassage(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
    child: Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              Text(
                widget.readingSet.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                widget.readingSet.bodyFr,
                style: const TextStyle(fontSize: 16, height: 1.55),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('start-questions'),
          onPressed: () => setState(() => _readingPhase = false),
          icon: const Icon(Icons.quiz_outlined),
          label: Text('Passer aux questions (${_questions.length})'),
        ),
      ],
    ),
  );

  Widget _buildQuestion(BuildContext context) {
    final question = _questions[_index];
    final answered = _selectedIndex >= 0;
    final correctIndex = question['correctIndex'] as int;
    final isCorrect = _selectedIndex == correctIndex;
    final options = (question['options'] as List).cast<String>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: ListView(
        children: [
          Text(
            'Question ${_index + 1} sur ${_questions.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (_index + 1) / _questions.length),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => setState(() => _readingPhase = true),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Relire le texte'),
          ),
          const SizedBox(height: 8),
          Text(
            question['prompt'] as String,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          ...options.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(16),
                  backgroundColor: !answered
                      ? null
                      : entry.key == correctIndex
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : entry.key == _selectedIndex
                      ? Theme.of(context).colorScheme.errorContainer
                      : null,
                ),
                onPressed: answered
                    ? null
                    : () => _selectAnswer(question, entry.key),
                child: Row(
                  children: [
                    Icon(
                      answered && entry.key == correctIndex
                          ? Icons.check_circle_outline
                          : answered && entry.key == _selectedIndex
                          ? Icons.cancel_outlined
                          : Icons.radio_button_unchecked,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              ),
            ),
          ),
          if (answered) ...[
            Container(
              key: const Key('reading-explanation'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCorrect
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(question['explanationFr'] as String),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('next-reading-question'),
              onPressed: _saving ? null : _next,
              child: Text(
                _saving
                    ? 'Enregistrement…'
                    : _index + 1 == _questions.length
                    ? 'Voir le bilan'
                    : 'Suivant',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadingSummary extends StatelessWidget {
  const _ReadingSummary({
    required this.correct,
    required this.total,
    required this.elapsed,
  });

  final int correct;
  final int total;
  final String elapsed;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Lecture terminée',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('$correct sur $total en $elapsed.', textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text(
            'À l\'ELS, visez environ 80 % en gestion serrée du temps.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
