---
name: speckit-tasks
description: Create the tasks needed for implementation and store them in tasks.md.
argument-hint: "Optional task generation constraints"
compatibility: Requires spec-kit project structure with .specify/ directory
metadata:
  author: github-spec-kit
  source: preset:lean (adapted)
user-invocable: true
disable-model-invocation: false
---

# Speckit Tasks Skill

## User Input

```text
$ARGUMENTS
```

## Outline

1. Read `.specify/feature.json` to get the feature directory path.

2. **Load context**: `.specify/memory/constitution.md`, `<feature_directory>/spec.md`,
   and `<feature_directory>/plan.md`.

3. Create dependency-ordered tasks in `<feature_directory>/tasks.md`.
   - Every task uses checklist format: `- [ ] [TaskID] Description with file path`
   - Organised by phase: setup, foundational, then per requirement, then polish

4. **Derive a task from every unproven requirement.** Read the spec's Verification
   table: each row with `—` in the Test column becomes a task to write that test,
   naming the file it goes in. This is how Principle II is enforced mechanically
   rather than remembered — a requirement with no test and no task is a requirement
   that will ship unproven.

5. **Tests come before the code they cover.** Order each requirement's test task
   ahead of its implementation task, so the test fails first and you know it runs.

6. **End with the gates.** The final tasks are always, in this order:
   - `- [ ] Update the Verification table — every requirement names a real test`
   - `- [ ] dart format lib test tool`
   - `- [ ] flutter analyze --fatal-infos --fatal-warnings`
   - `- [ ] flutter test --exclude-tags golden`
   - `- [ ] dart run tool/check_coverage.dart --min 85`
   - `- [ ] cd test_rules && npm test` — only if a `*.rules` file changed
   - `- [ ] Update task.md if anything was left incomplete`

   Principle III: all four gates pass, or the change is not done.
