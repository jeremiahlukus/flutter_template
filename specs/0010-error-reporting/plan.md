# Implementation Plan: 0010 · Error reporting

- **Status:** Accepted
- **Created:** 2026-08-21

> Specification: [`spec.md`](spec.md)

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
