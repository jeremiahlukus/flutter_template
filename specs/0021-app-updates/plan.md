# Implementation Plan: 0021 · App updates

- **Status:** Accepted
- **Created:** 2026-08-22

> Specification: [`spec.md`](spec.md)

## Design

`AppVersion` is hand-rolled rather than pulling in `pub_semver`: the app compares
three integers from a store listing, and a dependency for that is not worth the
resolution risk. `tryParse` tolerates a `v` prefix and a `+build` suffix and
returns null on anything else (R2) — this value is usually typed by a human into
a console.

**Every ambiguous case fails open** (R2, R5, R6). This is a remote kill switch:
a typo in a config document, a permissions slip, or an offline launch must never
look like "your app is out of date and unusable". The only path to a block is an
explicitly-parsed floor above an explicitly-parsed current version.

R8 puts `UpdateGate` outside the router: a required update means this client can
no longer talk to the backend correctly, so there is no route worth navigating
to. R10 keeps the optional case to a single Settings row — nagging is not the
same as informing.
