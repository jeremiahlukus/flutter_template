# 0015 · First run and misconfiguration

- **Status:** Accepted
- **Created:** 2026-08-21

## Context

A template's first impression is `flutter run` on a fresh clone. Before this
spec, that produced a hard crash: `firebase_options.dart` is a placeholder that
throws, `Firebase.initializeApp` never returned, and the process died with a
stack trace whose actual cause — "you have not run `flutterfire configure`" —
appeared nowhere on screen.

Throwing was the *right* call over shipping fake credentials, which produce
confusing `FirebaseException`s at the first auth call instead. But "fail loudly"
and "crash" are not the same thing. The app can launch and say what to do.

There is a second, less obvious failure in the same area: Flutter's iOS scaffold
targets iOS 13.0, and `cloud_firestore` requires 15.0. A fresh clone could not
even `pod install`.

## Requirements

| ID | Requirement |
|---|---|
| 0015-R1 | An unconfigured app MUST still launch and render. |
| 0015-R2 | The screen MUST state that the app requires Firebase. |
| 0015-R3 | It MUST show the exact commands that fix it. |
| 0015-R4 | It MUST be copyable, so nobody retypes a command. |
| 0015-R5 | It MUST point at the fuller checklist. |
| 0015-R6 | The underlying error MUST be available but not prominent. |
| 0015-R7 | It MUST NOT depend on Riverpod, Firebase, or any provider. |
| 0015-R8 | It MUST render at every supported window size without clipping. |
| 0015-R9 | The placeholder MUST throw a *named* type, distinguishable from a real Firebase failure. |
| 0015-R10 | Platform deployment targets MUST satisfy every Firebase plugin. |
| 0015-R11 | QA tooling MUST NOT be reachable from `lib/`. |

## Non-goals

- **Configuring Firebase from inside the app.** `flutterfire configure` writes a
  source file; that is a build-time job.
- **A retry button.** The fix requires regenerating a Dart file and restarting.
- **Detecting a *partly* configured project** (say, iOS set up but not Android).
  `Firebase.initializeApp` failing is the only signal used.

## Design

`bootstrap` takes `firebaseOptions` as a **callback**, not a value. That is the
whole trick: a placeholder that throws is invoked *inside* `bootstrap`'s `try`,
so it becomes `FirebaseSetupApp` rather than an uncaught error in `main`.

`FirebaseSetupScreen` is deliberately austere (R7): no `ProviderScope`, no
Firebase, no repositories. It has to work in exactly the situation where
everything else does not. It does use the theme and localisations, because
neither depends on Firebase.

R9 exists so `bootstrap` — and a test — can tell "not configured yet" apart from
"configured but the network is down". Only the former is really a setup problem.

R11 is why the `flutter_skill` QA SDK is a **dev_dependency** with its entrypoint
at `tool/main_dev.dart`: Dart forbids `lib/` from importing a dev_dependency,
which is exactly the constraint wanted. `lib/main.dart` stays free of test
tooling and a release build cannot include it.

### Verified on device

Built and run on an iPhone 17 simulator with no Firebase configured. The app
launches, logs `Firebase failed to initialise; showing the setup screen`, and
renders the screen. Before the R10 fix it failed at `pod install` with
*"The plugin cloud_firestore requires a higher minimum iOS deployment version"*.

## Verification

| ID | Test |
|---|---|
| 0015-R1 | `test/app/firebase_setup_screen_test.dart` › `rendering` › `builds with no provider scope at all` |
| 0015-R2 | `…` › `rendering` › `says the app needs Firebase` |
| 0015-R3 | `…` › `rendering` › `shows both setup commands` |
| 0015-R4 | `…` › `copy buttons` › `copy the command to the clipboard` |
| 0015-R5 | `…` › `rendering` › `points at the checklist` |
| 0015-R6 | `…` › `rendering` › `offers collapsed error details when there is an error` / `expanding the details reveals the raw error` |
| 0015-R7 | `…` › `rendering` › `builds with no provider scope at all` (pumped bare) |
| 0015-R8 | `…` › `robustness` › `renders on a narrow phone without overflowing` / `renders on a wide desktop window` |
| 0015-R9 | `…` › `FirebaseNotConfigured` › `the placeholder throws it` |
| 0015-R10 | — *(build-time; verified by an on-device run, not by the suite)* |
| 0015-R11 | `tool/main_dev.dart` is outside `lib/`; `flutter analyze` would reject the import otherwise |

## Open questions

- R10 is only verified by a human running the build. A CI job already builds for
  iOS, which covers regression — but nothing asserts the *version numbers* stay
  in step with the Firebase plugins' requirements.
