import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/course_daos.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/data/db/database.dart';
import 'package:sle_prep/data/db/learning_daos.dart';
import 'package:sle_prep/data/db/speaking_daos.dart';
import 'package:sle_prep/data/db/weekly_daos.dart';
import 'package:sle_prep/domain/weekly/weekly_plan.dart';
import 'package:sqlite3/sqlite3.dart';
import '../support/test_db.dart';

void main() {
  test('v7 upgrade keeps every existing record and adds the weekly tables', () async {
    setupSqliteForTests();
    final directory = await Directory.systemTemp.createTemp('sle-v8-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/legacy.sqlite');

    // A phone as it is today: plan start, a personal word, listening history,
    // a speaking session, a mock result and course progress.
    final before = AppDatabase(NativeDatabase(file));
    await before.setSetting('planStartDate', '2026-09-11');
    await before.addPersonalWord(
      front: 'a deadline',
      back: 'une échéance',
      example: '',
      now: DateTime(2026, 9, 11),
    );
    await before.recordListening(
      lessonId: '-1',
      correct: 3,
      total: 3,
      seconds: 60,
      usedTranscript: false,
      at: DateTime(2026, 9, 12),
    );
    final sessionId = await before.createSpeakingSession(
      topic: 'Travail',
      prompt: 'Présentez-vous.',
      now: DateTime(2026, 9, 12),
    );
    await before.recordMockResult(
      skill: 'oral',
      score: 0,
      total: 0,
      levelEstimate: 'B',
      at: DateTime(2026, 9, 13),
    );
    await before.markCourseRead('01-detail');
    await before.close();

    // Rewind the file to a genuine v7 database.
    final old = sqlite3.open(file.path);
    for (final table in ['study_weeks', 'weekly_assignments']) {
      old.execute('DROP TABLE $table');
    }
    old.execute('PRAGMA user_version = 7');
    old.dispose();

    final after = AppDatabase(NativeDatabase(file));
    addTearDown(after.close);

    expect(after.schemaVersion, greaterThanOrEqualTo(8));
    expect(await after.getSetting('planStartDate'), '2026-09-11');
    expect(await after.vocabularyLibrary(), hasLength(1));
    expect(await after.listeningHistory(), hasLength(1));
    expect((await after.speakingSession(sessionId)).topic, 'Travail');
    expect(await after.latestMockPerSkill(), contains('oral'));
    expect((await after.courseProgress('01-detail')).read, isTrue);

    // And the new weekly layer works on the upgraded file.
    final weekId = await after.createStudyWeek(
      plan: composeWeeklyPlan(
        weekNumber: 1,
        trackId: 'b-to-c-v1',
        lessonId: '01-detail',
        lessonTitleFr: 'Décrire avec précision',
      ),
      startDate: DateTime(2026, 11, 2),
    );
    expect((await after.activeStudyWeek())!.id, weekId);
    expect(await after.assignmentsForWeek(weekId), isNotEmpty);
  });
}
