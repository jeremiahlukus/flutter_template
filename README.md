# flutter_template

A Flutter starter that is actually finished. Firebase auth and storage, an
offline-first Drift cache, a tested route guard, a real design system,
flavours, crash reporting, localisation, onboarding — and CI that refuses to go
green below 85% coverage.

> **Start here.** This project is **spec-driven**: behaviour is written down in
> [`specs/`](specs/) before it is built, and every requirement names the test that
> proves it. Before changing anything, read
> [How this template is developed](#how-this-template-is-developed) and the spec
> for the area you are touching. [`task.md`](task.md) tracks what is done, what is
> deliberately not done, and what is known-broken.
>
> **Working with a coding agent?** [`CLAUDE.md`](CLAUDE.md) (aliased as
> [`AGENTS.md`](AGENTS.md)) is the condensed version: the hard rules, the four
> gates, the `TestHarness` API, and the traps that have already caused real bugs
> in this codebase.

| | |
|---|---|
| **Tests** | 968 Dart + 48 security-rules + 12 goldens |
| **Line coverage** | 93.7% (85% floor, enforced in CI) |
| **Analyzer** | `very_good_analysis`, zero issues, `--fatal-infos` |
| **Flutter / Dart** | 3.44.0 / 3.12 |
| **Specs** | 23, every requirement mapped to a named test |

---

## What this app actually is

A working notes app, built to be the scaffolding you delete. Two screens of real
product sitting on top of the plumbing every app needs.

**The product:** sign in with email, write notes, edit and delete them. Notes
live in Firestore under your account and are cached locally, so the list is
instant and keeps working offline. A profile screen lets you rename yourself and
set an avatar. A settings screen covers theme, accent colour, language, push,
analytics consent, and manual sync.

**Why notes?** It is the smallest domain that still exercises everything hard:
a per-user Firestore collection, an offline cache with two-way sync, a paged
list, file upload, and a form. Every pattern you would otherwise have to invent
is already worked out against a feature you can read in ten minutes.

### The one flow worth understanding

Saving a note is where most of the design lives:

```
User taps Save
  └─ NotesController.save()          state → loading
       └─ NotesRepository.save()
            ├─ reject if over the length limits        → NotesFailure
            ├─ write to Drift with pendingSync: true   ← UI updates from here
            ├─ write to Firestore
            │    ├─ success → clear pendingSync
            │    └─ failure → leave it queued, do NOT throw
            └─ return
```

The list renders from **Drift**, never from Firestore directly. That single
decision is why the app works offline, why the UI never waits on a network
round-trip, and why `sync()` has to push before it pulls — a note created offline
would otherwise be deleted as "not on the server" before it was ever sent.

### Where things live

| I want to… | Go to |
|---|---|
| Add a screen | `lib/src/features/<name>/presentation/`, then `lib/src/routing/app_routes.dart` |
| Add a route | `AppRoute` enum → `app_router.dart` → guard truth table in `test/routing/redirect_test.dart` |
| Touch a Firebase SDK | **Don't.** Add a provider in `lib/src/core/providers/firebase_providers.dart` |
| Add a string | `lib/src/l10n/arb/app_en.arb` **and** `app_es.arb`, then `context.l10n.key` |
| Add a colour / spacing / radius | `lib/src/app/theme/` — never inline |
| Add a local table | `lib/src/database/tables.dart`, then `dart run build_runner build` |
| Change a Firestore path | The repository **and** `firestore.rules` **and** `test_rules/` |
| Add a preference | `lib/src/features/settings/setting_keys.dart` + a controller |
| Call your own backend | `lib/src/core/network/` — `ref.read(apiClientProvider)` |

---

## ⚠️ Read this before you run it

**The app needs a Firebase project.** Until you configure one it still launches —
it shows a setup screen naming the exact commands, rather than crashing:

```
┌────────────────────────────────────────────────┐
│  🔥                                            │
│  Firebase setup required                       │
│                                                │
│  This app needs Firebase to run. Auth, notes,  │
│  and file storage all depend on it, so nothing │
│  works until it is configured.                 │
│                                                │
│  Run these once, from the project root:        │
│  ┌──────────────────────────────────────┬───┐  │
│  │ dart pub global activate flutterfire… │ ⧉ │  │
│  ├──────────────────────────────────────┼───┤  │
│  │ flutterfire configure                 │ ⧉ │  │
│  └──────────────────────────────────────┴───┘  │
│  Then stop and rerun the app.                  │
│                                                │
│  ▸ Error details                               │
└────────────────────────────────────────────────┘
```

The placeholder `lib/firebase_options.dart` throws a named
`FirebaseNotConfigured`, and `bootstrap()` catches it. Shipping fake credentials
instead would produce confusing `FirebaseException`s at the first auth call, far
from the actual cause. → [spec 0015](specs/0015-first-run.md)

```sh
flutter pub get                         # also runs gen-l10n
dart run build_runner build             # Drift codegen

dart pub global activate flutterfire_cli
flutterfire configure                   # ← required; regenerates firebase_options.dart

flutter run                             # dev flavour by default
flutter run --dart-define=APP_ENV=staging
```

Two related notes:

- **`tool/stub_firebase_options.dart` is for CI only.** It writes obviously-fake
  credentials so the build matrix can prove the app *compiles* without secrets in
  the repo. Never run it locally; you will overwrite your real config.
- **The tests need none of this.** `flutter test` works on a fresh clone with no
  Firebase project and no network. See [Testing](#testing).
- **iOS targets 15.0**, raised from Flutter's scaffold default of 13.0 because
  `cloud_firestore` requires it. Keep `ios/Podfile` and the Xcode
  `IPHONEOS_DEPLOYMENT_TARGET` in step if you change it.

Then work through [`task.md`](task.md) Milestone 0 to make the template yours
(rename the package, set the bundle id, deploy the security rules).

Start with the rename, and use the tool rather than a `sed` one-liner:

```sh
dart run tool/rename_package.dart your_app     # --dry-run to preview
```

A bare find-and-replace leaves the project **not analyzing** — roughly 65
`directives_ordering` errors, because `package:your_app/...` does not sort where
`package:flutter_template/...` did. The tool replaces, then runs
`dart fix --code=directives_ordering` and `dart format`.

It deliberately does **not** rename `AppDatabase.databaseName`. That constant is
the on-disk SQLite file name, and if this template is replacing an app you have
already shipped, changing it points the new build at an empty database beside the
real one — every user's local data still on disk with nothing referencing it, and
nothing thrown. Milestone 0 has the decision.

---

## Feature matrix

Everything below is implemented and tested unless the Status column says
otherwise.

| Feature | Status | Spec | Entry point |
|---|---|---|---|
| Email auth (sign in / up / reset) | ✅ | [0001](specs/0001-authentication.md) | `features/auth/` |
| Notes CRUD | ✅ | [0002](specs/0002-notes-sync.md) | `features/notes/` |
| Offline cache + two-way sync | ✅ | [0002](specs/0002-notes-sync.md) | `notes_repository.dart` |
| Auto-sync on reconnect | ✅ | [0011](specs/0011-connectivity.md) | `ReconnectSyncCoordinator` |
| Pagination | ✅ | [0018](specs/0018-pagination.md) | `core/paging/` |
| Local database | ✅ | [0003](specs/0003-local-persistence.md) | `database/` |
| Routing + auth guard | ✅ | [0004](specs/0004-routing.md) | `routing/` |
| Onboarding | ✅ | [0014](specs/0014-onboarding.md) | `features/onboarding/` |
| Design system (tokens, brands) | ✅ | [0008](specs/0008-design-system.md) | `app/theme/` |
| Dark mode + accent picker | ✅ | [0008](specs/0008-design-system.md) | `settings_screen.dart` |
| Localisation (en, es) | ✅ | [0013](specs/0013-localisation.md) | `l10n/arb/` |
| Analytics + consent gate | ✅ | [0005](specs/0005-analytics.md) | `core/analytics/` |
| Crash reporting | ✅ | [0010](specs/0010-error-reporting.md) | `core/errors/` |
| Flavours (dev/staging/prod) | ✅ | [0009](specs/0009-environments.md) | `core/config/` |
| File upload + image picking | ✅ | [0019](specs/0019-media.md) | `features/storage/` |
| HTTP client for your backend | ✅ | [0017](specs/0017-api-client.md) | `core/network/` |
| Forced-update gate | ✅ | [0021](specs/0021-app-updates.md) | `features/update/` |
| Push notifications (Dart side) | ⚠️ needs native setup | [0020](specs/0020-push-notifications.md) | `features/push/` |
| Deep links | ⚠️ declared, unverified on device | [0004](specs/0004-routing.md) | manifest + `Info.plist` |
| Security rules + emulator | ✅ | [0016](specs/0016-emulator-and-rules.md) | `test_rules/` |
| Accessibility suite | ✅ | [0022](specs/0022-accessibility.md) | `test/a11y/` |
| Golden tests | ✅ | [0023](specs/0023-visual-regression.md) | `test/goldens/` |
| App icons + splash | ⚠️ config only, no artwork | — | `assets/branding/` |
| Search | ❌ not built | — | — |
| Social sign-in | ❌ not built | [0001](specs/0001-authentication.md) | — |

---

## What you get

**Firebase** — Auth via `firebase_ui_auth` (sign-in, sign-up, password reset, no
custom form to maintain), Firestore, Cloud Storage, Analytics, and Crashlytics.
Every SDK singleton sits behind a Riverpod provider, which is what makes the
whole app testable with no Firebase project.

**Offline-first data** — Drift caches Firestore locally. Reads never touch the
network; writes land locally first and stay flagged until the server confirms.
Sync pushes before it pulls and never clobbers a pending local edit — the two
mistakes that silently lose user data. Queued writes go out automatically when
the network returns.

**A real design system** — spacing, radius, duration, and breakpoint tokens;
success/warning/info colours as a `ThemeExtension` (WCAG AA verified in a test);
six brand presets that re-derive the entire light *and* dark theme from one seed;
an explicit type scale; every Material component themed. Rebranding is one enum
value. → [Theming](#theming)

**Flavours** — `--dart-define=APP_ENV=dev|staging|prod` drives one `AppConfig`.
Dev sends nothing to production analytics or Crashlytics. Non-production builds
carry a corner banner, so nobody demos against the wrong backend.

**Localisation** — `gen-l10n` with English and Spanish, ICU plurals, a persisted
locale picker, and CI that fails on any untranslated or stale message. Every
user-visible string is already in an ARB file, so you are not retrofitting this
later.

**Onboarding** — a three-page intro, once per device, gated *before* auth.

**Routing** — `go_router` with the route guard extracted as a pure function, so
the whole truth table (every route × signed-in/out × auth-resolved/not ×
onboarded/not) is covered by fast unit tests instead of slow widget tests.

**Shared UI kit** — `AsyncValueView` plus empty/error/loading states, so a screen
body is one widget instead of a four-branch switch. Every interactive widget
carries a stable `ValueKey`.

**Analytics** — screen views logged from a router observer, so a new screen is
tracked the moment it has a route. The opt-out in Settings is actually honoured,
via a decorator, so no call site has to remember. Every call swallows its own
failures; analytics is never the reason a save fails.

**Your own backend too** — a typed `ApiClient` over Dio wired to
`AppConfig.apiBaseUrl`. Every failure arrives as an `ApiFailure` with a
`isRetryable` flag, the Firebase ID token is attached per-request, and retries
back off exponentially on idempotent methods only — never a POST.

**Offline-first, and paged** — the notes list is a bounded query with a growing
window, so it stays fast at 2,000 rows. The Firestore pull is keyset-paged.

**Push notifications** — opt-in only (prompting unasked is how you get denied
forever), with token-rotation handling and notification taps opening validated
routes.

**A forced-update gate** — a remote version floor that blocks unsupported builds
and fails open on every ambiguous case, because it is also a kill switch.

**Accessibility, asserted** — tap targets, labels, contrast, and 2× text scale
across every screen. Writing these found four real bugs.

**The emulator suite** — `firebase.json` plus opt-in redirection, and **36
security-rules tests** running against the real emulator in CI. The rules are no
longer just assertion.

**Quality gates** — formatting, codegen freshness, ARB parity, analysis, tests,
a coverage floor, security rules, platform-pinned goldens, and an
Android/iOS/web build matrix.

---

## Layout

```
lib/
  main.dart                     one line; calls bootstrap
  bootstrap.dart                Firebase init + error handlers
  firebase_options.dart         placeholder; throws until configured
  src/
    app/
      app.dart                  root widget
      theme/                    tokens, semantic colours, brands, ThemeData
      widgets/                  shared states and banners
    core/
      analytics/                AnalyticsService + consent gate + doubles
      config/                   AppEnvironment, AppConfig, version
      connectivity/            ConnectivityService + fake
      errors/                   ErrorReporter + localised failure copy
      logging/                  AppLogger
      network/                  ApiClient, typed failures, interceptors
      paging/                   PageWindow — the growing-window primitive
      providers/                every Firebase singleton, behind a seam
    database/                   Drift schema and queries
    features/
      auth/                     repository, AppUser, sign-in + profile
      notes/                    the reference feature: Firestore + Drift
      onboarding/               first-run intro
      push/                     PushService, token registration, tap routing
      settings/                 preferences persisted in Drift
      storage/                  Cloud Storage + image picking, with doubles
      update/                   version floor and the update gate
    l10n/
      arb/                      app_en.arb, app_es.arb  ← the source of truth
      generated/                gen-l10n output
    routing/                    routes, guard, analytics observer

specs/                          14 numbered specs; requirements → tests
task.md                         milestones, known gaps, next features
flutter-skill.md                on-device flows for what widget tests can't reach
test_rules/                     Node: security-rules tests vs the emulator
tool/check_coverage.dart        the coverage gate
tool/coverage_report.dart       its parser, unit tested
tool/main_dev.dart              QA entrypoint (flutter_skill)
tool/stub_firebase_options.dart CI-only credential stub
l10n.yaml                       gen-l10n config
firebase.json                   emulator ports and rule file paths
firestore.rules, storage.rules  mirror the client's path scheme
assets/branding/                your icon and splash art goes here
```

---

## Testing

```sh
flutter test
flutter test --coverage && dart run tool/check_coverage.dart --min 85
```

The suite needs **no Firebase project and no network**. That is the design
constraint everything else follows from:

| Layer | Test double |
|---|---|
| Auth | `firebase_auth_mocks` → `MockFirebaseAuth` |
| Firestore | `fake_cloud_firestore` → `FakeFirebaseFirestore` |
| Drift | `NativeDatabase.memory()` |
| Cloud Storage | `InMemoryStorageRepository` (no fake exists; this template ships one) |
| Analytics | `RecordingAnalyticsService` |
| Crashlytics | `RecordingErrorReporter` |
| Connectivity | `FakeConnectivityService` (drive `goOffline()` / `goOnline()`) |
| HTTP | Dio's `HttpClientAdapter` seam — the real interceptor chain runs |
| Image picking | `FakeImageSourceService` |
| Push | `FakePushService` (drive permission, tokens, taps) |
| Package info | injected `PackageInfo` |
| Firebase Core | `setupFirebaseCoreMocks()` |

**Security rules are the exception.** They cannot be tested in Dart — the fakes
support neither custom functions nor `request.resource`, and these rules use
both. `test_rules/` runs them against the real emulator instead:

```sh
cd test_rules && npm ci && npm test
```

Needs **JDK 21+** — the emulators are JVM processes and firebase-tools 15 dropped
older runtimes. CI pins 21 for that job; the Android build job stays on 17, which
is what its toolchain wants.

`test/helpers/test_helpers.dart` wires all of it into one `TestHarness`, so a
widget test is three lines:

```dart
final harness = TestHarness.create(user: testUser());
await harness.pumpApp(tester);
expect(find.text('Notes'), findsOne);
```

Named parameters cover everything the harness already overrides — `environment`,
`config`, `network`, `packageInfo`, `mockAuth`, `database`, `onboardingCompleted`.
Supplying one of those through `extraOverrides` instead would override the same
provider twice, which Riverpod rejects.

```dart
// Offline, staging, first run.
final harness = TestHarness.create(
  user: testUser(),
  network: NetworkStatus.offline,
  environment: AppEnvironment.staging,
  onboardingCompleted: false,
);
```

### Coverage exclusions

Six patterns are excluded from the total, each justified in
`tool/check_coverage.dart`:

| Excluded | Why |
|---|---|
| `*.g.dart`, `*.freezed.dart`, `generated_plugin_registrant.dart` | Build output. Tested through the code that uses it. |
| `firebase_options.dart` | Placeholder that throws until configured. |
| `database/tables.dart` | Drift's column getters (`text()()`) are evaluated by the **generator** at build time and are unreachable at runtime, so they report 0% however well the schema is tested. The schema is covered in `test/database/tables_test.dart`, which asserts on the generated table info. |

Keep that list short. Every entry is a place the real number can drift while the
gate stays green.

Coverage fell from 97.9% to 93.9% when the platform-bound features landed
(`image_picker`, `firebase_messaging`, emulator redirection). Those lines reach a
platform channel and cannot execute under `flutter test` — the interfaces in front
of them are fully covered, and the doubles behind those interfaces are what every
other test uses. Excluding them would flatter the number without adding
confidence.

---

## Theming

Everything visual is decided in `lib/src/app/theme/`. A screen never constructs a
colour, a radius, or a duration inline.

### Rebranding is one value

```dart
enum AppBrand {
  indigo('Indigo', Color(0xFF3D5AFE)),   // ← change the seed
  ...
  static const fallback = AppBrand.indigo;
}
```

Material 3 derives the entire scheme — light *and* dark, every surface, every
container — from that one colour. Six presets ship, and the picker in Settings
re-seeds the theme in place, which is the fastest way to check the design system
actually holds together.

### Tokens, not magic numbers

```dart
Padding(padding: AppSpacing.pagePadding)                  // 16
SizedBox(height: AppSpacing.lg)                            // 24
BorderRadius: AppRadius.mdAll                              // 12
AnimatedContainer(duration: AppDurations.quick)            // 200ms
```

Durations are named by *intent* (`instant`, `quick`, `moderate`), so "make it
snappier" is one edit here rather than a hunt through the widget tree. The
spacing scale is tested to be strictly ascending and whole-pixel.

### Status colours Material does not give you

`ColorScheme` has `error` and nothing else. Reaching for `Colors.green` breaks in
dark mode, so success/warning/info live in a `ThemeExtension`:

```dart
final colors = AppSemanticColors.of(context);
Container(color: colors.successContainer);
Text('Saved', style: TextStyle(color: colors.onSuccessContainer));
```

Theme-aware, animated with the rest of the theme, and **every foreground/background
pair is verified against WCAG AA (4.5:1) in a test**. A status colour nobody can
read is worse than no status colour.

`AppSemanticColors.of` falls back to the light palette rather than throwing, so a
missing extension degrades to readable colours instead of crashing a screen.

### Responsive by breakpoint, not by guesswork

```dart
if (AppBreakpoints.of(context).isWide) { ... }

ConstrainedBox(
  constraints: BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
  child: ...,
)
```

Breakpoints match Material 3's window size classes. Wide windows get a centred
column — a text field spanning a desktop monitor is measurably harder to read.

### Component themes

`AppTheme` themes app bars, inputs (with a visibly emphasised focus state), all
four button types, cards, chips, dialogs, bottom sheets, list tiles, snack bars,
dividers, progress indicators, navigation bars, tooltips, and page transitions.
Every tappable control is tested to meet the 48dp Material touch-target minimum.

The type scale is spelled out rather than left to the default, so swapping in
`google_fonts` is a single edit in `AppTheme._textTheme`.

→ [spec 0008](specs/0008-design-system.md)

---

## Design decisions worth knowing

These are the non-obvious ones — each is a trap that cost real debugging time, and
each is now pinned by a regression test. If you are about to "simplify" one of
them, read this first.

### `authStateChanges()` uses `Stream.multi`, not `async*`

An `async*` generator suspended in `await for` over a broadcast stream that never
closes **cannot be cancelled**. `cancel()` hangs forever and the subscription
leaks — in this app, the router's listener. `Stream.multi` provides an explicit
`onCancel` that forwards straight upstream.

The same method also **seeds its current value**, because
`FirebaseAuth.authStateChanges()` is a broadcast stream: a subscriber arriving
after the SDK has settled gets nothing until the *next* transition, which leaves
the router stuck in its loading state on a warm start. Consecutive duplicates are
filtered so the seed costs nothing when the SDK does replay.

→ [spec 0001](specs/0001-authentication.md)

### `updatedAt` is always UTC, and Drift stores datetimes as text

`Timestamp.toDate()` returns **local** time. Without explicit normalisation, a
note round-tripped through Firestore compares unequal to itself, and every
change-detection check based on `updatedAt` becomes unreliable.

Drift compounds this: its default datetime format is unix **seconds**, which
truncates sub-second precision and drops the timezone. Since `updatedAt` is the
basis of sync conflict resolution, the default quietly corrupts the one field the
sync logic depends on. `DriftDatabaseOptions(storeDateTimeAsText: true)` fixes it.

→ [spec 0002](specs/0002-notes-sync.md), [spec 0003](specs/0003-local-persistence.md)

### Sync pushes before it pulls, and never clobbers a pending write

Two ways a naive offline cache silently loses data:

1. **Pull-first** deletes a note created offline as "not on the server" before
   ever sending it.
2. **Blind cache replacement** discards local edits the server has not seen.

The second invariant lives in `AppDatabase.replaceNotes` — in the *database*
layer, not the repository — so no future caller can forget it.

A delete is deliberately asymmetric with a save: a failed remote delete still
removes the local copy, because a note that reappears after the user deleted it is
more alarming than a tombstone that takes a while to propagate.

→ [spec 0002](specs/0002-notes-sync.md)

### Nothing outside `firebase_providers.dart` may touch a Firebase singleton

Every test in the suite depends on this holding. If you need a new Firebase
service, add a provider — do not call `.instance` from a feature.

→ [spec 0001](specs/0001-authentication.md)

### Reading remote documents tolerates bad data

`Note.fromFirestore` uses `is` checks rather than casts. A stray number where a
string belongs is data to ignore, not an exception to propagate — one malformed
document should not break the whole list.

### Connectivity seeding, and a synchronous-throw trap

`PlatformConnectivityService` seeds its stream so a late subscriber is not left
waiting for the next change — the same fix as the auth stream, and it uses
`Stream.multi` for the same cancellation reason.

The subtle part: the first version chained
`checkConnectivity().then(...).catchError(...)`. A platform implementation that
throws **synchronously** escapes before `catchError` is attached, so the
subscriber received *no seed at all*. Routing through `currentStatus()`, which
has a real `try`/`catch`, fixes it. A test pins this.

Status is also de-duplicated: switching wifi→ethernet is a platform event but not
a status change, and re-emitting would re-trigger every reconnect listener.

### Reconnect sync fires on the transition, never the initial emission

`ReconnectSyncCoordinator` tracks the previous status and only syncs on a genuine
offline→online transition. Syncing on the initial emission would hit Firestore on
every cold start. A `_syncing` flag stops a flapping connection starting
overlapping syncs.

### Analytics consent is a decorator, and `setUserId` is special

`ConsentGatedAnalyticsService` wraps the real implementation, so consent is
checked in exactly one place and a new feature cannot forget it. The check is a
**callback**, not a captured bool, so a mid-session opt-out takes effect on the
very next event.

`setUserId` is forwarded even when disabled — with a null id. Suppressing the
call instead would leave the previous user attached to the analytics session,
which is the opposite of honouring an opt-out.

### The environment fails towards dev, never towards prod

`AppEnvironment.decode` resolves an unrecognised value to `dev`. A typo in a CI
variable should produce a harmless build, not one that believes it is production
and starts writing real analytics and crash reports.

### Onboarding defaults to "already seen" while loading

`onboardingCompletedProvider` returns **true** until the stored flag resolves.
A genuinely first-run user waits one invisible frame; defaulting the other way
would flash the intro at every returning user on every cold start.

### Domain objects take their fallback copy as an argument

`Note.titleOr(fallback)` rather than `Note.displayTitle` returning a hard-coded
`'Untitled note'`. A domain object has no `BuildContext`, so the localised
placeholder has to come from the UI layer. `displayTitle` survives for logs and
`toString`.

### A paged reactive list grows a window; it does not accumulate pages

Drift streams re-emit on every write, so the usual "append the next page to a
list" approach fights the query. `PageWindow` instead tracks *how many rows the
UI wants*, and the query re-runs bounded to that.

It deliberately holds **no total**. Whether more exists is already implied by the
result — a query returning fewer rows than the window has hit the end — so
`hasMoreAfter(loaded)` needs no second query and no second source of truth.

Three bugs came from getting this wrong first, all worth knowing:

1. A count provider **pushed** its total into a window provider that the notes
   provider also watched. A provider writing to a provider it watches re-enters
   its own build; the whole suite hung.
2. The scroll handler called `ref.read` on an auto-dispose provider — building
   and tearing down a Drift stream on *every scroll frame*.
3. A trailing "loading more" spinner shown whenever more exists sits parked at
   the bottom of every long list, implying work that is not happening — and
   stops `pumpAndSettle` from ever settling. With a SQLite-backed list a page is
   never genuinely in flight, so there is no spinner at all.

### Retries never replay a POST

`ApiFailureKind.isRetryable` lives on the failure, so the retry interceptor and a
retry button in the UI can never disagree. On top of that,
`RetryInterceptor.idempotentMethods` excludes POST and PATCH: replaying a POST
can create two records or double-charge a card.

The ID token is read per-request rather than cached — Firebase already caches it
until near expiry, so a local cache would only add a class of 401 that looks like
a backend bug.

### The update gate fails open on every ambiguous case

An unparseable version, a missing policy document, a permissions slip, an offline
launch — all resolve to "no update information". This is a remote kill switch, so
the only path to blocking a user is an explicitly-parsed floor above an
explicitly-parsed current version.

### Push has two gates, not one

The OS answers "may we send?"; the stored preference answers "does the user want
us to?". Both must be true to register a token. Conflating them means a user who
turns notifications off in-app keeps receiving them until they find system
settings.

Token rotation is handled explicitly. Register once at sign-in and a reinstall or
restore silently stops delivery, with no error anywhere.

### Security rules could not be tested in Dart, so they are not

`fake_firebase_security_rules` supports neither custom functions nor
`request.resource`, and these rules use both — verified by experiment: the real
file parses and then denies the owner's own read. Rewriting production rules to
suit a limited fake would trade real security for testability, so `test_rules/`
runs the real emulator instead.

### A new Firestore path needs a new rule, or it fails silently

Every path the app touches must be matched by `firestore.rules`, and the
catch-all at the bottom denies everything else. Two features shipped broken
because of this: push-token registration wrote to `users/{uid}/devices/{token}`
and the update gate read `config/app_update`, neither of which any rule matched.

The reason it went unnoticed is worth internalising: **both call sites swallow
their errors on purpose.** A failed token registration is not worth interrupting
the user for, and the update policy fails open by design. So the writes were
denied, the catch blocks logged a warning nobody read, and both features were
simply inert in production while every Dart test passed — because
`FakeFirebaseFirestore` does not apply rules unless you ask it to.

If you add a Firestore path: add the rule, and add a case to `test_rules/`.
That suite is the only thing that would have caught this.

### Nothing in `lib/` may import a native-only library

One `dart:ffi` import reachable from `lib/` makes `flutter build web` fail to
compile, and **`flutter analyze` says nothing about it** — the first sign is a red
build matrix. That happened here: `AppDatabase.memory()` was a convenience
factory in `lib/`, and `package:drift/native.dart` dragged `dart:ffi` in behind
it. The web build had never worked.

The in-memory database now lives in `test/helpers/test_database.dart`, and CI
greps `lib/` for `dart:ffi`, `dart:io`, `dart:mirrors`, and `drift/native.dart`
before it bothers analyzing. Use `drift_flutter`'s `driftDatabase()` in
production code — it handles every platform, web included.

### Every interactive widget carries a `ValueKey`

Not decoration. It is what lets integration drivers target a specific row instead
of guessing at screen coordinates, which is the largest source of flaky manual QA.
The full key map is in [`flutter-skill.md`](flutter-skill.md).

### Lint relaxations are all justified in place

`analysis_options.yaml` carries a comment per disabled rule explaining why it
cannot or should not be satisfied — e.g. `prefer_initializing_formals` is
unsatisfiable because Dart forbids named parameters starting with `_`, and
`specify_nonobvious_property_types` because Riverpod 3 keeps its provider types in
a separate `misc.dart` export. A bare disable is a TODO in disguise.

---

## Known limitations

Things that will bite you, documented so you do not rediscover them.

### `firebase_auth_mocks` and `firebase_ui_auth` cannot be driven together

On a successful sign-in, `firebase_ui_auth` reads
`UserCredential.additionalUserInfo`; `firebase_auth_mocks` throws
`UnimplementedError` from that getter. **The sign-in form therefore cannot be
submitted in a widget test.**

The workaround is structural: the analytics side effects live in the static
handlers `TemplateSignInScreen.recordSignIn` / `.recordSignUp`, which are unit
tested directly. Everything else about the screen (rendering, branding, layout at
three widths, the signed-in redirect) is covered normally.

The same package also **cannot model an anonymous account being upgraded to a
permanent one** — and it fails by crashing, not by returning something wrong.

`MockUser.linkWithCredential` returns `MockUserCredential(false, mockUser: this)`,
while `MockUserCredential` asserts `mockUser.isAnonymous == isAnonymous`. Link an
anonymous user and those contradict, so the call throws:

```
_AssertionError: 'package:firebase_auth_mocks/src/mock_user_credential.dart':
Failed assertion: line 10 pos 16:
'mockUser == null || mockUser.isAnonymous == isAnonymous': is not true.
```

(Verified against `firebase_auth_mocks` 0.15.2.) `MockUser._isAnonymous` is also
`final` with no setter, so even without the assert the user could never transition.
Do not read the crash as a bug in your own linking code.

If your app offers "try it without an account, sign up later", the link step is
not unit-testable with these fakes. The options, in the order worth trying:

1. **Test the seam, not the SDK.** Put the linking behind your own method on
   `AuthRepository` and fake *that* — the same move already used for
   `StorageRepository`. Your orchestration gets covered; the one SDK call does not.
2. **Test it against the Firebase Auth emulator**, alongside the Firestore rules
   suite in `test_rules/`. Real linking semantics, at the cost of an emulator run.
3. **Cover it on-device**, per [`flutter-skill.md`](flutter-skill.md).

What does not work is asserting on it in a widget test and believing the result.

### `desktop_webview_auth` blocks Swift Package Manager, and you cannot drop it

Every `flutter run` and `flutter build` for iOS and macOS prints:

```
The following plugins do not support Swift Package Manager for ios:
  - desktop_webview_auth
This will become an error in a future version of Flutter.
```

It is **not** optional and not something the template pulled in carelessly.
`firebase_ui_auth` depends on `firebase_ui_oauth`, which depends on
`desktop_webview_auth`, so it arrives transitively from the one auth UI package:

```
firebase_ui_auth → firebase_ui_oauth → desktop_webview_auth
```

Confirm it yourself with `flutter pub deps --style=compact | grep desktop_webview_auth`.

Consequences to plan for:

- **You cannot migrate this app to Swift Package Manager** while `firebase_ui_auth`
  is a dependency. If SPM-only is a requirement, budget for replacing
  `firebase_ui_auth` with hand-rolled auth screens over `firebase_auth` — the
  package is a convenience, and `TemplateSignInScreen` is the only place it is used.
- **The warning becomes an error in a future Flutter release.** When it does, this
  stops being noise and starts being a broken build, on Flutter's schedule rather
  than yours.
- CocoaPods still works today, so nothing is blocked right now. Do not spend time
  trying to silence the warning; there is no flag for it.

`firebase_ui_oauth_google` is separately not included — social sign-in needs
per-app provider setup — but adding it changes nothing here. The transitive
dependency is already present either way.

### There is no fake for Cloud Storage

Unlike Auth and Firestore, nothing equivalent exists. `StorageRepository` is
therefore an interface with two implementations: `FirebaseStorageRepository`
(tested with `mocktail`) and `InMemoryStorageRepository` (a `Map`, with a
`failWith` hook for error paths).

One test compares the two implementations' path output directly. That is the only
cheap defence against the client and `storage.rules` drifting apart — if they do,
uploads land somewhere the rules do not protect, and nothing fails loudly.

### `flutter_skill`'s tap overlay throws on every tap

The QA harness's own tap-visualisation painter crashes:

```
'dart:ui/painting.dart': Failed assertion: line 346 pos 12: is not true.
#2  Color.withOpacity
#3  _ParticleEffectPainter._drawActionParticles (package:flutter_skill/flutter_skill.dart:4199)
```

It computes `withOpacity(0.8 * (1 - progress))`, which goes negative once
`progress` exceeds 1, and `withOpacity` asserts its argument is within 0..1. The
result is an "Uncaught framework error" box per frame for the duration of the
animation, on **every** driven tap.

Nothing in this app is involved — it is `flutter_skill`'s indicator overlay
painting itself. It matters only because it looks exactly like an app crash in
the run log while you are trying to read that log for real failures. Turn the
overlay off before driving a flow:

```
ext.flutter.flutter_skill.disableIndicators
```

or pass `FlutterSkillBinding.ensureInitialized(autoEnableIndicators: false)` in
`tool/main_dev.dart`. Verified against `flutter_skill` 0.9.36.

Two smaller quirks from the same package, so you do not misdiagnose them as
missing keys: `inspectInteractive` reports the route *underneath* a pushed
screen, and it does not resolve a tappable `TextSpan` inside a `RichText` (the
"Register" link on the sign-in screen). Use `getTextContent` for the former and
`tapAt` for the latter.

### Widget tests and `pumpAndSettle`

A `CircularProgressIndicator` is a perpetual animation, so `pumpAndSettle` times
out rather than settling. `TestHarness.pumpApp` resolves the async providers the
first frame reads *before* pumping. Tests that deliberately assert on a loading
state pump the screen directly instead.

Relatedly: `MockUser` substitutes a live imgur URL when `photoURL` is null, and a
`NetworkImage` in a widget test fails with an HTTP 400. `testUser()` supplies a
`memory://` URL so the same code path runs offline.

---

## Deliberately not done

Tracked here rather than quietly omitted. The full list, with notes on how to
close each one, is [`task.md`](task.md) Milestone 5.

| Gap | State |
|---|---|
| **Spanish is unreviewed** | Grammatical, but written without a native speaker. Review before shipping to a Spanish market. |
| **No RTL locale** | Both shipped locales are LTR, so no RTL layout pass has been done. |
| **Security rules** | `firestore.rules` and `storage.rules` mirror the client's paths, but **nothing executes them**. The Firebase emulator suite is the honest answer. |
| **On-device flows** | [`flutter-skill.md`](flutter-skill.md) documents the manual flows; **none has been run**. Every result cell reads `⏳ NOT RUN` and should stay that way until someone actually runs it. |
| **Schema migrations** | There is one schema version, so nothing to migrate. Add `drift_dev`'s schema verification the moment there are two. |
| **Integration tests** | Widget tests cover the screens; nothing runs on a device in CI. |
| **Deployment-target drift** | iOS 15.0 / macOS 10.15 satisfy today's Firebase plugins. Nothing fails when an upgrade raises the bar, except the CI build itself. |
| **No sync backoff** | A reconnect triggers one attempt; repeated failure waits for the next transition or a manual tap. |
| **Native push setup** | APNs certificate, entitlements, and the Android notification channel are per-app. The Dart side is complete and tested. |
| **Deep links unverified** | The custom scheme is declared on both platforms but no flow has run on a device. App Links additionally need files hosted on your domain. |
| **Branding is empty** | `assets/branding/` ships no artwork on purpose — a template putting its own logo in your store listing is worse than a build error. |
| **The API client has no caller** | Notes are Firestore-backed, so the typed-method shape is unexercised by a real endpoint. |

Not included, and probably wanted eventually: native flavours (separate app ids
and Xcode schemes), push notifications, golden tests, social sign-in, localised
date formatting, Remote Config. See [`task.md`](task.md) Milestone 7.

---

## How this template is developed

**Spec-first.** Behaviour a maintainer will rely on gets a numbered requirement
in [`specs/`](specs/) *before* the code, and every requirement names the test that
proves it. This is the single most important thing to understand before changing
anything here.

### Why bother

Six months from now, "why does sync push before it pulls?" has an answer you can
read, and a test that fails if someone changes their mind without changing the
spec. The specs are also where the *rejected* options live — which is usually the
part that stops a well-meaning simplification from reintroducing a bug.

### The loop

```
1. WRITE     Add or edit a spec. Number every requirement.
2. REVIEW    Agree the spec before writing code. Cheapest place to be wrong.
3. TEST      Write failing tests that name the requirement IDs.
4. BUILD     Implement until the tests pass.
5. VERIFY    Fill in the spec's Verification table with the real test names.
6. GATE      analyze clean, tests green, coverage ≥ 85%.
```

Step 5 is the one people skip and the one that makes this worth doing. A spec
with an empty Verification table is a wish, not a spec.

### Anatomy of a spec

Every file in `specs/` has the same seven sections:

| Section | What goes in it |
|---|---|
| **Status** | `Draft` / `Accepted` / `Superseded by NNNN` |
| **Context** | The problem. Why the obvious approach is not enough. |
| **Requirements** | Numbered, individually testable. `MUST` / `SHOULD` / `MAY`. |
| **Non-goals** | What this deliberately does not do, so scope creep is visible. |
| **Design** | How it works, and the trade-offs taken. |
| **Verification** | Requirement ID → the test that proves it. |
| **Open questions** | Known unknowns. Empty is a valid answer. |

Requirement IDs are `<SPEC>-R<n>` — `0002-R5` is the fifth requirement of spec
0002. Grep is the traceability tool; there is nothing to install. Start a new spec
from [`specs/templates/spec-template.md`](specs/templates/spec-template.md).

### Reading order

If you are new to the codebase — human or otherwise — read these three first.
They explain most of the surprising decisions:

1. [0002 · Offline-first notes sync](specs/0002-notes-sync.md) — the core data
   flow, and the two ways a naive version silently loses user data.
2. [0007 · Quality gates](specs/0007-quality-gates.md) — what "green" means here.
3. [0008 · Design system](specs/0008-design-system.md) — why there are no inline
   colours or magic numbers.

### The full index

| # | Spec | Covers |
|---|---|---|
| [0001](specs/0001-authentication.md) | Authentication | Auth stream, `AppUser`, failure mapping |
| [0002](specs/0002-notes-sync.md) | Offline-first notes sync | Push-before-pull, pending writes |
| [0003](specs/0003-local-persistence.md) | Local persistence | Drift schema, UTC timestamps |
| [0004](specs/0004-routing.md) | Routing and guards | Redirect truth table, deep links |
| [0005](specs/0005-analytics.md) | Analytics | Consent gate, screen-view observer |
| [0006](specs/0006-file-storage.md) | File storage | Path scheme, in-memory double |
| [0007](specs/0007-quality-gates.md) | Quality gates | Coverage floor, exclusions |
| [0008](specs/0008-design-system.md) | Design system | Tokens, semantic colours, brands |
| [0009](specs/0009-environments.md) | Environments | Flavours, `AppConfig`, banners |
| [0010](specs/0010-error-reporting.md) | Error reporting | Crashlytics behind an interface |
| [0011](specs/0011-connectivity.md) | Connectivity | Offline banner, reconnect sync |
| [0012](specs/0012-ui-kit.md) | Shared UI kit | `AsyncValueView`, empty/error states |
| [0013](specs/0013-localisation.md) | Localisation | ARB parity, plurals, locale picker |
| [0014](specs/0014-onboarding.md) | Onboarding | First-run gate, ordering vs auth |
| [0015](specs/0015-first-run.md) | First run | Launching unconfigured |
| [0016](specs/0016-emulator-and-rules.md) | Emulator and rules | Rules tested for real |
| [0017](specs/0017-api-client.md) | API client | Typed failures, retry policy |
| [0018](specs/0018-pagination.md) | Pagination | Growing window, keyset paging |
| [0019](specs/0019-media.md) | Image picking | Downscale, cancellation |
| [0020](specs/0020-push-notifications.md) | Push notifications | Opt-in, token rotation |
| [0021](specs/0021-app-updates.md) | App updates | Version floor, failing open |
| [0022](specs/0022-accessibility.md) | Accessibility | Tap targets, labels, text scale |
| [0023](specs/0023-visual-regression.md) | Visual regression | Goldens, platform pinning |
| [0024](specs/0024-settings-composability.md) | Settings composability | Public sections, suppressible chrome |

### Working agreements

These are the rules that keep the codebase coherent. Breaking one is not a style
disagreement; it breaks something concrete.

| Rule | What breaks if you don't |
|---|---|
| **Spec first** for behaviour a maintainer will rely on | The reasoning is lost, and the next person re-litigates it |
| **Every requirement names a test** | The spec drifts from the code silently |
| **Never reach for a Firebase singleton** — add a provider | Every test in the suite depends on this holding |
| **No magic numbers in the UI** — use `design_tokens.dart` | A rebrand stops being one enum value |
| **No hard-coded user-visible strings** — use an ARB key | CI fails; and a locale ships half-translated |
| **Justify every lint relaxation and coverage exclusion**, in place | A bare disable is a TODO nobody finds |
| **Failure copy lives in the UI, not the repository** | A repository has no `BuildContext` to localise with |

### Conventions an agent should follow

- **Keys on every interactive widget.** `ValueKey('thing_action')`. Integration
  drivers target keys, not coordinates.
- **Tooltips on every icon-only button.** They are the accessibility label; the
  a11y suite fails without them.
- **Interfaces for anything that touches a platform channel**, with a
  `Fake…`/`Recording…` implementation beside it. That is why the suite needs no
  Firebase project.
- **Exceptions carry a `code` and an English `message`.** The code is the
  contract; the message is a developer-facing fallback.
- **Fail open on ambiguity** in anything that can lock a user out — see
  [0021](specs/0021-app-updates.md).
- **Comments explain *why*, not what.** If a line looks wrong but is deliberate,
  say why it is deliberate.

## Commands

```sh
flutter pub get                      # also runs gen-l10n
dart run build_runner build          # after editing Drift tables
flutter gen-l10n                     # after editing an ARB file

flutter analyze --fatal-infos --fatal-warnings
dart format lib test tool
flutter test --exclude-tags golden   # what CI runs
flutter test --coverage --exclude-tags golden && \
  dart run tool/check_coverage.dart --min 85

flutter test --tags golden                   # platform-pinned
flutter test --tags golden --update-goldens  # after an intentional change

cd test_rules && npm ci && npm test  # security rules vs the emulator

firebase emulators:start             # local backend
flutter run --dart-define=APP_ENV=dev --dart-define=USE_EMULATORS=true

flutter run                                          # dev, real backend
flutter run --dart-define=APP_ENV=staging
flutter build apk --release --dart-define=APP_ENV=prod

dart run flutter_launcher_icons       # once assets/branding/ has your art
dart run flutter_native_splash:create
```

## License

MIT. See [LICENSE](LICENSE).
