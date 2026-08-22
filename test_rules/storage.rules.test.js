import { afterAll, afterEach, beforeAll, describe, it } from 'vitest';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { ref, uploadBytes, getBytes, deleteObject } from 'firebase/storage';
import { paths, pngBytes, testEnv } from './helpers.js';

/**
 * Tests `storage.rules` against the real emulator.
 *
 * There is no Dart or JS fake for Cloud Storage rules at all, so without this
 * the rules were pure assertion — and a client/rules mismatch means uploads land
 * somewhere unprotected while nothing fails loudly.
 */
describe('storage.rules', () => {
  let env;
  let owner;
  let intruder;
  let anon;

  const image = { contentType: 'image/png' };

  beforeAll(async () => {
    env = await testEnv();
    owner = env.authenticatedContext('owner').storage();
    intruder = env.authenticatedContext('intruder').storage();
    anon = env.unauthenticatedContext().storage();
  });

  afterEach(() => env.clearStorage());
  afterAll(() => env.cleanup());

  /** Uploads bypassing rules, so read tests have something to read. */
  const seed = (path) =>
    env.withSecurityRulesDisabled((ctx) =>
      uploadBytes(ref(ctx.storage(), path), pngBytes, image),
    );

  describe('avatars', () => {
    it('lets the owner upload their avatar', async () => {
      await assertSucceeds(
        uploadBytes(ref(owner, paths.avatar('owner')), pngBytes, image),
      );
    });

    it('lets the owner read their avatar', async () => {
      await seed(paths.avatar('owner'));
      await assertSucceeds(getBytes(ref(owner, paths.avatar('owner'))));
    });

    it('denies uploading over another user\'s avatar', async () => {
      await assertFails(
        uploadBytes(ref(intruder, paths.avatar('owner')), pngBytes, image),
      );
    });

    it('denies reading another user\'s avatar', async () => {
      await seed(paths.avatar('owner'));
      await assertFails(getBytes(ref(intruder, paths.avatar('owner'))));
    });

    it('denies an unauthenticated upload', async () => {
      await assertFails(
        uploadBytes(ref(anon, paths.avatar('owner')), pngBytes, image),
      );
    });

    it('rejects a non-image avatar', async () => {
      await assertFails(
        uploadBytes(ref(owner, paths.avatar('owner')), pngBytes, {
          contentType: 'application/pdf',
        }),
      );
    });

    it('rejects an avatar over 5 MB', async () => {
      const big = Buffer.alloc(6 * 1024 * 1024);
      await assertFails(
        uploadBytes(ref(owner, paths.avatar('owner')), big, image),
      );
    });
  });

  describe('note attachments', () => {
    const path = paths.attachment('owner', 'n1', 'photo.png');

    it('lets the owner upload an attachment', async () => {
      await assertSucceeds(uploadBytes(ref(owner, path), pngBytes, image));
    });

    it('lets the owner delete an attachment', async () => {
      await seed(path);
      await assertSucceeds(deleteObject(ref(owner, path)));
    });

    it('denies another user reading it', async () => {
      await seed(path);
      await assertFails(getBytes(ref(intruder, path)));
    });

    it('denies another user deleting it', async () => {
      await seed(path);
      await assertFails(deleteObject(ref(intruder, path)));
    });

    it('rejects an attachment over 8 MB', async () => {
      // Matches FirebaseStorageRepository.maxDownloadBytes — a file larger than
      // the client will ever download is not worth storing.
      const big = Buffer.alloc(9 * 1024 * 1024);
      await assertFails(uploadBytes(ref(owner, path), big, image));
    });

    it('allows a non-image attachment, unlike an avatar', async () => {
      await assertSucceeds(
        uploadBytes(ref(owner, paths.attachment('owner', 'n1', 'notes.pdf')),
          pngBytes, { contentType: 'application/pdf' }),
      );
    });
  });

  describe('deny by default', () => {
    it('denies an unmatched path', async () => {
      await assertFails(
        uploadBytes(ref(owner, 'public/anything.png'), pngBytes, image),
      );
    });

    it('denies a path just outside the user subtree', async () => {
      await assertFails(
        uploadBytes(ref(owner, 'users/owner/other.png'), pngBytes, image),
      );
    });
  });
});
