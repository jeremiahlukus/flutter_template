# 0007 · Quality gates

- **Status:** Accepted
- **Created:** 2026-08-21

## Context

A template's tests are its most valuable and most fragile asset. Fragile because
the moment the gate can be satisfied without actually testing anything, it stops
being a gate. Two specific ways that happens:

1. **Generated code inflates the number.** Drift's `.g.dart` output is thousands
   of well-covered lines that say nothing about your code.
2. **`flutter analyze` passes with warnings.** By default, `info`-level issues do
   not fail CI, so lint debt accumulates silently.

## Requirements

| ID | Requirement |
|---|---|
| 0007-R1 | Line coverage MUST be at least 85%, enforced in CI. |
| 0007-R2 | The coverage total MUST exclude generated code and the placeholder Firebase config. |
| 0007-R3 | Every coverage exclusion MUST carry a written justification. |
| 0007-R4 | `flutter analyze` MUST fail CI on any issue, including `info`. |
| 0007-R5 | Formatting MUST be enforced. |
| 0007-R6 | Stale generated code MUST fail CI. |
| 0007-R7 | The coverage tool MUST need no dependency beyond the Dart SDK. |
| 0007-R8 | The gate MUST report the least-covered files on failure. |
| 0007-R9 | The suite MUST run with no Firebase project and no network. |
| 0007-R10 | The Flutter version MUST be pinned in CI. |
| 0007-R11 | Every requirement MUST have a Verification row, and every row a requirement. |
| 0007-R12 | A test named in a Verification row MUST exist, by that exact name. |
| 0007-R13 | Every repo path named in a Verification row MUST exist. |
| 0007-R14 | An `Accepted` spec MUST explain every unproven requirement, not just leave `—`. |
| 0007-R15 | The counts of unresolved paths, stale test names, and unverifiable rows MUST NOT grow silently. |

## Non-goals

- **Branch coverage.** `flutter test --coverage` emits line coverage only.
- **Mutation testing.** Genuinely the next thing worth adding; out of scope here.
- **A coverage badge.** Wire up Codecov per-app if you want one.
- **Counting the rules and golden suites towards the coverage floor.** They run in
  separate jobs against separate runtimes; folding them in would make the number
  less meaningful, not more.

## Verification

| ID | Test |
|---|---|
| 0007-R1 | `.github/workflows/ci.yaml` › `Enforce coverage threshold` |
| 0007-R2 | `test/tool/coverage_report_test.dart` › `exclusions` › `an excluded file does not affect the total` |
| 0007-R3 | `tool/check_coverage.dart` (each entry is commented) |
| 0007-R4 | `.github/workflows/ci.yaml` › `Analyze` |
| 0007-R5 | `.github/workflows/ci.yaml` › `Verify formatting` |
| 0007-R6 | `.github/workflows/ci.yaml` › `Verify generated code is up to date` |
| 0007-R7 | `tool/check_coverage.dart` imports only `dart:io` |
| 0007-R8 | `tool/check_coverage.dart` › failure branch |
| 0007-R9 | The whole suite: `flutter test` with no configuration |
| 0007-R10 | `.github/workflows/ci.yaml` › `env.FLUTTER_VERSION` |
| 0007-R11 | `test/specs/verification_test.dart` › `structure` › `every requirement has a verification row, and vice versa` |
| 0007-R12 | `…` › `rows resolve` › `a named test exists in the file the row points at` |
| 0007-R13 | `…` › `rows resolve` › `every repo path named in a Verification row exists` |
| 0007-R14 | `…` › `honesty` › `an Accepted spec explains every unproven requirement` |
| 0007-R15 | `…` › `honesty` › `rows nothing can verify stay within budget` |

### Dependabot and SDK-pinned packages

The Flutter SDK pins some transitive versions *exactly*, and Dependabot does not
model that — so it opens PRs that can never resolve. Three arrived on the first
day: `intl` (pinned by `flutter_localizations`), and `build_runner` / `drift_dev`
(both blocked by the `analyzer` ceiling that `flutter_test`'s pinned `meta`
imposes).

`intl` is ignored in `.github/dependabot.yml`, since that one can only change
when the SDK does. The analyzer-coupled tooling stays enabled — those bumps do
become valid once Flutter updates — with a comment pointing the next reader at
the `Install dependencies` step, because a red PR there is almost never the
code's fault.

Also worth knowing: the codegen-freshness check diffs **only** the generated
paths, not the whole repo. A repo-wide diff reports an incidentally-touched file
as "generated files are stale", which sends the reader somewhere useless.

## Open questions

- ~~The gate itself has no tests.~~ **Resolved:** the parser and threshold logic
  live in `tool/coverage_report.dart` with 28 tests, including truncated reports
  and the exactly-at-threshold case.
- Coverage fell from 97.9% to 93.9% as the platform-bound features landed
  (`image_picker`, `firebase_messaging`, emulator redirection). Those lines reach
  a platform channel and cannot execute in `flutter test`; the interfaces in
  front of them are fully covered.
