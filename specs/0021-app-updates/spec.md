# 0021 · App updates

- **Status:** Accepted
- **Created:** 2026-08-22

## Context

Old clients are a permanent tax. Once a backend contract changes, a build from
eighteen months ago either breaks confusingly or forces you to keep supporting
it. A version floor you can raise remotely is the cheapest way out — but it is
also a remote kill switch, so the failure modes matter more than the feature.

## Requirements

| ID | Requirement |
|---|---|
| 0021-R1 | Versions MUST compare numerically, not lexicographically. |
| 0021-R2 | An unparseable version MUST resolve to "no information", not an error. |
| 0021-R3 | A build below the floor MUST be blocked from use. |
| 0021-R4 | A build below the latest, but above the floor, MUST NOT be blocked. |
| 0021-R5 | An unreadable policy MUST fail open. |
| 0021-R6 | An unknown local version MUST fail open. |
| 0021-R7 | A build ahead of the latest MUST NOT be nagged. |
| 0021-R8 | The block MUST replace the app, not overlay it. |
| 0021-R9 | A missing store URL MUST hide the action rather than show a dead button. |
| 0021-R10 | An optional update MUST be informational only. |

## Non-goals

- **In-app updates** (Android's `in_app_update`, iOS has no equivalent).
  Deep-linking to the store is portable and enough.
- **Staged rollout / percentage gating.** Remote Config territory.
- **Remote Config as the transport.** A Firestore document needs no extra SDK, is
  covered by the rules already in place, and is editable from the console mid
  incident.

## Verification

| ID | Test |
|---|---|
| 0021-R1 | `test/features/update/app_version_test.dart` › `ordering` › `does not compare components lexicographically` |
| 0021-R2 | `…` › `tryParse` › `returns null rather than throwing on nonsense`; `UpdatePolicy.fromMap` › `unparseable versions become null, not an exception` |
| 0021-R3 | `test/features/update/update_gate_test.dart` › `UpdateGate` › `replaces the app when an update is required` |
| 0021-R4 | `…` › `UpdateGate` › `does not gate an optional update` |
| 0021-R5 | `…` › `updatePolicyProvider` › `is empty when the document is missing` |
| 0021-R6 | `…app_version…` › `requirementFor` › `is none when the current version is unknown` |
| 0021-R7 | `…app_version…` › `requirementFor` › `is none when ahead of the latest` |
| 0021-R8 | `…update_gate…` › `UpdateGate` › `replaces the app…` (asserts the app is gone) |
| 0021-R9 | `…` › `UpdateGate` › `hides the action when no store URL is configured` |
| 0021-R10 | `…` › `OptionalUpdateTile` › `appears in Settings for an optional update` |

## Open questions

- The policy is read once per launch. A user left running for days will not see a
  newly-raised floor until they restart — acceptable, and cheaper than a listener.
