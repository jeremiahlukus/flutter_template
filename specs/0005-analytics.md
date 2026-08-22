# 0005 · Analytics

- **Status:** Accepted
- **Created:** 2026-08-21

## Context

Analytics has one hard rule that is easy to get wrong: **it must never be the
reason a user-facing action fails.** A `logEvent` that throws inside a save
handler takes the save down with it.

Screens also should not have to remember to log a screen view. Per-screen wiring
is per-screen opportunity to forget.

## Requirements

| ID | Requirement |
|---|---|
| 0005-R1 | Features MUST depend on an `AnalyticsService` interface, not on `FirebaseAnalytics`. |
| 0005-R2 | Every analytics call MUST swallow its failures, sync and async alike. |
| 0005-R3 | Screen views MUST be logged from the router, not from individual screens. |
| 0005-R4 | A route with no name MUST NOT be logged. |
| 0005-R5 | Screen names MUST come from the route name, not the raw path — no ids in analytics. |
| 0005-R6 | A test double MUST be able to record calls for assertion. |
| 0005-R7 | The user id MUST be set on sign-in and cleared on sign-out. |
| 0005-R8 | An analytics opt-out MUST be persisted locally. |
| 0005-R9 | An analytics opt-out MUST actually suppress collection. |
| 0005-R10 | A mid-session opt-out MUST take effect on the very next event. |
| 0005-R11 | Opting out MUST clear the analytics user id, not merely stop sending it. |
| 0005-R12 | An environment that disables analytics MUST send nothing at all. |

## Non-goals

- **A consent dialog on first run.** The switch defaults to on and lives in
  Settings. Jurisdictions that require explicit prior consent need a gate in
  onboarding ([0014](0014-onboarding.md)).
- **Crash reporting.** Covered by [0010](0010-error-reporting.md).

## Design

`AnalyticsService` (interface) → `FirebaseAnalyticsService` (production),
`ConsentGatedAnalyticsService` (decorator), `NoopAnalyticsService` (environments
with analytics off), and `RecordingAnalyticsService` (tests). Every production
method routes through one private `_guard` that logs and swallows, satisfying R2
in a single place rather than seven `try`/`catch` blocks.

R9–R11 are handled by the decorator rather than an `if (enabled)` at each call
site, so a new feature cannot forget to honour consent. The check is a
**callback**, not a captured bool, which is what makes R10 work.

R11 is the subtle one: `setUserId` is forwarded even when disabled — with a null
id. Suppressing the call instead would leave the previous user attached to the
analytics session, which is the opposite of honouring an opt-out.

`AnalyticsNavigatorObserver` is attached to `GoRouter.observers`, satisfying R3.

`RecordingAnalyticsService` is what the whole suite asserts against; it is what
makes "did signing out clear the user id?" a one-line test.

## Verification

| ID | Test |
|---|---|
| 0005-R1 | `test/core/firebase_analytics_service_test.dart` › `honours the AnalyticsService contract` |
| 0005-R2 | `…` › `failure handling` (every method, plus an async rejection) |
| 0005-R3 | `test/app/app_test.dart` › `routing integration` › `every navigation is reported to analytics` |
| 0005-R4 | `test/routing/analytics_observer_test.dart` › `didPush` › `logs nothing for an unnamed route` |
| 0005-R5 | `test/routing/analytics_observer_test.dart` › `screenNameOf` › `returns the route name` |
| 0005-R6 | `test/core/analytics_service_test.dart` › `RecordingAnalyticsService` › `preserves call order` |
| 0005-R7 | `test/features/auth/auth_repository_test.dart` › `signOut` › `clears the user and the analytics id` |
| 0005-R8 | `test/features/settings/settings_providers_test.dart` › `AnalyticsEnabledController` › `set persists the choice` |
| 0005-R9 | `test/core/consent_gated_analytics_test.dart` › `while consent is withheld` › `drops events` |
| 0005-R10 | `…` › `a mid-session opt-out takes effect on the very next event` |
| 0005-R11 | `…` › `while consent is withheld` › `clears the user id rather than suppressing the call` |
| 0005-R12 | `test/core/firebase_providers_test.dart` › `analyticsServiceProvider` › `is a no-op where the environment disables analytics` |

## Open questions

- Screen-view logging still runs through the same gate, which means an opted-out
  user produces no funnel data at all. That is correct, but it does mean
  aggregate navigation metrics under-report by however many users opt out.
