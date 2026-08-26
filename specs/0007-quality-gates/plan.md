# Implementation Plan: 0007 · Quality gates

- **Status:** Accepted
- **Created:** 2026-08-21

> Specification: [`spec.md`](spec.md)

## Design

`tool/check_coverage.dart` parses `coverage/lcov.info` — just the `SF`/`LF`/`LH`
triples — and needs nothing but the Dart SDK (R7). Writing it in Dart rather than
as a shell pipeline means the same command works on every developer machine and
on CI.

Exclusions live in one `_excluded` list, each with a comment (R3). The current
set: build output, `firebase_options.dart`, and `database/tables.dart` — the last
because Drift's column getters are evaluated by the generator at build time and
are unreachable at runtime, so they report 0% however well the schema is tested.

CI runs `flutter analyze --fatal-infos --fatal-warnings` (R4) and rebuilds
generated code then checks `git diff` (R6).

R9 is what the whole test strategy rests on: `firebase_auth_mocks`,
`fake_cloud_firestore`, `NativeDatabase.memory()`, `InMemoryStorageRepository`,
and `setupFirebaseCoreMocks()` between them mean the suite needs no credentials
and no network.

**Current state:** 951 Dart tests at 94.0% line coverage, plus 36 security-rules tests and 12 goldens in their own CI jobs.
