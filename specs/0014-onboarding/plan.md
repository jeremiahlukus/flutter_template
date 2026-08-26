# Implementation Plan: 0014 · Onboarding

- **Status:** Accepted
- **Created:** 2026-08-21

> Specification: [`spec.md`](spec.md)

## Design

`OnboardingController` is an `AsyncNotifier<bool>` over the Drift settings table
(R2, R4). The interesting decision is `onboardingCompletedProvider`, which
defaults to **true** while the read is in flight — satisfying R3 at the cost of
one invisible frame for a genuinely first-run user. Defaulting the other way
would flash the intro at every returning user on every cold start.

`resolveRedirect` checks onboarding *before* auth (R5) and bounces a completed
user off `/welcome` (R6). The router also listens to
`onboardingCompletedProvider`, so completing the intro re-runs the guard (R9).
