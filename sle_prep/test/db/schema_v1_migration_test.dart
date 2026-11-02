import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/data/db/database.dart';
import 'package:sle_prep/data/db/weekly_daos.dart';
import 'package:sle_prep/domain/course/course_catalog.dart';
import 'package:sle_prep/domain/weekly/weekly_plan.dart';
import 'package:sqlite3/sqlite3.dart';
import '../support/test_db.dart';
import '../support/legacy_schema.dart';

/// The oldest upgrade path the product promises: a phone that has not been
/// opened since the first release still carries its study history forward.
/// Every later migration test starts one version below its own feature, so
/// without this one nothing proves the whole chain runs end to end.
void main() {
  test('v1 upgrades through every step without losing study history', () async {
    setupSqliteForTests();
    final directory = await Directory.systemTemp.createTemp('sle-v1-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/legacy.sqlite');

    // Seed only what the very first schema could hold.
    final before = AppDatabase(NativeDatabase(file));
    await before.setSetting('planStartDate', '2026-07-12');
    final cardId = await before.insertCardWithState(
      front: 'the deadline',
      back: 'l\'échéance',
      exampleFr: 'Respectez l\'échéance.',
      domain: 'gestion_projet',
      now: DateTime(2026, 7, 12),
    );
    final drillId = await before.insertDrillItem(
      topic: 'subjonctif_present',
      prompt: 'Il faut que le rapport ___ remis.',
      options: const ['est', 'soit', 'sera', 'serait'],
      correctIndex: 1,
      explanationFr: 'Il faut que déclenche le subjonctif.',
    );
    await before.recordAttempt(
      drillId,
      wasCorrect: true,
      at: DateTime(2026, 7, 12, 9),
    );
    await before.upsertWeek(
      weekNumber: 8,
      themeFr: 'Réunions d\'équipe',
      themeEn: 'Team meetings',
      grammarTopics: const ['subjonctif_present'],
      vocabDomain: 'gestion_projet',
      resourceSlots: const [
        {'label': 'Mauril', 'url': 'https://mauril.ca'},
      ],
    );
    await before.upsertSessionLog(
      day: DateTime(2026, 7, 12),
      blocksPlanned: const ['vocabReview', 'grammarDrillPrimary'],
      blocksCompleted: const ['vocabReview'],
      minutesActive: 35,
    );
    await before.close();

    // Rewind the file to a genuine first-release database.
    final old = sqlite3.open(file.path);
    rewindSchema(old, 1);
    expect(
      old.select('PRAGMA user_version').first.values.first,
      1,
      reason: 'the fixture must really be a v1 file',
    );
    old.dispose();

    final after = AppDatabase(NativeDatabase(file));
    addTearDown(after.close);

    // Every original record survives the whole chain.
    expect(after.schemaVersion, greaterThanOrEqualTo(9));
    expect(await after.getSetting('planStartDate'), '2026-07-12');
    expect(await after.reviewStateFor(cardId), isNotNull);
    expect(await after.dueCardCount(DateTime(2030)), 1);
    expect((await after.weekByNumber(8))!.themeFr, 'Réunions d\'équipe');
    expect(await after.topicAccuracy(), containsPair('subjonctif_present', 1.0));
    final log = await after.sessionLogFor(DateTime(2026, 7, 12));
    expect(log, isNotNull);
    expect(log!.minutesActive, 35);
    expect(
      log.blocksCompletedList,
      ['vocabReview'],
      reason: 'the v5 plan-snapshot column must not disturb older rows',
    );

    // And the newest layer works on the upgraded file.
    final lesson = bToCCourse.lessons.first;
    final weekId = await after.createStudyWeek(
      plan: composeWeeklyPlan(
        weekNumber: 1,
        trackId: bToCCourse.id,
        lessonId: lesson.id,
        lessonTitleFr: lesson.title,
      ),
      startDate: DateTime(2026, 11, 2),
    );
    expect((await after.activeStudyWeek())!.id, weekId);
    expect(await after.assignmentsForWeek(weekId), isNotEmpty);
  });
}
