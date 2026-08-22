# 0004 · Routing and route guards

- **Status:** Accepted
- **Created:** 2026-08-21

## Context

A route guard is one of the easiest places in an app to ship a security bug, and
one of the most awkward things to test — widget tests are slow and cover one path
at a time.

There is also a subtler failure: guarding on "is the user signed in" while auth
is still resolving. Answer "no" too early and a returning user sees a flash of
the sign-in screen; answer "yes" too early and a protected screen leaks.

## Requirements

| ID | Requirement |
|---|---|
| 0004-R1 | Route paths and names MUST be declared in one place, not scattered as string literals. |
| 0004-R2 | The guard MUST be a pure function, testable without pumping a widget. |
| 0004-R3 | A signed-out visitor MUST be redirected away from every non-public route. |
| 0004-R4 | A signed-in visitor MUST be redirected away from the sign-in route. |
| 0004-R5 | While auth is unresolved, the guard MUST NOT redirect at all. |
| 0004-R6 | A redirect target MUST NOT itself redirect — no loops. |
| 0004-R7 | Public-route matching MUST be by path segment, so `/sign-in-secretly` is not public. |
| 0004-R8 | An auth change MUST re-run the guard with no explicit navigation call. |
| 0004-R9 | An unknown route MUST render an error screen with a way back. |
| 0004-R10 | Deep links MUST be declared for both platforms. |
| 0004-R11 | An externally-supplied route MUST be validated before navigation. |

## Non-goals

- **Verified App Links / Universal Links.** The `https` intent filter and
  `autoVerify` are declared, but `assetlinks.json` and
  `apple-app-site-association` must be hosted on a domain you own, and iOS
  additionally needs an Associated Domains entitlement. Custom-scheme links work
  with no server setup, which is what the on-device flows use.
- **Nested navigation shells.** Add a `StatefulShellRoute` when there is a bottom
  nav bar to justify it.

## Design

`resolveRedirect({location, signedIn, authResolved})` is a top-level pure
function, marked `@visibleForTesting`. The whole truth table — every route × both
auth states × both resolution states — is covered by fast unit tests in
`test/routing/redirect_test.dart`, including a convergence check for R6 that
tries to follow every redirect twice.

`routerProvider` bridges Riverpod to `go_router` with a `ValueNotifier` fed by
`ref.listen(authStateProvider)`, satisfying R8. `AppRoute.isPublic` compares the
whole path or requires a `/` boundary, satisfying R7.

### Deep links

`flutter_deeplinking_enabled` (Android) and `FlutterDeepLinkingEnabled` (iOS) hand
incoming links to `go_router` rather than letting the platform open a fresh
activity. A `fluttertemplate://` custom scheme is declared on both, plus an
`https` filter for a domain to be replaced.

R11 matters because a link — or a push payload ([0020](0020-push-notifications.md))
— is untrusted input. `AppRoute.paths` is the allow-list; an unrecognised route is
logged and dropped rather than navigated to.

## Verification

| ID | Test |
|---|---|
| 0004-R1 | `test/routing/app_routes_test.dart` › `paths and names` › `paths are unique` |
| 0004-R2 | `test/routing/redirect_test.dart` (the whole file calls the function directly) |
| 0004-R3 | `…` › `signed out` › `is sent to sign-in from every protected route` |
| 0004-R4 | `…` › `signed in` › `is bounced off the sign-in screen to the notes list` |
| 0004-R5 | `…` › `while auth is still resolving` › `never redirects, whatever the location` |
| 0004-R6 | `…` › `redirects converge — the result of a redirect is never redirected` |
| 0004-R7 | `test/routing/app_routes_test.dart` › `isPublic` › `a path that merely starts with the same letters is not public` |
| 0004-R8 | `test/app/app_test.dart` › `routing integration` › `signing out from the profile returns to sign-in` |
| 0004-R9 | `test/app/app_test.dart` › `RouteErrorScreen` › `shows the error and offers a way back` |
| 0004-R10 | `android/app/src/main/AndroidManifest.xml` intent filters; `ios/Runner/Info.plist` `CFBundleURLTypes` |
| 0004-R11 | `test/routing/app_routes_test.dart` › `paths` › `enumerates every route` |

## Open questions

None.
