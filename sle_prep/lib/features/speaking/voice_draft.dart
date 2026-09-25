import 'dart:async';
import 'package:flutter/material.dart';
import '../word_help/app_text_selection.dart';
import '../word_help/word_help_guard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/speech/speech_services.dart';
import '../../domain/speech/openai_speech_service.dart';
import '../../data/db/daos.dart';
import '../../providers.dart';

/// Learner-controlled continuous dictation, with an editable transcription.
class VoiceDraft extends ConsumerStatefulWidget {
  const VoiceDraft({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onBusy,
    this.enabled = true,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onBusy;
  final bool enabled;
  @override
  ConsumerState<VoiceDraft> createState() => VoiceDraftState();
}

class VoiceDraftState extends ConsumerState<VoiceDraft>
    with WidgetsBindingObserver {
  late SpeechService _speech;
  late final TtsService _tts;
  bool _listening = false, _starting = false, _background = false;
  int _epoch = 0;
  String? _error;
  bool _cloud = false;
  bool _choiceMade = false;
  int _choiceRevision = 0;
  VoidCallback _releaseWordHelp = () {};
  @override
  void initState() {
    super.initState();
    _releaseWordHelp = ref
        .read(wordHelpGuardProvider)
        .register(() => _starting || _listening);
    _speech = ref.read(speechServiceProvider);
    _tts = ref.read(ttsServiceProvider);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadChoice());
  }

  Future<void> _loadChoice() async {
    try {
      final value = await ref
          .read(appDatabaseProvider)
          .getSetting('speakingDictationEngine');
      if (!mounted ||
          _choiceMade ||
          _starting ||
          _listening ||
          value != 'openai') {
        return;
      }
      setState(() {
        _cloud = true;
        _speech = ref.read(cloudSpeechFactoryProvider)();
      });
    } catch (_) {
      /* Keep device dictation when settings are unavailable. */
    }
  }

  Future<void> _choose(bool? cloud) async {
    if (cloud == null || cloud == _cloud || _starting || _listening) return;
    _choiceMade = true;
    if (cloud) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Activer la dictée OpenAI ?'),
          content: const Text(
            'Quand vous activez le microphone, votre audio est envoyé en continu à OpenAI '
            'pour afficher la transcription. Internet et un accès API payant sont nécessaires '
            '(pas votre abonnement ChatGPT). Aucun fichier audio n’est enregistré par l’app. '
            'Les corrections attendent toujours votre envoi. Évitez les informations confidentielles.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Activer'),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted || _background) {
        if (mounted) setState(() => _choiceRevision++);
        return;
      }
    }
    if (!mounted || _starting || _listening) return;
    if (_speech case final OpenAiSpeechService service) await service.cancel();
    if (!mounted) return;
    setState(() {
      _cloud = cloud;
      _error = null;
      _speech = cloud
          ? ref.read(cloudSpeechFactoryProvider)()
          : ref.read(speechServiceProvider);
    });
    try {
      await ref
          .read(appDatabaseProvider)
          .setSetting('speakingDictationEngine', cloud ? 'openai' : 'device');
    } catch (_) {
      /* Choice works for this editor even if persistence fails. */
    }
  }

  void _notify() => widget.onBusy(_starting || _listening);
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _background =
        state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
    if (_background) {
      unawaited(stop());
      unawaited(_tts.stop().catchError((Object _) {}));
    }
  }

  Future<void> stop() async {
    if (_starting && !_listening) {
      ++_epoch;
      if (_speech case final OpenAiSpeechService service) {
        await service.cancel();
      }
      return;
    }
    if (!_listening) return;
    setState(() => _starting = true);
    _notify();
    try {
      await _speech.stop();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is DictationException
              ? error.message
              : 'La dictée n’a pas pu être finalisée. Vérifiez le texte conservé.',
        );
      }
    }
    ++_epoch;
    if (mounted) {
      setState(() {
        _listening = false;
        _starting = false;
      });
      _notify();
    }
  }

  Future<void> _start() async {
    if (_starting || _listening || !widget.enabled || _background) return;
    final epoch = ++_epoch;
    setState(() {
      _starting = true;
      _error = null;
    });
    _notify();
    try {
      await _tts.stop().catchError((Object _) {});
      final ready = await _speech.initialize();
      if (!mounted || epoch != _epoch || _background) return;
      if (!ready) throw StateError('Speech unavailable');
      final prefix = widget.controller.text.trim();
      setState(() => _listening = true);
      await _speech.listen(
        onResult: (text) {
          if (!mounted || epoch != _epoch) return;
          final full = [
            if (prefix.isNotEmpty) prefix,
            if (text.trim().isNotEmpty) text.trim(),
          ].join(' ');
          final bounded = full.length > 20000 ? full.substring(0, 20000) : full;
          widget.controller.value = TextEditingValue(
            text: bounded,
            selection: TextSelection.collapsed(offset: bounded.length),
          );
          widget.onChanged(bounded);
          if (full.length > 20000) {
            setState(
              () => _error =
                  'Limite du brouillon atteinte. Copiez le texte et poursuivez dans un autre tour.',
            );
            unawaited(stop());
          }
        },
        onDone: () {
          if (!mounted || epoch != _epoch) return;
          setState(() {
            _listening = false;
            _error =
                (_speech is OpenAiSpeechService
                    ? (_speech as OpenAiSpeechService).lastError
                    : null) ??
                'Dictée interrompue. Vous pouvez continuer ou modifier votre réponse.';
          });
          _notify();
        },
      );
      if (!mounted || epoch != _epoch || _background) await _speech.stop();
    } catch (error) {
      await _speech.stop().catchError((Object _) {});
      if (mounted) {
        setState(() {
          _listening = false;
          _error = error is DictationException
              ? error.message
              : 'Microphone indisponible. Vérifiez les permissions ou écrivez votre réponse.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _starting = false);
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _releaseWordHelp();
    ++_epoch;
    WidgetsBinding.instance.removeObserver(this);
    final speech = _speech;
    unawaited(
      (speech is OpenAiSpeechService ? speech.cancel() : speech.stop())
          .catchError((Object _) {}),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DropdownButtonFormField<bool>(
        key: ValueKey('dictation-engine-$_cloud-$_choiceRevision'),
        initialValue: _cloud,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Transcription vocale'),
        items: const [
          DropdownMenuItem(value: false, child: Text('Dictée de l’appareil')),
          DropdownMenuItem(
            value: true,
            child: Text('OpenAI en direct · recommandé'),
          ),
        ],
        onChanged: !widget.enabled || _starting || _listening ? null : _choose,
      ),
      if (_cloud)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Audio → OpenAI dès l’activation du micro · API payante. '
            'Le texte provisoire peut évoluer; attendez la finalisation après l’arrêt. '
            '10 minutes maximum par prise, puis vous pouvez continuer.',
          ),
        ),
      const SizedBox(height: 12),
      TextField(
        contextMenuBuilder: learningTextContextMenu,
        controller: widget.controller,
        minLines: 3,
        maxLines: 8,
        maxLength: 20000,
        readOnly: !widget.enabled || _listening || _starting,
        decoration: const InputDecoration(
          labelText: 'Ma réponse / transcription',
          border: OutlineInputBorder(),
          helperText:
              'Vérifiez la transcription avant l’envoi. 6 000 caractères par tour IA.',
        ),
        onChanged: widget.onChanged,
      ),
      Wrap(
        spacing: 8,
        children: [
          OutlinedButton.icon(
            key: const Key('partner-mic'),
            onPressed: _starting || !widget.enabled
                ? null
                : (_listening ? stop : _start),
            icon: Icon(_listening ? Icons.stop : Icons.mic),
            label: Text(
              _starting
                  ? 'Patientez…'
                  : _listening
                  ? 'Arrêter la dictée'
                  : 'Parler / continuer',
            ),
          ),
          if (_listening)
            Chip(
              label: Text(
                _starting
                    ? 'Connexion / finalisation…'
                    : 'Micro actif · les pauses ne soumettent pas',
              ),
            ),
        ],
      ),
      if (_error != null)
        Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
    ],
  );
}
