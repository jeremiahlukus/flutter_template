# Working in this repo

A Flutter notes app used as a production-ready template. **Read this before
changing anything.** Full detail is in [README.md](README.md); this file is the
short version an agent needs to not break things.

## The one rule

This project is **spec-driven**. The rules live in
[`.specify/memory/constitution.md`](.specify/memory/constitution.md) — that file is
the source of truth, and this one only points at it. Principles I and II are the
ones you will touch every time: specify before you build, and every requirement
names its test.

- **Adding or changing behaviour?** Run `/speckit-specify`, then `/speckit-plan`,
  `/speckit-tasks`, `/speckit-implement`. The loop is in
  [`specs/README.md`](specs/README.md).
- **Changing existing behaviour?** Read that spec first and update it in the same
  change. Requirement IDs look like `0002-R5` — grep for them. They are permanent
  (Principle I), so never renumber.
- **A spec's Verification table must name real tests**, or an honest `—`
  (Principle II). Naming a test that does not exist is the one thing it exists to
  prevent.
- Specs are directories: `specs/NNNN-slug/spec.md` is what and why,
  `plan.md` is how.

[`task.md`](task.md) is the source of truth for what is done, what is
deliberately not done, and what is known-broken. Check it before reporting
something as missing.

## Commands

```sh
flutter test --exclude-tags golden      # what CI runs; goldens are separate
flutter analyze --fatal-infos --fatal-warnings
dart format lib test tool

flutter test --coverage --exclude-tags golden && \
  dart run tool/check_coverage.dart --min 85

dart run build_runner build              # after editing lib/src/database/tables.dart
flutter gen-l10n                         # after editing an ARB file
flutter test --tags golden               # platform-pinned to macOS
cd test_rules && npm ci && npm test      # security rules; needs JDK 21+
```

All four gates must pass: analyze (zero issues, infos included), tests, coverage
≥ 85%, and — if you touched `*.rules` — the rules suite.

## Architecture in one paragraph

Riverpod 3 for state. `go_router` for navigation, with the guard extracted as a
pure function. Firestore is the source of truth; **Drift is what the UI reads**,
which is what makes the app work offline. Every Firebase SDK singleton sits
behind a provider in `lib/src/core/providers/firebase_providers.dart`, and
anything that touches a platform channel sits behind an interface with a fake
beside it — that is why the whole suite runs with no Firebase project and no
network.

## Hard rules

| Rule | Why |
|---|---|
| Never call `FirebaseAuth.instance` (or friends) outside `firebase_providers.dart` | Every test depends on the seam |
| No inline colours, spacing, radii, or durations | Use `lib/src/app/theme/` — a rebrand is one enum value |
| No hard-coded user-visible strings | Add to **both** `app_en.arb` and `app_es.arb`; CI fails otherwise |
| Every interactive widget gets a `ValueKey` | Integration drivers target keys, not coordinates |
| Every icon-only button gets a `tooltip` | It is the accessibility label; `test/a11y/` fails without it |
| Repositories throw typed failures with a `code` | The UI maps the code to localised copy, not the message |
| Changing a Firestore path? Update the rules **and** `test_rules/` | Otherwise the write is denied and swallowed silently |
| Justify every lint relaxation and coverage exclusion, in place | A bare disable is a TODO nobody finds |

## Traps that have already bitten

These are real bugs that were found and fixed here. Do not reintroduce them.

- **A provider must not write to a provider it watches.** It re-enters its own
  build and hangs the suite. Derive instead. → [0018](specs/0018-pagination/spec.md)
- **Do not `ref.read` an auto-dispose provider from a scroll handler** or any
  callback outside the widget lifecycle. It builds and tears down on every call.
- **`async*` over a never-closing broadcast stream cannot be cancelled.** Use
  `Stream.multi` with an explicit `onCancel`. → [0001](specs/0001-authentication/spec.md)
- **`Timestamp.toDate()` returns local time.** Normalise to UTC at every
  boundary. → [0002](specs/0002-notes-sync/spec.md)
- **Use `is` checks, not casts, on remote data.** One bad document must not break
  a list.
- **A perpetual `CircularProgressIndicator` makes `pumpAndSettle` time out.**
  If a screen can show one, resolve the providers first or pump manually.
- **Length limits must be checked in the domain**, not left to Drift (which
  throws out of the save) or the rules (which reject it after the local write
  succeeded, leaving it queued forever).
- **Fail open on ambiguity** in anything that can lock a user out.
  → [0021](specs/0021-app-updates/spec.md)

## Testing

`test/helpers/test_helpers.dart` provides `TestHarness`, which wires every fake:

```dart
final harness = TestHarness.create(
  user: testUser(),                      // omit to start signed out
  network: NetworkStatus.offline,
  environment: AppEnvironment.staging,
  onboardingCompleted: false,
);
await harness.pumpApp(tester);
```

Anything the harness already overrides has a **named parameter** — `mockAuth`,
`config`, `packageInfo`, `database`, `push`. Passing one via `extraOverrides`
double-overrides the provider, which Riverpod rejects.

Riverpod 3 auto-disposes providers with no listeners, so an async provider you
only `read` will hang. Use `harness.keepAlive(provider)` first. For
repository-level tests, construct the repository directly instead — simpler and
avoids the whole issue.

Security rules **cannot** be tested in Dart (the fakes support neither custom
functions nor `request.resource`). They run against the real emulator in
`test_rules/`. → [0016](specs/0016-emulator-and-rules/spec.md)

## Before you say "done"

- All four gates pass.
- The spec you touched has its Verification table updated, naming the test by its
  **exact** name. `test/specs/verification_test.dart` resolves every row against
  the filesystem, so an approximate name fails the suite — which is the intended
  behaviour, not an inconvenience to work around.
- If you renamed a test, you updated the row that names it.
- New strings exist in every ARB file.
- `task.md` reflects anything you left incomplete — say so plainly rather than
  omitting it.
