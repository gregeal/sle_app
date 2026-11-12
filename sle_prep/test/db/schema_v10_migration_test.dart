import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/data/db/database.dart';
import 'package:sle_prep/data/db/habit_daos.dart';
import 'package:sle_prep/data/db/weekly_daos.dart';
import 'package:sle_prep/domain/course/course_catalog.dart';
import 'package:sle_prep/domain/weekly/weekly_plan.dart';
import 'package:sle_prep/domain/weekly/weekly_report.dart';
import 'package:sqlite3/sqlite3.dart';

import '../support/legacy_schema.dart';
import '../support/test_db.dart';

void main() {
  test('v9 upgrades to v10: observed time carries over, leases gain a '
      'checkpoint', () async {
    setupSqliteForTests();
    final directory = await Directory.systemTemp.createTemp('sle-v10-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/v9.sqlite');
    final monday = DateTime(2026, 11, 2, 9);

    final before = AppDatabase(NativeDatabase(file));
    final week = await before.createStudyWeek(
      plan: composeWeeklyPlan(
        weekNumber: 1,
        trackId: 'b-to-c-v1',
        lessonId: '01-detail',
        lessonTitleFr: 'Décrire',
      ),
      startDate: monday,
    );
    final teaching = (await before.assignmentsForWeek(week)).first;
    await before.saveAssignmentEvidence(
      teaching.id,
      AssignmentEvidence(
        kind: EvidenceKind.quiz,
        data: {
          'answers': findCourseLesson(
            '01-detail',
          ).questions.map((q) => q.correct).toList(),
        },
        observedSeconds: 240,
      ),
      at: monday,
    );
    final lease = await before.reserveWeeklyVoice(week, now: monday);
    await before.close();

    final raw = sqlite3.open(file.path);
    rewindSchema(raw, 9);
    expect(raw.select('PRAGMA user_version').first.values.first, 9);
    expect(
      raw.select("SELECT name FROM sqlite_master WHERE name = 'activity_logs'"),
      isEmpty,
      reason: 'the fixture must really be a v9 file',
    );
    raw.dispose();

    final after = AppDatabase(NativeDatabase(file));
    addTearDown(after.close);

    // Observed time becomes study time. The 15 planned minutes do not.
    expect(await after.totalActiveMinutes(), 4);
    final carried = (await after.activitySince(DateTime(2026))).single;
    expect(carried.kind, 'weekly');
    expect(carried.skill, 'teaching');
    expect(carried.seconds, 240);
    expect(carried.startedAt, monday.subtract(const Duration(seconds: 240)));

    // The open lease survives and can now be checkpointed and reconciled.
    await after.heartbeatWeeklyVoice(
      lease,
      75,
      now: monday.add(const Duration(seconds: 80)),
    );
    final next = await after.reserveWeeklyVoice(
      week,
      now: monday.add(const Duration(minutes: 5)),
    );
    expect(await after.voiceLeaseSeconds(next), 1200 - 75);

    // The new layer works on the upgraded file.
    await after.saveGroupClassNote(
      day: monday,
      covered: 'Les connecteurs logiques',
      corrections: '',
      at: monday,
    );
    expect(await after.groupClassNoteFor(monday), isNotNull);
    expect(await after.getSetting('habit:logSince'), isNotNull);
    expect((await after.activeStudyWeek())!.id, week);
  });
}
