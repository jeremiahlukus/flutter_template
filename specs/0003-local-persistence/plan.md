# Implementation Plan: 0003 · Local persistence (Drift)

- **Status:** Accepted
- **Created:** 2026-08-21

> Specification: [`spec.md`](spec.md)

## Design

Two tables, declared in `lib/src/database/tables.dart`:

- `Notes` — the cache. `pendingSync` marks rows the server has not accepted.
- `SettingsEntries` — untyped key/value. Preferences churn faster than schemas,
  and a migration per new toggle is not worth it.

`storeDateTimeAsText: true` is set via `options`, satisfying R2.

`inMemoryDatabase()` — in `test/helpers/test_database.dart`, **not** on
`AppDatabase` — uses `NativeDatabase.memory()`, which needs no `path_provider`
and no platform channels. That one helper is why the repository, provider, and
widget layers are all testable.

R11 is why it lives in `test/`. It was originally an `AppDatabase.memory()`
factory in `lib/`, which meant `lib/` imported `package:drift/native.dart` →
`dart:ffi`, and **`flutter build web` could not compile at all**. `flutter
analyze` is silent about this; the only signal was a failing build job. CI now
greps `lib/` for native-only imports as a cheap early check. Production code uses
`drift_flutter`'s `driftDatabase()`, which handles web.

### Coverage note

`tables.dart` reports 0% line coverage and is excluded from the gate. The column
getters (`text()()`) are evaluated by Drift's **generator** at build time and
never at runtime. The schema itself is covered by
`test/database/tables_test.dart`, which asserts on the *generated* table info.
