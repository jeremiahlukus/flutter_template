# 0009 · Environments and configuration

- **Status:** Accepted
- **Created:** 2026-08-21

## Context

Every app eventually needs dev, staging, and production, and the way it usually
goes wrong is a single `if (kDebugMode)` scattered through the code. Two failures
follow from that:

1. **Dev traffic in production analytics.** Nobody notices until the funnel
   numbers are wrong.
2. **A demo pointed at the wrong backend.** Nothing on screen says which one.

## Requirements

| ID | Requirement |
|---|---|
| 0009-R1 | The environment MUST be a compile-time choice, not a runtime lookup. |
| 0009-R2 | An unrecognised value MUST resolve to dev, never to production. |
| 0009-R3 | Everything that differs per environment MUST live in one config object. |
| 0009-R4 | Dev MUST send nothing to production analytics or crash reporting. |
| 0009-R5 | Each environment MUST have a distinct API base URL. |
| 0009-R6 | Every non-production build MUST display a visible environment banner. |
| 0009-R7 | Dev and staging banners MUST be visually distinguishable. |
| 0009-R8 | Production MUST show no banner and no environment row in Settings. |
| 0009-R9 | The app version and build number MUST be visible in Settings. |
| 0009-R10 | The config MUST be overridable in tests without rebuilding. |

## Non-goals

- **Separate Firebase projects per flavour.** Recommended, but it is per-app
  setup: run `flutterfire configure` once per project and swap the generated
  file per flavour. See task.md.
- **Native flavours** (`--flavor`, Android product flavours, Xcode schemes).
  `--dart-define` covers the Dart side; separate app ids and icons need native
  work this template does not prescribe.

## Verification

| ID | Test |
|---|---|
| 0009-R1 | `test/core/config/app_environment_test.dart` › `current resolves without a dart-define, defaulting to dev` |
| 0009-R2 | `…` › `AppEnvironment.decode` › `falls back to dev for an unknown value` |
| 0009-R3 | `…` › `AppConfig` › `every environment has a config` |
| 0009-R4 | `…` › `AppConfig` › `dev sends nothing to production analytics or crash reporting` |
| 0009-R5 | `…` › `AppConfig` › `api base urls are distinct per environment` |
| 0009-R6 | `test/app/widgets/app_banners_test.dart` › `EnvironmentBanner` › `shows DEV in development` |
| 0009-R7 | `…` › `EnvironmentBanner` › `colours dev and staging differently` |
| 0009-R8 | `…` › `EnvironmentBanner` › `is absent in production`; `test/features/settings/presentation/settings_screen_test.dart` › `about` › `hides the environment row in production` |
| 0009-R9 | `test/features/settings/presentation/settings_screen_test.dart` › `about` › `shows the app version` |
| 0009-R10 | `test/core/config/config_providers_test.dart` › `appConfigProvider` › `is overridable, so tests need no rebuild` |

## Open questions

- The API base URLs are placeholders (`api.example.com`). Nothing consumes them
  yet — there is no HTTP client in the template.
