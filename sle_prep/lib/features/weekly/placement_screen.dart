import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/speech/speech_services.dart';
import '../../domain/weekly/placement.dart';
import '../../providers.dart';

/// The one-time placement class: a short spoken sample and a short written
/// one decide which track the weekly programme starts from. The reasoning is
/// shown and stored, so the choice is never a black box.
class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({super.key});

  @override
  ConsumerState<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends ConsumerState<PlacementScreen> {
  final _written = TextEditingController();
  var _transcript = '';
  var _listening = false;
  late final SpeechService _speech;
  var _working = false;
  Object? _error;
  PlacementResult? _result;

  static const _question =
      'Parlez environ une minute : décrivez votre travail, une tâche '
      'récente et ce qui a été difficile.';

  @override
  void initState() {
    super.initState();
    _speech = ref.read(speechServiceProvider);
  }

  @override
  void dispose() {
    unawaited(_speech.stop().catchError((Object _) {}));
    _written.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    final speech = _speech;
    if (_listening) {
      await speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    if (!await speech.initialize()) {
      if (mounted) {
        setState(
          () => _error = 'Microphone indisponible. Vérifiez la permission.',
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _listening = true;
      _error = null;
    });
    await speech.listen(
      onResult: (value) {
        if (mounted) setState(() => _transcript = value);
      },
      onDone: () {
        if (mounted) setState(() => _listening = false);
      },
    );
  }

  Future<void> _submit() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await _speech.stop();
      final client = await ref.read(llmClientProvider.future);
      final result = await requestPlacement(
        db: ref.read(appDatabaseProvider),
        client: client,
        spokenTranscript: _transcript,
        writtenText: _written.text,
      );
      ref.invalidate(placementProvider);
      if (mounted) {
        setState(() {
          _result = result;
          _listening = false;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Classe de placement')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            if (result != null) ..._resultView(result) else ..._formView(),
          ],
        ),
      ),
    );
  }

  List<Widget> _formView() => [
    const Text(
      'Deux courts échantillons suffisent. Votre enseignante choisit ensuite '
      'le parcours de départ et explique pourquoi. L’estimation est non '
      'officielle.',
    ),
    const SizedBox(height: 16),
    Text('À l’oral', style: Theme.of(context).textTheme.titleMedium),
    const Text(_question),
    const SizedBox(height: 8),
    FilledButton.icon(
      key: const Key('placement-mic'),
      onPressed: _working ? null : _toggleListening,
      icon: Icon(_listening ? Icons.stop : Icons.mic),
      label: Text(_listening ? 'Arrêter' : 'Parler'),
    ),
    const SizedBox(height: 8),
    Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          _transcript.isEmpty
              ? 'Votre transcription apparaîtra ici.'
              : _transcript,
        ),
      ),
    ),
    const SizedBox(height: 20),
    Text('À l’écrit', style: Theme.of(context).textTheme.titleMedium),
    const Text(
      'Écrivez 3 à 5 phrases : annoncez une rencontre à votre équipe.',
    ),
    const SizedBox(height: 8),
    TextField(
      key: const Key('placement-written'),
      controller: _written,
      enabled: !_working,
      minLines: 4,
      maxLines: 8,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: 16),
    if (_error != null)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          '$_error',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    FilledButton.icon(
      key: const Key('placement-submit'),
      onPressed: _working || _transcript.trim().length < 40 ? null : _submit,
      icon: _working
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.school_outlined),
      label: Text(_working ? 'Analyse…' : 'Obtenir mon parcours'),
    ),
    const SizedBox(height: 8),
    const Text(
      'Le bouton s’active après environ deux phrases à l’oral.',
      style: TextStyle(fontSize: 12.5),
    ),
  ];

  List<Widget> _resultView(PlacementResult result) => [
    Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.trackId == 'a-to-b-v1'
                  ? 'Parcours A → B'
                  : 'Parcours B → C',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text('Niveau de travail observé : ${result.levelEstimate} '
                '(estimation non officielle)'),
            const SizedBox(height: 10),
            Text(result.reasoning),
          ],
        ),
      ),
    ),
    const SizedBox(height: 16),
    Text('Vos forces', style: Theme.of(context).textTheme.titleMedium),
    for (final strength in result.strengths) Text('• $strength'),
    const SizedBox(height: 12),
    Text('Priorités', style: Theme.of(context).textTheme.titleMedium),
    for (final priority in result.priorities) Text('• $priority'),
    const SizedBox(height: 20),
    FilledButton(
      key: const Key('placement-continue'),
      onPressed: () => Navigator.of(context).pop(result),
      child: const Text('Commencer la semaine 1'),
    ),
  ];
}
