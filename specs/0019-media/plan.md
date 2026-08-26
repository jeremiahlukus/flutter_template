# Implementation Plan: 0019 · Image picking

- **Status:** Accepted
- **Created:** 2026-08-22

> Specification: [`spec.md`](spec.md)

## Design

`ImageSourceService` is an interface because `image_picker` reaches a platform
channel and cannot run in a widget test — and because R2 needs cancellation to be
a **null return**, not an exception. A picker the user backs out of is normal
behaviour.

R4 does the real work: downscaling to 512px before compressing is what actually
saves bandwidth. 512 covers an 80dp avatar on a 4x display with headroom. R5's
quality of 85 is visually indistinguishable from 100 at that size for roughly a
third of the bytes.

Compression runs unconditionally rather than trusting `image_picker`'s own
`imageQuality`, which is ignored on some platforms. R6 returns the original on
failure: a larger upload beats no upload.
