import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/daos.dart';
import '../../domain/srs/sm2.dart';
import '../../providers.dart';

class VocabReviewScreen extends ConsumerStatefulWidget {
  const VocabReviewScreen({super.key});

  @override
  ConsumerState<VocabReviewScreen> createState() => _VocabReviewScreenState();
}

class _VocabReviewScreenState extends ConsumerState<VocabReviewScreen> {
  var _cardIndex = 0;
  var _reviewed = 0;
  var _showAnswer = false;
  var _isSaving = false;

  Future<void> _grade(DueCard dueCard, ReviewGrade grade) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    final nextState = applyGrade(
      Sm2State(
        easeFactor: dueCard.state.easeFactor,
        intervalDays: dueCard.state.intervalDays,
        repetitions: dueCard.state.repetitions,
        lapses: dueCard.state.lapses,
      ),
      grade,
    );

    await ref
        .read(appDatabaseProvider)
        .applyReview(
          cardId: dueCard.card.id,
          easeFactor: nextState.easeFactor,
          intervalDays: nextState.intervalDays,
          repetitions: nextState.repetitions,
          lapses: nextState.lapses,
          dueDate: nextDue(DateTime.now(), nextState),
        );

    if (!mounted) return;
    setState(() {
      _cardIndex++;
      _reviewed++;
      _showAnswer = false;
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(dueCardsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Objectif C'), centerTitle: false),
      body: SafeArea(
        child: queue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _QueueError(error: error),
          data: (cards) => _buildReview(context, cards),
        ),
      ),
    );
  }

  Widget _buildReview(BuildContext context, List<DueCard> cards) {
    if (cards.isEmpty || _cardIndex >= cards.length) {
      return _ReviewSummary(reviewed: _reviewed);
    }

    final dueCard = cards[_cardIndex];
    final card = dueCard.card;
    final progress = (_cardIndex + 1) / cards.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Révision de vocabulaire',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '${_cardIndex + 1} sur ${cards.length} cartes à revoir',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress),
          const Spacer(),
          Semantics(
            button: true,
            label: _showAnswer ? 'Masquer la réponse' : 'Afficher la réponse',
            child: InkWell(
              key: const Key('vocab-card'),
              borderRadius: BorderRadius.circular(28),
              onTap: () => setState(() => _showAnswer = !_showAnswer),
              child: Ink(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: _showAnswer
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _showAnswer
                      ? Column(
                          key: const ValueKey('answer'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              card.back,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              card.exampleFr,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Touchez la carte pour revoir l’anglais.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        )
                      : Column(
                          key: const ValueKey('prompt'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              card.front,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Touchez la carte pour afficher la réponse.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const Spacer(),
          if (_showAnswer) ...[
            Text(
              'Comment était votre rappel ?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _GradeButton(
                  label: 'Encore',
                  grade: ReviewGrade.again,
                  onPressed: _isSaving
                      ? null
                      : () => _grade(dueCard, ReviewGrade.again),
                ),
                _GradeButton(
                  label: 'Difficile',
                  grade: ReviewGrade.hard,
                  onPressed: _isSaving
                      ? null
                      : () => _grade(dueCard, ReviewGrade.hard),
                ),
                _GradeButton(
                  label: 'Bien',
                  grade: ReviewGrade.good,
                  onPressed: _isSaving
                      ? null
                      : () => _grade(dueCard, ReviewGrade.good),
                ),
                _GradeButton(
                  label: 'Facile',
                  grade: ReviewGrade.easy,
                  onPressed: _isSaving
                      ? null
                      : () => _grade(dueCard, ReviewGrade.easy),
                ),
              ],
            ),
          ] else
            const Text(
              'Révélez la réponse, puis choisissez une évaluation.',
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.label,
    required this.grade,
    required this.onPressed,
  });

  final String label;
  final ReviewGrade grade;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final button = switch (grade) {
      ReviewGrade.again => OutlinedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
      ReviewGrade.hard => OutlinedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
      ReviewGrade.good => FilledButton.tonal(
        onPressed: onPressed,
        child: Text(label),
      ),
      ReviewGrade.easy => FilledButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    };

    return SizedBox(width: 132, height: 48, child: button);
  }
}

class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({required this.reviewed});

  final int reviewed;

  @override
  Widget build(BuildContext context) {
    final hasReviewed = reviewed > 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasReviewed
                  ? Icons.celebration_outlined
                  : Icons.check_circle_outline,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              hasReviewed ? 'Révision terminée !' : 'Aucune carte à revoir',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasReviewed
                  ? '$reviewed carte${reviewed > 1 ? 's' : ''} révisée${reviewed > 1 ? 's' : ''}. Revenez demain pour la prochaine révision.'
                  : 'Vos cartes dues apparaîtront ici. Revenez demain ou ajoutez du vocabulaire.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueError extends ConsumerWidget {
  const _QueueError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          const Text('Impossible de charger les cartes à revoir.'),
          const SizedBox(height: 8),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => ref.invalidate(dueCardsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );
}
