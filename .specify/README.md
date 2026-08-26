# `.specify/` — spec-kit configuration

This repo drives spec-driven development with [spec-kit](https://github.com/github/spec-kit)'s
**lean** preset. The workflow is five commands; see
[`specs/README.md`](../specs/README.md) for how to use them and
[`memory/constitution.md`](memory/constitution.md) for the rules they check against.

## What is here

| Path | What it is |
|---|---|
| `memory/constitution.md` | The project's non-negotiable rules. Written for this repo; `/speckit-plan` checks designs against it. |
| `presets/lean/` | The lean preset — five command prompts. MIT, from `github/spec-kit`, unmodified. |
| `templates/` | The artifact templates. `spec-template.md` is this repo's house format. |
| `extensions/git/` | Branch creation and number allocation. MIT, from `github/spec-kit`; numbering switched from tracker IDs to this repo's four-digit sequence. |
| `extensions.yml` | Which hooks are wired. One: branch creation before `/speckit-specify`. |
| `scripts/bash/` | Prerequisite checks and path resolution used by the commands. |
| `init-options.json` | `branch_numbering: sequential` — the next spec after `0024` is `0025`. |

`feature.json` is written at runtime by `/speckit-specify` to record which feature
you are working on. It is gitignored; it is per-checkout state, not shared config.

## Not here, on purpose

No generated install state — no `.registry`, no `integrations/*.manifest.json`.
Those files carry sha256 checksums of every installed file, and a hand-written
copy would claim hashes that do not match, which reads to the CLI as "someone
edited these". If you use the `specify` CLI, let it generate its own:

```sh
specify preset add --dev .specify/presets/lean
```

The commands work without it — Claude Code reads `.claude/skills/` directly.

## Attribution

The preset, the git extension, the templates and the helper scripts come from
[github/spec-kit](https://github.com/github/spec-kit), which is MIT licensed:

```
MIT License

Copyright (c) GitHub, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

Local changes to it, all of them noted where they apply:

- Branch and spec numbering is **sequential four-digit** (`0025-dark-mode`), not a
  tracker ID, so it continues this repo's existing `specs/NNNN-slug/` sequence.
- `templates/spec-template.md` is this repo's house format — numbered requirement
  IDs and a Verification table — not the stock spec-kit one.
- The `specify`, `plan`, `tasks` and `implement` skills reference this repo's
  constitution, its four gates, and the traps table in `CLAUDE.md`.
- Only the `git` extension is installed, and only its branch-creation hook. No
  auto-commit.
