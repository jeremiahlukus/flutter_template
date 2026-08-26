---
name: speckit-constitution
description: Create or update the project constitution.
argument-hint: "Principles or values for the project constitution"
compatibility: Requires spec-kit project structure with .specify/ directory
metadata:
  author: github-spec-kit
  source: preset:lean (adapted)
user-invocable: true
disable-model-invocation: false
---

# Speckit Constitution Skill

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Pre-Execution Checks

**Check for extension hooks (before constitution update)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_constitution` key
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

You are amending the project constitution at `.specify/memory/constitution.md`. This is a mature, fully-populated document — not a fresh template — so there are no `[PLACEHOLDER]` tokens to fill in; every amendment is an edit to existing, concrete text.

1. **Load** the existing constitution and identify exactly which principle(s) or sections the user's input touches.

2. **Draft the amendment**:
   - Preserve heading hierarchy and existing principle numbering unless the user explicitly asks to add, remove, or renumber a principle.
   - Each modified or added principle section keeps a succinct name line, the non-negotiable rule as a paragraph or bullet list, and explicit rationale where it isn't obvious.
   - Do not restate mechanics that belong in agent-context files — this document is the source of truth those files point back to (Governance § "Agent Context Files").

3. **Determine the version bump**, per semantic versioning:
   - **MAJOR**: backward-incompatible governance/principle removal or redefinition (the principle's meaning flips or a requirement disappears entirely).
   - **MINOR**: a new principle/section added, or an existing principle materially narrowed or expanded (e.g. a MUST loosened to a conditional, new steps added to an existing requirement).
   - **PATCH**: wording-only — clarifications, typo fixes, non-semantic refinements that don't change what's required.
   - If the bump type is ambiguous, state your reasoning and proposed classification before finalizing, rather than guessing silently.
   - `Last Amended` is today's date; `Ratified` is unchanged.

4. **Propagation checklist** — before finalizing, check whether the amendment requires updates elsewhere in this repo, and make those updates in the same change:
   - `.specify/templates/plan-template.md`, `spec-template.md`, `tasks-template.md`, `checklist-template.md` — does a "Constitution Check" section or any template content now conflict with the amended principle?
   - `specs/README.md` — it describes the loop and the house spec format.
   - `README.md` — does it restate anything the amended principle now contradicts (tables, workflow diagrams, directory-structure listings)?
   - `CLAUDE.md` and `AGENTS.md` — per Governance § "Agent Context Files" these cite principles by number and never restate them, so confirm each citation still points at the right principle. Do not move mechanics into them.
   - Any other doc that quotes or paraphrases the amended text.
   - Record what was checked and what (if anything) was updated — this becomes the Sync Impact Report's "Templates/docs requiring sync" bullet.

5. **Produce a Sync Impact Report**, prepended as an HTML comment at the very top of the constitution file, above the existing one:
   - `Version change: <old> → <new>`
   - `Bump rationale:` MAJOR/MINOR/PATCH and why, in enough detail that a future amendment can tell what changed and why without reading the diff
   - `Modified principles:` which principle(s)/section(s), old title → new title if renamed
   - `Templates/docs requiring sync:` what was checked in step 4, and what was updated (or "none")
   - Move what was previously the top entry down into the `Prior history:` list below it. **Never delete, rewrite, or reorder an existing prior-history entry** — this is an append-only log of every past amendment.

6. **Update the footer version line**: `**Version**: X.Y.Z | **Ratified**: <unchanged> | **Last Amended**: <today>`.

7. **Write** the completed constitution back to `.specify/memory/constitution.md`.

## Mandatory Post-Execution Hooks

**You MUST complete this section before reporting completion to the user.**

Check if `.specify/extensions.yml` exists in the project root.
- If it does not exist, or no hooks are registered under `hooks.after_constitution`, skip to the Completion Report.
- If it exists, read it and look for entries under the `hooks.after_constitution` key.
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

Report to the user:
- New version and bump rationale
- Which dependent docs were checked, and which (if any) were updated
- A suggested commit message

**Amending the constitution is not spec work**, so it needs no feature branch. The edits above are made directly, but `git add`/`git commit`/`git push` require explicit approval every time (Governance § "Auto-commit is off") — stop here and wait for it.
