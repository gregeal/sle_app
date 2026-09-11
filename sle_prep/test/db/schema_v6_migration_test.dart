import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/database.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/data/db/learning_daos.dart';
import 'package:sqlite3/sqlite3.dart';
import '../support/test_db.dart';

void main() {
  test(
    'v5 migration preserves vocabulary and settings while adding listening history',
    () async {
      setupSqliteForTests();
      final directory = await Directory.systemTemp.createTemp('sle-prep-v6-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/legacy.sqlite');
      final before = AppDatabase(NativeDatabase(file));
      final id = await before.insertCardWithState(
        front: 'deadline',
        back: 'échéance',
        exampleFr: '',
        domain: 'test',
        now: DateTime(2026, 9, 1),
      );
      await before.setSetting('planStartDate', '2026-09-01');
      await before.close();
      final legacy = sqlite3.open(file.path);
      legacy.execute('DROP TABLE listening_attempts');
      legacy.execute('PRAGMA user_version = 5');
      legacy.dispose();
      final after = AppDatabase(NativeDatabase(file));
      addTearDown(after.close);
      expect((await after.vocabularyLibrary()).single.id, id);
      expect(await after.getSetting('planStartDate'), '2026-09-01');
      expect((await after.reviewStateFor(id)).repetitions, 0);
      await after.recordListening(
        lessonId: '-1',
        correct: 3,
        total: 3,
        seconds: 60,
        usedTranscript: false,
        at: DateTime.now(),
      );
      expect(await after.listeningHistory(), hasLength(1));
      expect(after.schemaVersion, 6);
    },
  );
}
