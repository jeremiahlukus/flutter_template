import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_template/src/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// An isolated, empty database for a single test.
///
/// Lives in `test/` rather than as a factory on [AppDatabase] on purpose:
/// `package:drift/native.dart` imports `dart:ffi`, which is unavailable on web.
/// A single import of it from `lib/` makes `flutter build web` fail to compile —
/// which is exactly what happened before this was moved here.
///
/// [NativeDatabase.memory] needs no `path_provider` and no platform channels,
/// which is what makes the whole Drift layer unit-testable.
AppDatabase inMemoryDatabase() => AppDatabase(inMemoryExecutor());

/// The executor behind [inMemoryDatabase], for a caller that wants to own the
/// `AppDatabase` lifetime itself.
QueryExecutor inMemoryExecutor() => NativeDatabase.memory();

/// An in-memory database closed automatically at the end of the test.
AppDatabase managedDatabase() {
  final db = inMemoryDatabase();
  addTearDown(db.close);
  return db;
}
