import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/llm/llm_client.dart';
import '../../domain/llm/writing_coach.dart';
import '../../providers.dart';

class WritingScreen extends ConsumerStatefulWidget {
  const WritingScreen({super.key, required this.themeFr});

  final String themeFr;

  @override
  ConsumerState<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends ConsumerState<WritingScreen> {
  final _textController = TextEditingController();
  var _variant = 0;
  var _isSubmitting = false;
  WritingFeedback? _feedback;

  String get _prompt => compositionPromptFor(widget.themeFr, _variant);
  int get _wordCount =>
      RegExp(r'\S+').allMatches(_textController.text.trim()).length;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (_wordCount < 80) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Écrivez au moins 80 mots pour obtenir une estimation utile.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final client = await ref.read(llmClientProvider.future);
      final feedback = await requestWritingFeedback(
        db: ref.read(appDatabaseProvider),
        client: client,
        promptFr: _prompt,
        userText: text,
      );
      if (mounted) setState(() => _feedback = feedback);
    } on LlmException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rétroaction impossible : $error')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rétroaction impossible : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Expression écrite')),
    body: SafeArea(
      child: _feedback != null
          ? _FeedbackView(
              feedback: _feedback!,
              onRestart: () => setState(() {
                _feedback = null;
                _textController.clear();
                _variant++;
              }),
            )
          : _buildEditor(context),
    ),
  );

  Widget _buildEditor(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Consigne',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() => _variant++),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Autre consigne'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(_prompt),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _textController,
        enabled: !_isSubmitting,
        minLines: 8,
        maxLines: 16,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Rédigez votre texte ici…',
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 6),
      Text(
        '$_wordCount mot${_wordCount > 1 ? 's' : ''} · cible : 120 à 180',
        textAlign: TextAlign.end,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed: _isSubmitting ? null : _submit,
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.rate_review_outlined),
        label: Text(
          _isSubmitting ? 'Analyse en cours…' : 'Obtenir la rétroaction',
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Votre texte est envoyé à votre fournisseur IA configuré. '
        'L\'estimation de niveau est non officielle.',
        style: TextStyle(fontSize: 12.5),
      ),
    ],
  );
}

class _FeedbackView extends StatelessWidget {
  const _FeedbackView({required this.feedback, required this.onRestart});

  final WritingFeedback feedback;
  final VoidCallback onRestart;

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
                  radius: 26,
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    feedback.levelEstimate,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Niveau estimé — non officiel, calibré sur les repères '
                    'publiés de l\'ELS.',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (feedback.errors.isNotEmpty) ...[
          Text('Corrections', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...feedback.errors.map(
            (error) => Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: error.extrait,
                            style: TextStyle(
                              color: colorScheme.error,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const TextSpan(text: '  →  '),
                          TextSpan(
                            text: error.correction,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(error.explication),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text('Texte corrigé', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              feedback.correctedText,
              style: const TextStyle(height: 1.5),
            ),
          ),
        ),
        if (feedback.tips.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Pistes concrètes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...feedback.tips.asMap().entries.map(
            (entry) => ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 13,
                child: Text(
                  '${entry.key + 1}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              title: Text(entry.value),
            ),
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onRestart,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Nouvelle rédaction'),
        ),
      ],
    );
  }
}
