# 0020 · Push notifications

- **Status:** Accepted
- **Created:** 2026-08-22

## Context

Two things go wrong with push in almost every app:

1. **Prompting unasked.** Requesting notification permission on first launch is
   the fastest way to be denied permanently, and on both platforms a hard denial
   is final until the user digs into system settings.
2. **Ignoring token rotation.** A device token changes on reinstall, restore, and
   occasionally at random. Register once at sign-in and the device silently stops
   receiving — with no error anywhere.

## Requirements

| ID | Requirement |
|---|---|
| 0020-R1 | Permission MUST be requested only on an explicit opt-in. |
| 0020-R2 | The in-app preference MUST be separate from the OS permission. |
| 0020-R3 | The preference MUST default to off. |
| 0020-R4 | A token MUST be registered only when signed in *and* opted in. |
| 0020-R5 | Token rotation MUST re-register, and remove the old token. |
| 0020-R6 | Opting out or signing out MUST remove the token. |
| 0020-R7 | One token per device — signing out on one device MUST NOT silence others. |
| 0020-R8 | A failed registration MUST NOT surface to the user. |
| 0020-R9 | A hard denial MUST disable the switch and explain why. |
| 0020-R10 | A notification tap MUST be able to open a route. |
| 0020-R11 | A tap that launched a terminated app MUST also open its route. |
| 0020-R12 | An unknown route in a payload MUST be ignored, not navigated to. |
| 0020-R13 | Signing out MUST remove this device's token, even though the user is already gone. |
| 0020-R14 | A different user signing in on one device MUST move the token, not duplicate it. |
| 0020-R15 | Overlapping syncs MUST register once. |
| 0020-R16 | Every platform `AuthorizationStatus` MUST map to a `PushPermission`, with no wildcard case. |

## Non-goals

- **Native setup.** APNs certificates, entitlements, and the Android
  notification channel are per-app; task.md lists them.
- **Local notifications** (`flutter_local_notifications`) and a foreground
  in-app banner. `onForegroundMessage()` is exposed; nothing consumes it.
- **Topic subscriptions.** Add when a feature needs a broadcast.

## Verification

| ID | Test |
|---|---|
| 0020-R1 | `test/features/push/push_registration_test.dart` › `settings toggle` › `turning it on prompts for permission` |
| 0020-R2 | `…` › `PushRegistrar` › `registers nothing when the user has not opted in` |
| 0020-R3 | `…` › `PushEnabledController` › `defaults to off` |
| 0020-R4 | `…` › `PushRegistrar` › `registers a token for an opted-in signed-in user` |
| 0020-R5 | `…` › `PushRegistrar` › `re-registers when the token rotates` |
| 0020-R6 | `…` › `PushRegistrar` › `removes the token when the user opts out` |
| 0020-R7 | `…` › `PushRegistrar` › `keeps other devices registered` |
| 0020-R8 | `PushRegistrar._sync` catch branch — logged, never surfaced |
| 0020-R9 | `…` › `settings toggle` › `is disabled and explained when blocked in system settings` |
| 0020-R10 | `…` › `pushRouteProvider` › `emits the route from a notification tap` |
| 0020-R11 | `…` › `pushRouteProvider` › `emits the route from a cold-start launch message` |
| 0020-R12 | `app_router.dart` validates against `AppRoute.paths` |
| 0020-R13 | `test/features/push/push_registration_test.dart` › `PushRegistrar` › `removes the token when the user signs out` |
| 0020-R14 | `…` › `PushRegistrar` › `moves the token when a different user signs in` |
| 0020-R15 | `…` › `PushRegistrar` › `concurrent syncs register once` |
| 0020-R16 | `test/features/push/push_service_test.dart` › `FirebasePushService permission mapping` › `every platform status maps to one of ours` |

### Two bugs the audit found

Both silent, because `PushRegistrar` swallows its failures by design:

1. **The security rules denied `users/{uid}/devices/{token}` entirely.** No rule
   matched the subcollection, so the catch-all denied every registration and push
   simply never worked — with nothing in the logs.
   → [0016](../0016-emulator-and-rules/spec.md)
2. **`_registered` tracked only the token, not its owner.** On sign-out the
   listener fires when the current user is already null, so the delete looked up
   nobody and did nothing — leaving a signed-out device still receiving. And a
   second account signing in on the same device matched the cached token and
   skipped re-registration, so the *first* account kept the notifications.

The fix is R13/R14: remember `(userId, token)` and pass the remembered owner into
the delete. R15's guard came from the same review — sign-in and opt-in can land in
the same frame and fire both listeners.

## Open questions

- R12 is enforced but not directly tested — it needs the router built with a
  push route in flight. The validation itself is one line against a tested set.
- No background message handler is registered. One is only needed for data-only
  messages that must be processed while the app is terminated.
