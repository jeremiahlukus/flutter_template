# Implementation Plan: 0001 · Authentication

- **Status:** Accepted
- **Created:** 2026-08-21

> Specification: [`spec.md`](spec.md)

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
