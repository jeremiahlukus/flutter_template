# 0016 · Emulator suite and security rules

- **Status:** Accepted
- **Created:** 2026-08-22

## Context

[Spec 0006](../0006-file-storage/spec.md) left `firestore.rules` and `storage.rules` as
pure assertion: written to mirror the client's paths, executed by nothing. That
is the worst kind of gap, because a client/rules mismatch means uploads land
somewhere unprotected and *nothing fails loudly*.

The obvious fix — test them with the Dart fakes already in the project — does not
work. `fake_firebase_security_rules` (which backs `fake_cloud_firestore`)
supports neither **custom functions** nor **`request.resource`**, and these rules
use both. Verified by experiment: the real rule file parses, and then denies
every operation including the owner's own read.

Rewriting production rules to suit a limited fake would trade real security for
testability. So the emulator it is.

## Requirements

| ID | Requirement |
|---|---|
| 0016-R1 | `firestore.rules` MUST be executed against a real emulator in CI. |
| 0016-R2 | `storage.rules` MUST be executed against a real emulator in CI. |
| 0016-R3 | Ownership and cross-user isolation MUST be covered for both rule sets. |
| 0016-R4 | Document-shape validation MUST be covered. |
| 0016-R5 | Deny-by-default MUST be covered — an unmatched path is denied. |
| 0016-R6 | The app MUST be able to point at the local emulator suite. |
| 0016-R7 | A production build MUST NOT be able to point at the emulator. |
| 0016-R8 | Emulator use MUST be opt-in, never implied by the environment. |
| 0016-R9 | The Node test package MUST be self-contained and not affect `flutter test`. |

## Non-goals

- **Running the whole app against the emulator in CI.** That is
  `integration_test` territory and needs a booted device; see task.md.
- **Testing rules in Dart.** Established above as not possible without
  weakening the rules.
- **Seeding demo data into the emulator.** Useful, but per-app.

## Verification

| ID | Test |
|---|---|
| 0016-R1 | `test_rules/firestore.rules.test.js` (whole file) |
| 0016-R2 | `test_rules/storage.rules.test.js` (whole file) |
| 0016-R3 | `…firestore…` › `isolation between users`; `…storage…` › `denies another user reading it` |
| 0016-R4 | `…firestore…` › `document shape validation` |
| 0016-R5 | `…firestore…` › `deny by default`; `…storage…` › `deny by default` |
| 0016-R6 | `test/core/config/app_environment_test.dart` › `emulators` › `are opt-in` |
| 0016-R7 | `…` › `emulators` › `are never enabled in production` |
| 0016-R8 | `…` › `emulators` › `are off unless explicitly requested` |
| 0016-R9 | `.github/workflows/ci.yaml` › `rules` job |

### The emulators need JDK 21+

The Firestore and Storage emulators are JVM processes, and **firebase-tools 15
dropped support for anything below JDK 21**. The `rules` job pins
`java-version: "21"`, so CI is fine — but a contributor on JDK 17 gets a runtime
failure with no obvious connection to the version bump. Noted in
`test_rules/package.json`.

(The `build android` job deliberately stays on JDK 17, which is what the Android
toolchain wants. Two different Java versions in one workflow is correct here.)

### The lockfile has to be committed, and pinned to the public registry

`npm ci` requires `package-lock.json`, so it is committed. But the first
generated lockfile pinned all 901 `resolved` URLs to a **private corporate
Artifactory** — inherited from the machine's global npm config. CI has no
credentials for it, so the rules job failed with an npm authentication error, and
an internal hostname ended up in a public repo.

`test_rules/.npmrc` now pins `registry.npmjs.org` for this package, so the
lockfile is reproducible regardless of whoever's global config generated it.

## Open questions

- The Storage rules' size limits are tested with real multi-megabyte buffers,
  which makes that file the slowest in the suite. Acceptable at 15 tests.
