# Implementation Plan: 0024 · Settings composability

- **Status:** Accepted
- **Created:** 2026-08-24

> Specification: [`spec.md`](spec.md)

## Design

`settings_screen.dart` splits into three layers:

1. **The sections** — `ThemeModeSection`, `BrandSection`, `LanguageSection`,
   `PushSection`, `AnalyticsSection`, `SyncSection`, plus
   `SettingsSectionHeader` for forks writing their own. All public, all
   `{super.key}`, each independently mountable.
2. **`SettingsSections`** — the template's default ordering, and nothing else.
   No `Scaffold`, no padding assumptions. A fork that wants a different set does
   not use this; it lists the sections it wants.
3. **`SettingsScreen({this.showBackButton = true})`** — the routed screen. Owns
   only the `Scaffold` and the `AppBar`.

`showBackButton` defaults to `true` because the failure modes are asymmetric: a
stray back arrow on a tab is cosmetic, while a missing one on a pushed route
traps the user. The default protects the case that cannot be recovered from.

Note what is *not* parameterised: the sections take no configuration objects and
no callbacks. Each reads what it needs from its own provider. That is what makes
them mountable in isolation, and it is why point 1 is a requirement rather than a
style note.
