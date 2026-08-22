# 0018 · Pagination

- **Status:** Accepted
- **Created:** 2026-08-22

## Context

`watchNotes()` loaded every cached row and `sync()` read the entire remote
collection in one `get()`. Fine at 20 notes, a problem at 2,000 — and genuinely
annoying to retrofit, because it touches the repository, the sync loop, and the
list widget at once.

The design question is not "how do I page" but "how do I page a **reactive**
list". Drift streams re-emit on every write, so the usual accumulate-pages-in-a-
list approach fights the query and drifts out of sync with it.

## Requirements

| ID | Requirement |
|---|---|
| 0018-R1 | The list query MUST be bounded. |
| 0018-R2 | A bounded query MUST return the newest rows, with a stable tie-break. |
| 0018-R3 | Scrolling toward the end MUST request more, ahead of the edge. |
| 0018-R4 | "More may exist" MUST be derivable from the result, with no extra query. |
| 0018-R5 | Growing MUST stop once the collection is exhausted. |
| 0018-R6 | The remote pull MUST be paged. |
| 0018-R7 | The pull cursor MUST be stable while the pull is in flight. |
| 0018-R8 | A full final page MUST NOT cause a duplicate read. |
| 0018-R9 | Paging MUST NOT introduce a perpetual spinner. |

## Non-goals

- **Paging the *remote* query from the UI.** The UI reads the local cache; the
  remote pull is a background concern with its own page size.
- **Reverse paging / jump-to-index.** Neither is needed by a chronological list.
- **A network-backed paged list.** Would need a real loading state; see R9.

## Design

`PageWindow` holds a requested size and a page step, and nothing else. Note what
is *absent*: any notion of the collection's total. R4 is satisfied by
`hasMoreAfter(loaded)` — a query returning fewer rows than the window has hit the
end. Tracking a count would mean a second query, a second stream, and two sources
of truth that can disagree.

**Two bugs from getting this wrong first**, both worth recording:

1. A `notesCountProvider` pushed its total into the window provider that
   `notesProvider` also watched. A provider writing to a provider it watches
   re-enters its own build; the whole test suite hung.
2. The scroll handler called `ref.read` on an auto-dispose provider. With no
   listener it built and tore down the count stream on *every scroll frame*.

R9 is the third. A trailing spinner shown whenever more exists is parked
permanently at the bottom of a long list — implying work that is not happening,
and stopping `pumpAndSettle` from ever settling. With a SQLite-backed list a page
is never genuinely in flight, so there is no spinner at all. A network-backed
list would need one.

R7 uses keyset pagination on the document id rather than `startAfterDocument`:
the cursor is a plain string, so no snapshot is held across pages, and id
ordering is stable while a note edited mid-sync would move under an `updatedAt`
cursor and could be skipped or read twice.

## Verification

| ID | Test |
|---|---|
| 0018-R1 | `test/features/notes/notes_pagination_test.dart` › `AppDatabase.watchNotes` › `respects a limit` |
| 0018-R2 | `…` › `a limit takes the newest rows, not an arbitrary slice` / `ordering is stable for identical timestamps` |
| 0018-R3 | `…` › `notes list UI` › `scrolling to the bottom loads more` |
| 0018-R4 | `test/core/paging/page_window_test.dart` › `hasMoreAfter` |
| 0018-R5 | `…notes_pagination…` › `notes list UI` › `stops growing once the whole cache is shown` |
| 0018-R6 | `…` › `sync paging` › `pulls a collection larger than one page` |
| 0018-R7 | `notes_repository.dart` › keyset cursor on `FieldPath.documentId` |
| 0018-R8 | `…` › `sync paging` › `pulls an exact multiple of the page size without duplicating` |
| 0018-R9 | `…` › `notes list UI` › `shows no trailing spinner, even with more to load` |

## Open questions

- `syncPageSize` is 200, chosen because Firestore bills per document read either
  way and 200 keeps peak memory modest. Untuned against a real dataset.
