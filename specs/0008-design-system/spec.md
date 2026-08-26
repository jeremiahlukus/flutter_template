# 0008 · Design system

- **Status:** Accepted
- **Created:** 2026-08-21

## Context

"Theming" in most templates means one `ColorScheme.fromSeed` call, which leaves
every screen still hard-coding padding, radii, and status colours. Three specific
gaps cause the drift:

1. **No spacing scale.** Ad-hoc numbers mean nobody remembers whether the last
   card used 12 or 14, and layouts stop looking related.
2. **`ColorScheme` has no success/warning/info.** It gives you `error` and
   nothing else, so people reach for `Colors.green` — which breaks in dark mode.
3. **Rebranding means touching every screen.** Unless every colour is derived
   from one seed.

## Requirements

| ID | Requirement |
|---|---|
| 0008-R1 | Spacing, radii, durations, and breakpoints MUST come from named tokens, never inline numbers. |
| 0008-R2 | The spacing scale MUST be strictly ascending and whole-pixel. |
| 0008-R3 | Success, warning, and info colours MUST be theme-aware and available in both brightnesses. |
| 0008-R4 | Every foreground/background pair MUST meet WCAG AA (4.5:1) contrast. |
| 0008-R5 | The semantic-colour lookup MUST degrade to a readable palette rather than throwing. |
| 0008-R6 | The semantic colours MUST interpolate, so a theme change animates. |
| 0008-R7 | Changing one enum value MUST re-derive the entire theme, light and dark. |
| 0008-R8 | Every brand preset MUST produce a visibly distinct scheme. |
| 0008-R9 | Every tappable control MUST meet the 48dp Material touch-target minimum. |
| 0008-R10 | The type scale MUST be explicit, so a font swap is one edit. |
| 0008-R11 | The brand choice MUST persist across restarts. |
| 0008-R12 | Wide windows MUST cap content width rather than stretching text full-bleed. |

## Non-goals

- **A custom font.** `google_fonts` is a one-line addition; the type scale in
  `AppTheme._textTheme` is where it plugs in.
- **Per-brand semantic colours.** Success is green in every brand. If that ever
  needs to vary, `AppSemanticColors` becomes a function of `AppBrand`.
- **Component *widgets*.** This spec covers tokens and `ThemeData`. Shared
  widgets are in [0012](../0012-ui-kit/spec.md).

## Verification

| ID | Test |
|---|---|
| 0008-R1 | `test/app/theme/design_tokens_test.dart` (whole file) |
| 0008-R2 | `…` › `AppSpacing` › `the scale is strictly ascending` / `every step is a whole number of logical pixels` |
| 0008-R3 | `test/app/theme/app_semantic_colors_test.dart` › `palettes` › `light and dark differ on every role` |
| 0008-R4 | `…` › `palettes` › `foreground colours are legible on their backgrounds` |
| 0008-R5 | `…` › `of(context)` › `falls back to light when the extension is absent` |
| 0008-R6 | `…` › `lerp` › `at t=0.5 lands between the two` |
| 0008-R7 | `test/app/theme/app_theme_test.dart` › `brand seeding` › `a brand seeds both light and dark consistently` |
| 0008-R8 | `…` › `brand seeding` › `every brand produces a distinct primary` |
| 0008-R9 | `…` › `component theming` › `every button meets the 48dp touch target minimum` |
| 0008-R10 | `…` › `typography` › `headings are weighted more than body text` |
| 0008-R11 | `test/features/settings/presentation/settings_screen_test.dart` › `accent colour` › `a stored brand is applied on open` |
| 0008-R12 | `lib/src/features/notes/presentation/note_editor_screen.dart` uses `AppBreakpoints.maxContentWidth`; covered indirectly by `test/app/theme/design_tokens_test.dart` › `maxContentWidth keeps lines readable` |

## Open questions

- R12 is only weakly verified — the constant is tested, the layout is not.
  A golden test at three widths is the right answer.
