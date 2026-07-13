/// The offline daily study plan. It deliberately creates only today's work:
/// missed days do not accumulate into an impossible backlog.
library;

enum BlockType { vocabReview, grammarDrill, resource, freePractice }

class SessionBlock {
  const SessionBlock({
    required this.id,
    required this.type,
    required this.minutes,
    required this.titleFr,
    required this.subtitleFr,
    this.grammarTopics = const [],
    this.resource,
  });

  /// Stable per-day identifier persisted in [SessionLogs.blocksCompleted].
  final String id;
  final BlockType type;
  final int minutes;
  final String titleFr;
  final String subtitleFr;
  final List<String> grammarTopics;
  final SessionResource? resource;
}

class SessionResource {
  const SessionResource({required this.label, required this.url});

  final String label;
  final String url;
}

/// Composes one achievable session between 60 and 90 minutes.
List<SessionBlock> composeSession({
  required int dueCardCount,
  required List<String> grammarTopics,
  required Map<String, double> topicAccuracy,
  required List<SessionResource> resources,
  required int targetMinutes,
}) {
  if (grammarTopics.isEmpty) {
    throw ArgumentError.value(
      grammarTopics,
      'grammarTopics',
      'A daily plan needs at least one grammar topic.',
    );
  }

  final target = targetMinutes.clamp(60, 90);
  final weakTopics = [...grammarTopics]
    ..sort(
      (a, b) => (topicAccuracy[a] ?? 0.5).compareTo(topicAccuracy[b] ?? 0.5),
    );
  final primaryTopics = weakTopics.take(2).toList(growable: false);
  final blocks = <SessionBlock>[];
  var scheduled = 0;

  if (dueCardCount > 0) {
    final minutes = dueCardCount >= 15 ? 15 : 10;
    blocks.add(
      SessionBlock(
        id: 'vocabReview',
        type: BlockType.vocabReview,
        minutes: minutes,
        titleFr: 'Révision de vocabulaire',
        subtitleFr: dueCardCount >= 15
            ? 'Cartes dues · répétition espacée'
            : 'Courte révision · répétition espacée',
      ),
    );
    scheduled += minutes;
  }

  blocks.add(
    SessionBlock(
      id: 'grammarDrillPrimary',
      type: BlockType.grammarDrill,
      minutes: 15,
      titleFr: 'Grammaire ciblée',
      subtitleFr: _topicSummary(primaryTopics),
      grammarTopics: primaryTopics,
    ),
  );
  scheduled += 15;

  final resource = resources.isNotEmpty ? resources.first : null;
  if (resource != null) {
    blocks.add(
      SessionBlock(
        id: 'resource',
        type: BlockType.resource,
        minutes: 20,
        titleFr: 'Ressource du jour',
        subtitleFr: resource.label,
        resource: resource,
      ),
    );
    scheduled += 20;
  }

  final remaining = target - scheduled;
  if (remaining > 0) {
    final grammarMinutes = remaining >= 15 ? 15 : remaining;
    blocks.add(
      SessionBlock(
        id: 'grammarDrillReinforcement',
        type: BlockType.grammarDrill,
        minutes: grammarMinutes,
        titleFr: 'Renforcement grammatical',
        subtitleFr: _topicSummary(weakTopics),
        grammarTopics: weakTopics,
      ),
    );
    scheduled += grammarMinutes;
  }

  if (scheduled < target) {
    blocks.add(
      SessionBlock(
        id: 'freePractice',
        type: BlockType.freePractice,
        minutes: target - scheduled,
        titleFr: 'Production libre',
        subtitleFr: 'Répondez oralement ou par écrit au thème de la semaine.',
      ),
    );
  }

  return blocks;
}

String _topicSummary(List<String> topics) => topics.join(' · ');
