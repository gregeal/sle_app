import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/speaking_daos.dart';
import 'package:sle_prep/domain/srs/sm2.dart';
import '../support/test_db.dart';
import 'speaking_partner_test.dart' show learnerAnswer, validFeedback;

void main() {
  test(
    'turn save is atomic, retry-safe and preserves session continuity',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final now = DateTime(2026, 9, 13, 12);
      final id = await db.createSpeakingSession(
        topic: 'Travail',
        prompt: 'Pourquoi ?',
        now: now,
      );
      await db.saveSpeakingDraft(id, learnerAnswer, now, expectedTurnCount: 0);
      expect((await db.speakingSession(id)).draft, learnerAnswer);
      for (var i = 0; i < 2; i++) {
        await db.saveSpeakingTurn(
          sessionId: id,
          turnNumber: 0,
          prompt: 'Pourquoi ?',
          answer: learnerAnswer,
          feedback: validFeedback,
          now: now,
        );
      }
      expect(await db.speakingHistory(id), hasLength(1));
      final session = await db.speakingSession(id);
      expect(session.draft, '');
      expect(session.turnCount, 1);
      expect(session.promptFr, validFeedback.reply);
      expect((await db.speakingMistakeLibrary()).single.occurrences, 1);
      await expectLater(
        db.saveSpeakingDraft(id, 'stale draft', now, expectedTurnCount: 0),
        throwsStateError,
      );
      expect((await db.speakingSession(id)).draft, '');
      await expectLater(
        db.saveSpeakingTurn(
          sessionId: id,
          turnNumber: 0,
          prompt: 'Pourquoi ?',
          answer: 'different',
          feedback: validFeedback,
          now: now,
        ),
        throwsStateError,
      );
    },
  );
  test(
    'review uses latest state, again returns soon, recurrence resets spacing',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final now = DateTime(2026, 9, 13, 12);
      final id = await db.createSpeakingSession(
        topic: 'Travail',
        prompt: 'Pourquoi ?',
        now: now,
      );
      await db.saveSpeakingTurn(
        sessionId: id,
        turnNumber: 0,
        prompt: 'Pourquoi ?',
        answer: learnerAnswer,
        feedback: validFeedback,
        now: now,
      );
      final card = (await db.speakingMistakeLibrary()).single;
      await db.gradeSpeakingMistake(
        card: card,
        grade: ReviewGrade.again,
        now: now,
      );
      expect(await db.speakingMistakeLibrary(dueBy: now), isEmpty);
      expect(
        (await db.speakingMistakeLibrary()).single.dueAt,
        now.add(const Duration(minutes: 10)),
      );
      await expectLater(
        db.gradeSpeakingMistake(card: card, grade: ReviewGrade.good, now: now),
        throwsStateError,
      );
      final again = (await db.speakingMistakeLibrary()).single;
      await db.gradeSpeakingMistake(
        card: again,
        grade: ReviewGrade.good,
        now: now.add(const Duration(minutes: 10)),
      );
      expect((await db.speakingMistakeLibrary()).single.repetitions, 1);
      await db.saveSpeakingTurn(
        sessionId: id,
        turnNumber: 1,
        prompt: validFeedback.reply,
        answer: learnerAnswer,
        feedback: validFeedback,
        now: now.add(const Duration(hours: 1)),
      );
      final repeated = (await db.speakingMistakeLibrary()).single;
      expect(repeated.occurrences, 2);
      expect(repeated.repetitions, 0);
      expect(repeated.lapses, 2);
    },
  );
  test(
    'dismissed mistakes stay dismissed and session closure preserves drafts',
    () async {
      final db = inMemoryDatabase();
      addTearDown(db.close);
      final now = DateTime(2026, 9, 13);
      final id = await db.createSpeakingSession(
        topic: 'Travail',
        prompt: 'Pourquoi ?',
        now: now,
      );
      await db.saveSpeakingTurn(
        sessionId: id,
        turnNumber: 0,
        prompt: 'Pourquoi ?',
        answer: learnerAnswer,
        feedback: validFeedback,
        now: now,
      );
      final card = (await db.speakingMistakeLibrary()).single;
      await db.dismissSpeakingMistake(card.id);
      await db.saveSpeakingTurn(
        sessionId: id,
        turnNumber: 1,
        prompt: validFeedback.reply,
        answer: learnerAnswer,
        feedback: validFeedback,
        now: now,
      );
      expect(await db.speakingMistakeLibrary(), isEmpty);
      await db.saveSpeakingDraft(id, 'À continuer', now, expectedTurnCount: 2);
      await db.finishSpeakingSession(id);
      expect((await db.speakingSession(id)).draft, 'À continuer');
      await expectLater(
        db.saveSpeakingDraft(id, 'bad', now, expectedTurnCount: 2),
        throwsStateError,
      );
      await expectLater(
        db.gradeSpeakingMistake(card: card, grade: ReviewGrade.good, now: now),
        throwsStateError,
      );
    },
  );
  test('targeted partner practice can revisit a scheduled card', () async {
    final db = inMemoryDatabase();
    addTearDown(db.close);
    final now = DateTime(2026, 9, 13);
    final id = await db.createSpeakingSession(
      topic: 'Travail',
      prompt: 'Pourquoi ?',
      now: now,
    );
    await db.saveSpeakingTurn(
      sessionId: id,
      turnNumber: 0,
      prompt: 'Pourquoi ?',
      answer: learnerAnswer,
      feedback: validFeedback,
      now: now,
    );
    final card = (await db.speakingMistakeLibrary()).single;
    await db.gradeSpeakingMistake(
      card: card,
      grade: ReviewGrade.good,
      now: now,
    );
    final repairId = await db.createSpeakingSession(
      topic: 'Réparation',
      prompt: 'Reformulez',
      now: now,
      repairMode: true,
      focusMistakeId: card.id,
    );
    expect(
      (await db.speakingFocus(
        await db.speakingSession(repairId),
        now,
      )).single.id,
      card.id,
    );
  });
}
