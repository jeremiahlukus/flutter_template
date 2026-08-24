# 0024 · Settings composability

- **Status:** Accepted
- **Created:** 2026-08-24

## Context

Settings is the one screen in this template that is guaranteed to be wrong for
every fork. It hosts six sections — theme mode, accent colour, language, push,
analytics, sync — and a fork will keep some, drop others, and add its own
(account, subscription, notifications-per-topic). It will also often want the
sections inside a tab or a pane rather than behind a pushed route.

The original screen made all of that a fork of the file. The sections were
private widgets and the `Scaffold` and back arrow were baked into the same class,
so a fork had exactly two options: edit the template's file, and carry a
permanent conflict against upstream forever; or copy it, and silently lose every
later fix. There is no third option when the parts are not addressable.

This is not a hypothetical — it was found by porting the template into a real
app, which needed to add one section and remove the back arrow, and could do
neither without rewriting the file.

The general rule this encodes: **in a template, the seams matter more than the
screens.** A screen a fork must edit is a screen that stops receiving upstream
changes the first time it is touched.

## Requirements

| ID | Requirement |
|---|---|
| 0024-R1 | Every settings section MUST be a public widget, usable on its own. |
| 0024-R2 | A fork MUST be able to add, remove, and reorder sections without editing the template's files. |
| 0024-R3 | The section list MUST be usable without the surrounding `Scaffold`, so it can sit in a tab or a pane. |
| 0024-R4 | The back affordance MUST be suppressible, because a top-level tab destination has nothing to go back to. |
| 0024-R5 | The back affordance MUST default to present, so an omitted argument cannot strand a pushed route. |
| 0024-R6 | Every section MUST accept a `Key`, so a driver can target it in a fork's own layout. |

## Non-goals

- **A settings DSL or a declarative schema.** A `List<Widget>` is already the
  composition mechanism Flutter provides. Wrapping it in a registry of
  `SettingsItem` descriptors buys nothing and costs a layer of indirection.
- **Persisting section order.** Reordering is a compile-time decision by the
  fork, not a user preference.
- **Splitting each section into its own file.** They are small, and they are read
  together. Publicness is what mattered, not file layout.

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

## Verification

| ID | Test |
|---|---|
| 0024-R1 | `test/features/settings/presentation/settings_composition_test.dart` › `a fork can interleave its own sections` |
| 0024-R2 | `…` › `a fork can interleave its own sections` (own section between two template ones) |
| 0024-R3 | `…` › `a fork can interleave its own sections` (mounted in a bare `ListView`, no `SettingsScreen`) |
| 0024-R4 | `…` › `the back arrow can be dropped for a tab destination` |
| 0024-R5 | `…` › `the back arrow is present by default` |
| 0024-R6 | Enforced by signature — every section is `const X({super.key})`; exercised by the keyed finders in the tests above. |

## Open questions

- Whether `SyncSection` belongs in settings at all, or in a status area. It is
  the one section that reports state rather than accepting a choice.
