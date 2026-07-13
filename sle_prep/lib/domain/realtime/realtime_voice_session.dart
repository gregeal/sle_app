import 'dart:convert';

enum RealtimeVoiceActivity {
  connecting,
  connected,
  listening,
  userSpeaking,
  thinking,
  assistantSpeaking,
  disconnected,
}

sealed class RealtimeVoiceEvent {
  const RealtimeVoiceEvent();
}

class RealtimeActivityEvent extends RealtimeVoiceEvent {
  const RealtimeActivityEvent(this.activity);

  final RealtimeVoiceActivity activity;
}

class RealtimeTranscriptEvent extends RealtimeVoiceEvent {
  const RealtimeTranscriptEvent({
    required this.isUser,
    required this.text,
    this.itemId,
  });

  final bool isUser;
  final String text;
  final String? itemId;
}

class RealtimeConversationItemEvent extends RealtimeVoiceEvent {
  const RealtimeConversationItemEvent({
    required this.itemId,
    required this.previousItemId,
  });

  final String itemId;
  final String? previousItemId;
}

class RealtimeErrorEvent extends RealtimeVoiceEvent {
  const RealtimeErrorEvent(
    this.message, {
    this.type,
    this.code,
    this.param,
    this.eventId,
    this.isFatal = false,
  });

  final String message;
  final String? type;
  final String? code;
  final String? param;
  final String? eventId;

  /// Server-side Realtime errors are recoverable unless the transport itself
  /// has failed. This flag is set by the WebRTC implementation for peer or
  /// data-channel failures; parsed OpenAI `error` events remain non-fatal.
  final bool isFatal;
}

class RealtimeVoiceException implements Exception {
  const RealtimeVoiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      statusCode == null ? message : '$message (HTTP $statusCode)';
}

/// Converts a Realtime data-channel payload into the small event vocabulary
/// consumed by the interview UI. Unknown server events are intentionally
/// ignored so additions to the API do not break an active interview.
List<RealtimeVoiceEvent> parseRealtimeServerEvent(String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return const [];
  }
  if (decoded is! Map<String, dynamic>) return const [];

  final type = decoded['type'];
  if (type is! String) return const [];
  switch (type) {
    case 'session.created':
    case 'session.updated':
      return const [RealtimeActivityEvent(RealtimeVoiceActivity.connected)];
    case 'input_audio_buffer.speech_started':
      return const [RealtimeActivityEvent(RealtimeVoiceActivity.userSpeaking)];
    case 'input_audio_buffer.speech_stopped':
      return const [RealtimeActivityEvent(RealtimeVoiceActivity.thinking)];
    case 'output_audio_buffer.started':
      return const [
        RealtimeActivityEvent(RealtimeVoiceActivity.assistantSpeaking),
      ];
    case 'output_audio_buffer.stopped':
      return const [RealtimeActivityEvent(RealtimeVoiceActivity.listening)];
    case 'conversation.item.input_audio_transcription.completed':
      final transcript = decoded['transcript'];
      if (transcript is String && transcript.trim().isNotEmpty) {
        final itemId = decoded['item_id'];
        return [
          RealtimeTranscriptEvent(
            isUser: true,
            text: transcript.trim(),
            itemId: itemId is String ? itemId : null,
          ),
        ];
      }
    case 'response.output_audio_transcript.done':
      final transcript = decoded['transcript'];
      if (transcript is String && transcript.trim().isNotEmpty) {
        final itemId = decoded['item_id'];
        return [
          RealtimeTranscriptEvent(
            isUser: false,
            text: transcript.trim(),
            itemId: itemId is String ? itemId : null,
          ),
        ];
      }
    case 'conversation.item.added':
      final item = decoded['item'];
      final itemId = item is Map ? item['id'] : null;
      if (itemId is String && itemId.isNotEmpty) {
        final previous = decoded['previous_item_id'];
        return [
          RealtimeConversationItemEvent(
            itemId: itemId,
            previousItemId: previous is String ? previous : null,
          ),
        ];
      }
    case 'error':
      final error = decoded['error'];
      final message = error is Map ? error['message'] : null;
      return [
        RealtimeErrorEvent(
          message is String && message.isNotEmpty
              ? message
              : 'La session Realtime a signalé une erreur.',
          type: error is Map && error['type'] is String
              ? error['type'] as String
              : null,
          code: error is Map && error['code'] is String
              ? error['code'] as String
              : null,
          param: error is Map && error['param'] is String
              ? error['param'] as String
              : null,
          eventId: error is Map && error['event_id'] is String
              ? error['event_id'] as String
              : null,
        ),
      ];
  }
  return const [];
}

/// Reconstructs conversation order independently from event arrival order.
/// Input transcription is asynchronous in the Realtime API, so a user's
/// completed transcript may arrive after the following assistant response.
class RealtimeTranscriptBuffer {
  final _itemOrder = <String>[];
  final _itemArrival = <String>[];
  final _previousByItemId = <String, String?>{};
  final _byItemId = <String, RealtimeTranscriptEvent>{};
  final _withoutItemId = <RealtimeTranscriptEvent>[];
  var _revision = 0;

  void add(RealtimeVoiceEvent event) {
    switch (event) {
      case RealtimeConversationItemEvent():
        if (!_itemArrival.contains(event.itemId)) {
          _itemArrival.add(event.itemId);
        }
        _previousByItemId[event.itemId] = event.previousItemId;
        _rebuildItemOrder();
        _revision++;
      case RealtimeTranscriptEvent():
        final itemId = event.itemId;
        if (itemId == null || itemId.isEmpty) {
          _withoutItemId.add(event);
        } else {
          _byItemId[itemId] = event;
          if (!_itemArrival.contains(itemId)) _itemArrival.add(itemId);
          _rebuildItemOrder();
        }
        _revision++;
      case RealtimeActivityEvent() || RealtimeErrorEvent():
        break;
    }
  }

  List<RealtimeTranscriptEvent> get orderedTurns => [
    for (final itemId in _itemOrder) ?_byItemId[itemId],
    ..._withoutItemId,
  ];

  void _rebuildItemOrder() {
    final known = _itemArrival.toSet();
    final remaining = {...known};
    final ordered = <String>[];
    while (remaining.isNotEmpty) {
      var progressed = false;
      for (final itemId in _itemArrival) {
        if (!remaining.contains(itemId)) continue;
        final previous = _previousByItemId[itemId];
        if (previous == null ||
            !known.contains(previous) ||
            ordered.contains(previous)) {
          ordered.add(itemId);
          remaining.remove(itemId);
          progressed = true;
        }
      }
      if (!progressed) {
        // A malformed predecessor cycle should not hide transcript content.
        ordered.addAll(_itemArrival.where(remaining.contains));
        break;
      }
    }
    _itemOrder
      ..clear()
      ..addAll(ordered);
  }

  bool get isEmpty => _byItemId.isEmpty && _withoutItemId.isEmpty;

  /// Monotonically changes whenever ordering or transcript content changes.
  /// The interview screen uses it to wait briefly for asynchronous final
  /// transcription events before tearing down WebRTC.
  int get revision => _revision;

  bool get hasPendingTranscripts =>
      _itemOrder.any((itemId) => !_byItemId.containsKey(itemId));

  void clear() {
    final hadContent =
        _itemOrder.isNotEmpty ||
        _itemArrival.isNotEmpty ||
        _previousByItemId.isNotEmpty ||
        _byItemId.isNotEmpty ||
        _withoutItemId.isNotEmpty;
    _itemOrder.clear();
    _itemArrival.clear();
    _previousByItemId.clear();
    _byItemId.clear();
    _withoutItemId.clear();
    if (hadContent) _revision++;
  }
}

/// Gives the Realtime API a bounded window to deliver a final asynchronous
/// transcription. It returns early after the minimum grace period only when
/// the buffer is stable and no known conversation item is awaiting text.
Future<void> waitForRealtimeTranscriptFinalization({
  required int Function() revision,
  required bool Function() hasPendingTranscripts,
  Duration minimumWait = const Duration(milliseconds: 1500),
  Duration quietPeriod = const Duration(milliseconds: 400),
  Duration maximumWait = const Duration(seconds: 3),
  Future<void> Function(Duration duration)? delay,
}) async {
  assert(!minimumWait.isNegative);
  assert(quietPeriod > Duration.zero);
  assert(maximumWait >= minimumWait);
  final wait = delay ?? Future<void>.delayed;
  final initialRevision = revision();
  await wait(minimumWait);

  var elapsed = minimumWait;
  var lastRevision = revision();
  if (!hasPendingTranscripts() && lastRevision == initialRevision) return;

  while (elapsed < maximumWait) {
    final remaining = maximumWait - elapsed;
    final interval = remaining < quietPeriod ? remaining : quietPeriod;
    await wait(interval);
    elapsed += interval;
    final currentRevision = revision();
    if (!hasPendingTranscripts() && currentRevision == lastRevision) return;
    lastRevision = currentRevision;
  }
}

/// Pairs the adaptive interview transcript into the format already used by
/// the five-dimension oral coach and persistence layer.
List<Map<String, dynamic>> pairRealtimeTranscript(
  Iterable<RealtimeTranscriptEvent> transcript,
) {
  final exchanges = <Map<String, dynamic>>[];
  final interviewer = <String>[];

  for (final turn in transcript) {
    if (!turn.isUser) {
      interviewer.add(turn.text);
      continue;
    }
    if (interviewer.isEmpty || turn.text.trim().isEmpty) continue;
    exchanges.add({
      'question': interviewer.join(' ').trim(),
      'answer': turn.text.trim(),
    });
    interviewer.clear();
  }
  return exchanges;
}

abstract class RealtimeVoiceSession {
  Stream<RealtimeVoiceEvent> get events;

  bool get isMuted;

  Future<void> connect();

  Future<void> setMuted(bool muted);

  Future<void> close();
}
