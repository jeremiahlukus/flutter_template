# Specs

This template is developed spec-first. Every behaviour a maintainer relies on is
written down here **before** it is implemented, and every requirement carries an
ID that a test can name.

The point is not ceremony. It is that six months from now, "why does sync push
before it pulls?" has an answer you can read, and a test that fails if someone
changes their mind without changing the spec.

## The loop

```
1. WRITE     Add or edit a spec. Number every requirement.
2. REVIEW    Agree the spec before writing code. Cheapest place to be wrong.
3. TEST      Write failing tests that name the requirement IDs.
4. BUILD     Implement until the tests pass.
5. VERIFY    Fill in the spec's Verification table with the real test names.
6. GATE      `flutter analyze` clean, tests green, coverage ≥ 85%.
```

Step 5 is the one people skip and the one that makes this worth doing. A spec
with an empty Verification table is a wish, not a spec.

## Anatomy of a spec

| Section | What goes in it |
|---|---|
| **Status** | `Draft` / `Accepted` / `Superseded by NNNN` |
| **Context** | The problem. Why the obvious approach is not enough. |
| **Requirements** | Numbered, individually testable statements. `MUST` / `SHOULD` / `MAY`. |
| **Non-goals** | What this deliberately does not do, so scope creep is visible. |
| **Design** | How it works, and the trade-offs taken. |
| **Verification** | Requirement ID → the test that proves it. |
| **Open questions** | Known unknowns. Empty is a valid answer. |

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
| [0001](0001-authentication.md) | Authentication | Accepted |
| [0002](0002-notes-sync.md) | Offline-first notes sync | Accepted |
| [0003](0003-local-persistence.md) | Local persistence (Drift) | Accepted |
| [0004](0004-routing.md) | Routing and route guards | Accepted |
| [0005](0005-analytics.md) | Analytics | Accepted |
| [0006](0006-file-storage.md) | File storage | Accepted |
| [0007](0007-quality-gates.md) | Quality gates | Accepted |
| [0008](0008-design-system.md) | Design system | Accepted |
| [0009](0009-environments.md) | Environments and configuration | Accepted |
| [0010](0010-error-reporting.md) | Error reporting | Accepted |
| [0011](0011-connectivity.md) | Connectivity and automatic sync | Accepted |
| [0012](0012-ui-kit.md) | Shared UI kit | Accepted |
| [0013](0013-localisation.md) | Localisation | Accepted |
| [0014](0014-onboarding.md) | Onboarding | Accepted |
| [0015](0015-first-run.md) | First run and misconfiguration | Accepted |
| [0016](0016-emulator-and-rules.md) | Emulator suite and security rules | Accepted |
| [0017](0017-api-client.md) | API client | Accepted |
| [0018](0018-pagination.md) | Pagination | Accepted |
| [0019](0019-media.md) | Image picking | Accepted |
| [0020](0020-push-notifications.md) | Push notifications | Accepted |
| [0021](0021-app-updates.md) | App updates | Accepted |
| [0022](0022-accessibility.md) | Accessibility | Accepted |
| [0023](0023-visual-regression.md) | Visual regression | Accepted |
| [0024](0024-settings-composability.md) | Settings composability | Accepted |

Start a new one from [`templates/spec-template.md`](templates/spec-template.md).
