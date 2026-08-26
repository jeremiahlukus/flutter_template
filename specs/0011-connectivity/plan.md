# Implementation Plan: 0011 · Connectivity and automatic sync

- **Status:** Accepted
- **Created:** 2026-08-21

> Specification: [`spec.md`](spec.md)

## Design

`ConnectivityService` is an interface with a platform implementation and a
controllable `FakeConnectivityService`. Both build their stream with
`Stream.multi`, matching [0001](../0001-authentication/spec.md) — and for the same
reason: an `async*` generator suspended in `await for` over a never-closing
stream cannot be cancelled.

`ReconnectSyncCoordinator` lives in a provider watched by `TemplateApp`, so it
keeps working whatever screen the user is on. It tracks the previous status and
fires only on a genuine transition (R7), and guards with a `_syncing` flag (R8).

**Two bugs this spec's tests caught, both worth knowing about:**

1. Seeding via `checkConnectivity().then(...).catchError(...)` silently produced
   *no seed at all* when the platform threw **synchronously** — the throw escapes
   before `catchError` is attached. Routing through `currentStatus()`, which has
   a real `try`/`catch`, fixes it.
2. Without R3, switching wifi→ethernet is a platform event but not a status
   change, and re-emitting re-triggers every reconnect listener.
