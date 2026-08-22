import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_template/src/features/storage/storage_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements FirebaseStorage {}

class _MockReference extends Mock implements Reference {}

class _MockListResult extends Mock implements ListResult {}

class _MockSnapshot extends Mock implements TaskSnapshot {}

/// `UploadTask` is a `Future<TaskSnapshot>`, so a fake only has to forward the
/// `Future` surface to a real future. Mocking `then` directly is far more
/// fragile than this.
class _FakeUploadTask implements UploadTask {
  _FakeUploadTask(this._future);

  final Future<TaskSnapshot> _future;

  @override
  Stream<TaskSnapshot> asStream() => _future.asStream();

  @override
  Future<TaskSnapshot> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) => _future.catchError(onError, test: test);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(TaskSnapshot value) onValue, {
    Function? onError,
  }) => _future.then(onValue, onError: onError);

  @override
  Future<TaskSnapshot> timeout(
    Duration timeLimit, {
    FutureOr<TaskSnapshot> Function()? onTimeout,
  }) => _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<TaskSnapshot> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} is not needed in tests');
}

void main() {
  late _MockStorage storage;
  late _MockReference ref;
  late FirebaseStorageRepository repo;

  final bytes = Uint8List.fromList([1, 2, 3]);
  final failure = FirebaseException(
    plugin: 'firebase_storage',
    code: 'unauthorized',
  );

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(SettableMetadata());
  });

  setUp(() {
    storage = _MockStorage();
    ref = _MockReference();
    repo = FirebaseStorageRepository(storage);
    when(() => storage.ref(any())).thenReturn(ref);
  });

  group('uploadBytes', () {
    setUp(() {
      // `UploadTask` is itself a `Future`, so mocktail rejects `thenReturn`.
      when(
        () => ref.putData(any(), any()),
      ).thenAnswer((_) => _FakeUploadTask(Future.value(_MockSnapshot())));
      when(ref.getDownloadURL).thenAnswer((_) async => 'https://cdn/a.png');
    });

    test('writes to the requested path and returns the download URL', () async {
      final url = await repo.uploadBytes(path: 'a/b.png', bytes: bytes);

      expect(url, 'https://cdn/a.png');
      verify(() => storage.ref('a/b.png')).called(1);
    });

    test('passes the supplied content type through', () async {
      await repo.uploadBytes(
        path: 'a/b.png',
        bytes: bytes,
        contentType: 'image/png',
      );

      final metadata =
          verify(() => ref.putData(bytes, captureAny())).captured.single
              as SettableMetadata;
      expect(metadata.contentType, 'image/png');
    });

    test('defaults the content type rather than sending none', () async {
      await repo.uploadBytes(path: 'a/b.bin', bytes: bytes);

      final metadata =
          verify(() => ref.putData(bytes, captureAny())).captured.single
              as SettableMetadata;
      expect(metadata.contentType, 'application/octet-stream');
    });

    test('maps a Firebase error to a StorageFailure', () async {
      when(() => ref.putData(any(), any())).thenThrow(failure);

      await expectLater(
        repo.uploadBytes(path: 'p', bytes: bytes),
        throwsA(
          isA<StorageFailure>()
              .having((e) => e.code, 'code', 'unauthorized')
              .having(
                (e) => e.message,
                'message',
                'You do not have permission to do that.',
              ),
        ),
      );
    });

    test('maps a non-Firebase error to a generic StorageFailure', () async {
      when(() => ref.putData(any(), any())).thenThrow(StateError('boom'));

      await expectLater(
        repo.uploadBytes(path: 'p', bytes: bytes),
        throwsA(
          isA<StorageFailure>()
              .having((e) => e.code, 'code', 'unknown')
              .having((e) => e.message, 'message', 'File operation failed.'),
        ),
      );
    });
  });

  group('downloadUrl', () {
    test('returns the URL for the path', () async {
      when(ref.getDownloadURL).thenAnswer((_) async => 'https://cdn/x');

      expect(await repo.downloadUrl('x'), 'https://cdn/x');
      verify(() => storage.ref('x')).called(1);
    });

    test('maps object-not-found', () async {
      when(ref.getDownloadURL).thenThrow(
        FirebaseException(plugin: 'p', code: 'object-not-found'),
      );

      await expectLater(
        repo.downloadUrl('x'),
        throwsA(
          isA<StorageFailure>().having(
            (e) => e.message,
            'message',
            'That file no longer exists.',
          ),
        ),
      );
    });
  });

  group('readBytes', () {
    test('returns the bytes, capped at the max download size', () async {
      when(() => ref.getData(any())).thenAnswer((_) async => bytes);

      expect(await repo.readBytes('x'), bytes);
      verify(
        () => ref.getData(FirebaseStorageRepository.maxDownloadBytes),
      ).called(1);
    });

    test('caps downloads at 8 MB', () {
      // A runaway download should be refused rather than exhaust device memory.
      expect(FirebaseStorageRepository.maxDownloadBytes, 8 * 1024 * 1024);
    });

    test('maps a quota error', () async {
      when(() => ref.getData(any())).thenThrow(
        FirebaseException(plugin: 'p', code: 'quota-exceeded'),
      );

      await expectLater(
        repo.readBytes('x'),
        throwsA(
          isA<StorageFailure>().having(
            (e) => e.message,
            'message',
            'Storage quota exceeded.',
          ),
        ),
      );
    });
  });

  group('delete', () {
    test('deletes the reference', () async {
      when(ref.delete).thenAnswer((_) async {});

      await repo.delete('x');

      verify(ref.delete).called(1);
    });

    test('maps a cancellation', () async {
      when(
        ref.delete,
      ).thenThrow(FirebaseException(plugin: 'p', code: 'canceled'));

      await expectLater(
        repo.delete('x'),
        throwsA(
          isA<StorageFailure>().having(
            (e) => e.message,
            'message',
            'Upload canceled.',
          ),
        ),
      );
    });
  });

  group('list', () {
    test('returns the full paths of the listed items', () async {
      final a = _MockReference();
      final b = _MockReference();
      when(() => a.fullPath).thenReturn('users/u1/a.png');
      when(() => b.fullPath).thenReturn('users/u1/b.png');

      final result = _MockListResult();
      when(() => result.items).thenReturn([a, b]);
      when(ref.listAll).thenAnswer((_) async => result);

      expect(
        await repo.list('users/u1'),
        ['users/u1/a.png', 'users/u1/b.png'],
      );
    });

    test('returns empty for an empty directory', () async {
      final result = _MockListResult();
      when(() => result.items).thenReturn([]);
      when(ref.listAll).thenAnswer((_) async => result);

      expect(await repo.list('empty'), isEmpty);
    });

    test('maps a listing failure', () async {
      when(ref.listAll).thenThrow(failure);

      await expectLater(repo.list('x'), throwsA(isA<StorageFailure>()));
    });
  });

  group('path conventions', () {
    test('match the in-memory implementation exactly', () {
      // Client and security rules must agree on one layout; if the two
      // implementations drift, uploads land where the rules do not protect them.
      final memory = InMemoryStorageRepository();

      expect(repo.avatarPath('u1'), memory.avatarPath('u1'));
      expect(
        repo.attachmentPath('u1', 'n1', 'f.png'),
        memory.attachmentPath('u1', 'n1', 'f.png'),
      );
    });

    test('avatars live under the owning user', () {
      expect(repo.avatarPath('u1'), 'users/u1/avatar.jpg');
    });

    test('attachments live under the owning user and note', () {
      expect(
        repo.attachmentPath('u1', 'n1', 'f.png'),
        'users/u1/notes/n1/f.png',
      );
    });
  });

  group('StorageFailure.fromFirebase', () {
    test('falls back to the Firebase message for an unmapped code', () {
      final result = StorageFailure.fromFirebase(
        FirebaseException(plugin: 'p', code: 'weird', message: 'Raw detail'),
      );

      expect(result.message, 'Raw detail');
    });

    test('falls back to generic copy when there is no message', () {
      final result = StorageFailure.fromFirebase(
        FirebaseException(plugin: 'p', code: 'weird'),
      );

      expect(result.message, 'File operation failed.');
    });
  });
}
