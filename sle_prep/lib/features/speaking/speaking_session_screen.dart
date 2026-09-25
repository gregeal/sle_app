import 'dart:async';
import '../../data/db/course_daos.dart';
import '../word_help/app_text_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/database.dart';
import '../../data/db/speaking_daos.dart';
import '../../domain/llm/speaking_partner.dart';
import '../../domain/speech/speech_services.dart';
import '../../providers.dart';
import 'voice_draft.dart';
import 'speaking_mistakes_screen.dart';

class SpeakingSessionScreen extends ConsumerStatefulWidget {
  const SpeakingSessionScreen({super.key, required this.sessionId});
  final int sessionId;
  @override
  ConsumerState<SpeakingSessionScreen> createState() => _PartnerSessionState();
}

class _PartnerSessionState extends ConsumerState<SpeakingSessionScreen>
    with WidgetsBindingObserver {
  late final AppDatabase _db;
  late final TtsService _tts;
  final _editor = TextEditingController();
  final _voice = GlobalKey<VoiceDraftState>();
  final _scroll = ScrollController();
  SpeakingSession? _session;
  List<SpeakingTurn> _turns = [];
  PartnerFeedback? _lastFeedback, _pending;
  String? _pendingAnswer, _error;
  bool _busy = false, _voiceBusy = false, _background = false, _leaving = false;
  Timer? _debounce;
  Future<void> _draftWrite = Future.value();
  @override
  void initState() {
    super.initState();
    _db = ref.read(appDatabaseProvider);
    _tts = ref.read(ttsServiceProvider);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  Future<void> _load({bool rethrowErrors = false}) async {
    try {
      final session = await _db.speakingSession(widget.sessionId);
      final turns = await _db.speakingHistory(widget.sessionId);
      PartnerFeedback? last;
      if (turns.isNotEmpty) {
        last = parsePartnerFeedback(turns.last.feedbackJson, turns.last.answer);
      }
      if (!mounted) return;
      setState(() {
        _session = session;
        _turns = turns;
        _lastFeedback = last;
        _editor.text = session.draft;
        _error = null;
      });
    } catch (_) {
      if (rethrowErrors) rethrow;
      if (mounted) {
        setState(() => _error = 'Conversation indisponible. Réessayez.');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _background =
        state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
    if (_background) {
      unawaited(_tts.stop().catchError((Object _) {}));
      unawaited(_flushDraft().catchError((Object _) {}));
    }
  }

  void _changed(String text) {
    if (mounted) setState(() {});
    _debounce?.cancel();
    if (_background) {
      unawaited(_flushDraft().catchError((Object _) {}));
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(
        _flushDraft().catchError((Object _) {
          if (mounted) {
            setState(
              () => _error =
                  'Brouillon non enregistré. Gardez cette page ouverte et réessayez.',
            );
          }
        }),
      );
    });
  }

  Future<void> _flushDraft() {
    _debounce?.cancel();
    if (_session == null || _session!.finished) return _draftWrite;
    final text = _editor.text;
    // Serial writes prevent an older dictation update overwriting newer text.
    final count = _session!.turnCount;
    _draftWrite = _draftWrite
        .catchError((Object _) {})
        .then(
          (_) => _db.saveSpeakingDraft(
            widget.sessionId,
            text,
            DateTime.now(),
            expectedTurnCount: count,
          ),
        );
    return _draftWrite;
  }

  Future<void> _say(String text) async {
    if (_background || _voiceBusy) return;
    try {
      await _tts.speak(text);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Voix indisponible. La réponse du partenaire reste lisible.',
        );
      }
    }
  }

  Future<void> _submit() async {
    final session = _session;
    if (_busy ||
        _voiceBusy ||
        session == null ||
        session.finished ||
        _turns.length >= 30) {
      return;
    }
    final answer = _pendingAnswer ?? _editor.text.trim();
    if (answer.isEmpty || answer.length > speakingAnswerLimit) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_pending == null) await _flushDraft();
      if (!mounted) return;
      if (_pending == null) {
        final focus = await _db.speakingFocus(session, DateTime.now());
        if (!mounted) return;
        final client = await ref.read(llmClientProvider.future);
        _pending = await requestPartnerFeedback(
          client: client,
          answer: answer,
          prompt: session.promptFr,
          topic: session.topic,
          repairMode: session.repairMode,
          foundationCourse: await _db.isFoundationCourseSession(session.id),
          history: _turns.reversed
              .take(6)
              .toList()
              .reversed
              .map(
                (t) => {
                  'prompt': t.promptFr,
                  'answer': t.answer.length > 1500
                      ? t.answer.substring(0, 1500)
                      : t.answer,
                },
              )
              .toList(),
          focus: focus
              .map(
                (m) => {
                  'original': m.original,
                  'corrected': m.corrected,
                  'explanation': m.explanation,
                  'exercise': m.exercise,
                },
              )
              .toList(),
        );
        _pendingAnswer = answer;
      }
      await _db.saveSpeakingTurn(
        sessionId: session.id,
        turnNumber: _turns.length,
        prompt: session.promptFr,
        answer: answer,
        feedback: _pending!,
        now: DateTime.now(),
      );
      final reply = _pending!.reply;
      await _load(rethrowErrors: true);
      _pending = null;
      _pendingAnswer = null;
      if (mounted) {
        if (_scroll.hasClients) _scroll.jumpTo(0);
        await _say(reply);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = _pending == null
              ? 'Réponse IA indisponible ou correction non vérifiable. Votre brouillon est conservé; réessayez.'
              : 'Réponse reçue, mais non enregistrée. Réessayez l’enregistrement sans nouvel appel IA.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave({bool finish = false}) async {
    if (_busy || _leaving) return;
    _leaving = true;
    try {
      await _voice.currentState?.stop();
      await _tts.stop().catchError((Object _) {});
      await _flushDraft();
      if (finish) await _db.finishSpeakingSession(widget.sessionId);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Brouillon non enregistré. Réessayez ou copiez votre texte avant de quitter.',
        );
      }
    } finally {
      _leaving = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    // Also flush on route removal/logout; reportable failures use _leave above.
    unawaited(_flushDraft().catchError((Object _) {}));
    unawaited(_tts.stop().catchError((Object _) {}));
    _editor.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        appBar: AppBar(title: Text(session?.topic ?? 'Partenaire oral')),
        body: session == null
            ? Center(
                child: _error == null
                    ? const CircularProgressIndicator()
                    : TextButton(onPressed: _load, child: Text(_error!)),
              )
            : ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '${_turns.length} échange(s) sauvegardé(s) · ${session.repairMode ? 'Réparation ciblée' : 'Conversation'}',
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.promptFr,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton.icon(
                            onPressed: _voiceBusy
                                ? null
                                : () => _say(session.promptFr),
                            icon: const Icon(Icons.volume_up),
                            label: const Text('Écouter le partenaire'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_lastFeedback case final feedback?) ...[
                    Text('Point réussi : ${feedback.strength}'),
                    if (feedback.corrections.isEmpty)
                      const Text(
                        'Aucune correction précise retenue pour ce tour.',
                      ),
                    for (final c in feedback.corrections)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Vous avez dit : « ${c.original} »'),
                              Text(
                                'Suggestion : ${c.corrected}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(c.explanation),
                              const SizedBox(height: 6),
                              Text('À réutiliser : ${c.exercise}'),
                            ],
                          ),
                        ),
                      ),
                    const Text(
                      'Suggestions enregistrées dans votre carnet. Écartez celles qui viennent d’une mauvaise transcription.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (!session.finished && _turns.length < 30) ...[
                    const SizedBox(height: 16),
                    VoiceDraft(
                      key: _voice,
                      controller: _editor,
                      enabled: !_busy && _pending == null,
                      onChanged: _changed,
                      onBusy: (value) {
                        if (mounted) setState(() => _voiceBusy = value);
                      },
                    ),
                    FilledButton(
                      key: const Key('partner-submit'),
                      onPressed:
                          _busy ||
                              _voiceBusy ||
                              _editor.text.trim().isEmpty ||
                              _editor.text.length > speakingAnswerLimit
                          ? null
                          : _submit,
                      child: Text(
                        _busy
                            ? 'Le partenaire prépare sa réponse…'
                            : _pending != null
                            ? 'Réessayer l’enregistrement'
                            : 'Envoyer ma pensée',
                      ),
                    ),
                  ],
                  if (!session.finished && _turns.length >= 30)
                    const Text(
                      '30 échanges : terminez cette séance, puis reprenez vos corrections dans une nouvelle conversation.',
                    ),
                  TextButton(
                    onPressed: _busy || _voiceBusy
                        ? null
                        : () async {
                            await _tts.stop().catchError((Object _) {});
                            if (!context.mounted) return;
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SpeakingMistakesScreen(),
                              ),
                            );
                          },
                    child: const Text(
                      'Revoir mes erreurs · seul ou avec le partenaire',
                    ),
                  ),
                  if (session.finished && session.draft.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Brouillon conservé (non envoyé)'),
                            SelectableText(
                              session.draft,
                              contextMenuBuilder: learningTextContextMenu,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_editor.text.length > speakingAnswerLimit &&
                      !session.finished)
                    const Text(
                      'Cette réponse dépasse 6 000 caractères. Conservez une partie pour le tour suivant avant d’envoyer.',
                    ),
                  if (!session.finished)
                    OutlinedButton(
                      onPressed: _busy || _voiceBusy
                          ? null
                          : () => _leave(finish: true),
                      child: const Text('Terminer et conserver la séance'),
                    ),
                  ExpansionTile(
                    title: const Text('Échanges précédents'),
                    children: [
                      for (final t in _turns)
                        ListTile(
                          title: Text(t.promptFr),
                          subtitle: SelectableText(
                            t.answer,
                            contextMenuBuilder: learningTextContextMenu,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
