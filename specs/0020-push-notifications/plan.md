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

### Mapping platform statuses, exhaustively

`FirebasePushService._map` has **no wildcard case**, and that is the design rather
than an oversight. `firebase_messaging` 16.6.0 added `AuthorizationStatus
.deniedPermanently`; because the switch is exhaustive, the analyzer failed the
build on the dependency bump and forced someone to decide what the new state
means. A `_ =>` fallback would have folded an unknown OS permission state into
whichever case sat first, silently, in a patch release.

`deniedPermanently` collapses onto `PushPermission.denied`: neither can deliver,
and this app re-prompts on neither, so nothing downstream can distinguish them.
It is Android 13+ only — Apple reports permanent denial as plain `denied`.

One thing upstream changed that this repo has **not** followed, recorded here so
the gap is deliberate rather than forgotten: `firebase_messaging` now documents
plain `denied` on Android 13+ as possibly re-promptable, and recommends calling
`requestPermission()` again rather than sending the user to system settings.
`PushPermission.denied.canPrompt` is `false`, so the settings screen does the
opposite — it shows a blocked message. Changing that is a UX decision with its own
requirements, not something to fold into a version bump.

