# 0023 · Visual regression

- **Status:** Accepted
- **Created:** 2026-08-22

## Context

[Spec 0008](../0008-design-system/spec.md) is asserted by unit tests that check *values*:
this radius is 12, this button is at least 48dp, these colours meet contrast. None
of them catches "the theme still compiles but now looks wrong" — a component
theme dropped from `ThemeData`, a radius that stopped applying, a surface colour
that regressed on one brand only.

That is what a golden is for, and `dart_test.yaml` had declared a `golden` tag
since the beginning with nothing using it.

## Requirements

| ID | Requirement |
|---|---|
| 0023-R1 | Every themed component MUST appear in a golden. |
| 0023-R2 | Every brand MUST be covered, in both brightnesses. |
| 0023-R3 | Goldens MUST be tagged so they can be run and excluded selectively. |
| 0023-R4 | The main CI test job MUST NOT run goldens. |
| 0023-R5 | Goldens MUST run in CI, on the platform they were generated on. |
| 0023-R6 | A failing comparison MUST publish its diff images. |

## Non-goals

- **Screen-level goldens.** Screens change constantly; a churning golden gets
  regenerated without being read, which is worse than not having it.
- **Real fonts.** The default test font renders as boxes, so these are not a
  typography review — but layout, colour, spacing, and component shape are all
  verified, and a deterministic font is *more* stable across machines.
- **`golden_toolkit` / `alchemist`.** `matchesGoldenFile` plus a tag is enough at
  this size.

## Verification

| ID | Test |
|---|---|
| 0023-R1 | `test/goldens/design_system_golden_test.dart` › `showcase` builder |
| 0023-R2 | `…` › `brand themes` — 6 brands × light/dark |
| 0023-R3 | `@Tags(['golden'])` on the library; declared in `dart_test.yaml` |
| 0023-R4 | `.github/workflows/ci.yaml` › `Test` step › `--exclude-tags golden` |
| 0023-R5 | `.github/workflows/ci.yaml` › `goldens` job on `macos-latest` |
| 0023-R6 | `…` › `Upload failure diffs` step |

## Open questions

- The macOS pinning is a precaution, not a measured result — the goldens may well
  be identical on Linux with the deterministic test font. Worth checking once,
  since it would remove a macOS CI job.
