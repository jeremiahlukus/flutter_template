# `test_rules` — security-rules tests

Tests `firestore.rules` and `storage.rules` against the real Firebase emulator
suite. A separate Node package because security rules **cannot** be tested in
Dart: `fake_cloud_firestore` supports neither custom functions nor
`request.resource`. → [spec 0016](../specs/0016-emulator-and-rules/spec.md)

```sh
npm ci && npm test     # needs JDK 21+ (firebase-tools 15)
```

`flutter test` never sees this package, and CI runs it as its own job.

## Why `overrides` exists

`package.json` pins three transitive dependencies. Do not remove them without
re-checking `npm audit`, because npm's own suggested remedy is worse than the
problem it solves.

| Override | Reason |
|---|---|
| `re2: ^1.26.1` | Three moderate advisories (out-of-bounds heap read, uncatchable process abort) against `<= 1.26.0`. It arrives as an **optional** transitive dep of `superstatic`, so `npm update` will not move it — an override is the only lever. |
| `uuid: ^11.1.1` | Missing buffer bounds check in v3/v5/v6. `gaxios` nests `uuid@9.0.1`, below the patched floor. |
| `@opentelemetry/core: ^2.8.0` | Unbounded memory allocation in W3C Baggage propagation, against `< 2.8.0`. Reached via `@google-cloud/pubsub`. |

All three come in under `firebase-tools`, and the fix npm proposes for every one
of them is **downgrading `firebase-tools` to 14.23.0** — a major downgrade that
would take the emulator back below the JDK 21 line and undo the bump in #62. The
overrides get to zero advisories while keeping `firebase-tools` current, which is
why they are here rather than an `npm audit fix`.

Bumping `re2` also moves the `node-gyp` chain it builds through (`abbrev`,
`nopt`, `proc-log`, `undici`, `which`). That is expected, not drift.

Re-check with `npm audit` after any `firebase-tools` bump: when upstream carries
patched versions itself, these overrides become dead weight and should go.
