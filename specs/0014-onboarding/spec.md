# 0014 · Onboarding

- **Status:** Accepted
- **Created:** 2026-08-21

## Context

A sign-in screen as the first thing a new user sees asks for commitment before
explaining anything. A short intro raises activation, and it is cheap — but only
if the gate is right. Two ways it goes wrong:

1. **A returning user sees a flash of onboarding** on a cold start, because the
   "has it been seen?" read is async and the guard defaulted to "not seen".
2. **It reappears after switching accounts**, because completion was stored
   per-user rather than per-device.

## Requirements

| ID | Requirement |
|---|---|
| 0014-R1 | The intro MUST be shown once per device, before sign-in. |
| 0014-R2 | Completion MUST be device-local, not per-account. |
| 0014-R3 | A returning user MUST NOT see a flash of onboarding while the flag loads. |
| 0014-R4 | Completion MUST survive a restart. |
| 0014-R5 | The gate MUST be checked before the auth guard. |
| 0014-R6 | A completed intro MUST be unreachable, even by direct navigation. |
| 0014-R7 | Skip MUST be available on every page. |
| 0014-R8 | Finishing MUST land a signed-out user on sign-in and a signed-in user on the notes list. |
| 0014-R9 | Finishing MUST re-run the route guard without an explicit navigation. |
| 0014-R10 | The intro copy MUST describe template capabilities (sync, offline, per-user privacy), not the `notes` example feature. |

## Non-goals

- **Permission prompts during onboarding.** No permissions are requested yet.
- **A "replay the intro" setting.** `OnboardingController.reset()` exists; no UI
  exposes it.
- **Per-feature tooltips or coach marks.**

## Verification

| ID | Test |
|---|---|
| 0014-R1 | `test/features/onboarding/onboarding_test.dart` › `OnboardingScreen` › `is what a first-run user lands on` |
| 0014-R2 | `…` › `OnboardingController` › `complete() persists the flag` (device-local settings table) |
| 0014-R3 | `…` › `onboardingCompletedProvider` › `assumes complete while the read is in flight` |
| 0014-R4 | `…` › `OnboardingController` › `completion survives a restart` |
| 0014-R5 | `test/routing/redirect_test.dart` › `onboarding` › `takes precedence over the auth guard` |
| 0014-R6 | `…` › `onboarding` › `a completed user is bounced off the intro` |
| 0014-R7 | `test/features/onboarding/onboarding_test.dart` › `OnboardingScreen` › `Skip completes it immediately` |
| 0014-R8 | `…` › `a signed-out user reaches sign-in after finishing` / `a signed-in user reaches the notes list after finishing` |
| 0014-R9 | `…` › `finishing marks it complete and moves on` |
| 0014-R10 | `test/l10n/l10n_test.dart` › `ARB files` › `copy outside the notes feature names no feature` |

## Open questions

None.
