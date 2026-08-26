# 0012 · Shared UI kit

- **Status:** Accepted
- **Created:** 2026-08-21

## Context

Every screen that loads anything needs four states — loading, error, empty, and
data — and hand-rolling them per screen produces four slightly different empty
states and one screen that forgot the error case entirely.

There is also a specific bug this prevents: **"loaded but empty" is a distinct
state from "loading"**, and conflating them is how an empty screen ends up
spinning forever.

## Requirements

| ID | Requirement |
|---|---|
| 0012-R1 | Empty, error, and loading states MUST come from shared widgets. |
| 0012-R2 | An `AsyncValue` MUST be renderable without a four-branch switch per screen. |
| 0012-R3 | "Loaded but empty" MUST be distinguishable from "loading". |
| 0012-R4 | The error state MUST offer a retry affordance when one is available. |
| 0012-R5 | Every state MUST accept a key, so integration drivers can target it. |
| 0012-R6 | The widgets MUST take their colours and spacing from the design system. |

## Non-goals

- **A full component library.** Buttons, cards, and inputs are themed in
  [0008](../0008-design-system/spec.md); wrapping them adds a layer with no payoff.
- **Skeleton loaders.** A spinner is honest and cheap. Shimmer is per-app taste.
- **Hiding the real error from the reader.** `AppErrorState` shows
  `error.toString()`, which is right for a template — a developer needs to know
  what broke. Map it to friendly copy before shipping to users.

## Verification

| ID | Test |
|---|---|
| 0012-R1 | `test/app/widgets/app_states_test.dart` › `AppEmptyState` / `AppErrorState` / `AppLoadingIndicator` |
| 0012-R2 | `…` › `AsyncValueView` › `renders data` / `renders a spinner while loading` / `renders the error state on failure` |
| 0012-R3 | `…` › `AsyncValueView` › `renders the empty state for loaded-but-empty data` |
| 0012-R4 | `…` › `AsyncValueView` › `wires retry through to the error state` |
| 0012-R5 | `…` › `AsyncValueView` › `applies errorKey so drivers can target the state` |
| 0012-R6 | `test/app/theme/design_tokens_test.dart` (tokens); widgets read them directly |

## Open questions

None.
