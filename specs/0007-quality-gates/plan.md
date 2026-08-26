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

### Checking the Verification tables themselves

The tables were the strongest thing in this repo and the easiest to let rot:
rename a test and the row still reads as proof. `test/specs/verification_test.dart`
resolves every row against the filesystem, so a stale row fails the suite.

It is strict where the format is knowable and honest where it is not. Dart and JS
test names are quoted literals, so it demands the quotes — a rename to
`…the intro (v2)` fails, where a substring check would pass it as a prefix. YAML
step names and prose citations have no such shape, so those fall back to a
substring, because a gate that produces false failures is a gate someone disables.

Rows that cite a constant or a code path rather than a test cannot be checked at
all. Rather than pretend, the count of them is pinned (`maxUncheckableRows`), so
adding one means changing a committed number on purpose. Lowering it never fails.

**It found four stale rows and two fictions on its first run**, which is the
argument for it. `0007-R2` cited a `_excluded` that had been renamed; `0015-R9`
named a test renamed the day before; `0023-R5` still said `macos-latest` after the
runner was pinned. And `0014-R5`/`R6` named two tests that **had never existed** —
the onboarding-precedence requirements had been reading as proven, in a table whose
whole purpose is to prevent exactly that. Those tests are now written.
