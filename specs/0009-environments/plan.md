# Implementation Plan: 0009 · Environments and configuration

- **Status:** Accepted
- **Created:** 2026-08-21

> Specification: [`spec.md`](spec.md)

## Design

`AppEnvironment.current` reads `--dart-define=APP_ENV`. A compile-time constant
satisfies R1 and lets release builds tree-shake dev-only code.

R2 is the interesting choice: failing *towards dev* is deliberate. A typo in a CI
variable should produce a harmless build, not one that believes it is production
and starts writing real analytics.

`AppConfig.forEnvironment` is an exhaustive `switch`, so adding an environment
is a compile error until every field is decided — which is the point.
