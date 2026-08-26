# Implementation Plan: 0005 · Analytics

- **Status:** Accepted
- **Created:** 2026-08-21

> Specification: [`spec.md`](spec.md)

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
