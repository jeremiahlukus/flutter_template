# Implementation Plan: 0018 · Pagination

- **Status:** Accepted
- **Created:** 2026-08-22

> Specification: [`spec.md`](spec.md)

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
