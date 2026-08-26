# Implementation Plan: 0004 · Routing and route guards

- **Status:** Accepted
- **Created:** 2026-08-21

> Specification: [`spec.md`](spec.md)

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

R11 matters because a link — or a push payload ([0020](../0020-push-notifications/spec.md))
— is untrusted input. `AppRoute.paths` is the allow-list; an unrecognised route is
logged and dropped rather than navigated to.
