import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/data/db/database.dart';
import 'package:sle_prep/domain/session/session_composer.dart';
import 'package:sqlite3/sqlite3.dart';

import '../support/test_db.dart';

void main() {
  test('v4 session plans migrate and recover a reviewed vocab block', () async {
    setupSqliteForTests();
    final directory = await Directory.systemTemp.createTemp('sle-prep-v5-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File(
      '${directory.path}${Platform.pathSeparator}legacy.sqlite',
    );

    final legacyPlan = composeSession(
      dueCardCount: 15,
      grammarTopics: const ['accord'],
      topicAccuracy: const {},
      resources: const [],
      targetMinutes: 75,
    );
    final legacy = sqlite3.open(file.path);
    legacy.execute('''
      CREATE TABLE session_logs (
        date TEXT NOT NULL PRIMARY KEY,
        blocks_planned TEXT NOT NULL,
        blocks_completed TEXT NOT NULL,
        minutes_active INTEGER NOT NULL DEFAULT 0
      )
    ''');
    legacy.execute('INSERT INTO session_logs VALUES (?, ?, ?, ?)', [
      '2026-07-13',
      jsonEncode(legacyPlan.map((block) => block.id).toList()),
      jsonEncode(['vocabReview']),
      15,
    ]);
    legacy.execute('INSERT INTO session_logs VALUES (?, ?, ?, ?)', [
      '2026-07-14',
      jsonEncode(legacyPlan.map((block) => block.id).toList()),
      jsonEncode(<String>[]),
      0,
    ]);
    legacy.execute('PRAGMA user_version = 4');
    legacy.dispose();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final day = DateTime(2026, 7, 13);
    final migrated = await db.sessionLogFor(day);
    expect(migrated, isNotNull);
    expect(migrated!.planSnapshotList, isEmpty);

    final currentPlan = composeSession(
      dueCardCount: 0,
      grammarTopics: const ['accord'],
      topicAccuracy: const {},
      resources: const [],
      targetMinutes: 75,
    );
    final tenCardPlan = composeSession(
      dueCardCount: 1,
      grammarTopics: const ['accord'],
      topicAccuracy: const {},
      resources: const [],
      targetMinutes: 75,
    );
    final recovered = await db.ensureSessionPlan(
      day: day,
      blocks: currentPlan,
      legacyRecoveryPlans: [legacyPlan, tenCardPlan],
    );

    expect(
      recovered.planSnapshotList.map((block) => block.id),
      legacyPlan.map((block) => block.id),
    );
    expect(recovered.blocksCompletedList, ['vocabReview']);
    expect(recovered.planSnapshotList.first.minutes, 15);
    expect(recovered.minutesActive, 15);
    expect(
      recovered.planSnapshotList.fold(0, (sum, block) => sum + block.minutes),
      75,
    );

    final unchecked = await db.toggleSessionBlock(
      day: day,
      blockId: 'vocabReview',
      fallbackPlan: recovered.planSnapshotList,
    );
    expect(unchecked.blocksCompletedList, isEmpty);
    expect(unchecked.minutesActive, 0);

    final unstarted = await db.ensureSessionPlan(
      day: DateTime(2026, 7, 14),
      blocks: currentPlan,
      legacyRecoveryPlans: [legacyPlan, tenCardPlan],
    );
    expect(unstarted.planSnapshotList.first.minutes, 15);
    expect(
      unstarted.planSnapshotList.fold(0, (sum, block) => sum + block.minutes),
      75,
    );
  });
}
