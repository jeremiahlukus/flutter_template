import 'package:drift/drift.dart';

/// Local mirror of the user's notes.
///
/// This table is a *cache*, not the source of truth — Firestore is. It exists so
/// the UI can render instantly and keep working offline. [pendingSync] marks
/// rows written locally that Firestore has not accepted yet.
@DataClassName('NoteRow')
class Notes extends Table {
  TextColumn get id => text()();

  TextColumn get title => text().withLength(min: 0, max: 200)();

  TextColumn get body => text().withDefault(const Constant(''))();

  DateTimeColumn get updatedAt => dateTime()();

  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Simple key/value store for device-local preferences.
///
/// Deliberately untyped: preferences churn faster than schemas, and a migration
/// for every new toggle is not worth it.
@DataClassName('SettingRow')
class SettingsEntries extends Table {
  TextColumn get key => text()();

  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
