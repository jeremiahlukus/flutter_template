# 0017 · API client

- **Status:** Accepted
- **Created:** 2026-08-22

## Context

`AppConfig.apiBaseUrl` had **zero consumers**. Most apps talk to their own
backend alongside Firebase, and that was the one layer the template did not have
— so the first person to need it would invent their own conventions for error
handling, auth headers, and retries, none of which would match how the rest of
the app works.

## Requirements

| ID | Requirement |
|---|---|
| 0017-R1 | Feature code MUST NOT see a `DioException`. |
| 0017-R2 | Every failure MUST classify into a small, actionable set. |
| 0017-R3 | Retryability MUST be a property of the failure, so the interceptor and the UI cannot disagree. |
| 0017-R4 | The signed-in user's ID token MUST be attached automatically. |
| 0017-R5 | A request MUST be able to opt out of authentication. |
| 0017-R6 | A failed token read MUST NOT block the request. |
| 0017-R7 | Retries MUST apply only to idempotent methods. |
| 0017-R8 | Retries MUST back off exponentially and be bounded. |
| 0017-R9 | A decode failure MUST surface as a failure, not a `TypeError`. |
| 0017-R10 | Failures MUST be logged even when verbose logging is off. |
| 0017-R11 | Timeouts MUST fail faster than a user's patience. |

## Non-goals

- **Code generation** (`retrofit`, `chopper`). The typed methods on `ApiClient`
  are enough for a template, and a generator is another build step to keep green.
- **Response caching.** Firestore already covers the offline story; an HTTP cache
  is app-specific.
- **A refresh-token flow.** Firebase rotates ID tokens itself; a non-Firebase
  backend would add its own interceptor here.

## Verification

| ID | Test |
|---|---|
| 0017-R1 | `test/core/network/api_client_test.dart` › `failure mapping` › `a 404 becomes an ApiFailure, not a DioException` |
| 0017-R2 | `test/core/network/api_failure_test.dart` › `status code mapping` |
| 0017-R3 | `…api_failure…` › `isRetryable` › `is true only for transient kinds` |
| 0017-R4 | `…api_client…` › `AuthTokenInterceptor` › `attaches a bearer token when signed in` |
| 0017-R5 | `…` › `AuthTokenInterceptor` › `honours an explicit anonymous request` |
| 0017-R6 | `…` › `AuthTokenInterceptor` › `sends no header when signed out` |
| 0017-R7 | `…` › `RetryInterceptor` › `does not retry a POST, even on a 500` |
| 0017-R8 | `…` › `RetryInterceptor` › `backs off exponentially` / `retries a 500 up to the attempt limit` |
| 0017-R9 | `…` › `failure mapping` › `a decode failure is reported, not thrown as a TypeError` |
| 0017-R10 | `…` › `ApiLogInterceptor` › `logs a failure in quiet mode too` |
| 0017-R11 | `ApiTimeouts` in `api_providers.dart`; 10s connect, 20s send/receive |

## Open questions

- Nothing in the app calls it yet — the notes feature is Firestore-backed. The
  first real endpoint will show whether the typed-method shape is right.
