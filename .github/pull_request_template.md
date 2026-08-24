## What changed

<!-- One or two sentences. What does this do, and why now? -->

## Spec

<!--
Behaviour a maintainer will rely on needs a numbered requirement in specs/.
Link it, or say why this change does not need one (a refactor, a typo, a bump).
-->

- Spec: `specs/NNNN-…md`, requirements: `NNNN-R…`
- [ ] The spec's Verification table names the tests added here

## Checks

- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean
- [ ] `flutter test` passes
- [ ] Coverage still clears the floor (`dart run tool/check_coverage.dart`)
- [ ] `dart format lib test tool` applied
- [ ] Generated code committed (`build_runner build`, `gen-l10n`)
- [ ] New user-visible strings added to **every** ARB file
- [ ] Security rules changed? `cd test_rules && npm test`

## Anything reviewers should look at closely

<!-- A trade-off you took, a case you are unsure about, a thing you left out. -->
