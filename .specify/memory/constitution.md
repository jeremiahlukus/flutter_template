<!--
Sync Impact Report
Version change: — → 1.0.0
Bump rationale: MAJOR/initial. First constitution for this repo. Ratifies rules
  that already governed the codebase in CLAUDE.md and README.md; nothing here is
  a new constraint, so no code or spec had to change to comply.
Modified principles: none (initial adoption).
Templates/docs requiring sync: checked CLAUDE.md (now cites principles by
  number), README.md (spec-driven section rewritten for the spec-kit layout),
  specs/README.md (loop rewritten around the five commands),
  .specify/templates/*.md (plan-template's Constitution Check now names these
  principles). All updated in the same change.
Prior history: none.
-->

# Flutter Template Constitution

The rules a maintainer of this template can rely on. Everything here was already
true — it lived in `CLAUDE.md` and `README.md` as prose. Writing it down as a
constitution means `/speckit-plan` can check a design against it before any code
is written, instead of a reviewer catching it afterwards.

## Core Principles

### I. Spec Before Code (NON-NEGOTIABLE)

Behaviour a maintainer will rely on is specified before it is built. A change to
observable behaviour updates its spec in the same commit.

Every spec lives in `specs/<NNNN>-<slug>/` and carries numbered requirements
(`0002-R5`), so a requirement can be cited from a commit, a test name, or a code
comment and still be findable years later. Requirement IDs are permanent: renumber
nothing, retire a requirement by marking it superseded.

**Rationale:** the template's value is that its behaviour is written down. Code
without a spec is a feature nobody can safely change.

### II. Every Requirement Names Its Test (NON-NEGOTIABLE)

Each spec has a **Verification** table mapping every requirement ID to a real,
named test. A requirement with `—` in the Test column is unproven, and that is a
bug in either the spec or the suite.

A test named in a Verification table must exist and must actually exercise the
requirement. Renaming a test means updating the table in the same commit.

**Rationale:** this is the only mechanism that stops a spec drifting into
aspiration. It has repeatedly caught requirements that read as satisfied and were
not — see `0016`, where the rules for push tokens and the update gate were
written, believed, and denying every write in production.

### III. Four Gates, All Passing

No change is done until all four pass:

1. `flutter analyze --fatal-infos --fatal-warnings` — zero issues, infos included
2. `flutter test --exclude-tags golden`
3. Coverage ≥ 85% (`dart run tool/check_coverage.dart --min 85`)
4. `cd test_rules && npm test` — if any `*.rules` file changed

Goldens (`flutter test --tags golden`) are platform-pinned to macOS and run as
their own job.

A gate is never weakened to make a change pass. Every lint relaxation and coverage
exclusion is justified in place, next to the code it applies to.

### IV. The Test Suite Needs Nothing (NON-NEGOTIABLE)

`flutter test` passes on a fresh clone with no Firebase project, no network, and
no emulator.

Every Firebase SDK singleton sits behind a provider in
`lib/src/core/providers/firebase_providers.dart`. Anything touching a platform
channel sits behind an interface with a fake beside it. Nothing in `lib/` may
import a native-only library (`dart:ffi`, `dart:io`, `dart:mirrors`,
`package:drift/native.dart`) — that breaks the web build silently, and
`flutter analyze` says nothing about it.

**Rationale:** a template whose tests need credentials is a template nobody runs
the tests for.

### V. Offline Is The Default, Not A Mode

Firestore is the source of truth; **Drift is what the UI reads**. A write succeeds
locally and syncs later. Push happens before pull so a fresh local write is not
clobbered by a stale remote one.

A failed sync must be visible to the user. Silently swallowing it and reporting
success is the specific failure this principle exists to prevent.

### VI. Localised, Accessible, Themed — By Construction

- No hard-coded user-visible strings. Every string lives in **every** ARB file.
- No inline colours, spacing, radii, or durations — use `lib/src/app/theme/`.
- Every interactive widget carries a `ValueKey`; every icon-only button carries a
  `tooltip`, which is its accessibility label.
- Repositories throw typed failures with a `code`; the UI maps the code to
  localised copy, never the message.

These are enforced by tests in `test/a11y/` and `test/l10n/`, not by review.

### VII. A Fork Must Not Have To Edit The Template

Anything a fork will reasonably want to change is a seam: a public widget, an
overridable provider, a named constant, a documented parameter. If adapting the
template means editing one of its files, that fork stops receiving upstream fixes
the first time it does so.

**Rationale:** learned from `0024` — private settings sections and welded-in
chrome left a real fork no option but to edit the file and own the conflict
forever.

## Development Workflow

Specs are produced with the spec-kit commands, in order:

| Command | Produces |
|---|---|
| `/speckit-specify` | `specs/<NNNN>-<slug>/spec.md` |
| `/speckit-plan` | `plan.md` (+ `research.md`/`data-model.md`/`contracts/` when warranted) |
| `/speckit-tasks` | `tasks.md` |
| `/speckit-implement` | code, ticking tasks off as it goes |
| `/speckit-constitution` | amendments to this file |

`/speckit-specify` runs the `before_specify` hook, which creates the feature
branch and allocates the next four-digit number.

**Auto-commit is off.** Every entry under `auto_commit` in
`.specify/extensions/git/git-config.yml` is `false`. Commits and pushes need
explicit approval, every time. The hooks may create a branch; they may not write
history on your behalf.

## Governance

This constitution supersedes prose guidance elsewhere in the repo. Where they
disagree, this file wins and the other document is wrong and should be fixed.

**Amendments** go through `/speckit-constitution`, which requires a semantic
version bump, a Sync Impact Report prepended to this file, and a propagation check
across the templates, `README.md`, `CLAUDE.md`, and `specs/README.md`.

**Agent context files** (`CLAUDE.md`, `AGENTS.md`) cite principles by number and
do not restate them. A rule written in two places drifts in one of them.

**Version**: 1.0.0 | **Ratified**: 2026-08-26 | **Last Amended**: 2026-08-26
