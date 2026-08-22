# Agent instructions

See **[CLAUDE.md](CLAUDE.md)** — the same guidance applies to any coding agent.

The short version:

- This project is **spec-driven**. Read the relevant file in [`specs/`](specs/)
  before changing behaviour, and update it in the same change.
- Four gates must pass: `flutter analyze --fatal-infos --fatal-warnings`,
  `flutter test --exclude-tags golden`, coverage ≥ 85%, and the security-rules
  suite in `test_rules/` if you touched a `.rules` file.
- [`task.md`](task.md) records what is done, what is deliberately not done, and
  what is known-broken. Check it before reporting something as missing.
- [CLAUDE.md](CLAUDE.md) lists the hard rules and the traps that have already
  caused real bugs here. Read that section before writing Riverpod, streams, or
  anything that touches Firestore paths.
