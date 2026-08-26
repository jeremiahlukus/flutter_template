# NNNN · <Title>

- **Status:** Draft
- **Created:** YYYY-MM-DD
- **Supersedes:** —

## Context

What problem is this solving? What breaks or stays annoying if we do nothing?
If there is an obvious approach that does not work, say why here — that is the
part a future reader most needs.

## Requirements

Numbered and individually testable. If you cannot imagine the test, the
requirement is too vague. IDs are permanent: never renumber, retire by marking
superseded.

| ID | Requirement |
|---|---|
| NNNN-R1 | The system MUST … |
| NNNN-R2 | The system MUST NOT … |
| NNNN-R3 | The system SHOULD … |

## Non-goals

- Something a reader might reasonably expect and will not get.

## Verification

Every requirement gets a row. `—` in the Test column means unproven — write it
honestly; `/speckit-tasks` turns each one into a task. Naming a test that does
not exist is the single failure this table exists to prevent (Principle II).

| ID | Test |
|---|---|
| NNNN-R1 | `test/…_test.dart` › `group` › `test name` |
| NNNN-R2 | — |

## Open questions

- Things you know you do not know. Empty is fine; fake certainty is not.
