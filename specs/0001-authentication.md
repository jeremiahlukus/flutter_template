# 0001 · Authentication

- **Status:** Accepted
- **Created:** 2026-08-21

## Context

Every app built from this template needs sign-in, and every one of them needs it
to be testable without a live Firebase project. Two things make that hard:

1. `FirebaseAuth.instance` is a global. Code that reaches for it directly cannot
   be tested at all.
2. `FirebaseAuth.authStateChanges()` is a **broadcast** stream. A subscriber that
   arrives after the SDK has settled receives nothing until the *next*
   transition — so an app that only listens can sit in its loading state
   indefinitely on a warm start.

Point 2 is not hypothetical: it is exactly the failure `firebase_auth_mocks`
reproduces, because it emits its initial event from its constructor.

## Requirements

| ID | Requirement |
|---|---|
| 0001-R1 | Nothing outside `firebase_providers.dart` MAY reference a Firebase SDK singleton directly. |
| 0001-R2 | The auth stream MUST emit the current state to every new subscriber, without waiting for a transition. |
| 0001-R3 | The auth stream MUST NOT emit consecutive duplicates. |
| 0001-R4 | A subscription to the auth stream MUST be cancellable, promptly and without deadlock. |
| 0001-R5 | The UI MUST see the app's own `AppUser`, never Firebase's `User`. |
| 0001-R6 | Every Firebase auth error MUST surface as an `AuthFailure` carrying a sentence fit to show a user. |
| 0001-R7 | Equivalent failures MUST produce identical copy — notably `wrong-password` and `invalid-credential`. |
| 0001-R8 | An operation requiring a signed-in user MUST fail with `no-current-user` rather than a null dereference. |
| 0001-R9 | Sign-in, sign-up, and sign-out MUST set or clear the analytics user id. |
| 0001-R10 | Form controllers MUST report failure by state, not by throwing, so screens need no try/catch. |

## Non-goals

- **Social sign-in.** `firebase_ui_oauth_google` pulls in `desktop_webview_auth`,
  which has no Swift Package Manager support. Add it deliberately, per app.
- **Custom sign-in UI.** `firebase_ui_auth` handles validation, error copy, and
  the sign-up toggle. Rewriting that is the work a template should save you.
- **Multi-factor auth.**

## Design

```
FirebaseAuth  ──(firebaseAuthProvider)──▶  AuthRepository  ──▶  AppUser
                                                 │
                                          AuthController (AsyncNotifier)
                                                 │
                                          screens read state
```

`AuthRepository.authStateChanges()` is built with **`Stream.multi`**, not an
`async*` generator. This is the load-bearing decision in this spec. A generator
suspended in `await for` over a broadcast stream that never closes **cannot be
cancelled** — `cancel()` hangs forever and the subscription leaks. `Stream.multi`
gives an explicit `onCancel` that forwards straight upstream. Seeding and
de-duplication happen inside the same callback, per subscriber.

`AppUser` exists so a fork can change auth backends without touching a screen,
and so `label`/`initials` fallbacks live in one tested place.

### Known limitation

`firebase_auth_mocks` and `firebase_ui_auth` cannot be driven end-to-end
together: on success `firebase_ui_auth` reads
`UserCredential.additionalUserInfo`, and the mock throws `UnimplementedError`
from that getter. The analytics side effects therefore live in the static
handlers `TemplateSignInScreen.recordSignIn` / `.recordSignUp`, which *are*
covered. Do not spend an afternoon rediscovering this.

## Verification

| ID | Test |
|---|---|
| 0001-R1 | `test/core/firebase_providers_test.dart` › `every Firebase seam is replaceable` |
| 0001-R2 | `test/features/auth/auth_repository_test.dart` › `authStateChanges` › `emits the user when signed in` |
| 0001-R3 | `test/features/auth/auth_repository_test.dart` › `authStateChanges` › `does not re-emit an unchanged user` |
| 0001-R4 | `test/features/auth/auth_repository_test.dart` › `authStateChanges` › `the subscription can be cancelled` |
| 0001-R5 | `test/features/auth/app_user_test.dart` › `fromFirebase` › `copies every field across` |
| 0001-R6 | `test/features/auth/auth_repository_test.dart` › `AuthFailure` › `maps a known Firebase code to friendly copy` |
| 0001-R7 | `test/features/auth/auth_repository_test.dart` › `AuthFailure` › `maps invalid-credential to the same copy as wrong-password` |
| 0001-R8 | `test/features/auth/auth_repository_test.dart` › `updateDisplayName` › `throws when signed out` |
| 0001-R9 | `test/features/auth/auth_repository_test.dart` › `signOut` › `clears the user and the analytics id` |
| 0001-R10 | `test/features/auth/auth_providers_test.dart` › `AuthController` › `signIn surfaces a failure as an error state` |

## Open questions

- Should anonymous sign-in be surfaced in the UI? The repository supports it
  (`signInAnonymously`); no screen offers it.
