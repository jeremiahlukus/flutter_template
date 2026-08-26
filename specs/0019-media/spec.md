# 0019 · Image picking

- **Status:** Accepted
- **Created:** 2026-08-22

## Context

The avatar upload was a hard-coded 1×1 PNG. It proved the Storage round-trip but
was not the feature — and the interesting parts of image upload are exactly the
ones a placeholder skips: cancellation, size, and the fact that a modern phone
photo is ~4MB before you do anything about it.

## Requirements

| ID | Requirement |
|---|---|
| 0019-R1 | The user MUST choose between camera and library. |
| 0019-R2 | Cancelling MUST be a normal outcome, not an error. |
| 0019-R3 | Cancelling MUST produce no message. |
| 0019-R4 | Images MUST be downscaled before upload. |
| 0019-R5 | Images MUST be re-encoded as JPEG at a fixed quality. |
| 0019-R6 | A compression failure MUST fall back to the original bytes. |
| 0019-R7 | An unreadable image MUST be reported to the user. |
| 0019-R8 | A storage failure MUST use localised copy. |
| 0019-R9 | The picker MUST be replaceable in tests. |

## Non-goals

- **Cropping.** `image_cropper` needs native config on both platforms; scaling to
  a square avatar is enough here.
- **Multiple selection / video.** The interface is shaped to grow into it.
- **Progress reporting.** A 512px JPEG uploads faster than a progress bar is
  worth.

## Verification

| ID | Test |
|---|---|
| 0019-R1 | `test/features/auth/presentation/profile_screen_test.dart` › `avatar` › `offers camera and gallery` |
| 0019-R2 | `…` › `avatar` › `cancelling the picker uploads nothing and says nothing` |
| 0019-R3 | (same test — asserts no snack bar) |
| 0019-R4 | `PlatformImageSourceService.maxDimension`, applied in `pickImage` and `compress` |
| 0019-R5 | `PlatformImageSourceService.jpegQuality`; upload sets `image/jpeg` |
| 0019-R6 | `PlatformImageSourceService.compress` catch branch |
| 0019-R7 | `…` › `avatar` › `reports an unreadable image` |
| 0019-R8 | `…` › `avatar` › `reports a storage failure with localised copy` |
| 0019-R9 | `…` › `avatar` › `requests the chosen source` (via `FakeImageSourceService`) |

## Open questions

- R4–R6 are only verified by construction: `flutter_image_compress` reaches a
  platform channel, so `compress` itself has no unit test. The bytes that *are*
  uploaded are asserted end to end.
