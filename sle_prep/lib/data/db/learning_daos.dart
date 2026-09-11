import 'package:drift/drift.dart';

import 'daos.dart';
import 'database.dart';

const personalVocabDomain = 'personnel';

extension LearningDaos on AppDatabase {
  Future<List<VocabCard>> vocabularyLibrary() =>
      (select(vocabCards)..orderBy([(c) => OrderingTerm.desc(c.id)])).get();

  Future<int> addPersonalWord({
    required String front,
    required String back,
    required String example,
    required DateTime now,
    int? cardId,
  }) async {
    String clean(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final term = clean(front);
    final meaning = clean(back);
    final sentence = example.trim();
    if (term.isEmpty ||
        meaning.isEmpty ||
        term.length > 200 ||
        meaning.length > 500 ||
        sentence.length > 1000) {
      throw const FormatException(
        'Terme et sens requis (200 / 500 caractères maximum).',
      );
    }
    return transaction(() async {
      if (cardId != null) {
        final card =
            await (select(vocabCards)..where(
                  (c) =>
                      c.id.equals(cardId) &
                      c.domain.equals(personalVocabDomain),
                ))
                .getSingleOrNull();
        if (card == null) throw ArgumentError('Personal card not found');
      }
      final existing = await (select(
        vocabCards,
      )..where((c) => c.domain.equals(personalVocabDomain))).get();
      for (final card in existing) {
        if (clean(card.front).toLowerCase() == term.toLowerCase() &&
            clean(card.back).toLowerCase() == meaning.toLowerCase()) {
          if (cardId != null && card.id != cardId) {
            throw const FormatException(
              'Cette expression existe déjà dans le carnet.',
            );
          }
          if (cardId != null) continue;
          return card
              .id; // Re-saving must never reset an existing SRS schedule.
        }
      }
      if (cardId != null) {
        await (update(vocabCards)..where((c) => c.id.equals(cardId))).write(
          VocabCardsCompanion(
            front: Value(term),
            back: Value(meaning),
            exampleFr: Value(sentence),
          ),
        );
        return cardId;
      }
      return insertCardWithState(
        front: term,
        back: meaning,
        exampleFr: sentence,
        domain: personalVocabDomain,
        now: now,
      );
    });
  }

  Future<void> deletePersonalWord(int cardId) => transaction(() async {
    final card =
        await (select(vocabCards)..where(
              (c) => c.id.equals(cardId) & c.domain.equals(personalVocabDomain),
            ))
            .getSingleOrNull();
    if (card == null) throw ArgumentError('Personal card not found');
    await (delete(reviewStates)..where((s) => s.cardId.equals(cardId))).go();
    await (delete(vocabCards)..where((c) => c.id.equals(cardId))).go();
  });

  Future<List<DrillItem>> unresolvedDrillMistakes({int limit = 50}) async {
    if (limit < 1 || limit > 200) throw ArgumentError.value(limit, 'limit');
    final rows = await customSelect(
      '''
      WITH ranked AS (
        SELECT item_id, was_correct, answered_at, id,
          ROW_NUMBER() OVER (PARTITION BY item_id ORDER BY answered_at DESC, id DESC) AS rank
        FROM drill_attempts
      )
      SELECT a.item_id FROM ranked a JOIN drill_items d ON d.id = a.item_id
      WHERE a.rank = 1 AND a.was_correct = 0
      ORDER BY a.answered_at DESC, a.id DESC LIMIT ?
    ''',
      variables: [Variable.withInt(limit)],
      readsFrom: {drillAttempts, drillItems},
    ).get();
    final ids = rows.map((r) => r.read<int>('item_id')).toList();
    if (ids.isEmpty) return const [];
    final items = await (select(
      drillItems,
    )..where((d) => d.id.isIn(ids))).get();
    final byId = {for (final item in items) item.id: item};
    return [
      for (final id in ids)
        if (byId.containsKey(id)) byId[id]!,
    ];
  }

  Future<void> recordListening({
    required String lessonId,
    required int correct,
    required int total,
    required int seconds,
    required bool usedTranscript,
    required DateTime at,
  }) async {
    if (lessonId.isEmpty ||
        lessonId.length > 100 ||
        total < 1 ||
        total > 100 ||
        correct < 0 ||
        correct > total ||
        seconds < 0) {
      throw ArgumentError('Invalid listening result');
    }
    await into(listeningAttempts).insert(
      ListeningAttemptsCompanion.insert(
        lessonId: lessonId,
        correct: correct,
        total: total,
        seconds: seconds,
        usedTranscript: usedTranscript,
        answeredAt: at,
      ),
    );
  }

  Future<List<ListeningAttempt>> listeningHistory() =>
      (select(listeningAttempts)
            ..orderBy([
              (a) => OrderingTerm.desc(a.answeredAt),
              (a) => OrderingTerm.desc(a.id),
            ])
            ..limit(100))
          .get();
}
