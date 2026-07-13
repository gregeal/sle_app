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
  const RealtimeErrorEvent(this.message);

  final String message;
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
        return [
          RealtimeTranscriptEvent(
            isUser: true,
            text: transcript.trim(),
            itemId: decoded['item_id'] as String?,
          ),
        ];
      }
    case 'response.output_audio_transcript.done':
      final transcript = decoded['transcript'];
      if (transcript is String && transcript.trim().isNotEmpty) {
        return [
          RealtimeTranscriptEvent(
            isUser: false,
            text: transcript.trim(),
            itemId: decoded['item_id'] as String?,
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
  final _byItemId = <String, RealtimeTranscriptEvent>{};
  final _withoutItemId = <RealtimeTranscriptEvent>[];

  void add(RealtimeVoiceEvent event) {
    switch (event) {
      case RealtimeConversationItemEvent():
        _itemOrder.remove(event.itemId);
        final previous = event.previousItemId;
        final previousIndex = previous == null
            ? -1
            : _itemOrder.indexOf(previous);
        if (previous == null) {
          _itemOrder.insert(0, event.itemId);
        } else if (previousIndex >= 0) {
          _itemOrder.insert(previousIndex + 1, event.itemId);
        } else {
          _itemOrder.add(event.itemId);
        }
      case RealtimeTranscriptEvent():
        final itemId = event.itemId;
        if (itemId == null || itemId.isEmpty) {
          _withoutItemId.add(event);
        } else {
          _byItemId[itemId] = event;
          if (!_itemOrder.contains(itemId)) _itemOrder.add(itemId);
        }
      case RealtimeActivityEvent() || RealtimeErrorEvent():
        break;
    }
  }

  List<RealtimeTranscriptEvent> get orderedTurns => [
    for (final itemId in _itemOrder) ?_byItemId[itemId],
    ..._withoutItemId,
  ];

  bool get isEmpty => _byItemId.isEmpty && _withoutItemId.isEmpty;

  void clear() {
    _itemOrder.clear();
    _byItemId.clear();
    _withoutItemId.clear();
  }
}

/// Pairs the adaptive interview transcript into the format already used by
/// the five-criterion oral assessor and persistence layer.
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
