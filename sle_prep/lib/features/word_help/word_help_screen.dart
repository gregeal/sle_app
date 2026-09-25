import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/learning_daos.dart';
import '../../domain/llm/word_help.dart';
import '../../domain/llm/llm_client.dart';
import '../../providers.dart';
import 'word_help_guard.dart';

class WordHelpScreen extends ConsumerStatefulWidget {
  const WordHelpScreen({
    super.key,
    required this.selection,
    this.mode = WordHelpMode.translate,
  });
  final String selection;
  final WordHelpMode mode;
  @override
  ConsumerState<WordHelpScreen> createState() => _WordHelpState();
}

class _WordHelpState extends ConsumerState<WordHelpScreen> {
  late final TextEditingController _selection;
  final _question = TextEditingController(), _context = TextEditingController();
  final _meaning = TextEditingController(),
      _french = TextEditingController(),
      _example = TextEditingController();
  late WordHelpMode _mode;
  String _language = 'English';
  bool _busy = false, _saving = false, _saved = false;
  String? _error;
  WordHelpResult? _result;
  VoidCallback _releaseWordHelp = () {};
  @override
  void initState() {
    super.initState();
    _releaseWordHelp = ref
        .read(wordHelpGuardProvider)
        .register(() => _busy || _saving);
    _selection = TextEditingController(text: widget.selection);
    _mode = widget.mode;
  }

  @override
  void dispose() {
    _releaseWordHelp();
    for (final controller in [
      _selection,
      _question,
      _context,
      _meaning,
      _french,
      _example,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || _saving) return;
    if (_selection.text.trim().isEmpty ||
        (_mode == WordHelpMode.question && _question.text.trim().isEmpty)) {
      setState(
        () =>
            _error = 'Ajoutez une sélection et, si nécessaire, votre question.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
      _saved = false;
    });
    try {
      final client = await ref.read(llmClientProvider.future);
      if (!mounted) return;
      final result = await requestWordHelp(
        client: client,
        selection: _selection.text,
        mode: _mode,
        question: _question.text,
        context: _context.text,
        language: _language,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _meaning.text = result.translation;
        _french.text = result.french;
        _example.text = result.example;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is LlmException
              ? error.message
              : 'Aide indisponible. Vérifiez votre connexion et les paramètres IA, puis réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _busy || _saved) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(appDatabaseProvider)
          .addPersonalWord(
            front: _meaning.text,
            back: _french.text,
            example: _example.text,
            now: DateTime.now(),
          );
      if (mounted) {
        ref.invalidate(dueCardsProvider);
        ref.invalidate(remainingDueCardsProvider);
        setState(() => _saved = true);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Carte non enregistrée. Vérifiez le sens et l’expression; réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Comprendre une expression')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Seuls le texte ci-dessous, votre question et le contexte ajouté seront envoyés au fournisseur IA configuré (via le serveur sécurisé sur le web). Aucun envoi à l’ouverture. Des frais API peuvent s’appliquer. Évitez les renseignements confidentiels.',
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('word-selection'),
          controller: _selection,
          readOnly: _busy,
          maxLength: 1000,
          minLines: 1,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Mot ou passage sélectionné',
          ),
        ),
        SegmentedButton<WordHelpMode>(
          segments: const [
            ButtonSegment(
              value: WordHelpMode.translate,
              label: Text('Traduire'),
            ),
            ButtonSegment(
              value: WordHelpMode.question,
              label: Text('Poser une question'),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: _busy
              ? null
              : (modes) => setState(() => _mode = modes.single),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _language,
          decoration: const InputDecoration(
            labelText: 'Langue de traduction / explication',
          ),
          items: const [
            DropdownMenuItem(value: 'English', child: Text('English')),
            DropdownMenuItem(value: 'français', child: Text('Français')),
          ],
          onChanged: _busy
              ? null
              : (value) => setState(() => _language = value ?? 'English'),
        ),
        if (_mode == WordHelpMode.question)
          TextField(
            key: const Key('word-question'),
            controller: _question,
            readOnly: _busy,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Ma question',
              hintText:
                  'Pourquoi utilise-t-on ce temps ? Est-ce naturel au travail ?',
            ),
          ),
        ExpansionTile(
          title: const Text('Ajouter une phrase de contexte (facultatif)'),
          children: [
            TextField(
              controller: _context,
              readOnly: _busy,
              maxLength: 1000,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Contexte que je choisis de partager',
              ),
            ),
          ],
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        FilledButton.icon(
          key: const Key('word-send'),
          onPressed: _busy || _saving ? null : _send,
          icon: const Icon(Icons.send),
          label: Text(_busy ? 'Demande en cours…' : 'Envoyer à mon IA'),
        ),
        if (_busy)
          const Text(
            'Quitter cette page ne garantit pas l’annulation d’une demande déjà envoyée.',
          ),
        if (_result != null) ...[
          const Divider(),
          Text(_result!.answer),
          const Text(
            'Suggestion IA à vérifier, surtout sans contexte. Ce n’est pas une source officielle.',
          ),
          ExpansionTile(
            title: const Text('Garder dans mon vocabulaire à réviser'),
            children: [
              const Text(
                'Vérifiez ou corrigez la carte avant de l’enregistrer. Elle sera disponible dans votre carnet et la révision espacée.',
              ),
              TextField(
                controller: _meaning,
                readOnly: _saving,
                maxLength: 200,
                onChanged: (_) => setState(() => _saved = false),
                decoration: const InputDecoration(
                  labelText: 'Sens / indice en anglais',
                ),
              ),
              TextField(
                controller: _french,
                readOnly: _saving,
                maxLength: 500,
                onChanged: (_) => setState(() => _saved = false),
                decoration: const InputDecoration(
                  labelText: 'Expression française',
                ),
              ),
              TextField(
                controller: _example,
                readOnly: _saving,
                maxLength: 1000,
                maxLines: 3,
                onChanged: (_) => setState(() => _saved = false),
                decoration: const InputDecoration(
                  labelText: 'Exemple français',
                ),
              ),
              FilledButton(
                key: const Key('word-save'),
                onPressed: _saving || _saved ? null : _save,
                child: Text(
                  _saved ? 'Carte enregistrée ✓' : 'Enregistrer cette carte',
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
