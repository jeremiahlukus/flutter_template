# 0013 · Localisation

- **Status:** Accepted
- **Created:** 2026-08-21

## Context

Retrofitting localisation is the painful part — it touches every screen at once,
which is exactly the work a template should absorb up front.

Two failure modes are worth designing against:

1. **A missing translation falls back to English silently.** It ships unnoticed.
2. **A dropped placeholder throws at runtime, not at build time.** A translator
   deleting `{count}` produces a crash nobody sees until that locale is used.

There is also a structural problem: domain objects have no `BuildContext`, so
`Note.displayTitle` cannot localise its own fallback.

## Requirements

| ID | Requirement |
|---|---|
| 0013-R1 | Every user-visible string MUST come from an ARB file. |
| 0013-R2 | At least two locales MUST ship, so the setup is genuinely exercised. |
| 0013-R3 | Every locale MUST define every message English defines. |
| 0013-R4 | No locale MAY carry a key English does not. |
| 0013-R5 | Every declared placeholder MUST appear in every translation. |
| 0013-R6 | Counts MUST use ICU plurals, not string concatenation. |
| 0013-R7 | The locale MUST be user-selectable and persisted. |
| 0013-R8 | "Match system" MUST be a distinct, storable choice from any explicit locale. |
| 0013-R9 | An unsupported stored locale MUST fall back to the system. |
| 0013-R10 | A locale change MUST re-render without a restart. |
| 0013-R11 | CI MUST fail on any untranslated message. |
| 0013-R12 | Domain objects MUST NOT hard-code user-visible copy. |
| 0013-R13 | Copy every fork keeps — onboarding, auth, setup, settings — MUST NOT name a feature the fork may delete. |

## Non-goals

- **RTL layout.** `en` and `es` are both LTR. Adding an RTL locale needs a
  layout pass this template has not done.
- **Localised date and number formatting.** `intl` is a dependency; nothing
  formats a date for display yet.
- **Translating `AuthFailure` / `StorageFailure` messages.** The English strings
  on those exceptions are developer-facing fallbacks. The ARB carries `auth*` and
  `storage*` keys ready for a code→message mapping in the presentation layer;
  wiring it is a task, not a gap in this spec.

## Verification

| ID | Test |
|---|---|
| 0013-R1 | `test/l10n/l10n_test.dart` › `rendering` › `renders Spanish when that locale is stored` |
| 0013-R2 | `…` › `AppLocales` › `ships more than one locale, so the setup is actually exercised` |
| 0013-R3 | `…` › `ARB files` › `no translation is missing` |
| 0013-R4 | `…` › `ARB files` › `no locale carries keys English does not` |
| 0013-R5 | `…` › `ARB files` › `every declared placeholder appears in every translation` |
| 0013-R6 | `test/features/notes/presentation/notes_screen_test.dart` › `syncMessage` › `uses the singular for one stuck note` |
| 0013-R7 | `test/features/settings/presentation/settings_screen_test.dart` › `language` › `choosing Spanish re-renders and persists` |
| 0013-R8 | `…` › `language` › `choosing system clears the stored locale` |
| 0013-R9 | `test/l10n/l10n_test.dart` › `LocaleController.decode` › `an unsupported code falls back to the system` |
| 0013-R10 | `…` › `rendering` › `a locale change re-renders without a restart` |
| 0013-R11 | `.github/workflows/ci.yaml` › `Verify every message is translated` |
| 0013-R12 | `test/features/notes/note_test.dart` › `displayTitle`; `titleOr` is passed `l10n.untitledNote` by the screen |
| 0013-R13 | `test/l10n/l10n_test.dart` › `ARB files` › `copy outside the notes feature names no feature` |

## Open questions

- The Spanish translations were written without a native reviewer. They are
  grammatical but should be reviewed before anyone ships to a Spanish market.
