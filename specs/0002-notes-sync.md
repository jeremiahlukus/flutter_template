# 0002 · Offline-first notes sync

- **Status:** Accepted
- **Created:** 2026-08-21

## Context

`notes` is the template's reference feature: it exists to demonstrate the pattern
every real feature will need — a Firestore collection cached locally so the UI is
instant and works offline.

The interesting part is not CRUD. It is the failure modes. A naive
implementation loses user data in two specific ways:

1. **Pull-first.** A note created offline is queued locally. A sync that pulls
   before it pushes deletes that note as "not on the server" before ever sending
   it.
2. **Blind cache replacement.** Overwriting the cache with the server's view
   discards any local edit the server has not seen yet.

Both are silent. The user finds out later that their note is gone.

## Requirements

| ID | Requirement |
|---|---|
| 0002-R1 | Reads MUST come from the local cache, never blocking on the network. |
| 0002-R2 | A write MUST persist locally before it is attempted remotely. |
| 0002-R3 | A note not yet accepted by the server MUST be flagged `pendingSync`. |
| 0002-R4 | A remote write failure MUST NOT propagate to the caller, and MUST leave the note queued. |
| 0002-R5 | `sync()` MUST push queued writes **before** pulling. |
| 0002-R6 | A pull MUST NOT overwrite or delete a note flagged `pendingSync`. |
| 0002-R7 | A failed pull MUST leave the cache untouched and report `ok: false`. |
| 0002-R8 | A delete MUST remove the local copy even if the remote delete fails. |
| 0002-R9 | `sync()` MUST be idempotent. |
| 0002-R10 | A partial failure MUST be reported to the user as such — never as plain success. |
| 0002-R11 | All reads and writes MUST be scoped to `users/{uid}/notes`. |
| 0002-R12 | Signing out MUST clear the local cache. |
| 0002-R13 | `updatedAt` MUST be UTC on every path in and out of storage. |
| 0002-R14 | A malformed remote document MUST NOT break the list. |
| 0002-R15 | A note exceeding a length limit MUST be rejected before anything is persisted. |

## Non-goals

- **Field-level conflict resolution.** Last-write-wins on whole notes. Anything
  better needs a CRDT and belongs in an app, not a template.
- **Realtime listeners on Firestore.** Sync is explicit — triggered by the user
  or by a reconnect ([0011](0011-connectivity.md)). Swapping in `snapshots()` is
  a small change if an app wants it.
- **Attachment sync.** See [0006](0006-file-storage.md).

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

## Verification

| ID | Test |
|---|---|
| 0002-R1 | `test/features/notes/notes_repository_test.dart` › `watchNotes` › `emits the cache contents as they change` |
| 0002-R2 | `…` › `save` › `writes to the local cache` |
| 0002-R3 | `…` › `save when Firestore is unavailable` › `leaves it flagged for a later sync` |
| 0002-R4 | `…` › `save when Firestore is unavailable` › `does not throw at the caller` |
| 0002-R5 | `…` › `sync` › `pushes before pulling so a new note is not clobbered` |
| 0002-R6 | `test/database/app_database_test.dart` › `replaceNotes` › `does not let a remote copy overwrite a pending local edit` |
| 0002-R7 | `test/features/notes/notes_repository_test.dart` › `sync` › `reports not-ok and touches nothing when the pull fails` |
| 0002-R8 | `…` › `delete` › `still deletes locally when the remote call fails` |
| 0002-R9 | `…` › `sync` › `is idempotent` |
| 0002-R10 | `test/features/notes/presentation/notes_screen_test.dart` › `syncMessage` › `reports a partial failure rather than claiming success` |
| 0002-R11 | `test/features/notes/notes_repository_test.dart` › `scoping` › `reads and writes under the signed-in user only` |
| 0002-R12 | `test/features/auth/presentation/profile_screen_test.dart` › `sign out` › `confirming signs out and clears the local cache` |
| 0002-R13 | `test/features/notes/note_test.dart` › `fromFirestore` › `normalises a local Timestamp to UTC` |
| 0002-R14 | `test/features/notes/note_test.dart` › `fromFirestore` › `tolerates a wrongly-typed title rather than throwing` |
| 0002-R15 | `test/features/notes/note_limits_test.dart` › `save` › `writes nothing locally when a limit is exceeded` |

### Length limits, and why the client must check first

R15 exists because of a real pair of bugs. The limits were declared in the Drift
column *and* `firestore.rules` but nowhere the app checked, and both enforcement
layers fail badly on their own:

- Drift throws `InvalidDataException` straight out of `save()`. `NotesController`
  only catches `NotesFailure`, so a 201-character title reached the UI as an
  unhandled error.
- The rules reject an over-long body *after* the local write has already
  succeeded, leaving the note `pendingSync: true` forever with nothing to explain
  it.

`Note.maxTitleLength` / `Note.maxBodyLength` are now the single source of truth,
checked before anything is written. The other two layers remain as defence in
depth, and the editor's `maxLength` stops the user at the boundary so the error
path is a backstop rather than the normal way to hit it.

## Open questions

- ~~Should `sync()` run automatically on connectivity restore?~~ **Resolved by
  [0011](0011-connectivity.md):** `ReconnectSyncCoordinator` pushes the queue on
  an offline→online transition.
- Nothing retries on a *failed* sync other than the next reconnect or a manual
  tap. Backoff is deliberately out of scope; see [0011](0011-connectivity.md).
