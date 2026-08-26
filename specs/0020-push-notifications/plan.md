# Implementation Plan: 0020 · Push notifications

- **Status:** Accepted
- **Created:** 2026-08-22

> Specification: [`spec.md`](spec.md)

## Design

`PushService` is an interface — `FirebaseMessaging` needs a platform channel and
a certificate, so none of it runs in a test — with `FakePushService` driving every
scenario below.

R2 is the distinction that matters: the OS answers "may we?", the preference
answers "does the user want us to?". Both must be true to register (R4).
Conflating them means a user who turns notifications off in-app keeps getting
them until they find system settings.

`PushRegistrar` listens to auth *and* the preference, and to
`onTokenRefresh()` for R5. Tokens are stored one document per token under
`users/{uid}/devices/{token}` — the same path scheme the security rules already
protect, and R7 falls out of it.

R11 needs `getInitialMessage()`, which is separate from the opened-message
stream. `pushRouteProvider` merges both, so a cold-start tap is not silently
dropped. R12 validates against `AppRoute.paths` before navigating, because a
payload is untrusted input.
