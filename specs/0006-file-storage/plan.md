# Implementation Plan: 0006 · File storage

- **Status:** Accepted
- **Created:** 2026-08-21

> Specification: [`spec.md`](spec.md)

## Design

`StorageRepository` is an interface with two implementations:

- `FirebaseStorageRepository` — production. Tested with `mocktail`. The one
  awkward part is `UploadTask`: it *is* a `Future<TaskSnapshot>`, so the test
  supplies a small fake that forwards the `Future` surface to a real future.
  Stubbing `then` directly is far more fragile.
- `InMemoryStorageRepository` — a `Map`. Covers every consumer of uploads, and
  supports `failWith` for R4.

R2 is enforced by a test that compares the two implementations' path output
directly, which is the only cheap defence against the drift described above.
