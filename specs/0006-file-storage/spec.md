# 0006 · File storage

- **Status:** Accepted
- **Created:** 2026-08-21

## Context

Cloud Storage differs from Auth and Firestore in one practical way: **there is no
usable fake.** `firebase_auth_mocks` and `fake_cloud_firestore` let those layers
be tested for real; nothing equivalent exists for Storage.

There is also a correctness trap. The client's upload paths and the Storage
security rules must describe the same layout. If they drift, uploads land
somewhere the rules do not protect — and nothing fails loudly.

## Requirements

| ID | Requirement |
|---|---|
| 0006-R1 | Storage paths MUST be produced by named helpers, never assembled at call sites. |
| 0006-R2 | The Firebase and in-memory implementations MUST agree on every path. |
| 0006-R3 | Features MUST depend on a `StorageRepository` interface. |
| 0006-R4 | An in-memory implementation MUST support injected failures for error-path tests. |
| 0006-R5 | Every Firebase error MUST surface as a `StorageFailure` with user-fit copy. |
| 0006-R6 | Downloads MUST be capped, so a large object cannot exhaust device memory. |
| 0006-R7 | Uploads MUST always send a content type. |
| 0006-R8 | Directory listing MUST NOT treat a prefix match as a directory match. |
| 0006-R9 | The rules in `storage.rules` MUST mirror the path helpers. |

## Non-goals

- **Upload progress.** `putData` returns an `UploadTask` with a snapshot stream;
  the repository awaits it. Expose the stream when a UI needs a progress bar.
- **Image picking / resizing.** `ProfileScreen` uploads a 1×1 PNG placeholder so
  the round-trip is real without an `image_picker` dependency.
- **Attachment sync.** Notes reference no files yet.

## Verification

| ID | Test |
|---|---|
| 0006-R1 | `test/features/storage/storage_repository_test.dart` › `path conventions` |
| 0006-R2 | `test/features/storage/firebase_storage_repository_test.dart` › `path conventions` › `match the in-memory implementation exactly` |
| 0006-R3 | `test/core/firebase_providers_test.dart` › `every Firebase seam is replaceable` |
| 0006-R4 | `test/features/storage/storage_repository_test.dart` › `uploadBytes` › `propagates an injected failure` |
| 0006-R5 | `test/features/storage/firebase_storage_repository_test.dart` › `uploadBytes` › `maps a Firebase error to a StorageFailure` |
| 0006-R6 | `…` › `readBytes` › `caps downloads at 8 MB` |
| 0006-R7 | `…` › `uploadBytes` › `defaults the content type rather than sending none` |
| 0006-R8 | `test/features/storage/storage_repository_test.dart` › `list` › `does not treat a prefix match as a directory match` |
| 0006-R9 | `test_rules/storage.rules.test.js` (whole file) → [spec 0016](../0016-emulator-and-rules/spec.md) |

## Open questions

- ~~R9 is unverified.~~ **Resolved by [0016](../0016-emulator-and-rules/spec.md):** both
  rule sets now run against the real emulator in CI. The Dart fakes turned out to
  be incapable of it — no custom functions, no `request.resource`.
- Image *picking* is covered ([0019](../0019-media/spec.md)), but nothing yet uses
  `attachmentPath` — note attachments remain unbuilt.
