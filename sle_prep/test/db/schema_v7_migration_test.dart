import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sle_prep/data/db/database.dart';
import 'package:sle_prep/data/db/daos.dart';
import 'package:sle_prep/data/db/learning_daos.dart';
import 'package:sle_prep/data/db/speaking_daos.dart';
import 'package:sqlite3/sqlite3.dart';
import '../support/test_db.dart';

void main() {
  test(
    'v6 upgrade preserves course, vocabulary and listening and adds speaking',
    () async {
      setupSqliteForTests();
      final directory = await Directory.systemTemp.createTemp('sle-v7-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/legacy.sqlite');
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
      await before.close();
      final old = sqlite3.open(file.path);
      for (final table in [
        'speaking_sessions',
        'speaking_turns',
        'speaking_mistakes',
      ]) {
        old.execute('DROP TABLE $table');
      }
      old.execute('PRAGMA user_version = 6');
      old.dispose();
      final after = AppDatabase(NativeDatabase(file));
      addTearDown(after.close);
      expect(await after.getSetting('planStartDate'), '2026-09-11');
      expect(await after.vocabularyLibrary(), hasLength(1));
      expect(await after.listeningHistory(), hasLength(1));
      final id = await after.createSpeakingSession(
        topic: 'Travail',
        prompt: 'Présentez-vous.',
        now: DateTime.now(),
      );
      expect((await after.speakingSession(id)).turnCount, 0);
      expect(after.schemaVersion, 7);
    },
  );
}
