import 'package:drift/drift.dart';

part 'database.g.dart';

class VocabCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get front => text()();
  TextColumn get back => text()();
  TextColumn get exampleFr => text()();
  TextColumn get domain => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ReviewStates extends Table {
  IntColumn get cardId => integer().references(VocabCards, #id)();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueDate => dateTime()();

  @override
  Set<Column> get primaryKey => {cardId};
}

class DrillItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get topic => text()();
  TextColumn get prompt => text()();

  /// JSON-encoded list of exactly four answer strings.
  TextColumn get options => text()();
  IntColumn get correctIndex => integer()();
  TextColumn get explanationFr => text()();
  TextColumn get source => text().withDefault(const Constant('seed'))();
}

class DrillAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer().references(DrillItems, #id)();
  BoolColumn get wasCorrect => boolean()();
  DateTimeColumn get answeredAt => dateTime()();
}

class CurriculumWeeks extends Table {
  IntColumn get weekNumber => integer()();
  TextColumn get themeFr => text()();
  TextColumn get themeEn => text()();

  /// JSON-encoded list of grammar topic keys.
  TextColumn get grammarTopics => text()();
  TextColumn get vocabDomain => text()();

  /// JSON-encoded list of {label, url} objects.
  TextColumn get resourceSlots => text()();

  @override
  Set<Column> get primaryKey => {weekNumber};
}

class SessionLogs extends Table {
  /// Date-only key, yyyy-MM-dd.
  TextColumn get date => text()();

  /// JSON-encoded lists of stable block IDs.
  TextColumn get blocksPlanned => text()();
  TextColumn get blocksCompleted => text()();

  /// JSON-encoded immutable block details for the day. IDs alone are not
  /// enough because minutes, topics, and resources can change after planning.
  TextColumn get planSnapshot => text().withDefault(const Constant('[]'))();
  IntColumn get minutesActive => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {date};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class ReadingSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();

  /// Passage genre: note_service, courriel, politique, article.
  TextColumn get kind => text()();
  TextColumn get bodyFr => text()();

  /// JSON list of {prompt, options[4], correctIndex, explanationFr}.
  TextColumn get questions => text()();
  TextColumn get source => text().withDefault(const Constant('seed'))();
}

class ReadingAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get setId => integer().references(ReadingSets, #id)();
  IntColumn get correct => integer()();
  IntColumn get total => integer()();

  /// Reading + answering time, for the timed mode.
  IntColumn get seconds => integer()();
  DateTimeColumn get answeredAt => dateTime()();
}

class OralQuestions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// OLA question tier: A (concrete/routine), B (narration/explanation),
  /// C (opinion/hypothetical/sensitive).
  TextColumn get tier => text()();
  TextColumn get questionFr => text()();
  TextColumn get source => text().withDefault(const Constant('seed'))();
}

class ListeningAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get lessonId => text()();
  IntColumn get correct => integer()();
  IntColumn get total => integer()();
  IntColumn get seconds => integer()();
  BoolColumn get usedTranscript => boolean()();
  DateTimeColumn get answeredAt => dateTime()();
}

class SpeakingSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get topic => text()();
  TextColumn get promptFr => text()();
  TextColumn get draft => text().withDefault(const Constant(''))();
  IntColumn get turnCount => integer().withDefault(const Constant(0))();
  BoolColumn get finished => boolean().withDefault(const Constant(false))();
  BoolColumn get repairMode => boolean().withDefault(const Constant(false))();
  IntColumn get focusMistakeId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class SpeakingTurns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer()();
  IntColumn get turnNumber => integer()();
  TextColumn get promptFr => text()();
  TextColumn get answer => text()();
  TextColumn get feedbackJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  List<Set<Column>> get uniqueKeys => [
    {sessionId, turnNumber},
  ];
}

class SpeakingMistakes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fingerprint => text().unique()();
  TextColumn get original => text()();
  TextColumn get corrected => text()();
  TextColumn get explanation => text()();
  TextColumn get category => text()();
  TextColumn get exercise => text()();
  IntColumn get occurrences => integer().withDefault(const Constant(1))();
  BoolColumn get dismissed => boolean().withDefault(const Constant(false))();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueAt => dateTime()();
  DateTimeColumn get lastSeen => dateTime()();
  DateTimeColumn get reviewedAt => dateTime().nullable()();
  IntColumn get reviewVersion => integer().withDefault(const Constant(0))();
}

class OralAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 'daily' (one question), 'interview' (guided STT/TTS sequence), or
  /// 'realtime' (voice-to-voice WebRTC interview).
  TextColumn get mode => text()();

  /// JSON list of {question, answer} transcript pairs.
  TextColumn get exchanges => text()();

  /// JSON feedback (5 coaching dimensions, level estimate, tips).
  TextColumn get feedback => text()();
  DateTimeColumn get answeredAt => dateTime()();
}

class MockResults extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 'reading', 'writing', or 'oral'.
  TextColumn get skill => text()();
  IntColumn get score => integer()();
  IntColumn get total => integer()();

  /// Approximate, unofficial A/B/C estimate for this checkpoint.
  TextColumn get levelEstimate => text()();
  DateTimeColumn get answeredAt => dateTime()();
}

class WritingAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get promptFr => text()();
  TextColumn get userText => text()();

  /// JSON feedback from the writing coach (corrections, level, tips).
  TextColumn get feedback => text()();
  DateTimeColumn get answeredAt => dateTime()();
}

/// One week of the AI teacher's programme: the class lesson it is bound to
/// and the immutable plan snapshot the learner was given.
class StudyWeeks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get weekNumber => integer()();
  TextColumn get trackId => text()();
  TextColumn get lessonId => text()();

  /// Date-only key, yyyy-MM-dd, like [SessionLogs.date].
  TextColumn get startDate => text()();

  /// 'active' or 'closed'. Exactly one week may be active at a time.
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// The composed [WeeklyPlan] as JSON, so a stored week never silently
  /// re-plans itself under the learner.
  TextColumn get planJson => text()();

  /// The end-of-week teacher report, written once the week closes.
  TextColumn get reportJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();
}

/// One assignment of a week. Completion is tracked per assignment so a single
/// missed item never blocks the week.
class WeeklyAssignments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get weekId =>
      integer().references(StudyWeeks, #id, onDelete: KeyAction.cascade)();

  /// Stable identifier from the plan, so completion survives a reload.
  TextColumn get specId => text()();
  IntColumn get dayIndex => integer()();

  /// A [SkillKind] name: speaking, listening, reading, writing, vocabulary,
  /// teaching.
  TextColumn get skill => text()();
  IntColumn get minutes => integer()();
  TextColumn get titleFr => text()();
  TextColumn get subtitleFr => text()();

  /// What the UI opens for this assignment, as JSON.
  TextColumn get payloadJson => text()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Where the proof of work lives: 'speakingSession', 'writingAttempt',
  /// 'readingAttempt', 'listeningAttempt'. Set together with [evidenceId].
  TextColumn get evidenceKind => text().nullable()();
  IntColumn get evidenceId => integer().nullable()();
}

@DriftDatabase(
  tables: [
    VocabCards,
    ReviewStates,
    DrillItems,
    DrillAttempts,
    CurriculumWeeks,
    SessionLogs,
    AppSettings,
    ReadingSets,
    ReadingAttempts,
    WritingAttempts,
    OralQuestions,
    OralAttempts,
    MockResults,
    ListeningAttempts,
    SpeakingSessions,
    SpeakingTurns,
    SpeakingMistakes,
    StudyWeeks,
    WeeklyAssignments,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(readingSets);
        await m.createTable(readingAttempts);
        await m.createTable(writingAttempts);
      }
      if (from < 3) {
        await m.createTable(oralQuestions);
        await m.createTable(oralAttempts);
      }
      if (from < 4) {
        await m.createTable(mockResults);
      }
      if (from < 5) {
        await m.addColumn(sessionLogs, sessionLogs.planSnapshot);
      }
      if (from < 6) {
        await m.createTable(listeningAttempts);
      }
      if (from < 7) {
        await m.createTable(speakingSessions);
        await m.createTable(speakingTurns);
        await m.createTable(speakingMistakes);
      }
      if (from < 8) {
        await m.createTable(studyWeeks);
        await m.createTable(weeklyAssignments);
      }
    },
  );
}
