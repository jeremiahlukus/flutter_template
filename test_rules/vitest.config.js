import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Rules tests share one emulator instance, so they must not run in
    // parallel — two files clearing Firestore at once would flake constantly.
    fileParallelism: false,
    testTimeout: 20_000,
    hookTimeout: 20_000,
  },
});
