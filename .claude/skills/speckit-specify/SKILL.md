---
name: speckit-specify
description: Create a specification and store it in spec.md.
argument-hint: "Describe the feature you want to specify"
compatibility: Requires spec-kit project structure with .specify/ directory
metadata:
  author: github-spec-kit
  source: preset:lean (adapted)
user-invocable: true
disable-model-invocation: false
---

# Speckit Specify Skill

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Pre-Execution Checks

**Check for extension hooks (before specification)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_specify` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- When constructing slash commands from hook command names, replace dots (`.`) with hyphens (`-`). For example, `speckit.git.commit` → `/speckit-git-commit`.
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Pre-Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```
    ## Extension Hooks

    **Automatic Pre-Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}

    Wait for the result of the hook command before proceeding to the Outline.
    ```
    After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing.
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently

## Outline

The text the user typed after `/speckit-specify` in the triggering message **is** the feature description. Assume you always have it available in this conversation even if `$ARGUMENTS` appears literally below. Do not ask the user to repeat it unless they provided an empty command.

Given that feature description, do this:

0. **Read the existing specs before writing a new one.** `specs/README.md` is the
   index. If the feature touches an area an existing spec already owns, the change
   probably belongs *in that spec* as new requirements rather than in a new one —
   Principle I keeps requirement IDs stable and findable, which only works if
   related requirements stay together.

1. **Generate a concise short name** (2-4 words) for the feature:
   - Analyze the feature description and extract the most meaningful keywords
   - Use action-noun format when possible (e.g., "add-user-auth", "fix-payment-bug")
   - Preserve technical terms and acronyms (OAuth2, API, JWT, etc.)

2. **Branch creation** (optional, via hook):

   If a `before_specify` hook ran successfully in the Pre-Execution Checks above, it will have created/switched to a git branch and output JSON containing `BRANCH_NAME` and `FEATURE_NUM`. Note these values for reference, but the branch name does **not** dictate the spec directory name.

   If the user explicitly provided `GIT_BRANCH_NAME`, pass it through to the hook so the branch script uses the exact value as the branch name (bypassing all prefix/suffix generation).

3. **Determine the feature directory**:

   Specs live under `specs/` unless the user explicitly provides `SPECIFY_FEATURE_DIRECTORY`.

   - The prefix is the **next free four-digit number**, continuing the existing
     sequence (`0024-settings-composability` → `0025`).
   - If the `before_specify` git hook already ran and produced a `BRANCH_NAME`,
     reuse that value verbatim as the directory name, so the spec directory and
     the branch always match. Do not re-derive it.
   - If the hook did not run, allocate the number with:
     `bash .specify/extensions/git/scripts/bash/create-new-feature.sh --json --dry-run --short-name "<short-name>" "<description>"`
     and use the `BRANCH_NAME` it prints. **Never pick a number by eye** — it reads
     the highest across both `specs/` and existing branches, which is what stops
     two features colliding on one number.
   - Construct the directory name: `<NNNN>-<short-name>` (e.g. `0025-dark-mode`).
   - Set `SPECIFY_FEATURE_DIRECTORY` to `specs/<directory-name>`.

   **Create the directory and spec file**:
   - `mkdir -p SPECIFY_FEATURE_DIRECTORY`
   - Persist the resolved path to `.specify/feature.json`:
     ```json
     { "feature_directory": "<resolved feature dir>" }
     ```
     Write the actual resolved path (for example, `specs/0025-dark-mode`), not the
     literal string `SPECIFY_FEATURE_DIRECTORY`.

   **IMPORTANT**:
   - Only one feature per `/speckit-specify` invocation.
   - The spec directory and file are always created by this command, never by the hook.

4. **IF EXISTS**: Load `.specify/memory/constitution.md` for project principles and governance constraints.

5. Create the specification at `SPECIFY_FEATURE_DIRECTORY/spec.md`, following
   `.specify/templates/spec-template.md` — which is this repo's house format, not
   the stock spec-kit one. Read an existing spec (`specs/0011-connectivity/spec.md`
   is a good short one) before writing, and match it:

   - `# NNNN · Title`, then `**Status:**` and `**Created:**`
   - `## Context` — the problem, and **why the obvious approach does not work**.
     That last part is what a future reader most needs.
   - `## Requirements` — a table of `| NNNN-R1 | The system MUST … |`. Every row
     must be individually testable. If you cannot imagine the test, the
     requirement is too vague (Principle II).
   - `## Non-goals` — what a reader might reasonably expect and will not get.
   - `## Verification` — a row per requirement. **Write `—` in the Test column for
     anything not yet written.** Do not name a test that does not exist; that is
     the one thing this table exists to prevent. `/speckit-tasks` turns each `—`
     into a task, and `/speckit-implement` fills it in.
   - `## Open questions` — empty is fine; fake certainty is not.

   Make informed defaults for unspecified details, and say in `## Open questions`
   which ones you guessed at.

## Mandatory Post-Execution Hooks

**You MUST complete this section before reporting completion to the user.**

Check if `.specify/extensions.yml` exists in the project root.
- If it does not exist, or no hooks are registered under `hooks.after_specify`, skip to the Completion Report.
- If it exists, read it and look for entries under the `hooks.after_specify` key.
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue to the Completion Report.
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- When constructing slash commands from hook command names, replace dots (`.`) with hyphens (`-`). For example, `speckit.git.commit` → `/speckit-git-commit`.
- For each executable hook, output the following based on its `optional` flag:
  - **Mandatory hook** (`optional: false`) — **You MUST emit `EXECUTE_COMMAND:` for each mandatory hook**:
    ```
    ## Extension Hooks

    **Automatic Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}
    ```
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```

## Completion Report

Report completion to the user with:
- `SPECIFY_FEATURE_DIRECTORY` — the feature directory path
- `SPEC_FILE` — the spec file path
- Readiness for the next phase (`/speckit-plan`)

**NOTE:** Branch creation is handled by the `before_specify` hook (git extension). Spec directory and file creation are always handled by this command.
