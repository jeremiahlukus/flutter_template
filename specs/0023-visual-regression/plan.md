# Implementation Plan: 0023 · Visual regression

- **Status:** Accepted
- **Created:** 2026-08-22

> Specification: [`spec.md`](spec.md)

## Design

One wide showcase surface per theme, rather than one golden per component: a
component regression almost always shows up next to its neighbours, and 6 brands
× 2 brightnesses × N components would be unreviewable. That gives 12 goldens
covering app bar, type scale, inputs, all four button types, cards, chips
(including the semantic colours), dividers, list tiles, and progress indicators.

R4 and R5 exist because rounded-corner anti-aliasing can differ between platform
Skia builds. Rather than guess, the `golden` tag is excluded from the main Ubuntu
job and a dedicated `goldens` job runs on macOS — the platform the committed files
were generated on. A gate that flakes by OS is worse than no gate.

Regenerate with:

```sh
flutter test --tags golden --update-goldens
```
