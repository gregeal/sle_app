import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Strip all later-version objects, rather than only changing user_version.
void rewindSchema(sqlite.Database db, int version) {
  if (version < 9) {
    for (final table in [
      'weekly_voice_leases',
      'weekly_feedback_jobs',
      'weekly_evidence',
      'weekly_class_states',
    ]) {
      db.execute('DROP TABLE IF EXISTS $table');
    }
    if (version >= 8) {
      db.execute('ALTER TABLE study_weeks DROP COLUMN schedule_json');
      db.execute('ALTER TABLE study_weeks DROP COLUMN paused');
    }
  }
  final introduced = {
    8: ['weekly_assignments', 'study_weeks'],
    7: ['speaking_turns', 'speaking_mistakes', 'speaking_sessions'],
    6: ['listening_attempts'],
    4: ['mock_results'],
    3: ['oral_attempts', 'oral_questions'],
    2: ['reading_attempts', 'writing_attempts', 'reading_sets'],
  };
  for (final e in introduced.entries) {
    if (version < e.key) {
      for (final table in e.value) {
        db.execute('DROP TABLE IF EXISTS $table');
      }
    }
  }
  if (version < 5) {
    db.execute('ALTER TABLE session_logs DROP COLUMN plan_snapshot');
  }
  db.execute('PRAGMA user_version = $version');
}
