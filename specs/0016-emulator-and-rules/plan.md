# Implementation Plan: 0016 · Emulator suite and security rules

- **Status:** Accepted
- **Created:** 2026-08-22

> Specification: [`spec.md`](spec.md)

## Design

`firebase.json` declares the emulator ports; `EmulatorPorts` in
`firebase_providers.dart` mirrors them. Duplicated deliberately — a mismatch
surfaces immediately as a connection refused, and parsing JSON at startup is a
worse failure mode than a stale constant.

Redirection lives in the Firebase providers, the one place that already owns
every SDK singleton. Analytics is not redirected: it has no emulator, and a
non-production `AppConfig.analyticsEnabled` already suppresses collection.

R7 and R8 are the load-bearing safety properties. `USE_EMULATORS` is a separate
`--dart-define` from `APP_ENV` (R8) — you want the emulator in dev *sometimes*
and never by accident — and `AppConfig.current()` masks it off in production
(R7), because a release build silently talking to localhost would look like a
total outage.

Rules tests live in `test_rules/`, a Node package using
`@firebase/rules-unit-testing` and vitest, driven by `firebase emulators:exec`.
Self-contained (R9): `flutter test` never sees it, and its own CI job installs
Node and a JDK.

**Current state:** 36 rules tests passing — 21 Firestore, 15 Storage.
