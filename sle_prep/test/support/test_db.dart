import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:sle_prep/data/db/database.dart';
import 'package:sqlite3/open.dart';

/// On Windows hosts there is no system sqlite3; point the sqlite3 package at
/// the DLL vendored under tool/sqlite3/ (tests run with cwd = project root).
void setupSqliteForTests() {
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('tool/sqlite3/sqlite3.dll'),
    );
  }
}

AppDatabase inMemoryDatabase() {
  setupSqliteForTests();
  return AppDatabase(NativeDatabase.memory());
}
