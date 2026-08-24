# task.md

Working checklist for this template. Specs live in [`specs/`](specs/); this file
tracks the *work*.

Legend: `[x]` done · `[ ]` open · `[~]` partially done, see note

---

## Milestone 0 — Make it yours

Everything here is per-app setup. Nothing below this milestone works until it is
done, because `lib/firebase_options.dart` deliberately throws.

- [ ] **Rename the package.** Use the tool; do not hand-roll a `sed`.
      ```sh
      dart run tool/rename_package.dart your_app   # --dry-run to preview
      ```
      A bare find-and-replace leaves the project **not analyzing** — around 65
      `directives_ordering` errors, because `package:flutter_template/...` and
      `package:your_app/...` sort differently, and import blocks that were
      alphabetised no longer are. The tool does the replace and then runs
      `dart fix --code=directives_ordering` and `dart format`, so you end on a
      clean `flutter analyze`.

      It deliberately leaves `AppDatabase.databaseName` alone — see the next
      item. That works via a `// keep-on-rename` marker comment; add it to any
      line of your own where the package name is data rather than a reference.
- [ ] **Set the on-disk database name.** `AppDatabase.databaseName` in
      `lib/src/database/app_database.dart`, plus the expectation pinning it in
      `test/database/app_database_test.dart`.
      - Greenfield? Set it to your app name and move on.
      - **Replacing an app that is already shipped? Set it to that app's existing
        database name, and carry its `schemaVersion` and migrations forward.** Get
        this wrong and the app opens a brand-new empty file beside the real one.
        Every user's data is still on disk with nothing referencing it, and
        *nothing throws* — it reaches you as "the update wiped my account".
- [ ] **Set the bundle id / application id.** `flutter create --org com.yourco
      --project-name your_app .` over the top, or edit
      `android/app/build.gradle.kts` and the Xcode target.
- [ ] **Create the Firebase project** and enable Email/Password auth, Firestore,
      Cloud Storage, and Analytics.
- [ ] **Generate the real Firebase config.**
      ```sh
      dart pub global activate flutterfire_cli
      flutterfire configure
      ```
      This replaces the throwing placeholder in `lib/firebase_options.dart`.
      Until you do, the app still launches — it shows the setup screen instead
      ([spec 0015](specs/0015-first-run.md)). Do **not** run
      `tool/stub_firebase_options.dart` locally; it is for CI.

      Afterwards, delete the test `the committed placeholder throws it` in
      `test/app/firebase_setup_screen_test.dart`. It asserts on the placeholder,
      which no longer exists once this file is real.
- [ ] **Enable Crashlytics** in the Firebase console (Crashlytics → Enable).
- [ ] **Deploy the security rules.** They are written but not deployed:
      ```sh
      firebase deploy --only firestore:rules,storage
      ```
- [ ] **Pick your environments.** `AppConfig.forEnvironment` has placeholder API
      URLs; set the real ones and decide whether each flavour gets its own
      Firebase project (recommended — run `flutterfire configure` per project).
      ```sh
      flutter run --dart-define=APP_ENV=staging
      ```
- [ ] **Set your brand colour.** `AppBrand.fallback` in
      `lib/src/app/theme/app_brand.dart`. Trim the presets you do not want.
- [ ] **Decide your locales.** Delete `app_es.arb` if you ship English only, or
      add more; `flutter pub get` regenerates.
- [ ] **Reword the onboarding and setup copy.** The strings in
      `lib/src/l10n/arb/` describe *this template*, not your app — onboarding,
      the sign-in subtitles and the Firebase setup screen are the visible ones,
      and they are the first thing a user reads. Grep every ARB for `note` and
      for the app name; the copy has been kept feature-neutral so a rename is
      the only edit needed, but that only holds until you add your own strings.
- [ ] **Confirm the gates pass**: `flutter analyze && flutter test --coverage &&
      dart run tool/check_coverage.dart`
- [ ] Delete the `notes` feature once you have a real one, or keep it as a
      worked example. It is the reference implementation for
      [spec 0002](specs/0002-notes-sync.md).

---

## Milestone 1 — Foundations *(done)*

- [x] Firebase Core bootstrap with `FlutterError.onError` + zone guard
- [x] Riverpod 3 provider graph; every Firebase singleton behind a seam
      → [0001-R1](specs/0001-authentication.md)
- [x] `go_router` with a pure, exhaustively-tested route guard
      → [spec 0004](specs/0004-routing.md)
- [x] Material 3 theming from a single seed colour, light + dark
- [x] `very_good_analysis` with every relaxation justified in
      `analysis_options.yaml`
- [x] Structured logging (`AppLogger`), quiet in release, swappable in tests

## Milestone 2 — Authentication *(done)*

- [x] `firebase_ui_auth` sign-in / sign-up / password reset
- [x] `AuthRepository` mapping every Firebase code to user-fit copy
      → [0001-R6](specs/0001-authentication.md)
- [x] `AppUser` domain model with `label` / `initials` fallbacks
- [x] Auth stream seeds its current value and is cancellable
      → [0001-R2, 0001-R4](specs/0001-authentication.md)
- [x] Profile: rename, avatar upload, sign out, delete account
- [x] Email-verification warning surfaced in the UI

## Milestone 3 — Data *(done)*

- [x] Drift schema, in-memory factory, UTC-safe datetimes
      → [spec 0003](specs/0003-local-persistence.md)
- [x] Offline-first notes: push-before-pull, pending-write preservation
      → [spec 0002](specs/0002-notes-sync.md)
- [x] Firestore scoped to `users/{uid}/notes`
- [x] Cloud Storage repository + in-memory double
      → [spec 0006](specs/0006-file-storage.md)
- [x] Settings persisted in Drift, driving the live theme

## Milestone 4 — Quality *(done)*

- [x] 968 Dart tests + 48 rules tests + 12 goldens; **93.7%** line coverage against an 85% floor
- [x] `tool/check_coverage.dart` — zero-dependency gate, justified exclusions
      → [spec 0007](specs/0007-quality-gates.md)
- [x] CI: format → codegen freshness → analyze → test → coverage → build matrix
- [x] Whole suite runs with no Firebase project and no network
      → [0007-R9](specs/0007-quality-gates.md)
- [x] Firestore + Storage rules written to mirror the client's path scheme
- [x] ARB parity gate: CI fails on any untranslated or stale message

## Milestone 5 — Production readiness *(done)*

Added to cut the gap between "template" and "shippable".

- [x] **Design system** — spacing/radius/duration/breakpoint tokens, semantic
      status colours as a `ThemeExtension` (WCAG AA verified), six brand presets
      re-seeding the whole theme, explicit type scale, every component themed
      → [spec 0008](specs/0008-design-system.md)
- [x] **Environments** — `--dart-define=APP_ENV`, per-environment `AppConfig`,
      corner banner off production, version + environment in Settings
      → [spec 0009](specs/0009-environments.md)
- [x] **Crash reporting** — Crashlytics behind an `ErrorReporter` interface,
      wired to `FlutterError.onError` and the zone guard, no-op in dev
      → [spec 0010](specs/0010-error-reporting.md)
- [x] **Connectivity + automatic sync** — offline banner on every screen, queued
      writes pushed on reconnect → [spec 0011](specs/0011-connectivity.md)
- [x] **Shared UI kit** — `AsyncValueView` plus empty/error/loading states, so a
      screen is not four branches of boilerplate
      → [spec 0012](specs/0012-ui-kit.md)
- [x] **Localisation** — `gen-l10n`, English + Spanish, ICU plurals, persisted
      locale picker, ARB parity enforced in CI
      → [spec 0013](specs/0013-localisation.md)
- [x] **Onboarding** — three-page intro, once per device, gated before auth
      → [spec 0014](specs/0014-onboarding.md)
- [x] **Analytics opt-out now honoured** — a consent decorator, so no call site
      has to remember → [0005-R9](specs/0005-analytics.md)
- [x] **Launches unconfigured** — a setup screen naming the exact commands,
      instead of a startup crash; verified on an iPhone 17 simulator
      → [spec 0015](specs/0015-first-run.md)
- [x] **iOS deployment target raised to 15.0** — `cloud_firestore` requires it,
      and Flutter's scaffold ships 13.0, so a fresh clone could not `pod install`
      → [0015-R10](specs/0015-first-run.md)
- [x] **Crash reports attributed to the signed-in user**, cleared on sign-out
      → [0010-R7](specs/0010-error-reporting.md)
- [x] **`bootstrap()` error wiring is now tested** — extracted into
      `installErrorHandlers` and `reportZoneError`
      → [spec 0010](specs/0010-error-reporting.md)
- [x] **Domain failure copy is localised** — `AuthFailure`/`StorageFailure` codes
      map to ARB strings in `core/errors/failure_messages.dart`
      → [spec 0013](specs/0013-localisation.md)
- [x] **The coverage gate is tested** — parser and threshold logic extracted to
      `tool/coverage_report.dart` → [spec 0007](specs/0007-quality-gates.md)
- [x] **Responsive layout verified at four widths**, including the content-width
      cap → [0008-R12](specs/0008-design-system.md)

## Milestone 6 — Production features *(done)*

- [x] **Firebase emulator suite** — `firebase.json`, opt-in redirection via
      `--dart-define=USE_EMULATORS=true`, and **36 security-rules tests** running
      against the real emulator in CI. Closes the "rules untested" gap for both
      Firestore and Storage. → [spec 0016](specs/0016-emulator-and-rules.md)
- [x] **API client** — Dio behind a typed `ApiClient`; every failure arrives as an
      `ApiFailure`, ID token attached per-request, exponential-backoff retry on
      idempotent methods only → [spec 0017](specs/0017-api-client.md)
- [x] **Pagination** — bounded Drift query with a growing window, keyset paging
      for the Firestore pull → [spec 0018](specs/0018-pagination.md)
- [x] **Image picking** — camera/library, downscale + JPEG re-encode, replacing
      the placeholder 1×1 PNG → [spec 0019](specs/0019-media.md)
- [x] **Push notifications** — opt-in only, token registration with rotation
      handling, notification taps opening validated routes
      → [spec 0020](specs/0020-push-notifications.md)
- [x] **Forced-update gate** — a remote version floor that fails open on every
      ambiguous case → [spec 0021](specs/0021-app-updates.md)
- [x] **Deep links** — custom scheme declared on both platforms, `https` filter
      ready for a domain → [0004-R10](specs/0004-routing.md)
- [x] **Accessibility suite** — tap targets, labels, contrast, and 2× text scale
      across every screen. Found four real bugs.
      → [spec 0022](specs/0022-accessibility.md)
- [x] **Golden tests** — 12 design-system goldens, 6 brands × light/dark, in a
      platform-pinned CI job → [spec 0023](specs/0023-visual-regression.md)
- [x] **Project chores** — `flutter_launcher_icons` + `flutter_native_splash`
      config, PR template, issue forms, CODEOWNERS, Dependabot
- [x] **Four production bugs fixed after an audit** — the security rules denied
      both push-token registration and the update-policy read (silently, since
      both swallow their errors); a signed-out device kept its push token; and an
      over-long note either crashed the save or never synced. See
      [spec 0016](specs/0016-emulator-and-rules.md),
      [0020](specs/0020-push-notifications.md), [0002](specs/0002-notes-sync.md).
- [x] **`CLAUDE.md` / `AGENTS.md`** — condensed rules, gates, and known traps for
      coding agents
- [x] **Two CI-only bugs fixed after the first real run** — `lib/` imported
      `drift/native.dart` for a test-only helper, so `flutter build web` had
      never compiled; and `test_rules/package-lock.json` was pinned to a private
      registry CI cannot reach. Both now have guards: a web-compatibility grep in
      CI, and a committed `test_rules/.npmrc`.
      → [0003-R11](specs/0003-local-persistence.md), [spec 0016](specs/0016-emulator-and-rules.md)
- [x] **Dependabot tuned for the Flutter SDK's version pins** — `intl` cannot be
      bumped while `flutter_localizations` pins it, so it is ignored rather than
      reopened weekly. → [spec 0007](specs/0007-quality-gates.md)

---

## Milestone 7 — Known gaps

These are deliberate and documented, not oversights. Each is a real task.

- [ ] **Spanish is unreviewed.** Grammatical, but written without a native
      speaker. Review before shipping to a Spanish market.
- [ ] **No RTL locale**, so no RTL layout pass has been done.
- [ ] **No schema migration test.** There is one schema version, so there is
      nothing to migrate yet. The moment there are two, add `drift_dev`'s
      schema verification — a silent migration bug is expensive.
      → [spec 0003, Non-goals](specs/0003-local-persistence.md)
- [ ] **No integration tests.** Widget tests cover the screens; nothing runs on
      a device in CI. The emulator suite makes this practical now — see
      [`flutter-skill.md`](flutter-skill.md) for the manual flows, **none of
      which has been run** beyond the first-launch check.
- [ ] **Native push setup is not done.** APNs certificate, entitlements, and the
      Android notification channel are per-app.
      → [spec 0020, Non-goals](specs/0020-push-notifications.md)
- [ ] **Deep links are unverified.** The custom scheme is declared but no flow
      has been run on a device, and App Links need `assetlinks.json` and
      `apple-app-site-association` hosted on a domain you own.
- [ ] **Branding assets are placeholders.** `assets/branding/` is empty by
      design; icons and splash need your artwork before either generator runs.
- [ ] **The API client has no caller.** The notes feature is Firestore-backed, so
      the typed-method shape is unexercised by a real endpoint.
      → [spec 0017, Open questions](specs/0017-api-client.md)
- [ ] **Deployment-target drift is unguarded.** iOS 15.0 / macOS 10.15 satisfy
      today's Firebase plugins. Nothing fails when a plugin upgrade raises the
      bar, except the CI build itself.
      → [spec 0015, Open questions](specs/0015-first-run.md)
- [ ] **No backoff on a failed sync.** A reconnect triggers one attempt;
      repeated failure waits for the next transition or a manual tap.
      → [spec 0011, Non-goals](specs/0011-connectivity.md)

## Milestone 8 — Likely next features

Not started. Ordered roughly by how often a real app needs them.

- [ ] Native flavours — `--dart-define` covers Dart; separate app ids, icons, and
      Xcode schemes are native work
- [ ] `integration_test` running against the emulator suite in CI
- [ ] Social sign-in — note the `desktop_webview_auth` / SPM caveat in
      [spec 0001, Non-goals](specs/0001-authentication.md)
- [ ] Localised date and number formatting (`intl` is already a dependency)
- [ ] Remote Config / feature flags
- [ ] Note attachments, using the storage `attachmentPath` helper
- [ ] Search over notes (needs a client-side compromise or Algolia)
- [ ] Local notifications and a foreground in-app banner
- [ ] Biometric app lock (`local_auth`)
- [ ] An RTL locale, with the layout pass it implies

---

## Working agreements

**Spec first.** Behaviour a maintainer will rely on gets a numbered requirement
in `specs/` *before* the code. The full loop is in
[`specs/README.md`](specs/README.md).

**Every requirement names a test.** A spec whose Verification table has a `—` is
either lying or unfinished. That table is the traceability tool; there is nothing
to install.

**Never reach for a Firebase singleton.** Add a provider to
`firebase_providers.dart` instead. Every test in the suite depends on this
holding. → [0001-R1](specs/0001-authentication.md)

**Justify every lint relaxation.** `analysis_options.yaml` has a comment per
disabled rule explaining why it cannot or should not be satisfied. A bare
disable is a TODO in disguise.

**Justify every coverage exclusion.** Same reasoning, in
`tool/check_coverage.dart`.

**No inline magic numbers in the UI.** Spacing, radii, and durations come from
`design_tokens.dart`; status colours from `AppSemanticColors`. That is what keeps
a rebrand to one enum value. → [spec 0008](specs/0008-design-system.md)

**No hard-coded user-visible strings.** Add a key to `app_en.arb`, translate it in
every other ARB, and read it via `context.l10n`. CI fails on a missing
translation. → [spec 0013](specs/0013-localisation.md)

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

# Goldens are platform-pinned; regenerate after an intentional visual change.
flutter test --tags golden
flutter test --tags golden --update-goldens

# Security rules, against the real emulator.
cd test_rules && npm ci && npm test

# Local emulator suite for the app itself.
firebase emulators:start
flutter run --dart-define=APP_ENV=dev --dart-define=USE_EMULATORS=true

flutter run                                        # dev, real backend
flutter run --dart-define=APP_ENV=staging
flutter build apk --release --dart-define=APP_ENV=prod

# Branding, once assets/branding/ has your artwork.
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
