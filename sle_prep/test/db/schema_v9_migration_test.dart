import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sle_prep/data/db/database.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/data/db/weekly_daos.dart';
import 'package:sle_prep/domain/weekly/weekly_plan.dart';
import '../support/test_db.dart';
import '../support/legacy_schema.dart';

void main() {
  for (final version in [1, 7, 8]) {
    test('v$version upgrades to v9 and retains existing history', () async {
      setupSqliteForTests();
      final dir = await Directory.systemTemp.createTemp('sle-schema9-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/saved.sqlite');
      final before = AppDatabase(NativeDatabase(file));
      await before.setSetting(
        'course:b-to-c-v1:01-detail',
        'saved-course-evidence',
      );
      final card = await before.insertCardWithState(
        front: 'deadline',
        back: 'échéance',
        exampleFr: '',
        domain: 'work',
        now: DateTime(2026, 11, 1),
      );
      int? oldWeek;
      if (version == 8) {
        oldWeek = await before.createStudyWeek(
          plan: composeWeeklyPlan(
            weekNumber: 1,
            trackId: 'b-to-c-v1',
            lessonId: '01-detail',
            lessonTitleFr: 'Décrire',
          ),
          startDate: DateTime(2026, 11, 2),
        );
      }
      await before.close();
      final raw = sqlite3.open(file.path);
      rewindSchema(raw, version);
      raw.dispose();
      final after = AppDatabase(NativeDatabase(file));
      addTearDown(after.close);
      expect(
        await after.getSetting('course:b-to-c-v1:01-detail'),
        'saved-course-evidence',
      );
      expect((await after.reviewStateFor(card)).repetitions, 0);
      expect(after.schemaVersion, 9);
      if (oldWeek != null) {
        expect((await after.activeStudyWeek())!.id, oldWeek);
        expect(
          await after.studyDates((await after.activeStudyWeek())!),
          hasLength(5),
        );
      }
      final tables = await after
          .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
          .get();
      expect(
        tables.map((r) => r.read<String>('name')),
        containsAll([
          'weekly_evidence',
          'weekly_class_states',
          'weekly_feedback_jobs',
          'weekly_voice_leases',
        ]),
      );
    });
  }
}
