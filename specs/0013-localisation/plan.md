# Implementation Plan: 0013 · Localisation

- **Status:** Accepted
- **Created:** 2026-08-21

> Specification: [`spec.md`](spec.md)

## Design

`flutter_localizations` + `gen-l10n`, configured by `l10n.yaml`. `generate: true`
in `pubspec.yaml` means every `pub get` regenerates, so the lookup tables cannot
drift from the ARB.

`context.l10n` (an extension on `BuildContext`) keeps call sites short. `AppLocales`
exposes the supported list so Settings builds its picker from the same source
`MaterialApp` is configured with.

R8 is why `LocaleController` stores `Locale?` and *removes* the key for "match
system": storing the resolved locale instead would freeze the choice the first
time the app ran.

R12 is handled by `Note.titleOr(fallback)` — the domain object takes the
placeholder as an argument, and the screen supplies `l10n.untitledNote`.
`displayTitle` remains for logs and `toString`.

R5 is tested off the `@key.placeholders` **metadata**, not a regex over the
string: ICU plural branches contain their own braces, so a naive scan mistakes
translated words for placeholder names.
