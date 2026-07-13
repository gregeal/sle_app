import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../domain/llm/oral_coach.dart';
import '../../providers.dart';
import 'coach_screen.dart';

enum _Stage { answering, reviewing, assessing, report }

class OralSessionScreen extends ConsumerStatefulWidget {
  const OralSessionScreen({
    super.key,
    required this.mode,
    required this.questions,
  });

  /// 'daily' or 'interview'.
  final String mode;
  final List<OralQuestion> questions;

  @override
  ConsumerState<OralSessionScreen> createState() => _OralSessionScreenState();
}

class _OralSessionScreenState extends ConsumerState<OralSessionScreen> {
  final _exchanges = <Map<String, dynamic>>[];
  var _index = 0;
  var _stage = _Stage.answering;
  var _transcript = '';
  var _isListening = false;
  var _speechUnavailable = false;
  OralFeedback? _feedback;
  Object? _assessError;

  OralQuestion get _question => widget.questions[_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakQuestion());
  }

  @override
  void dispose() {
    ref.read(ttsServiceProvider).stop();
    ref.read(speechServiceProvider).stop();
    super.dispose();
  }

  Future<void> _speakQuestion() async {
    await ref.read(ttsServiceProvider).speak(_question.questionFr);
  }

  Future<void> _toggleListening() async {
    final speech = ref.read(speechServiceProvider);
    if (_isListening) {
      await speech.stop();
      setState(() {
        _isListening = false;
        if (_transcript.trim().isNotEmpty) _stage = _Stage.reviewing;
      });
      return;
    }

    await ref.read(ttsServiceProvider).stop();
    final ready = await speech.initialize();
    if (!ready) {
      setState(() => _speechUnavailable = true);
      return;
    }
    setState(() {
      _isListening = true;
      _transcript = '';
    });
    await speech.listen(
      onResult: (transcript) {
        if (mounted) setState(() => _transcript = transcript);
      },
      onDone: () {
        if (mounted && _isListening) {
          setState(() {
            _isListening = false;
            if (_transcript.trim().isNotEmpty) _stage = _Stage.reviewing;
          });
        }
      },
    );
  }

  Future<void> _acceptAnswer() async {
    _exchanges.add({
      'question': _question.questionFr,
      'answer': _transcript.trim(),
    });

    if (_index + 1 < widget.questions.length) {
      setState(() {
        _index++;
        _transcript = '';
        _stage = _Stage.answering;
      });
      await _speakQuestion();
      return;
    }

    setState(() => _stage = _Stage.assessing);
    try {
      final client = await ref.read(llmClientProvider.future);
      final feedback = await requestOralFeedback(
        db: ref.read(appDatabaseProvider),
        client: client,
        mode: widget.mode,
        exchanges: _exchanges,
      );
      if (mounted) {
        setState(() {
          _feedback = feedback;
          _stage = _Stage.report;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _assessError = error;
          _stage = _Stage.report;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.mode == 'daily'
              ? 'Question du jour'
              : 'Entrevue simulée'),
        ),
        body: SafeArea(
          child: switch (_stage) {
            _Stage.answering || _Stage.reviewing => _buildQuestion(context),
            _Stage.assessing => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('L\'évaluatrice analyse vos réponses…'),
                  ],
                ),
              ),
            _Stage.report => _feedback != null
                ? OralReportView(
                    feedback: _feedback!,
                    exchanges: _exchanges,
                  )
                : _AssessError(
                    error: _assessError,
                    onRetry: () {
                      setState(() => _stage = _Stage.assessing);
                      // Re-run assessment with the exchanges already captured.
                      _exchanges.removeRange(0, 0);
                      _retryAssessment();
                    },
                  ),
          },
        ),
      );

  Future<void> _retryAssessment() async {
    try {
      final client = await ref.read(llmClientProvider.future);
      final feedback = await requestOralFeedback(
        db: ref.read(appDatabaseProvider),
        client: client,
        mode: widget.mode,
        exchanges: _exchanges,
      );
      if (mounted) {
        setState(() {
          _feedback = feedback;
          _assessError = null;
          _stage = _Stage.report;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _assessError = error;
          _stage = _Stage.report;
        });
      }
    }
  }

  Widget _buildQuestion(BuildContext context) {
    final reviewing = _stage == _Stage.reviewing;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          Row(
            children: [
              Chip(label: Text('Question ${_index + 1} / '
                  '${widget.questions.length}')),
              const SizedBox(width: 8),
              Chip(
                label: Text('Palier ${_question.tier}'),
                backgroundColor: _question.tier == 'C'
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _question.questionFr,
                    style: const TextStyle(fontSize: 17, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _isListening ? null : _speakQuestion,
                    icon: const Icon(Icons.replay, size: 18),
                    label: const Text('Réécouter la question'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_speechUnavailable)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'La reconnaissance vocale n\'est pas disponible. '
                          'Vérifiez la permission du microphone dans les '
                          'paramètres Android.',
                        ),
                      ),
                    )
                  else if (_transcript.isEmpty && !_isListening)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Répondez à voix haute, comme à l\'entrevue : '
                        'structurez votre réponse et visez 45 à 90 secondes.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isListening
                                  ? 'Transcription en direct…'
                                  : 'Votre réponse (transcrite)',
                              style:
                                  Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(_transcript.isEmpty ? '…' : _transcript),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (reviewing) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _transcript = '';
                      _stage = _Stage.answering;
                    }),
                    icon: const Icon(Icons.replay),
                    label: const Text('Reprendre'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _acceptAnswer,
                    icon: const Icon(Icons.check),
                    label: Text(
                      _index + 1 < widget.questions.length
                          ? 'Question suivante'
                          : 'Terminer',
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Center(
              child: GestureDetector(
                onTap: _toggleListening,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? coachAccent
                        : Theme.of(context).colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening
                                ? coachAccent
                                : Theme.of(context).colorScheme.primary)
                            .withValues(alpha: 0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          if (!reviewing)
            Text(
              _isListening
                  ? 'Touchez pour terminer votre réponse'
                  : 'Touchez pour répondre',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class OralReportView extends StatelessWidget {
  const OralReportView({
    super.key,
    required this.feedback,
    required this.exchanges,
  });

  final OralFeedback feedback;
  final List<Map<String, dynamic>> exchanges;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Card(
          color: colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    feedback.levelEstimate,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Niveau estimé : ${feedback.levelEstimate}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${feedback.summary} Estimation non officielle, '
                        'calibrée sur les critères publiés de la CFP.',
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LES 5 CRITÈRES DE L\'ELO',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 14),
                ...olaCriteria.map((name) {
                  final criterion = feedback.criterion(name)!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(criterionLabel(name)),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: LinearProgressIndicator(
                                  value: levelProgress(criterion.level),
                                  minHeight: 10,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 34,
                              child: Text(
                                criterion.level,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        if (criterion.comment.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              criterion.comment,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        if (feedback.tips.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PISTES CONCRÈTES',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  ...feedback.tips.asMap().entries.map(
                        (entry) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 13,
                            child: Text('${entry.key + 1}',
                                style: const TextStyle(fontSize: 13)),
                          ),
                          title: Text(entry.value),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        ExpansionTile(
          title: const Text('Revoir la transcription'),
          children: exchanges
              .map(
                (exchange) => ListTile(
                  title: Text(
                    exchange['question'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(exchange['answer'] as String),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _AssessError extends StatelessWidget {
  const _AssessError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              const Text('Impossible d\'obtenir la rétroaction.'),
              const SizedBox(height: 8),
              Text('$error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
}
