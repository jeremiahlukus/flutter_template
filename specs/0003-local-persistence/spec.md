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
sync conflict resolution ([0002](../0002-notes-sync/spec.md)), that default quietly
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
| 0003-R11 | Nothing in `lib/` may import a native-only library. |
| 0003-R12 | The on-disk database name MUST be a single named constant, pinned by a test, and MUST NOT be derived from the package name. |
| 0003-R13 | Exactly one `AppDatabase` MUST exist per process; the provider MUST be an injection seam that fails loudly if unset, never a default constructor. |

## Non-goals

- **Full-text search.** Drift supports FTS5; add it when a feature needs it.
- **Encryption at rest.** `sqlcipher_flutter_libs` is a drop-in if required.
- **Migration tests.** There is one schema version. The moment there are two,
  add `drift_dev`'s schema verification — see task.md.

## Verification

| ID | Test |
|---|---|
| 0003-R1 | `test/database/app_database_test.dart` › `notes` › `starts empty` |
| 0003-R2 | `…` › `timestamp fidelity` › `preserves sub-second precision through a write and read` |
| 0003-R3 | `…` › `schemaVersion is pinned so a bump is deliberate` |
| 0003-R4 | `test/database/tables_test.dart` › `database wiring` › `foreign keys are enabled on open` |
| 0003-R5 | `test/database/app_database_test.dart` › `notes` › `orders newest first` |
| 0003-R6 | `…` › `replaceNotes` › `preserves unsynced local work` |
| 0003-R7 | `test/database/tables_test.dart` › `SettingsEntries` › `declares only a key and a value` |
| 0003-R8 | `test/features/settings/settings_providers_test.dart` › `ThemeModeController.decode` › `falls back to system for a corrupt value` |
| 0003-R9 | `test/database/app_database_test.dart` › `notes` › `watchNotes emits on every write` |
| 0003-R10 | `test/database/tables_test.dart` › `Notes` › `title is capped at 200 characters` |
| 0003-R11 | `.github/workflows/ci.yaml` › `Verify lib/ stays web-compatible` |
| 0003-R12 | `test/database/app_database_test.dart` › `the on-disk database name is pinned` |
| 0003-R13 | `test/database/app_database_test.dart` › `appDatabaseProvider must be overridden` |

## Open questions

None.
