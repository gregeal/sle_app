import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import '../../providers.dart';

class DrillScreen extends ConsumerStatefulWidget {
  const DrillScreen({
    super.key,
    required this.topics,
    this.title = 'Exercice de grammaire',
  });

  final List<String> topics;
  final String title;

  @override
  ConsumerState<DrillScreen> createState() => _DrillScreenState();
}

class _DrillScreenState extends ConsumerState<DrillScreen> {
  List<DrillItem>? _items;
  Object? _error;
  var _index = 0;
  var _selectedIndex = -1;
  var _correctAnswers = 0;
  var _savingAttempt = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final database = ref.read(appDatabaseProvider);
      final allItems = await database.randomDrillItems(widget.topics, 1000);
      final accuracy = await database.topicAccuracy();
      allItems.sort(
        (a, b) =>
            (accuracy[a.topic] ?? 0.5).compareTo(accuracy[b.topic] ?? 0.5),
      );
      if (!mounted) return;
      setState(() => _items = allItems.take(10).toList(growable: false));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  Future<void> _selectAnswer(DrillItem item, int optionIndex) async {
    if (_selectedIndex >= 0 || _savingAttempt) return;

    final wasCorrect = optionIndex == item.correctIndex;
    setState(() {
      _selectedIndex = optionIndex;
      _savingAttempt = true;
      if (wasCorrect) _correctAnswers++;
    });
    try {
      await ref
          .read(appDatabaseProvider)
          .recordAttempt(item.id, wasCorrect: wasCorrect, at: DateTime.now());
    } finally {
      if (mounted) setState(() => _savingAttempt = false);
    }
  }

  void _next() {
    setState(() {
      _index++;
      _selectedIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: _error != null
            ? _LoadError(error: _error!, retry: _loadItems)
            : items == null
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
            ? const _NoDrills()
            : _index >= items.length
            ? _DrillSummary(
                correctAnswers: _correctAnswers,
                total: items.length,
              )
            : _buildQuestion(context, items),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context, List<DrillItem> items) {
    final item = items[_index];
    final answered = _selectedIndex >= 0;
    final isCorrect = _selectedIndex == item.correctIndex;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: ListView(
        children: [
          Text(
            'Question ${_index + 1} sur ${items.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (_index + 1) / items.length),
          const SizedBox(height: 28),
          Text(item.prompt, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          ...item.optionsList.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AnswerOption(
                label: entry.value,
                selected: _selectedIndex == entry.key,
                correct: entry.key == item.correctIndex,
                answered: answered,
                onPressed: _savingAttempt
                    ? null
                    : () => _selectAnswer(item, entry.key),
              ),
            ),
          ),
          if (answered) ...[
            Container(
              key: const Key('drill-explanation'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCorrect
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCorrect ? 'Bonne réponse' : 'À revoir',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(item.explanationFr),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('next-drill-question'),
              onPressed: _savingAttempt ? null : _next,
              child: Text(
                _index + 1 == items.length ? 'Voir le bilan' : 'Suivant',
              ),
            ),
          ] else
            const Text(
              'Choisissez la réponse la plus juste, comme à l’ÉLS.',
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.label,
    required this.selected,
    required this.correct,
    required this.answered,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final bool correct;
  final bool answered;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = !answered
        ? colorScheme.surface
        : correct
        ? colorScheme.secondaryContainer
        : selected
        ? colorScheme.errorContainer
        : colorScheme.surface;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: background,
        padding: const EdgeInsets.all(16),
      ),
      onPressed: answered ? null : onPressed,
      child: Row(
        children: [
          if (answered && correct)
            const Icon(Icons.check_circle_outline)
          else if (answered && selected)
            const Icon(Icons.cancel_outlined)
          else
            const Icon(Icons.radio_button_unchecked),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _DrillSummary extends StatelessWidget {
  const _DrillSummary({required this.correctAnswers, required this.total});

  final int correctAnswers;
  final int total;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Exercice terminé',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '$correctAnswers bonne${correctAnswers > 1 ? 's' : ''} réponse${correctAnswers > 1 ? 's' : ''} sur $total.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _NoDrills extends StatelessWidget {
  const _NoDrills();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        'Aucun exercice n’est encore disponible pour ce thème.',
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.retry});

  final Object error;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          const Text('Impossible de charger les exercices.'),
          const SizedBox(height: 8),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );
}
