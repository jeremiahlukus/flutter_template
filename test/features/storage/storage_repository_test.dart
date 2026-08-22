import 'dart:typed_data';

import 'package:flutter_template/src/features/storage/storage_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryStorageRepository storage;
  final bytes = Uint8List.fromList([1, 2, 3]);

  setUp(() => storage = InMemoryStorageRepository());

  group('path conventions', () {
    test('avatarPath is scoped to the user', () {
      expect(storage.avatarPath('u1'), 'users/u1/avatar.jpg');
    });

    test('attachmentPath is scoped to the user and note', () {
      expect(
        storage.attachmentPath('u1', 'n1', 'a.png'),
        'users/u1/notes/n1/a.png',
      );
    });
  });

  group('uploadBytes', () {
    test('stores the bytes and returns a URL', () async {
      final url = await storage.uploadBytes(path: 'a/b.png', bytes: bytes);

      expect(url, 'memory://a/b.png');
      expect(storage.files['a/b.png'], bytes);
    });

    test('overwrites an existing path', () async {
      await storage.uploadBytes(path: 'p', bytes: bytes);
      await storage.uploadBytes(path: 'p', bytes: Uint8List.fromList([9]));

      expect(storage.files['p'], [9]);
    });

    test('propagates an injected failure', () async {
      storage.failWith = 'unauthorized';

      await expectLater(
        storage.uploadBytes(path: 'p', bytes: bytes),
        throwsA(
          isA<StorageFailure>().having((e) => e.code, 'code', 'unauthorized'),
        ),
      );
    });

    test('an injected failure only fires once', () async {
      storage.failWith = 'quota-exceeded';
      await expectLater(
        storage.uploadBytes(path: 'p', bytes: bytes),
        throwsA(isA<StorageFailure>()),
      );

      await storage.uploadBytes(path: 'p', bytes: bytes);
      expect(storage.files, contains('p'));
    });
  });

  group('downloadUrl', () {
    test('returns a URL for an existing file', () async {
      await storage.uploadBytes(path: 'p', bytes: bytes);
      expect(await storage.downloadUrl('p'), 'memory://p');
    });

    test('throws object-not-found for a missing file', () async {
      await expectLater(
        storage.downloadUrl('nope'),
        throwsA(
          isA<StorageFailure>().having(
            (e) => e.code,
            'code',
            'object-not-found',
          ),
        ),
      );
    });

    test('propagates an injected failure', () async {
      storage.failWith = 'canceled';
      await expectLater(
        storage.downloadUrl('p'),
        throwsA(
          isA<StorageFailure>().having((e) => e.code, 'code', 'canceled'),
        ),
      );
    });
  });

  group('readBytes', () {
    test('returns the stored bytes', () async {
      await storage.uploadBytes(path: 'p', bytes: bytes);
      expect(await storage.readBytes('p'), bytes);
    });

    test('returns null for a missing path', () async {
      expect(await storage.readBytes('nope'), isNull);
    });

    test('propagates an injected failure', () async {
      storage.failWith = 'unauthorized';
      await expectLater(
        storage.readBytes('p'),
        throwsA(isA<StorageFailure>()),
      );
    });
  });

  group('delete', () {
    test('removes the file', () async {
      await storage.uploadBytes(path: 'p', bytes: bytes);
      await storage.delete('p');

      expect(storage.files, isEmpty);
    });

    test('is a no-op for a missing path', () async {
      await storage.delete('nope');
      expect(storage.files, isEmpty);
    });

    test('propagates an injected failure', () async {
      storage.failWith = 'unauthorized';
      await expectLater(storage.delete('p'), throwsA(isA<StorageFailure>()));
    });
  });

  group('list', () {
    setUp(() async {
      await storage.uploadBytes(path: 'users/u1/a.png', bytes: bytes);
      await storage.uploadBytes(path: 'users/u1/b.png', bytes: bytes);
      await storage.uploadBytes(path: 'users/u2/c.png', bytes: bytes);
    });

    test('returns only entries under the directory, sorted', () async {
      expect(
        await storage.list('users/u1'),
        ['users/u1/a.png', 'users/u1/b.png'],
      );
    });

    test('accepts a trailing slash', () async {
      expect(await storage.list('users/u1/'), hasLength(2));
    });

    test('returns empty for an unknown directory', () async {
      expect(await storage.list('users/u9'), isEmpty);
    });

    test('does not treat a prefix match as a directory match', () async {
      await storage.uploadBytes(path: 'users/u10/x.png', bytes: bytes);

      // 'users/u1' must not swallow 'users/u10/...'; the trailing slash in the
      // implementation is what prevents it.
      expect(await storage.list('users/u1'), hasLength(2));
    });

    test('propagates an injected failure', () async {
      storage.failWith = 'unauthorized';
      await expectLater(
        storage.list('users/u1'),
        throwsA(isA<StorageFailure>()),
      );
    });
  });

  group('StorageFailure', () {
    test('toString names the code and message', () {
      const failure = StorageFailure('code', 'message');
      expect(failure.toString(), contains('code'));
      expect(failure.toString(), contains('message'));
    });
  });
}
