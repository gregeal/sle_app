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

  /// JSON-encoded lists of block type names.
  TextColumn get blocksPlanned => text()();
  TextColumn get blocksCompleted => text()();
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

@DriftDatabase(tables: [
  VocabCards,
  ReviewStates,
  DrillItems,
  DrillAttempts,
  CurriculumWeeks,
  SessionLogs,
  AppSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
