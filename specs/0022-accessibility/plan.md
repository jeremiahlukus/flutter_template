# Implementation Plan: 0022 · Accessibility

- **Status:** Accepted
- **Created:** 2026-08-22

> Specification: [`spec.md`](spec.md)

## Design

`test/a11y/accessibility_test.dart` enumerates every reachable screen in one map
and runs each guideline across all of them (R7). Adding a screen means adding one
map entry, which is the point — a sampled a11y suite rots the moment someone adds
a screen.

Guidelines used: `androidTapTargetGuideline`, `iOSTapTargetGuideline`,
`labeledTapTargetGuideline`, `textContrastGuideline`. R6 is asserted separately in
`app_semantic_colors_test.dart` by computing real relative-luminance ratios,
because `ColorScheme` has no success/warning/info for the built-in guideline to
check.

### Bugs this found

| Bug | Fix |
|---|---|
| The profile avatar was a **32dp** tap target | Wrapped in `IconButton`, which supplies 48dp padding |
| Brand colour swatches were **32dp** tap targets | Same |
| Every back button had **no semantic label** | Added a `Back` tooltip (and an ARB string) |
| Onboarding **overflowed at 2× text scale** | Page content made scrollable |

A fifth finding was about the tests, not the app: a tooltip populates the
semantics `tooltip` field, **not** `label`. `labeledTapTargetGuideline` accepts
either, but `find.bySemanticsLabel` does not — worth knowing before writing an
assertion that silently cannot pass.
