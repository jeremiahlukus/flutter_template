---
description: "Create a feature branch prefixed with the next free spec number (timestamp fallback)"
---

# Create Feature Branch

Create and switch to a new git feature branch for the given specification. This command handles **branch creation only** — the spec directory and files are created by the core `__SPECKIT_COMMAND_SPECIFY__` workflow.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Environment Variable Override

If the user explicitly provided `GIT_BRANCH_NAME` (e.g., via environment variable, argument, or in their request), pass it through to the script by setting the `GIT_BRANCH_NAME` environment variable before invoking the script. When `GIT_BRANCH_NAME` is set:
- The script uses the exact value as the branch name, bypassing all prefix/suffix generation
- `--short-name`, `--number`, and `--timestamp` flags are ignored
- `FEATURE_NUM` is extracted from the name if it starts with a numeric prefix, otherwise set to the full branch name

## Prerequisites

- Verify Git is available by running `git rev-parse --is-inside-work-tree 2>/dev/null`
- If Git is not available, warn the user and skip branch creation

## Branch Numbering Mode

The branch prefix is the **next free spec number** (`branch_numbering: sequential`,
configured in `.specify/extensions/git/git-config.yml`) — four digits, continuing the
existing `specs/NNNN-slug/` sequence, so the one after `0024-settings-composability`
is `0025`. The script derives it from the highest number across `specs/` and existing
branches, so two people starting features do not collide.

Pass `--timestamp` instead for work that should not take a number.

## Execution

Generate a concise short name (2-4 words) for the branch:
- Analyze the feature description and extract the most meaningful keywords
- Use action-noun format when possible (e.g., "add-user-auth", "fix-payment-bug")
- Preserve technical terms and acronyms (OAuth2, API, JWT, etc.)

Let the script allocate the number — do not pick one yourself, and do not pass
`GIT_BRANCH_NAME` unless the user asked for an exact branch name:

- **Numbered (default)**:
  `.specify/extensions/git/scripts/bash/create-new-feature.sh --json --short-name "<short-name>" "<feature description>"`
- **Unnumbered** (spike, chore, anything not getting a spec number):
  `.specify/extensions/git/scripts/bash/create-new-feature.sh --json --timestamp --short-name "<short-name>" "<feature description>"`

**IMPORTANT**:
- Always include the JSON flag (`--json` for Bash, `-Json` for PowerShell) so the output can be parsed reliably
- You must only ever run this script once per feature
- The JSON output will contain `BRANCH_NAME` and `FEATURE_NUM`

## Graceful Degradation

If Git is not installed or the current directory is not a Git repository:
- Branch creation is skipped with a warning: `[specify] Warning: Git repository not detected; skipped branch creation`
- The script still outputs `BRANCH_NAME` and `FEATURE_NUM` so the caller can reference them

## Output

The script outputs JSON with:
- `BRANCH_NAME`: The branch name (e.g., `0025-dark-mode` or `20260319-143022-dark-mode`)
- `FEATURE_NUM`: The four-digit or timestamp prefix used
