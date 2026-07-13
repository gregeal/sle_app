import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/llm/oral_coach.dart';
import '../../domain/realtime/openai_realtime_api.dart';
import '../../domain/realtime/openai_realtime_voice_session.dart';
import '../../domain/realtime/realtime_voice_session.dart';
import '../../providers.dart';
import 'coach_screen.dart';
import 'oral_session_screen.dart';

class RealtimeInterviewScreen extends ConsumerStatefulWidget {
  const RealtimeInterviewScreen({super.key});

  @override
  ConsumerState<RealtimeInterviewScreen> createState() =>
      _RealtimeInterviewScreenState();
}

/// Realtime API `error` events generally describe a failed client operation,
/// not a dead session. Only transport failures marked fatal by the session
/// implementation should tear down the active interview.
bool shouldTerminateRealtimeInterview(RealtimeVoiceEvent event) =>
    event is RealtimeErrorEvent && event.isFatal;

class _RealtimeInterviewScreenState
    extends ConsumerState<RealtimeInterviewScreen> {
  final _transcript = RealtimeTranscriptBuffer();
  RealtimeVoiceSession? _session;
  StreamSubscription<RealtimeVoiceEvent>? _subscription;
  Timer? _maximumDurationTimer;
  RealtimeVoiceActivity _activity = RealtimeVoiceActivity.disconnected;
  OralFeedback? _feedback;
  Object? _error;
  var _started = false;
  var _starting = false;
  var _muted = false;
  var _finishing = false;
  var _assessmentFailed = false;

  @override
  void dispose() {
    _maximumDurationTimer?.cancel();
    _maximumDurationTimer = null;
    final subscription = _subscription;
    _subscription = null;
    final session = _session;
    _session = null;
    unawaited(_disposeDetached(subscription, session));
    super.dispose();
  }

  Future<void> _start() async {
    if (_starting) return;
    _starting = true;
    _transcript.clear();
    setState(() {
      _started = true;
      _error = null;
      _activity = RealtimeVoiceActivity.connecting;
      _feedback = null;
      _muted = false;
      _finishing = false;
      _assessmentFailed = false;
    });
    try {
      final config = await ref.read(llmConfigProvider.future);
      final gateway = ref.read(aiGatewayProvider);

      final session = OpenAiRealtimeVoiceSession(
        api: OpenAiRealtimeApi(
          baseUrl: 'https://api.openai.com/v1',
          clientSecretProvider: gateway.realtimeClientSecret,
        ),
        model: config.realtimeModel,
        voice: config.realtimeVoice,
      );
      _session = session;
      _subscription = session.events.listen(
        (event) => _handleEvent(session, event),
      );
      await session.connect();
      if (_session != session) return;
      _maximumDurationTimer = Timer(const Duration(minutes: 20), () {
        if (mounted && _session == session && !_finishing) {
          unawaited(_finish());
        }
      });
    } catch (error) {
      await _disposeActiveSession();
      if (mounted) {
        setState(() {
          _error = error;
          _activity = RealtimeVoiceActivity.disconnected;
        });
      }
    } finally {
      _starting = false;
    }
  }

  void _handleEvent(RealtimeVoiceSession source, RealtimeVoiceEvent event) {
    if (!mounted || _session != source) return;
    var failed = false;
    setState(() {
      switch (event) {
        case RealtimeActivityEvent():
          _activity = event.activity;
          if (event.activity != RealtimeVoiceActivity.disconnected) {
            // A later successful event confirms that a recoverable request
            // error did not end the interview.
            _error = null;
          }
        case RealtimeTranscriptEvent():
          _transcript.add(event);
        case RealtimeConversationItemEvent():
          _transcript.add(event);
        case RealtimeErrorEvent():
          _error = RealtimeVoiceException(event.message);
          failed = shouldTerminateRealtimeInterview(event);
      }
    });
    if (failed && !_finishing) {
      unawaited(_handleUnexpectedFailure(source));
    }
  }

  Future<void> _handleUnexpectedFailure(RealtimeVoiceSession source) async {
    if (_session != source || _finishing) return;
    _maximumDurationTimer?.cancel();
    _maximumDurationTimer = null;
    _session = null;
    final subscription = _subscription;
    _subscription = null;
    await _disposeDetached(subscription, source);
    if (mounted && !_finishing) {
      setState(() {
        _activity = RealtimeVoiceActivity.disconnected;
        _error ??= const RealtimeVoiceException(
          'La session Realtime a été interrompue. Réessayez.',
        );
      });
    }
  }

  Future<void> _disposeActiveSession() async {
    _maximumDurationTimer?.cancel();
    _maximumDurationTimer = null;
    final subscription = _subscription;
    _subscription = null;
    final session = _session;
    _session = null;
    await _disposeDetached(subscription, session);
  }

  Future<void> _disposeDetached(
    StreamSubscription<RealtimeVoiceEvent>? subscription,
    RealtimeVoiceSession? session,
  ) async {
    try {
      await subscription?.cancel();
    } catch (_) {
      // Still close WebRTC if a stream implementation fails to cancel.
    }
    try {
      await session?.close();
    } catch (_) {
      // Session cleanup is best effort during route disposal and retries.
    }
  }

  Future<void> _toggleMute() async {
    final session = _session;
    if (session == null) return;
    final muted = !_muted;
    await session.setMuted(muted);
    if (mounted) setState(() => _muted = muted);
  }

  Future<void> _finish() async {
    if (_finishing) return;
    final session = _session;
    if (session == null) return;
    _maximumDurationTimer?.cancel();
    _maximumDurationTimer = null;
    setState(() {
      _finishing = true;
      _error = null;
      _assessmentFailed = false;
    });
    try {
      await session.setMuted(true);
      if (mounted) setState(() => _muted = true);
    } catch (_) {
      // Muting is helpful but teardown must continue if the track disappeared.
    }

    // Input transcription completes asynchronously and can arrive after the
    // next assistant turn. Keep the data channel alive for a short, bounded
    // grace period so the learner's final answer reaches the assessment.
    await waitForRealtimeTranscriptFinalization(
      revision: () => _transcript.revision,
      hasPendingTranscripts: () => _transcript.hasPendingTranscripts,
    );

    if (_session == session) {
      _session = null;
      final subscription = _subscription;
      _subscription = null;
      await _disposeDetached(subscription, session);
    } else {
      await session.close();
    }
    if (!mounted) return;
    await _assessTranscript();
  }

  Future<void> _resetToIntroduction() async {
    await _disposeActiveSession();
    if (!mounted) return;
    _transcript.clear();
    setState(() {
      _started = false;
      _activity = RealtimeVoiceActivity.disconnected;
      _feedback = null;
      _error = null;
      _muted = false;
      _finishing = false;
      _assessmentFailed = false;
    });
  }

  Future<void> _assessTranscript() async {
    final exchanges = pairRealtimeTranscript(_transcript.orderedTurns);
    if (exchanges.isEmpty) {
      if (mounted) {
        setState(() {
          _finishing = false;
          _assessmentFailed = true;
          _error = const RealtimeVoiceException(
            'Aucune réponse complète n’a été transcrite. '
            'Vérifiez le microphone puis recommencez.',
          );
        });
      }
      return;
    }

    try {
      final client = await ref.read(llmClientProvider.future);
      final feedback = await requestOralFeedback(
        db: ref.read(appDatabaseProvider),
        client: client,
        mode: 'realtime',
        exchanges: exchanges,
      );
      if (mounted) {
        setState(() {
          _feedback = feedback;
          _finishing = false;
          _assessmentFailed = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _finishing = false;
          _assessmentFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedback = _feedback;
    final exchanges = pairRealtimeTranscript(_transcript.orderedTurns);
    return Scaffold(
      appBar: AppBar(title: const Text('Entrevue Realtime')),
      body: SafeArea(
        child: feedback != null
            ? OralReportView(feedback: feedback, exchanges: exchanges)
            : _finishing
            ? const _AssessingView()
            : !_started
            ? _buildIntroduction(context)
            : _buildLiveSession(context),
      ),
    );
  }

  Widget _buildIntroduction(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    children: [
      Icon(Icons.graphic_eq, size: 72, color: coachAccent),
      const SizedBox(height: 16),
      Text(
        'Une vraie entrevue voix-à-voix',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      const Text(
        'L’évaluatrice vous entend et répond directement en audio. Elle '
        'commence par des questions concrètes, relance vos réponses, puis '
        'progresse vers les opinions et hypothèses du niveau C.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoLine(icon: Icons.mic, text: 'Microphone requis'),
              SizedBox(height: 10),
              _InfoLine(
                icon: Icons.wifi,
                text: 'Connexion Internet stable requise',
              ),
              SizedBox(height: 10),
              _InfoLine(
                icon: Icons.payments_outlined,
                text: 'Audio facturé par OpenAI selon votre compte',
              ),
              SizedBox(height: 10),
              _InfoLine(
                icon: Icons.lock_outline,
                text: 'Un jeton de session de courte durée est utilisé',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: _start,
        icon: const Icon(Icons.headset_mic),
        label: const Text('Commencer l’entrevue'),
      ),
      const SizedBox(height: 10),
      const Text(
        'Conseil : utilisez des écouteurs dans un endroit calme. Touchez '
        '« Terminer et analyser » lorsque vous avez assez pratiqué.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.5),
      ),
    ],
  );

  Widget _buildLiveSession(BuildContext context) {
    final connecting = _activity == RealtimeVoiceActivity.connecting;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Column(
        children: [
          _VoiceStatus(activity: _activity, muted: _muted),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text('$_error'),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Expanded(
            child: _transcript.isEmpty
                ? Center(
                    child: Text(
                      connecting
                          ? 'Connexion sécurisée à l’évaluatrice…'
                          : 'La transcription apparaîtra ici après chaque tour.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _transcript.orderedTurns.length,
                    itemBuilder: (context, index) => _TranscriptBubble(
                      turn: _transcript.orderedTurns[index],
                    ),
                  ),
          ),
          if (_assessmentFailed) ...[
            OutlinedButton.icon(
              onPressed:
                  pairRealtimeTranscript(_transcript.orderedTurns).isEmpty
                  ? null
                  : () {
                      setState(() {
                        _finishing = true;
                        _error = null;
                      });
                      _assessTranscript();
                    },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer l’analyse'),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: connecting || _session == null ? null : _toggleMute,
                icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                tooltip: _muted ? 'Réactiver le micro' : 'Couper le micro',
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: coachAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: connecting || _session == null ? null : _finish,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Terminer et analyser'),
                ),
              ),
            ],
          ),
          if (_error != null && _session == null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => unawaited(_resetToIntroduction()),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Revenir aux instructions'),
            ),
          ],
        ],
      ),
    );
  }
}

class _VoiceStatus extends StatelessWidget {
  const _VoiceStatus({required this.activity, required this.muted});

  final RealtimeVoiceActivity activity;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = muted
        ? ('Micro coupé', Icons.mic_off, Colors.grey)
        : switch (activity) {
            RealtimeVoiceActivity.connecting => (
              'Connexion…',
              Icons.sync,
              Colors.orange,
            ),
            RealtimeVoiceActivity.assistantSpeaking => (
              'L’évaluatrice parle',
              Icons.volume_up,
              coachAccent,
            ),
            RealtimeVoiceActivity.userSpeaking => (
              'Je vous écoute',
              Icons.multitrack_audio,
              Colors.green,
            ),
            RealtimeVoiceActivity.thinking => (
              'L’évaluatrice réfléchit…',
              Icons.psychology_alt_outlined,
              Colors.orange,
            ),
            RealtimeVoiceActivity.connected ||
            RealtimeVoiceActivity.listening => (
              'À vous de répondre',
              Icons.mic,
              Colors.green,
            ),
            RealtimeVoiceActivity.disconnected => (
              'Session terminée',
              Icons.call_end,
              Colors.grey,
            ),
          };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TranscriptBubble extends StatelessWidget {
  const _TranscriptBubble({required this.turn});

  final RealtimeTranscriptEvent turn;

  @override
  Widget build(BuildContext context) => Align(
    alignment: turn.isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 330),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: turn.isUser
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            turn.isUser ? 'Vous' : 'Évaluatrice',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 3),
          Text(turn.text),
        ],
      ),
    ),
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 10),
      Expanded(child: Text(text)),
    ],
  );
}

class _AssessingView extends StatelessWidget {
  const _AssessingView();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Analyse des cinq dimensions de compétence…'),
      ],
    ),
  );
}
