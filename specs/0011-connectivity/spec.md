# 0011 · Connectivity and automatic sync

- **Status:** Accepted
- **Created:** 2026-08-21

## Context

[Spec 0002](../0002-notes-sync/spec.md) leaves a write queued when the network is down.
Something has to notice the network coming back, or the queue only drains when
the user happens to tap Sync — which they have no reason to do, because the app
told them their note was saved.

`connectivity_plus` is a poor fit as-is: it reports a *list of interfaces* and
says nothing about whether the internet is reachable. Left raw, "is this online?"
gets re-litigated at every call site.

## Requirements

| ID | Requirement |
|---|---|
| 0011-R1 | Reachability MUST be reduced to one enum in one place. |
| 0011-R2 | The status stream MUST emit the current state immediately to every subscriber. |
| 0011-R3 | The stream MUST NOT re-emit an unchanged status. |
| 0011-R4 | The subscription MUST be cancellable without deadlock. |
| 0011-R5 | A failed platform probe MUST assume online rather than blocking the UI. |
| 0011-R6 | Queued writes MUST be pushed on an offline→online transition. |
| 0011-R7 | A sync MUST NOT fire on the initial emission, only on a transition. |
| 0011-R8 | A flapping connection MUST NOT start overlapping syncs. |
| 0011-R9 | An offline banner MUST be visible on every screen. |
| 0011-R10 | The banner copy MUST reassure, not alarm — writes still succeed offline. |

## Non-goals

- **Reachability probing.** A captive portal reports a connection. "Online" here
  means *worth trying*, which is all the sync layer needs — it already re-queues
  a failed request.
- **Backoff.** A reconnect triggers one attempt. Repeated failure waits for the
  next transition or a manual tap.

## Verification

| ID | Test |
|---|---|
| 0011-R1 | `test/core/connectivity/connectivity_service_test.dart` › `PlatformConnectivityService.classify` |
| 0011-R2 | `test/core/connectivity/platform_connectivity_service_test.dart` › `onStatusChanged` › `seeds the current status to a new subscriber` |
| 0011-R3 | `…` › `onStatusChanged` › `does not re-emit an unchanged status` |
| 0011-R4 | `…` › `onStatusChanged` › `the subscription can be cancelled promptly` |
| 0011-R5 | `…` › `onStatusChanged` › `assumes online when the initial probe throws` |
| 0011-R6 | `test/features/notes/reconnect_sync_test.dart` › `pushes a queued write once the network returns` |
| 0011-R7 | `…` › `does not sync on the initial status emission` |
| 0011-R8 | `…` › `a flapping connection does not start overlapping syncs` |
| 0011-R9 | `test/app/widgets/app_banners_test.dart` › `OfflineBanner` › `shows over the sign-in screen too` |
| 0011-R10 | `…` › `OfflineBanner` › `the copy reassures rather than alarms` |

## Open questions

- R8's test asserts "at most 2" rather than exactly 1. The guard prevents
  *overlap*, not a second sync after the first completes — which is arguably
  correct, but the requirement is looser than it reads.
