# 0010 · Error reporting

- **Status:** Accepted
- **Created:** 2026-08-21

## Context

An app without crash reporting fails silently in the field. But the reporting
itself has to be invisible when it breaks — a `recordError` that throws takes
down whatever it was reporting on, which is the exact opposite of the point.

Dev builds must not pollute production Crashlytics either, or the crash-free-user
metric becomes meaningless.

## Requirements

| ID | Requirement |
|---|---|
| 0010-R1 | Features MUST depend on an `ErrorReporter` interface, not on Crashlytics. |
| 0010-R2 | Every reporting call MUST swallow its own failures. |
| 0010-R3 | Uncaught framework errors MUST be reported. |
| 0010-R4 | Uncaught async (zone) errors MUST be reported. |
| 0010-R5 | Reporting MUST be disabled where the environment says so. |
| 0010-R6 | The environment MUST be attached to every report as a custom key. |
| 0010-R7 | A recording implementation MUST exist for tests. |
| 0010-R8 | Clearing the user id MUST be possible, for sign-out. |

## Non-goals

- **Attaching the signed-in user automatically.** `setUserId` exists but nothing
  calls it on sign-in yet. See task.md — one `ref.listen` on `authStateProvider`.
- **Breadcrumbs from the analytics stream.** `log()` exists; nothing feeds it.
- **Testing `bootstrap()` itself.** It touches `Firebase.initializeApp` and
  `runApp`; the pieces it wires are covered individually.

## Design

Three implementations of one interface: `CrashlyticsErrorReporter` (production,
every call wrapped in a `_guard` that logs and swallows), `NoopErrorReporter`
(where the environment disables reporting), and `RecordingErrorReporter` (tests).

A no-op rather than a conditional at each call site — feature code never has to
ask whether reporting is on.

`bootstrap()` builds the `ProviderContainer` *before* `runApp` so the error
handlers can report through the same reporter the app uses, and so an error
thrown during the first frame is still captured.

R2 gets a test per method, not one representative test. A single un-guarded call
is enough to crash a save.

## Verification

| ID | Test |
|---|---|
| 0010-R1 | `test/core/errors/error_reporter_test.dart` › `errorReporterProvider` › `uses Crashlytics where the environment enables it` |
| 0010-R2 | `…` › `never lets reporting break the caller` (one test per method) |
| 0010-R3 | `…` › `CrashlyticsErrorReporter` › `forwards a framework error as fatal` |
| 0010-R4 | — *(wired in `bootstrap()`, which is not unit-tested; see Non-goals)* |
| 0010-R5 | `…` › `errorReporterProvider` › `is a no-op where the environment disables reporting` |
| 0010-R6 | — *(set in `bootstrap()`; see Non-goals)* |
| 0010-R7 | `…` › `RecordingErrorReporter` › `records a non-fatal error with its reason` |
| 0010-R8 | `…` › `CrashlyticsErrorReporter` › `a null user id becomes an empty identifier` |

## Open questions

- R4 and R6 are unverified because they live in `bootstrap()`. Extracting the
  handler wiring into a testable function would close both.
