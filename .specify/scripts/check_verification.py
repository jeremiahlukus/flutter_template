#!/usr/bin/env python3
"""Resolve every spec's Verification table against the code, so a renamed test
fails a check instead of leaving a row that still reads like proof.

A table mapping requirements to tests rots in the one way you cannot see by
reading it: rename a test and the row still looks like proof. This resolves each
row against the filesystem and fails when it does not hold.

Stack-agnostic. Everything that varies lives in .specify/verification.json:

    {
      "code_root": ".",
      "requirement_pattern": "\\\\d{4}-R\\\\d+",
      "name_style": "quoted",
      "budgets": {
        "unresolved_paths": 0,
        "stale_test_names": 0,
        "uncheckable_rows": 0,
        "unproven_requirements": 0
      }
    }

`name_style` is how the language writes a test name:
  quoted      — test('name') / it 'name' / @Test("name")   [Dart, Ruby, JS, TS]
  identifier  — def test_name / func testName              [Python, Swift XCTest, Go]
  either      — try both, then fall back to a substring

Budgets are ratchets: lowering one never fails, raising one is a deliberate edit
visible in the diff.

    python3 .specify/scripts/check_verification.py
    python3 .specify/scripts/check_verification.py --code-root ../other-repo
    python3 .specify/scripts/check_verification.py --write-budgets   # pin current state

Exits non-zero on any violation. No dependencies.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

# Bump on any behaviour change. Vendored copies record this in
# verification.json, so `/speckit-init` in a repo that already has a `.specify/`
# can tell whether its copy is behind the skill's — which is the only honest
# answer to "the skill is the source of truth" when CI needs the file in-repo.
CHECKER_VERSION = "1.1.0"

DEFAULTS = {
    "code_root": ".",
    "requirement_pattern": r"\d{4}-R\d+",
    "name_style": "either",
    # Extensions whose test names have a real syntax worth demanding. Anything
    # else a row points at (YAML, HCL, markdown) is matched by substring.
    "strict_extensions": [".dart", ".rb", ".ts", ".tsx", ".js", ".jsx", ".py", ".swift", ".go"],
    "budgets": {
        "unresolved_paths": 0,
        "stale_test_names": 0,
        "uncheckable_rows": 0,
        "unproven_requirements": 0,
    },
}

# A repo path: at least one slash and a file extension. Deliberately excludes a
# bare `foo.dart` and a `Class.member`, neither of which is a path.
REPO_PATH = re.compile(r"`([A-Za-z0-9_.\-]+(?:/[A-Za-z0-9_.\-]+)+\.[A-Za-z0-9]+)`")
BACKTICKED = re.compile(r"`([^`]+)`")
ABBREVIATION = re.compile(r"`…([^`…]+)…`")


def load_config(root: Path, overrides: dict) -> dict:
    cfg = json.loads(json.dumps(DEFAULTS))
    path = root / ".specify" / "verification.json"
    if path.exists():
        on_disk = json.loads(path.read_text())
        cfg.update({k: v for k, v in on_disk.items() if k != "budgets"})
        cfg["budgets"].update(on_disk.get("budgets", {}))
    cfg.update({k: v for k, v in overrides.items() if v is not None})
    return cfg


def section(body: str, name: str) -> str:
    """The body of a `## <name>` section, up to the next `## `."""
    match = re.search(rf"^## {re.escape(name)}\b.*$", body, re.M)
    if not match:
        return ""
    rest = body[match.end():]
    nxt = re.search(r"^## ", rest, re.M)
    return rest[: nxt.start()] if nxt else rest


def find_specs(root: Path) -> list[Path]:
    """Both layouts: specs/NNNN-slug/spec.md and specs/NNNN-slug.md."""
    specs_dir = root / "specs"
    if not specs_dir.is_dir():
        return []
    found = sorted(p for p in specs_dir.glob("*/spec.md"))
    found += sorted(
        p for p in specs_dir.glob("*.md") if p.name.lower() != "readme.md"
    )
    return found


def name_present(text: str, needle: str, style: str, target: str, strict_exts: list[str]) -> bool:
    """Whether `needle` names a test in `text`.

    **Strictness depends on the target file, not the language of the project.**
    A row may point at a test file, a CI workflow, or a rules file, and only the
    first has a syntax worth demanding:

      - a test file in this stack -> apply `style`, so a rename from
        `is blank` to `is blank now` fails instead of passing as a prefix
      - anything else (YAML step names, HCL blocks, prose) -> substring, because
        those have no declaration syntax and demanding one produces false
        failures, which is how a gate gets switched off
    """
    if not any(target.endswith(e) for e in strict_exts):
        return needle in text

    # Source quotes only here. A backticked mention is markdown, not a
    # declaration — accepting it would let a name that appears solely in a
    # comment read as proof.
    quoted = f"'{needle}'" in text or f'"{needle}"' in text
    # An identifier is a whole word: `def test_x`, `func testX`, `TestX`.
    identifier = re.search(rf"(?<![A-Za-z0-9_]){re.escape(needle)}(?![A-Za-z0-9_])", text) is not None
    if style == "quoted":
        return quoted
    if style == "identifier":
        return identifier
    return quoted or identifier


class Row:
    __slots__ = ("rid", "text", "paths", "target", "name")

    def __init__(self, rid, text, paths, target, name):
        self.rid, self.text, self.paths, self.target, self.name = rid, text, paths, target, name

    @property
    def unproven(self) -> bool:
        return self.text.lstrip().startswith("—")


def parse_spec(path: Path, req_pattern: str, code_root: Path):
    body = path.read_text(errors="ignore")
    verification = section(body, "Verification")

    # Requirements are collected document-wide minus the Verification section:
    # some specs use `## Requirements` with a `### Functional Requirements`
    # under it, others put the heading at the top level. Both a table row and a
    # definition bullet count as a declaration.
    outside = body.replace(verification, "") if verification else body
    declared = set(re.findall(rf"^\|\s*({req_pattern})\s*\|", outside, re.M))
    declared |= set(re.findall(rf"^-\s+\*\*({req_pattern})\*\*", outside, re.M))

    rows: list[Row] = []
    named_so_far: list[str] = []
    carried: str | None = None

    for match in re.finditer(rf"^\|\s*({req_pattern})\s*\|\s*(.+?)\s*\|\s*$", verification, re.M):
        rid, text = match.group(1), match.group(2).strip()
        paths = [p for p in REPO_PATH.findall(text)]
        existing = [p for p in paths if (code_root / p).exists()]

        # `…foo…` means "the file named earlier whose name contains foo".
        resolved_abbrev = []
        for abbr in ABBREVIATION.findall(text):
            hits = [p for p in named_so_far if abbr in Path(p).name]
            if hits:
                resolved_abbrev.append(hits[-1])

        first = BACKTICKED.search(text)
        first = first.group(1) if first else None
        target = None
        if first == "…":
            target = carried                      # "same file as the row above"
        elif resolved_abbrev:
            target = carried = resolved_abbrev[0]
        elif existing:
            target = carried = existing[0]
        named_so_far.extend(existing)

        # The innermost `› `-delimited backticked name is the test name.
        name = None
        if "›" in text:
            tail = text[text.rfind("›") + 1:].strip()
            m = BACKTICKED.search(tail)
            if m and m.group(1) != "…":
                name = m.group(1)

        rows.append(Row(rid, text, paths + resolved_abbrev, target, name))

    status = re.search(r"\*\*Status:\*\*\s*(.+)", body)
    return {
        "path": path,
        "status": status.group(1).strip() if status else "",
        "declared": declared,
        "rows": rows,
        "has_table": bool(verification.strip()),
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--code-root", help="where the tests live (default: the repo root, or verification.json)")
    ap.add_argument("--repo-root", default=".", help="the repo holding specs/ (default: .)")
    ap.add_argument("--write-budgets", action="store_true", help="pin the current counts into verification.json")
    ap.add_argument("--version", action="store_true", help="print the checker version and exit")
    args = ap.parse_args()

    if args.version:
        print(CHECKER_VERSION)
        return 0

    repo_root = Path(args.repo_root).resolve()
    cfg = load_config(repo_root, {"code_root": args.code_root})
    code_root = (repo_root / cfg["code_root"]).resolve()
    style = cfg["name_style"]
    strict_exts = cfg.get("strict_extensions", DEFAULTS["strict_extensions"])
    budgets = cfg["budgets"]

    specs = find_specs(repo_root)
    if not specs:
        print(f"No specs found under {repo_root / 'specs'} — nothing to check.")
        return 0

    problems, unresolved, stale, uncheckable, unproven, no_table = [], [], [], [], [], []

    for spec in (parse_spec(p, cfg["requirement_pattern"], code_root) for p in specs):
        rel = spec["path"].relative_to(repo_root)
        if not spec["has_table"]:
            no_table.append(str(rel))
            continue

        verified = {r.rid for r in spec["rows"]}
        missing = sorted(spec["declared"] - verified)
        orphaned = sorted(verified - spec["declared"])
        if missing:
            problems.append(f"{rel}: no Verification row for {', '.join(missing)}")
        if orphaned:
            problems.append(f"{rel}: Verification row for {', '.join(orphaned)}, which is not a requirement")

        # A bare `—` needs no reason while a spec is still Draft: the reason is
        # the same for every row and repeating it twenty times is noise. Once a
        # spec is Accepted the feature has shipped, and an unexplained gap is
        # indistinguishable from an oversight.
        accepted = spec["status"].startswith("Accepted")
        for row in spec["rows"]:
            # Paths are checked on every row, including `—` ones. A dash whose
            # reason cites a file that has moved is still misleading, and that
            # reason is often the only pointer to what would close the gap.
            for p in row.paths:
                if not (code_root / p).exists():
                    unresolved.append(f"{rel} {row.rid}: no such path `{p}`")

            if row.unproven:
                unproven.append(f"{rel} {row.rid}")
                if accepted and not row.text.replace("—", "", 1).strip():
                    problems.append(
                        f"{rel} {row.rid}: Accepted but unproven, with no reason. Write "
                        f"'— *(why, and what would prove it)*', name the test, or put the "
                        f"spec back to Draft."
                    )

            targets = [t for t in dict.fromkeys([row.target, *row.paths]) if t and (code_root / t).exists()]

            # The name check runs on **every** row that names something, dashes
            # included. A row reading `— · `foo_test.dart` › `thing`` is saying
            # "not proven, and here is the test that would" — but if that test
            # does not exist under that name, the citation is still wrong, and a
            # reader skimming the column sees a test name either way.
            if row.name and targets:
                needle = row.name[:-1] if row.name.endswith("…") else row.name
                trunc = row.name.endswith("…")
                found = any(
                    (needle in (code_root / t).read_text(errors="ignore"))
                    if trunc
                    else name_present((code_root / t).read_text(errors="ignore"), needle, style, t, strict_exts)
                    for t in targets
                )
                if not found:
                    stale.append(f"{rel} {row.rid}: `{row.name}` not found in {' or '.join(targets)}")
            elif not row.unproven:
                # Only a row that claims proof can fail to be verifiable. A dash
                # is an admission, not an unverifiable claim.
                uncheckable.append(f"{rel} {row.rid}: {row.text[:90]}")

    counts = {
        "unresolved_paths": len(unresolved),
        "stale_test_names": len(stale),
        "uncheckable_rows": len(uncheckable),
        "unproven_requirements": len(unproven),
    }

    if args.write_budgets:
        path = repo_root / ".specify" / "verification.json"
        on_disk = json.loads(path.read_text()) if path.exists() else {}
        on_disk.setdefault("code_root", cfg["code_root"])
        on_disk.setdefault("requirement_pattern", cfg["requirement_pattern"])
        on_disk.setdefault("name_style", style)
        on_disk["checker_version"] = CHECKER_VERSION
        on_disk["budgets"] = counts
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(on_disk, indent=2) + "\n")
        print(f"Pinned current counts into {path.relative_to(repo_root)}:")
        for k, v in counts.items():
            print(f"  {k}: {v}")
        return 0

    vendored = cfg.get("checker_version")
    if vendored and vendored != CHECKER_VERSION:
        print(f"NOTE: verification.json records checker {vendored}, this script is "
              f"{CHECKER_VERSION}. Re-run /speckit-init to refresh the vendored copy.")
    print(f"Checker:      {CHECKER_VERSION}")
    print(f"Specs:        {len(specs)}")
    print(f"Code root:    {code_root}")
    print(f"Name style:   {style} (strict for {' '.join(strict_exts)})")
    if no_table:
        print(f"No table:     {len(no_table)}")

    failed = False
    for label, items, key in [
        ("Specs with no Verification table", no_table, None),
        ("Rows naming a path that does not exist", unresolved, "unresolved_paths"),
        ("Rows naming a test that is not there", stale, "stale_test_names"),
        ("Rows naming no verifiable test", uncheckable, "uncheckable_rows"),
        ("Requirements with no named test", unproven, "unproven_requirements"),
    ]:
        if key is None:
            if items:
                failed = True
                print(f"\n{label}: {len(items)}", file=sys.stderr)
                for line in items:
                    print(f"  {line}", file=sys.stderr)
            continue
        budget = budgets.get(key, 0)
        if len(items) <= budget:
            if items:
                print(f"{label}: {len(items)} (within budget {budget})")
            continue
        failed = True
        print(f"\n{label}: {len(items)}, budget {budget}", file=sys.stderr)
        for line in items:
            print(f"  {line}", file=sys.stderr)

    if problems:
        failed = True
        print(f"\nStructural problems: {len(problems)}", file=sys.stderr)
        for line in problems:
            print(f"  {line}", file=sys.stderr)

    if failed:
        print("\nFAILED", file=sys.stderr)
        print("\nIf a count is legitimately higher now, --write-budgets pins it — "
              "but read the rows first.", file=sys.stderr)
        return 1
    print("\nOK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
