# Specs

This template is developed spec-first. Every behaviour a maintainer relies on is
written down here **before** it is implemented, and every requirement carries an
ID that a test can name.

The point is not ceremony. It is that six months from now, "why does sync push
before it pulls?" has an answer you can read, and a test that fails if someone
changes their mind without changing the spec.

## The loop

Driven by [spec-kit](https://github.com/github/spec-kit)'s lean preset. Five
commands, each producing one file:

| Step | Command | Produces |
|---|---|---|
| 1 | `/speckit-specify <description>` | `spec.md` — requirements, numbered |
| 2 | `/speckit-plan` | `plan.md` — the design, checked against the constitution |
| 3 | `/speckit-tasks` | `tasks.md` — ordered, tests before code |
| 4 | `/speckit-implement` | the code, ticking tasks off as it goes |

`/speckit-specify` allocates the next number and creates the branch, so you never
pick either by hand. `/speckit-constitution` amends the rules in
[`.specify/memory/constitution.md`](../.specify/memory/constitution.md).

You do not have to use the commands — a spec written by hand in the same format is
a spec. The commands exist so the boring parts (numbering, branch, the
Verification table, running the gates) are not the parts you forget.

**The step that matters is the Verification table.** Every requirement names the
test that proves it, or an honest `—`. `/speckit-tasks` turns every `—` into a
task, which is the whole reason the pipeline is worth running: a spec with an empty
Verification table is a wish, not a spec.

## Anatomy of a spec

Each spec is a directory, `specs/NNNN-slug/`:

| File | What it is | Written by |
|---|---|---|
| `spec.md` | **What and why.** Context, numbered requirements, non-goals, Verification, open questions. | `/speckit-specify` |
| `plan.md` | **How.** The design and the trade-offs taken. | `/speckit-plan` |
| `tasks.md` | Ordered work items, ticked off as they land. | `/speckit-tasks` |

`research.md`, `data-model.md`, `contracts/` and `quickstart.md` are optional and
usually unnecessary — none of the 24 specs below needed one. `/speckit-plan`
decides, and says why not.

Inside `spec.md`:

| Section | What goes in it |
|---|---|
| **Status** | `Draft` / `Accepted` / `Superseded by NNNN` |
| **Context** | The problem. Why the obvious approach is not enough. |
| **Requirements** | Numbered, individually testable statements. `MUST` / `SHOULD` / `MAY`. |
| **Non-goals** | What this deliberately does not do, so scope creep is visible. |
| **Verification** | Requirement ID → the test that proves it, or `—`. |
| **Open questions** | Known unknowns. Empty is a valid answer. |

The 24 specs below predate the spec-kit layout and were migrated into it
mechanically: what was one file is now `spec.md` (everything but the design) plus
`plan.md` (the design). None of them carry a `tasks.md` — the work is already
done, and back-filling task lists for shipped features would be fiction.

## Requirement IDs

`<SPEC>-R<n>` — e.g. `0002-R4` is the fourth requirement of spec 0002.

Reference the ID in the test's `reason:` or in a comment when the connection is
not obvious from the test name. Grep is the traceability tool; there is no
tooling to install.

## Numbering

Sequential, never reused. A spec is never deleted — a replaced one gets
`Status: Superseded by NNNN` and stays, because the reasoning that led there is
often the most useful part.

## Index

| # | Spec | Status |
|---|---|---|
| [0001](0001-authentication/spec.md) | Authentication | Accepted |
| [0002](0002-notes-sync/spec.md) | Offline-first notes sync | Accepted |
| [0003](0003-local-persistence/spec.md) | Local persistence (Drift) | Accepted |
| [0004](0004-routing/spec.md) | Routing and route guards | Accepted |
| [0005](0005-analytics/spec.md) | Analytics | Accepted |
| [0006](0006-file-storage/spec.md) | File storage | Accepted |
| [0007](0007-quality-gates/spec.md) | Quality gates | Accepted |
| [0008](0008-design-system/spec.md) | Design system | Accepted |
| [0009](0009-environments/spec.md) | Environments and configuration | Accepted |
| [0010](0010-error-reporting/spec.md) | Error reporting | Accepted |
| [0011](0011-connectivity/spec.md) | Connectivity and automatic sync | Accepted |
| [0012](0012-ui-kit/spec.md) | Shared UI kit | Accepted |
| [0013](0013-localisation/spec.md) | Localisation | Accepted |
| [0014](0014-onboarding/spec.md) | Onboarding | Accepted |
| [0015](0015-first-run/spec.md) | First run and misconfiguration | Accepted |
| [0016](0016-emulator-and-rules/spec.md) | Emulator suite and security rules | Accepted |
| [0017](0017-api-client/spec.md) | API client | Accepted |
| [0018](0018-pagination/spec.md) | Pagination | Accepted |
| [0019](0019-media/spec.md) | Image picking | Accepted |
| [0020](0020-push-notifications/spec.md) | Push notifications | Accepted |
| [0021](0021-app-updates/spec.md) | App updates | Accepted |
| [0022](0022-accessibility/spec.md) | Accessibility | Accepted |
| [0023](0023-visual-regression/spec.md) | Visual regression | Accepted |
| [0024](0024-settings-composability/spec.md) | Settings composability | Accepted |

Start a new one with `/speckit-specify`, or by hand from
[`.specify/templates/spec-template.md`](../.specify/templates/spec-template.md).
