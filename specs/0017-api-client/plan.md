# Implementation Plan: 0017 · API client

- **Status:** Accepted
- **Created:** 2026-08-22

> Specification: [`spec.md`](spec.md)

## Design

`ApiFailureKind` is a closed set of ten cases, because a screen only ever needs
to know *retry*, *sign in again*, or *give up*. `isRetryable` lives on the kind
(R3) so `RetryInterceptor` and a retry button in the UI read the same source.

R7 is the one people get wrong: `RetryInterceptor.idempotentMethods` excludes
POST and PATCH. Replaying a POST can create two records or double-charge a card.

The token is read per-request rather than cached (R4): Firebase rotates ID tokens
hourly and `getIdToken()` already returns the cached one until near expiry, so a
local cache would only add a class of 401 that looks like a backend bug.

Tests drive Dio's `HttpClientAdapter` seam rather than mocking `Dio`, so the real
interceptor chain, options merging, and error classification all execute.
