---
name: speckit-implement
description: Execute the implementation plan by processing all tasks in tasks.md.
argument-hint: "Optional implementation guidance or task filter"
compatibility: Requires spec-kit project structure with .specify/ directory
metadata:
  author: github-spec-kit
  source: preset:lean (adapted)
user-invocable: true
disable-model-invocation: false
---

# Speckit Implement Skill

## User Input

```text
$ARGUMENTS
```

## Outline

1. Read `.specify/feature.json` to get the feature directory path.

2. **Load context**: `.specify/memory/constitution.md`, plus `spec.md`, `plan.md`
   and `tasks.md` from the feature directory. Also read the "Traps that have
   already bitten" table in `CLAUDE.md` — those are real bugs from this codebase,
   and reintroducing one is the likeliest way this goes wrong.

3. **Execute tasks** in order:
   - Complete each task before starting the next
   - Mark completion by changing `- [ ]` to `- [x]` in `tasks.md`
   - Halt on failure and report it. Do not tick a task that did not pass.

4. **Keep the spec true as you go.** When you write a test that proves a
   requirement, fill it into that requirement's row in the spec's Verification
   table immediately — not at the end. If the implementation revealed the
   requirement was wrong, change the requirement and say so; a spec that no longer
   matches the code is worse than no spec (Principle I).

5. **Run the gates for real** and paste the actual output:
   - `dart format lib test tool`
   - `flutter analyze --fatal-infos --fatal-warnings`
   - `flutter test --exclude-tags golden`
   - `dart run tool/check_coverage.dart --min 85`
   - `cd test_rules && npm test` — if any `*.rules` file changed

   A gate is never weakened to make the change pass (Principle III). If coverage
   is short, write the missing test; do not raise an exclusion without justifying
   it in place.

6. **Report honestly.** Say which tasks are done, which are not, and why. If
   anything was left incomplete, record it in `task.md` — the constitution treats
   an omission as worse than an admission.

7. **Do not commit or push.** Auto-commit is off by design; commits and pushes
   need explicit approval every time.
