# Implementation Plan: 0012 · Shared UI kit

- **Status:** Accepted
- **Created:** 2026-08-21

> Specification: [`spec.md`](spec.md)

## Design

`app_states.dart`:

- `AppEmptyState` — icon, title, optional message, optional action.
- `AppErrorState` — an `AppEmptyState` with an error icon and a retry button.
- `AppLoadingIndicator` — the app's single spinner.
- `AsyncValueView<T>` — the one that earns its keep. `isEmpty` + `onEmpty`
  together satisfy R3; `errorKey` satisfies R5.

`app_banners.dart` holds `OfflineBanner` ([0011](../0011-connectivity/spec.md)) and
`EnvironmentBanner` ([0009](../0009-environments/spec.md)), both attached in
`MaterialApp.builder` so they apply to every screen with no per-screen wiring.

The notes screen is the worked example: its body is one `AsyncValueView` rather
than the switch it used to be.
