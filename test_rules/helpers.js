import { readFileSync } from 'node:fs';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';

/// Rules live one directory up, beside the app they protect.
const rulesPath = (name) => new URL(`../${name}`, import.meta.url).pathname;

/**
 * Boots one emulator-backed test environment for a whole test file.
 *
 * Both rule sets are loaded together because they describe the *same* path
 * scheme — `users/{uid}/...` — and the point of these tests is that the two
 * agree with each other and with `StorageRepository`'s path helpers.
 */
export async function testEnv() {
  return initializeTestEnvironment({
    projectId: 'flutter-template-local',
    firestore: {
      rules: readFileSync(rulesPath('firestore.rules'), 'utf8'),
      host: 'localhost',
      port: 8080,
    },
    storage: {
      rules: readFileSync(rulesPath('storage.rules'), 'utf8'),
      host: 'localhost',
      port: 9199,
    },
  });
}

/** A valid device document, matching what `PushRegistrar` writes. */
export function validDevice(overrides = {}) {
  return {
    token: 'device-token-1',
    updatedAt: new Date(),
    platform: 'iOS',
    ...overrides,
  };
}

/** A valid note, matching what `Note.toFirestore()` writes. */
export function validNote(overrides = {}) {
  return {
    title: 'Groceries',
    body: 'Milk\nEggs',
    updatedAt: new Date(),
    ...overrides,
  };
}

/** Path helpers, mirroring `lib/src/features/storage/storage_repository.dart`. */
export const paths = {
  note: (uid, id) => `users/${uid}/notes/${id}`,
  user: (uid) => `users/${uid}`,
  device: (uid, token) => `users/${uid}/devices/${token}`,
  updatePolicy: () => 'config/app_update',
  avatar: (uid) => `users/${uid}/avatar.jpg`,
  attachment: (uid, noteId, file) => `users/${uid}/notes/${noteId}/${file}`,
};

/** A 1×1 PNG, so Storage writes carry real image bytes. */
export const pngBytes = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==',
  'base64',
);
