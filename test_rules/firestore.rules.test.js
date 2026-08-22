import { afterAll, afterEach, beforeAll, describe, expect, it } from 'vitest';
import {
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, deleteDoc, collection, getDocs }
  from 'firebase/firestore';
import { paths, testEnv, validDevice, validNote } from './helpers.js';

/**
 * Tests `firestore.rules` against the real emulator.
 *
 * The Dart fake (`fake_cloud_firestore`) cannot do this: it supports neither
 * custom functions nor `request.resource`, and these rules use both. Rewriting
 * the rules to suit the fake would trade real security for testability, so the
 * emulator is the right tool here.
 */
describe('firestore.rules', () => {
  let env;
  let owner;
  let intruder;
  let anon;

  beforeAll(async () => {
    env = await testEnv();
    owner = env.authenticatedContext('owner').firestore();
    intruder = env.authenticatedContext('intruder').firestore();
    anon = env.unauthenticatedContext().firestore();
  });

  afterEach(() => env.clearFirestore());
  afterAll(() => env.cleanup());

  /** Writes a note bypassing rules, so read tests have something to read. */
  const seed = (uid, id, data = validNote()) =>
    env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), paths.note(uid, id)), data),
    );

  describe('ownership', () => {
    it('lets the owner read their own note', async () => {
      await seed('owner', 'n1');
      await assertSucceeds(getDoc(doc(owner, paths.note('owner', 'n1'))));
    });

    it('lets the owner create a note', async () => {
      await assertSucceeds(
        setDoc(doc(owner, paths.note('owner', 'n1')), validNote()),
      );
    });

    it('lets the owner update their note', async () => {
      await seed('owner', 'n1');
      await assertSucceeds(
        setDoc(doc(owner, paths.note('owner', 'n1')), validNote({
          title: 'Renamed',
        })),
      );
    });

    it('lets the owner delete their note', async () => {
      await seed('owner', 'n1');
      await assertSucceeds(deleteDoc(doc(owner, paths.note('owner', 'n1'))));
    });

    it('lets the owner list their own notes', async () => {
      await seed('owner', 'n1');
      await assertSucceeds(
        getDocs(collection(owner, `users/owner/notes`)),
      );
    });
  });

  describe('isolation between users', () => {
    it('denies reading another user\'s note', async () => {
      await seed('owner', 'n1');
      await assertFails(getDoc(doc(intruder, paths.note('owner', 'n1'))));
    });

    it('denies writing into another user\'s subtree', async () => {
      await assertFails(
        setDoc(doc(intruder, paths.note('owner', 'n1')), validNote()),
      );
    });

    it('denies deleting another user\'s note', async () => {
      await seed('owner', 'n1');
      await assertFails(deleteDoc(doc(intruder, paths.note('owner', 'n1'))));
    });

    it('denies listing another user\'s notes', async () => {
      await seed('owner', 'n1');
      await assertFails(getDocs(collection(intruder, 'users/owner/notes')));
    });

    it('denies reading another user\'s profile document', async () => {
      await assertFails(getDoc(doc(intruder, paths.user('owner'))));
    });
  });

  describe('unauthenticated access', () => {
    it('denies reads', async () => {
      await seed('owner', 'n1');
      await assertFails(getDoc(doc(anon, paths.note('owner', 'n1'))));
    });

    it('denies writes', async () => {
      await assertFails(
        setDoc(doc(anon, paths.note('owner', 'n1')), validNote()),
      );
    });
  });

  describe('document shape validation', () => {
    it('rejects a note with an unexpected field', async () => {
      // A compromised client must not be able to poison other devices' caches
      // with fields the app does not understand.
      await assertFails(
        setDoc(doc(owner, paths.note('owner', 'n1')), validNote({
          isAdmin: true,
        })),
      );
    });

    it('rejects a missing updatedAt', async () => {
      await assertFails(
        setDoc(doc(owner, paths.note('owner', 'n1')), {
          title: 'T',
          body: 'B',
        }),
      );
    });

    it('rejects a non-string title', async () => {
      await assertFails(
        setDoc(doc(owner, paths.note('owner', 'n1')), validNote({ title: 42 })),
      );
    });

    it('rejects a title over 200 characters', async () => {
      // Mirrors the Drift column limit; the two must agree or a synced note
      // fails to insert locally.
      await assertFails(
        setDoc(doc(owner, paths.note('owner', 'n1')), validNote({
          title: 'x'.repeat(201),
        })),
      );
    });

    it('accepts a title of exactly 200 characters', async () => {
      await assertSucceeds(
        setDoc(doc(owner, paths.note('owner', 'n1')), validNote({
          title: 'x'.repeat(200),
        })),
      );
    });

    it('rejects a body over 100k characters', async () => {
      await assertFails(
        setDoc(doc(owner, paths.note('owner', 'n1')), validNote({
          body: 'x'.repeat(100_001),
        })),
      );
    });

    it('accepts an empty title and body', async () => {
      // The app allows a note with only a body, and vice versa.
      await assertSucceeds(
        setDoc(doc(owner, paths.note('owner', 'n1')), validNote({
          title: '',
          body: '',
        })),
      );
    });
  });

  describe('push tokens', () => {
    // Without an explicit rule the catch-all denies these, and
    // `PushRegistrar` swallows the failure by design — so delivery would simply
    // never work, with nothing in the logs to say why.
    it('lets the owner register a device', async () => {
      await assertSucceeds(
        setDoc(doc(owner, paths.device('owner', 'tok1')), validDevice()),
      );
    });

    it('lets the owner refresh their own device document', async () => {
      await env.withSecurityRulesDisabled((ctx) =>
        setDoc(doc(ctx.firestore(), paths.device('owner', 'tok1')),
          validDevice()),
      );
      await assertSucceeds(
        setDoc(doc(owner, paths.device('owner', 'tok1')), validDevice()),
      );
    });

    it('lets the owner unregister a device', async () => {
      await env.withSecurityRulesDisabled((ctx) =>
        setDoc(doc(ctx.firestore(), paths.device('owner', 'tok1')),
          validDevice()),
      );
      await assertSucceeds(deleteDoc(doc(owner, paths.device('owner', 'tok1'))));
    });

    it('denies registering a device under another user', async () => {
      // Otherwise anyone could subscribe their device to someone else's
      // notifications.
      await assertFails(
        setDoc(doc(intruder, paths.device('owner', 'tok1')), validDevice()),
      );
    });

    it('denies reading another user\'s devices', async () => {
      await env.withSecurityRulesDisabled((ctx) =>
        setDoc(doc(ctx.firestore(), paths.device('owner', 'tok1')),
          validDevice()),
      );
      await assertFails(getDoc(doc(intruder, paths.device('owner', 'tok1'))));
    });

    it('denies an unauthenticated registration', async () => {
      await assertFails(
        setDoc(doc(anon, paths.device('owner', 'tok1')), validDevice()),
      );
    });

    it('rejects a device document with extra fields', async () => {
      // A device list is not general-purpose storage.
      await assertFails(
        setDoc(doc(owner, paths.device('owner', 'tok1')),
          validDevice({ arbitrary: 'x'.repeat(1000) })),
      );
    });

    it('rejects a missing token or platform', async () => {
      await assertFails(
        setDoc(doc(owner, paths.device('owner', 'tok1')), {
          updatedAt: new Date(),
        }),
      );
    });

    it('rejects an empty token', async () => {
      await assertFails(
        setDoc(doc(owner, paths.device('owner', 'tok1')),
          validDevice({ token: '' })),
      );
    });
  });

  describe('remote configuration', () => {
    // The forced-update gate reads this at launch. Without a rule the read is
    // denied, the policy fails open, and the gate can never fire.
    it('lets any signed-in user read the update policy', async () => {
      await env.withSecurityRulesDisabled((ctx) =>
        setDoc(doc(ctx.firestore(), paths.updatePolicy()),
          { minimumSupported: '1.0.0' }),
      );

      await assertSucceeds(getDoc(doc(owner, paths.updatePolicy())));
      await assertSucceeds(getDoc(doc(intruder, paths.updatePolicy())));
    });

    it('denies an unauthenticated read', async () => {
      await assertFails(getDoc(doc(anon, paths.updatePolicy())));
    });

    it('denies every client write', async () => {
      // This is a remote kill switch. Only the console or a trusted backend.
      await assertFails(
        setDoc(doc(owner, paths.updatePolicy()), { minimumSupported: '0.0.1' }),
      );
      await assertFails(
        setDoc(doc(anon, paths.updatePolicy()), { minimumSupported: '0.0.1' }),
      );
    });
  });

  describe('deny by default', () => {
    it('denies an unmatched collection', async () => {
      await assertFails(setDoc(doc(owner, 'audit/entry1'), { a: 1 }));
    });

    it('denies a deeper unmatched path under the user', async () => {
      await assertFails(
        setDoc(doc(owner, 'users/owner/secrets/s1'), { a: 1 }),
      );
    });
  });
});
