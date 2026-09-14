import 'dart:convert';
import 'package:drift/drift.dart';
import '../../domain/llm/speaking_partner.dart';
import '../../domain/srs/sm2.dart';
import 'database.dart';

String _mistakeKey(SpeakingCorrection correction) {
  String normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll(RegExp(r'\s+'), ' ');
  return jsonEncode([
    normalize(correction.original),
    normalize(correction.corrected),
  ]);
}

extension SpeakingDaos on AppDatabase {
  Future<int> createSpeakingSession({
    required String topic,
    required String prompt,
    required DateTime now,
    bool repairMode = false,
    int? focusMistakeId,
  }) {
    if (topic.trim().isEmpty ||
        topic.length > 300 ||
        prompt.trim().isEmpty ||
        prompt.length > 1200) {
      throw ArgumentError('Invalid speaking session');
    }
    return into(speakingSessions).insert(
      SpeakingSessionsCompanion.insert(
        topic: topic.trim(),
        promptFr: prompt.trim(),
        createdAt: now,
        updatedAt: now,
        repairMode: Value(repairMode),
        focusMistakeId: Value(focusMistakeId),
      ),
    );
  }

  Future<SpeakingSession> speakingSession(int id) =>
      (select(speakingSessions)..where((s) => s.id.equals(id))).getSingle();

  Future<List<SpeakingSession>> recentSpeakingSessions() =>
      (select(speakingSessions)
            ..orderBy([
              (s) => OrderingTerm.desc(s.updatedAt),
              (s) => OrderingTerm.desc(s.id),
            ])
            ..limit(20))
          .get();

  Future<List<SpeakingTurn>> speakingHistory(int sessionId) =>
      (select(speakingTurns)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm.asc(t.turnNumber)]))
          .get();

  Future<void> saveSpeakingDraft(
    int sessionId,
    String text,
    DateTime now, {
    required int expectedTurnCount,
  }) async {
    if (text.length > 20000) throw ArgumentError('Draft too long');
    final changed =
        await (update(speakingSessions)..where(
              (s) =>
                  s.id.equals(sessionId) &
                  s.finished.equals(false) &
                  s.turnCount.equals(expectedTurnCount),
            ))
            .write(
              SpeakingSessionsCompanion(
                draft: Value(text),
                updatedAt: Value(now),
              ),
            );
    if (changed != 1) throw StateError('Session unavailable');
  }

  Future<void> finishSpeakingSession(int id) async {
    await (update(speakingSessions)..where((s) => s.id.equals(id))).write(
      SpeakingSessionsCompanion(
        finished: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Retry-safe: one response and its suggestions are committed exactly once.
  Future<void> saveSpeakingTurn({
    required int sessionId,
    required int turnNumber,
    required String prompt,
    required String answer,
    required PartnerFeedback feedback,
    required DateTime now,
  }) => transaction(() async {
    final existing =
        await (select(speakingTurns)..where(
              (t) =>
                  t.sessionId.equals(sessionId) &
                  t.turnNumber.equals(turnNumber),
            ))
            .getSingleOrNull();
    if (existing != null) {
      if (existing.answer != answer || existing.promptFr != prompt) {
        throw StateError('Conflicting turn');
      }
      return;
    }
    final session = await speakingSession(sessionId);
    final turns = await speakingHistory(sessionId);
    if (session.finished ||
        session.turnCount != turnNumber ||
        turns.length != turnNumber ||
        turnNumber >= 30 ||
        session.promptFr != prompt ||
        answer.trim().isEmpty ||
        answer.length > speakingAnswerLimit) {
      throw StateError('Stale or invalid speaking turn');
    }
    final validated = parsePartnerFeedback(feedback.toJson(), answer);
    await into(speakingTurns).insert(
      SpeakingTurnsCompanion.insert(
        sessionId: sessionId,
        turnNumber: turnNumber,
        promptFr: prompt,
        answer: answer,
        feedbackJson: validated.toJson(),
        createdAt: now,
      ),
    );
    for (final correction in validated.corrections) {
      final key = _mistakeKey(correction);
      final old = await (select(
        speakingMistakes,
      )..where((m) => m.fingerprint.equals(key))).getSingleOrNull();
      if (old == null) {
        await into(speakingMistakes).insert(
          SpeakingMistakesCompanion.insert(
            fingerprint: key,
            original: correction.original,
            corrected: correction.corrected,
            explanation: correction.explanation,
            category: correction.category,
            exercise: correction.exercise,
            dueAt: now,
            lastSeen: now,
          ),
        );
      } else if (!old.dismissed) {
        await (update(
          speakingMistakes,
        )..where((m) => m.id.equals(old.id))).write(
          SpeakingMistakesCompanion(
            occurrences: Value(old.occurrences + 1),
            explanation: Value(correction.explanation),
            exercise: Value(correction.exercise),
            lastSeen: Value(now),
            dueAt: Value(now),
            repetitions: const Value(0),
            intervalDays: const Value(0),
            lapses: Value(old.lapses + (old.repetitions > 0 ? 1 : 0)),
            reviewVersion: Value(old.reviewVersion + 1),
          ),
        );
      }
    }
    await (update(
      speakingSessions,
    )..where((s) => s.id.equals(sessionId))).write(
      SpeakingSessionsCompanion(
        promptFr: Value(validated.reply),
        turnCount: Value(turnNumber + 1),
        draft: const Value(''),
        updatedAt: Value(now),
      ),
    );
  });

  Future<List<SpeakingMistake>> speakingMistakeLibrary({
    DateTime? dueBy,
    int limit = 200,
  }) {
    if (limit < 1 || limit > 500) throw ArgumentError('Invalid limit');
    final query = select(speakingMistakes)
      ..where((m) => m.dismissed.equals(false));
    if (dueBy != null) query.where((m) => m.dueAt.isSmallerOrEqualValue(dueBy));
    return (query
          ..orderBy([
            (m) => OrderingTerm.asc(m.dueAt),
            (m) => OrderingTerm.desc(m.lastSeen),
          ])
          ..limit(limit))
        .get();
  }

  Future<List<SpeakingMistake>> speakingFocus(
    SpeakingSession session,
    DateTime now,
  ) async {
    final id = session.focusMistakeId;
    if (id != null) {
      return (select(
        speakingMistakes,
      )..where((m) => m.id.equals(id) & m.dismissed.equals(false))).get();
    }
    return speakingMistakeLibrary(dueBy: now, limit: 3);
  }

  Future<void> dismissSpeakingMistake(int id) async {
    await (update(speakingMistakes)..where((m) => m.id.equals(id))).write(
      const SpeakingMistakesCompanion(dismissed: Value(true)),
    );
  }

  Future<void> gradeSpeakingMistake({
    required SpeakingMistake card,
    required ReviewGrade grade,
    required DateTime now,
  }) => transaction(() async {
    final current = await (select(
      speakingMistakes,
    )..where((m) => m.id.equals(card.id))).getSingle();
    if (current.dismissed || current.reviewVersion != card.reviewVersion) {
      throw StateError('Review changed; reload');
    }
    final state = applyGrade(
      Sm2State(
        easeFactor: current.easeFactor,
        intervalDays: current.intervalDays,
        repetitions: current.repetitions,
        lapses: current.lapses,
      ),
      grade,
    );
    final days = state.intervalDays.clamp(1, 365);
    final due = grade == ReviewGrade.again
        ? now.add(const Duration(minutes: 10))
        : DateTime(now.year, now.month, now.day + days);
    await (update(speakingMistakes)..where((m) => m.id.equals(card.id))).write(
      SpeakingMistakesCompanion(
        easeFactor: Value(state.easeFactor),
        intervalDays: Value(days),
        repetitions: Value(state.repetitions),
        lapses: Value(state.lapses),
        dueAt: Value(due),
        reviewedAt: Value(now),
        reviewVersion: Value(current.reviewVersion + 1),
      ),
    );
  });
}
