# 0003 · Local persistence (Drift)

- **Status:** Accepted
- **Created:** 2026-08-21

## Context

The app needs two very different kinds of local state: a **cache** of remote
records (notes) and **device-local preferences** (theme, analytics opt-in). Drift
covers both, and its in-memory executor is what makes the whole data layer unit
testable with no platform channels.

The trap is Drift's default datetime format: unix **seconds**. It truncates
sub-second precision and drops the UTC flag. Since `updatedAt` is the basis of
sync conflict resolution ([0002](0002-notes-sync.md)), that default quietly
corrupts the one field the sync logic depends on.

## Requirements

| ID | Requirement |
|---|---|
| 0003-R1 | The database MUST be constructible in-memory, with no Flutter binding. |
| 0003-R2 | Datetimes MUST round-trip without loss of precision or timezone. |
| 0003-R3 | `schemaVersion` MUST be explicit, so a migration is always a deliberate act. |
| 0003-R4 | Foreign keys MUST be enabled on open (Drift disables them by default). |
| 0003-R5 | Note reads MUST be ordered newest-first. |
| 0003-R6 | `replaceNotes` MUST preserve rows flagged `pendingSync`. |
| 0003-R7 | Preferences MUST be a key/value table, not a column per setting. |
| 0003-R8 | An unrecognised stored preference MUST fall back to a default, never throw. |
| 0003-R9 | Watched queries MUST emit on every relevant write. |
| 0003-R10 | Note titles MUST be capped at 200 characters at the schema level. |

## Non-goals

- **Full-text search.** Drift supports FTS5; add it when a feature needs it.
- **Encryption at rest.** `sqlcipher_flutter_libs` is a drop-in if required.
- **Migration tests.** There is one schema version. The moment there are two,
  add `drift_dev`'s schema verification — see task.md.

## Design

Two tables, declared in `lib/src/database/tables.dart`:

- `Notes` — the cache. `pendingSync` marks rows the server has not accepted.
- `SettingsEntries` — untyped key/value. Preferences churn faster than schemas,
  and a migration per new toggle is not worth it.

`storeDateTimeAsText: true` is set via `options`, satisfying R2.

`AppDatabase.memory()` uses `NativeDatabase.memory()`, which needs no
`path_provider` and no platform channels. That single factory is why the
repository, provider, and widget layers are all testable.

### Coverage note

`tables.dart` reports 0% line coverage and is excluded from the gate. The column
getters (`text()()`) are evaluated by Drift's **generator** at build time and
never at runtime. The schema itself is covered by
`test/database/tables_test.dart`, which asserts on the *generated* table info.

## Verification

| ID | Test |
|---|---|
| 0003-R1 | `test/database/app_database_test.dart` › `notes` › `starts empty` |
| 0003-R2 | `…` › `timestamp fidelity` › `preserves sub-second precision through a write and read` |
| 0003-R3 | `…` › `schemaVersion is pinned so migrations are deliberate` |
| 0003-R4 | `test/database/tables_test.dart` › `database wiring` › `foreign keys are enabled on open` |
| 0003-R5 | `test/database/app_database_test.dart` › `notes` › `orders newest first` |
| 0003-R6 | `…` › `replaceNotes` › `preserves unsynced local work` |
| 0003-R7 | `test/database/tables_test.dart` › `SettingsEntries` › `declares only a key and a value` |
| 0003-R8 | `test/features/settings/settings_providers_test.dart` › `ThemeModeController.decode` › `falls back to system for a corrupt value` |
| 0003-R9 | `test/database/app_database_test.dart` › `notes` › `watchNotes emits on every write` |
| 0003-R10 | `test/database/tables_test.dart` › `Notes` › `title is capped at 200 characters` |

## Open questions

None.
