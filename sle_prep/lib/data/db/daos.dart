import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../domain/session/session_composer.dart';
import 'database.dart';

/// A due vocabulary card together with its scheduling state.
class DueCard {
  const DueCard(this.card, this.state);

  final VocabCard card;
  final ReviewState state;
}

extension DrillItemJson on DrillItem {
  List<String> get optionsList => (jsonDecode(options) as List).cast<String>();
}

extension CurriculumWeekJson on CurriculumWeek {
  List<String> get grammarTopicsList =>
      (jsonDecode(grammarTopics) as List).cast<String>();

  List<Map<String, dynamic>> get resourceSlotsList =>
      (jsonDecode(resourceSlots) as List).cast<Map<String, dynamic>>();
}

extension ReadingSetJson on ReadingSet {
  List<Map<String, dynamic>> get questionsList =>
      (jsonDecode(questions) as List).cast<Map<String, dynamic>>();
}

extension OralAttemptJson on OralAttempt {
  List<Map<String, dynamic>> get exchangesList =>
      (jsonDecode(exchanges) as List).cast<Map<String, dynamic>>();
}

extension SessionLogJson on SessionLog {
  List<String> get blocksPlannedList => _decodeStringList(blocksPlanned);

  List<String> get blocksCompletedList => _decodeStringList(blocksCompleted);

  /// Returns an empty list for a legacy or corrupt snapshot so the planner can
  /// recover it from the current block definitions without crashing startup.
  List<SessionBlock> get planSnapshotList {
    try {
      final decoded = jsonDecode(planSnapshot);
      if (decoded is! List) return const [];
      return List.unmodifiable(
        decoded.map(
          (entry) =>
              SessionBlock.fromJson(Map<String, dynamic>.from(entry as Map)),
        ),
      );
    } on Object {
      return const [];
    }
  }
}

List<String> _decodeStringList(String value) {
  try {
    final decoded = jsonDecode(value);
    if (decoded is! List || decoded.any((entry) => entry is! String)) {
      return const [];
    }
    return List<String>.unmodifiable(decoded.cast<String>());
  } on Object {
    return const [];
  }
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

List<SessionBlock> _recoverLegacyPlan({
  required List<String> legacyIds,
  required List<String> completedIds,
  required int recordedMinutes,
  required List<List<SessionBlock>> candidates,
}) {
  final snapshots = <List<SessionBlock>>[];
  for (final candidate in candidates) {
    final byId = {for (final block in candidate) block.id: block};
    if (byId.length != candidate.length) continue;
    final recovered = legacyIds.map((id) => byId[id]).toList(growable: false);
    if (recovered.any((block) => block == null)) continue;
    snapshots.add(
      List<SessionBlock>.unmodifiable(recovered.whereType<SessionBlock>()),
    );
  }
  if (snapshots.isEmpty) {
    throw StateError(
      'Impossible de restaurer tous les blocs de la séance enregistrée.',
    );
  }
  if (completedIds.isNotEmpty) {
    for (final snapshot in snapshots) {
      final completedMinutes = snapshot
          .where((block) => completedIds.contains(block.id))
          .fold(0, (total, block) => total + block.minutes);
      if (completedMinutes == recordedMinutes) return snapshot;
    }
  }
  return snapshots.first;
}

String _dateKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

extension AppDaos on AppDatabase {
  // ── Vocabulary ────────────────────────────────────────────────────────────

  /// Inserts a card and its default review state (due immediately).
  Future<int> insertCardWithState({
    required String front,
    required String back,
    required String exampleFr,
    required String domain,
    required DateTime now,
  }) {
    return transaction(() async {
      final id = await into(vocabCards).insert(
        VocabCardsCompanion.insert(
          front: front,
          back: back,
          exampleFr: exampleFr,
          domain: domain,
        ),
      );
      await into(
        reviewStates,
      ).insert(ReviewStatesCompanion.insert(cardId: Value(id), dueDate: now));
      return id;
    });
  }

  Future<ReviewState> reviewStateFor(int cardId) =>
      (select(reviewStates)..where((s) => s.cardId.equals(cardId))).getSingle();

  Future<List<DueCard>> dueCards(DateTime now, {int limit = 100}) async {
    final query =
        (select(reviewStates)
              ..where((s) => s.dueDate.isSmallerOrEqualValue(now))
              ..orderBy([(s) => OrderingTerm.asc(s.dueDate)])
              ..limit(limit))
            .join([
              innerJoin(
                vocabCards,
                vocabCards.id.equalsExp(reviewStates.cardId),
              ),
            ]);
    final rows = await query.get();
    return rows
        .map((r) => DueCard(r.readTable(vocabCards), r.readTable(reviewStates)))
        .toList();
  }

  Future<int> dueCardCount(DateTime now) async {
    final countExp = reviewStates.cardId.count();
    final query = selectOnly(reviewStates)
      ..addColumns([countExp])
      ..where(reviewStates.dueDate.isSmallerOrEqualValue(now));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Number of cards that have been reviewed at least once.
  Future<int> studiedCardCount() async {
    final countExp = reviewStates.cardId.count();
    final query = selectOnly(reviewStates)
      ..addColumns([countExp])
      ..where(
        reviewStates.repetitions.isBiggerThanValue(0) |
            reviewStates.lapses.isBiggerThanValue(0),
      );
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<void> applyReview({
    required int cardId,
    required double easeFactor,
    required int intervalDays,
    required int repetitions,
    required int lapses,
    required DateTime dueDate,
  }) {
    return (update(reviewStates)..where((s) => s.cardId.equals(cardId)))
        .write(
          ReviewStatesCompanion(
            easeFactor: Value(easeFactor),
            intervalDays: Value(intervalDays),
            repetitions: Value(repetitions),
            lapses: Value(lapses),
            dueDate: Value(dueDate),
          ),
        )
        .then((_) {});
  }

  // ── Drills ────────────────────────────────────────────────────────────────

  Future<int> insertDrillItem({
    required String topic,
    required String prompt,
    required List<String> options,
    required int correctIndex,
    required String explanationFr,
    String source = 'seed',
  }) {
    return into(drillItems).insert(
      DrillItemsCompanion.insert(
        topic: topic,
        prompt: prompt,
        options: jsonEncode(options),
        correctIndex: correctIndex,
        explanationFr: explanationFr,
        source: Value(source),
      ),
    );
  }

  Future<List<DrillItem>> randomDrillItems(
    List<String> topics,
    int n, {
    Random? random,
  }) async {
    final rows = await (select(
      drillItems,
    )..where((d) => d.topic.isIn(topics))).get();
    rows.shuffle(random ?? Random());
    return rows.take(n).toList();
  }

  Future<void> recordAttempt(
    int itemId, {
    required bool wasCorrect,
    required DateTime at,
  }) {
    return into(drillAttempts)
        .insert(
          DrillAttemptsCompanion.insert(
            itemId: itemId,
            wasCorrect: wasCorrect,
            answeredAt: at,
          ),
        )
        .then((_) {});
  }

  /// Fraction of correct attempts per drill topic (topics with no attempts
  /// are absent from the map).
  Future<Map<String, double>> topicAccuracy() async {
    final correct = drillAttempts.wasCorrect.cast<int>().sum();
    final total = drillAttempts.id.count();
    final query = selectOnly(drillAttempts)
      ..join([
        innerJoin(drillItems, drillItems.id.equalsExp(drillAttempts.itemId)),
      ])
      ..addColumns([drillItems.topic, correct, total])
      ..groupBy([drillItems.topic]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(drillItems.topic)!:
            (row.read(correct) ?? 0) / (row.read(total) ?? 1),
    };
  }

  // ── Curriculum ────────────────────────────────────────────────────────────

  Future<void> upsertWeek({
    required int weekNumber,
    required String themeFr,
    required String themeEn,
    required List<String> grammarTopics,
    required String vocabDomain,
    required List<Map<String, dynamic>> resourceSlots,
  }) {
    return into(curriculumWeeks)
        .insertOnConflictUpdate(
          CurriculumWeeksCompanion.insert(
            weekNumber: Value(weekNumber),
            themeFr: themeFr,
            themeEn: themeEn,
            grammarTopics: jsonEncode(grammarTopics),
            vocabDomain: vocabDomain,
            resourceSlots: jsonEncode(resourceSlots),
          ),
        )
        .then((_) {});
  }

  Future<CurriculumWeek?> weekByNumber(int n) => (select(
    curriculumWeeks,
  )..where((w) => w.weekNumber.equals(n))).getSingleOrNull();

  // ── Session logs ──────────────────────────────────────────────────────────

  Future<void> upsertSessionLog({
    required DateTime day,
    required List<String> blocksPlanned,
    required List<String> blocksCompleted,
    required int minutesActive,
    List<SessionBlock>? planSnapshot,
  }) async {
    final existingSnapshot = planSnapshot == null
        ? (await sessionLogFor(day))?.planSnapshot
        : null;
    await into(sessionLogs).insertOnConflictUpdate(
      SessionLogsCompanion.insert(
        date: _dateKey(day),
        blocksPlanned: jsonEncode(blocksPlanned),
        blocksCompleted: jsonEncode(blocksCompleted),
        planSnapshot: Value(
          existingSnapshot ??
              jsonEncode(
                (planSnapshot ?? const <SessionBlock>[])
                    .map((block) => block.toJson())
                    .toList(growable: false),
              ),
        ),
        minutesActive: Value(minutesActive),
      ),
    );
  }

  /// Freezes the full block snapshot for a study day the first time it is
  /// shown. Existing completion state is never overwritten by a refresh.
  Future<SessionLog> ensureSessionPlan({
    required DateTime day,
    required List<SessionBlock> blocks,
    List<List<SessionBlock>> legacyRecoveryPlans = const [],
  }) => transaction(() async {
    if (blocks.isEmpty) {
      throw ArgumentError.value(
        blocks,
        'blocks',
        'A session plan cannot be empty.',
      );
    }
    if ({for (final block in blocks) block.id}.length != blocks.length) {
      throw ArgumentError.value(
        blocks,
        'blocks',
        'Session block IDs must be unique.',
      );
    }
    final existing = await sessionLogFor(day);
    if (existing != null) {
      final plannedIds = existing.blocksPlannedList;
      final snapshot = existing.planSnapshotList;
      if (plannedIds.isNotEmpty &&
          snapshot.length == plannedIds.length &&
          _sameStrings(
            snapshot.map((block) => block.id).toList(growable: false),
            plannedIds,
          )) {
        return existing;
      }
    }

    final legacyIds = existing?.blocksPlannedList ?? const <String>[];
    final completed = existing?.blocksCompletedList ?? const <String>[];
    final minutes = existing?.minutesActive ?? 0;
    final snapshot = legacyIds.isEmpty
        ? List<SessionBlock>.unmodifiable(blocks)
        : _recoverLegacyPlan(
            legacyIds: legacyIds,
            completedIds: completed,
            recordedMinutes: minutes,
            candidates: [...legacyRecoveryPlans, blocks],
          );
    await upsertSessionLog(
      day: day,
      blocksPlanned: snapshot.map((block) => block.id).toList(growable: false),
      blocksCompleted: completed,
      minutesActive: minutes,
      planSnapshot: snapshot,
    );
    return (await sessionLogFor(day))!;
  });

  /// Atomically toggles one block using the latest persisted state. This
  /// avoids lost updates when two quick taps were rendered from the same log.
  Future<SessionLog> toggleSessionBlock({
    required DateTime day,
    required String blockId,
    required List<SessionBlock> fallbackPlan,
  }) async {
    await ensureSessionPlan(day: day, blocks: fallbackPlan);
    return transaction(() async {
      final log = (await sessionLogFor(day))!;
      final planned = log.blocksPlannedList;
      if (!planned.contains(blockId)) {
        throw StateError(
          'Le bloc ne fait pas partie de la séance enregistrée.',
        );
      }
      final snapshot = log.planSnapshotList;
      final block = snapshot.where((candidate) => candidate.id == blockId);
      if (block.isEmpty) {
        throw StateError('Les détails du bloc enregistré sont introuvables.');
      }
      final completed = log.blocksCompletedList.toSet();
      final wasCompleted = !completed.add(blockId);
      if (wasCompleted) completed.remove(blockId);
      final minutes = wasCompleted
          ? max(0, log.minutesActive - block.single.minutes)
          : log.minutesActive + block.single.minutes;
      await upsertSessionLog(
        day: day,
        blocksPlanned: planned,
        blocksCompleted: completed.toList(growable: false),
        minutesActive: minutes,
        planSnapshot: snapshot,
      );
      return (await sessionLogFor(day))!;
    });
  }

  Future<SessionLog?> sessionLogFor(DateTime day) => (select(
    sessionLogs,
  )..where((l) => l.date.equals(_dateKey(day)))).getSingleOrNull();

  /// Consecutive days with at least one completed block, counting back from
  /// [today] (an inactive today does not break yesterday's streak).
  Future<int> currentStreak(DateTime today) async {
    final rows = await select(sessionLogs).get();
    final activeDays = {
      for (final log in rows)
        if (log.blocksCompletedList.isNotEmpty) log.date,
    };

    var day = DateTime(today.year, today.month, today.day);
    if (!activeDays.contains(_dateKey(day))) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    var streak = 0;
    while (activeDays.contains(_dateKey(day))) {
      streak++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return streak;
  }

  // ── Reading ───────────────────────────────────────────────────────────────

  Future<int> insertReadingSet({
    required String title,
    required String kind,
    required String bodyFr,
    required List<Map<String, dynamic>> questions,
    String source = 'seed',
  }) {
    return into(readingSets).insert(
      ReadingSetsCompanion.insert(
        title: title,
        kind: kind,
        bodyFr: bodyFr,
        questions: jsonEncode(questions),
        source: Value(source),
      ),
    );
  }

  Future<List<ReadingSet>> allReadingSets() => select(readingSets).get();

  Future<void> recordReadingAttempt({
    required int setId,
    required int correct,
    required int total,
    required int seconds,
    required DateTime at,
  }) {
    return into(readingAttempts)
        .insert(
          ReadingAttemptsCompanion.insert(
            setId: setId,
            correct: correct,
            total: total,
            seconds: seconds,
            answeredAt: at,
          ),
        )
        .then((_) {});
  }

  /// Newest first.
  Future<List<ReadingAttempt>> readingHistory() => (select(
    readingAttempts,
  )..orderBy([(a) => OrderingTerm.desc(a.answeredAt)])).get();

  // ── Mock exams ────────────────────────────────────────────────────────────

  Future<void> recordMockResult({
    required String skill,
    required int score,
    required int total,
    required String levelEstimate,
    required DateTime at,
  }) {
    return into(mockResults)
        .insert(
          MockResultsCompanion.insert(
            skill: skill,
            score: score,
            total: total,
            levelEstimate: levelEstimate,
            answeredAt: at,
          ),
        )
        .then((_) {});
  }

  /// Newest result per skill.
  Future<Map<String, MockResult>> latestMockPerSkill() async {
    final rows = await (select(
      mockResults,
    )..orderBy([(r) => OrderingTerm.asc(r.answeredAt)])).get();
    return {for (final row in rows) row.skill: row};
  }

  /// Total study minutes logged across all sessions.
  Future<int> totalActiveMinutes() async {
    final sum = sessionLogs.minutesActive.sum();
    final query = selectOnly(sessionLogs)..addColumns([sum]);
    final row = await query.getSingle();
    return row.read(sum) ?? 0;
  }

  /// Drill attempts recorded at or after [cutoff] (for scoring a timed mock).
  Future<({int correct, int total})> drillStatsSince(DateTime cutoff) async {
    final correct = drillAttempts.wasCorrect.cast<int>().sum();
    final total = drillAttempts.id.count();
    final query = selectOnly(drillAttempts)
      ..addColumns([correct, total])
      ..where(drillAttempts.answeredAt.isBiggerOrEqualValue(cutoff));
    final row = await query.getSingle();
    return (correct: row.read(correct) ?? 0, total: row.read(total) ?? 0);
  }

  Future<List<CurriculumWeek>> allCurriculumWeeks() => (select(
    curriculumWeeks,
  )..orderBy([(w) => OrderingTerm.asc(w.weekNumber)])).get();

  // ── Oral ──────────────────────────────────────────────────────────────────

  Future<int> insertOralQuestion({
    required String tier,
    required String questionFr,
    String source = 'seed',
  }) {
    return into(oralQuestions).insert(
      OralQuestionsCompanion.insert(
        tier: tier,
        questionFr: questionFr,
        source: Value(source),
      ),
    );
  }

  Future<List<OralQuestion>> oralQuestionsByTier(String tier) =>
      (select(oralQuestions)..where((q) => q.tier.equals(tier))).get();

  Future<void> recordOralAttempt({
    required String mode,
    required List<Map<String, dynamic>> exchanges,
    required String feedback,
    required DateTime at,
  }) {
    return into(oralAttempts)
        .insert(
          OralAttemptsCompanion.insert(
            mode: mode,
            exchanges: jsonEncode(exchanges),
            feedback: feedback,
            answeredAt: at,
          ),
        )
        .then((_) {});
  }

  /// Newest first.
  Future<List<OralAttempt>> oralHistory() => (select(
    oralAttempts,
  )..orderBy([(a) => OrderingTerm.desc(a.answeredAt)])).get();

  // ── Writing ───────────────────────────────────────────────────────────────

  Future<void> insertWritingAttempt({
    required String promptFr,
    required String userText,
    required String feedback,
    required DateTime at,
  }) {
    return into(writingAttempts)
        .insert(
          WritingAttemptsCompanion.insert(
            promptFr: promptFr,
            userText: userText,
            feedback: feedback,
            answeredAt: at,
          ),
        )
        .then((_) {});
  }

  /// Newest first.
  Future<List<WritingAttempt>> writingHistory() => (select(
    writingAttempts,
  )..orderBy([(a) => OrderingTerm.desc(a.answeredAt)])).get();

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final row = await (select(
      appSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) {
    return into(appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key, value: value),
        )
        .then((_) {});
  }
}
