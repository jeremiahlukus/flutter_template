# Implementation Plan: 0002 · Offline-first notes sync

- **Status:** Accepted
- **Created:** 2026-08-21

> Specification: [`spec.md`](spec.md)

## Design

```
UI ◀── watchNotes() ◀── Drift (source of truth for reads)
                            ▲
                      save()│ 1. local write, pendingSync: true
                            │ 2. remote write
                            │ 3. clear flag  ← only on confirmation
                            ▼
                        Firestore
```

R8's asymmetry with R4 is deliberate: a note that reappears after the user
deleted it is more alarming than a tombstone that takes a while to propagate.

R6 is enforced in one place — `AppDatabase.replaceNotes`, which deletes only
un-flagged rows and skips remote copies of flagged ids. Putting the invariant in
the database layer rather than the repository means no future caller can forget
it.

R13 exists because `Timestamp.toDate()` returns **local** time. Without explicit
normalisation, a note round-tripped through Firestore compares unequal to itself,
and every change-detection check based on `updatedAt` becomes unreliable.
