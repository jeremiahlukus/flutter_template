# Implementation Plan: 0008 · Design system

- **Status:** Accepted
- **Created:** 2026-08-21

> Specification: [`spec.md`](spec.md)

## Design

Four files under `lib/src/app/theme/`:

- `design_tokens.dart` — `AppSpacing`, `AppRadius`, `AppDurations`,
  `AppBreakpoints`. Durations are named by *intent* (`quick`, `moderate`) so
  "make it snappier" is one edit rather than a hunt through the widget tree.
- `app_semantic_colors.dart` — a `ThemeExtension`, so status colours are reached
  the same way as any other themed colour and animate with the rest.
- `app_brand.dart` — six seed presets. Material 3 derives a whole scheme from one
  colour, so this is all a rebrand needs.
- `app_theme.dart` — every component theme, in one place.

R4 is enforced by a test that computes real WCAG relative-luminance ratios over
every pair. A status colour nobody can read is worse than no status colour.

The brand picker in Settings doubles as a live preview: tapping a swatch
re-derives the scheme in place, which is the fastest way to see whether the
design system actually holds together.
