---
name: speckit-plan
description: Create a plan and store it in plan.md.
argument-hint: "Optional guidance for the planning phase"
compatibility: Requires spec-kit project structure with .specify/ directory
metadata:
  author: github-spec-kit
  source: preset:lean (adapted)
user-invocable: true
disable-model-invocation: false
---

# Speckit Plan Skill

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Pre-Execution Checks

**Check for extension hooks (before planning)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_plan` key
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

1. Read `.specify/feature.json` to get the feature directory path (`SPECIFY_FEATURE_DIRECTORY`).

2. **Load context**: `.specify/memory/constitution.md` and `SPECIFY_FEATURE_DIRECTORY/spec.md`.

3. **Fill Technical Context**: tech stack, dependencies, project structure. Mark unresolved unknowns as "NEEDS CLARIFICATION".

4. **Constitution Check gate**: evaluate the plan against every principle in
   `.specify/memory/constitution.md` and record a pass/fail for each. The ones that
   most often bite in this repo:

   - **II** — does every new requirement have a test named, or an honest `—`?
   - **III** — will this hold the four gates, including coverage ≥ 85%?
   - **IV** — does anything here need a network, a Firebase project, or a native-only
     import to test? If so, it needs a seam and a fake, and that is part of the plan.
   - **V** — if it writes data, what happens offline, and how does the user find out
     when a sync fails?
   - **VI** — new strings in every ARB, tokens not literals, keys and tooltips.
   - **VII** — what will a fork want to change here, and is that a seam yet?

   If a NON-NEGOTIABLE principle (I, II, IV) would be violated, revise the plan.
   If you cannot, record it under "Complexity Tracking" with what is needed, why,
   and which simpler alternative you rejected and on what grounds. Do not proceed
   past an unjustified violation.

5. **Decide whether the supporting artifacts are warranted.** Most features in this repo need none of them — a spec plus a plan is the norm, and 24 of 24 existing specs shipped without any. Produce one only if the feature genuinely has a new external interface, an unknown worth dedicated research, or a schema worth documenting on its own.
   - **If yes**, produce whichever of these apply under `SPECIFY_FEATURE_DIRECTORY/`:
     - `research.md` — for each unresolved unknown: Decision / Rationale / Alternatives considered
     - `data-model.md` — entities, fields, relationships, validation rules, state transitions
     - `contracts/` — interface contracts the feature exposes to users or other systems (skip if purely internal)
     - `quickstart.md` — a runnable validation guide: prerequisites, setup commands, run/test commands, expected outcomes. Link to contracts/data-model rather than duplicating them; no implementation code.
   - **If no**, skip all four and note in `plan.md` that they weren't warranted (one line is enough).

6. **Re-evaluate the Constitution Check** after the design decisions in step 5.

7. Create the implementation plan and store it in `SPECIFY_FEATURE_DIRECTORY/plan.md`:
   - Technical Context
   - Constitution Check (initial pass + post-design re-check)
   - Complexity Tracking (only if a violation was justified in step 4)
   - Project Structure
   - Design decisions, architecture, file structure
   - **Traps to avoid** — check the plan against the "Traps that have already bitten"
     table in `CLAUDE.md`. Those are real bugs found in this codebase; reintroducing
     one is the most likely way this plan goes wrong.

## Mandatory Post-Execution Hooks

**You MUST complete this section before reporting completion to the user.**

Check if `.specify/extensions.yml` exists in the project root.
- If it does not exist, or no hooks are registered under `hooks.after_plan`, skip to the Completion Report.
- If it exists, read it and look for entries under the `hooks.after_plan` key.
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
- `plan.md` path
- Which (if any) of `research.md`/`data-model.md`/`quickstart.md`/`contracts/` were produced, and why
- Constitution Check result (pass, or justified violations)
- Readiness for the next phase (`/speckit-tasks`)
