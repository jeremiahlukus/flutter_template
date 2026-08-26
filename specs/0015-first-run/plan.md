# Implementation Plan: 0015 · First run and misconfiguration

- **Status:** Accepted
- **Created:** 2026-08-21

> Specification: [`spec.md`](spec.md)

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
