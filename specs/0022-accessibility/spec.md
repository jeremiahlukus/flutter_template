# 0022 · Accessibility

- **Status:** Accepted
- **Created:** 2026-08-22

## Context

Accessibility bugs are invisible in a normal test run and obvious to anyone
affected. Three kinds account for most of them, and `flutter_test` can assert all
three — which makes leaving them unasserted hard to justify:

1. A control too small to hit reliably.
2. An icon-only button with no label — silence to a screen reader.
3. Text that overflows the moment someone turns font scaling up.

Writing these tests found **four real bugs in this template**, listed below.

## Requirements

| ID | Requirement |
|---|---|
| 0022-R1 | Every tappable MUST meet the 48dp Material minimum. |
| 0022-R2 | Every tappable MUST carry a label or tooltip. |
| 0022-R3 | Text MUST meet contrast guidelines in both brightnesses. |
| 0022-R4 | Every screen MUST render at 2× text scale without overflowing. |
| 0022-R5 | List rows MUST be findable by assistive technology. |
| 0022-R6 | Semantic colours MUST meet WCAG AA (4.5:1). |
| 0022-R7 | These guarantees MUST be asserted for *every* screen, not a sample. |

## Non-goals

- **Manual screen-reader testing.** Nothing replaces VoiceOver/TalkBack by hand;
  see `flutter-skill.md`.
- **Accessibility text sizes above 2×.** iOS's largest accessibility sizes go
  further; 2× is the largest *standard* setting and where most overflow lives.
- **Reduced-motion and high-contrast modes.**

## Verification

| ID | Test |
|---|---|
| 0022-R1 | `test/a11y/accessibility_test.dart` › `tap targets` (per screen) |
| 0022-R2 | `…` › `labels` (per screen) |
| 0022-R3 | `…` › `text contrast` (per screen, plus dark mode) |
| 0022-R4 | `…` › `large text` (per screen, plus sign-in, onboarding, and setup) |
| 0022-R5 | `…` › `semantics tree` › `the notes list exposes its rows to assistive tech` |
| 0022-R6 | `test/app/theme/app_semantic_colors_test.dart` › `foreground colours are legible on their backgrounds` |
| 0022-R7 | `…a11y…` — the `screens` map is the enumeration |

## Open questions

- The `screens` map is maintained by hand. Nothing fails when a new route is
  added without a corresponding entry.
