import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/core/logging/app_logger.dart';
import 'package:flutter_template/src/core/providers/firebase_providers.dart';

class StorageFailure implements Exception {
  const StorageFailure(this.code, this.message);

  factory StorageFailure.fromFirebase(FirebaseException e) => StorageFailure(
    e.code,
    switch (e.code) {
      'unauthorized' => 'You do not have permission to do that.',
      'object-not-found' => 'That file no longer exists.',
      'quota-exceeded' => 'Storage quota exceeded.',
      'canceled' => 'Upload canceled.',
      _ => e.message ?? 'File operation failed.',
    },
  );

  final String code;
  final String message;

  @override
  String toString() => 'StorageFailure($code): $message';
}

/// File storage in the app's vocabulary: paths in, URLs out.
///
/// An interface (rather than a `FirebaseStorage` wrapper) because there is no
/// usable fake for the Storage SDK — [InMemoryStorageRepository] is how the
/// suite covers everything that consumes uploads.
abstract interface class StorageRepository {
  /// Uploads [bytes] to [path] and returns the public download URL.
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
  });

  Future<String> downloadUrl(String path);

  Future<Uint8List?> readBytes(String path);

  Future<void> delete(String path);

  Future<List<String>> list(String directory);

  /// Conventional location for a user's avatar. Centralised so the storage
  /// security rules and the client agree on one layout.
  String avatarPath(String userId) => 'users/$userId/avatar.jpg';

  /// Conventional location for a note attachment.
  String attachmentPath(String userId, String noteId, String fileName) =>
      'users/$userId/notes/$noteId/$fileName';
}

class FirebaseStorageRepository implements StorageRepository {
  const FirebaseStorageRepository(this._storage);

  final FirebaseStorage _storage;

  /// 8 MB — enough for a photo, small enough to refuse a runaway upload.
  static const int maxDownloadBytes = 8 * 1024 * 1024;

  @override
  String avatarPath(String userId) => 'users/$userId/avatar.jpg';

  @override
  String attachmentPath(String userId, String noteId, String fileName) =>
      'users/$userId/notes/$noteId/$fileName';

  @override
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) => _run('upload:$path', () async {
    final ref = _storage.ref(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType ?? 'application/octet-stream'),
    );
    return ref.getDownloadURL();
  });

  @override
  Future<String> downloadUrl(String path) =>
      _run('url:$path', () => _storage.ref(path).getDownloadURL());

  @override
  Future<Uint8List?> readBytes(String path) => _run(
    'read:$path',
    () => _storage.ref(path).getData(maxDownloadBytes),
  );

  @override
  Future<void> delete(String path) =>
      _run('delete:$path', () => _storage.ref(path).delete());

  @override
  Future<List<String>> list(String directory) =>
      _run('list:$directory', () async {
        final result = await _storage.ref(directory).listAll();
        return result.items.map((ref) => ref.fullPath).toList();
      });

  Future<T> _run<T>(String label, Future<T> Function() body) async {
    try {
      return await body();
    } on FirebaseException catch (e) {
      AppLogger.instance.w('Storage "$label" failed: ${e.code}');
      throw StorageFailure.fromFirebase(e);
    } catch (error, stackTrace) {
      AppLogger.instance.e(
        'Storage "$label" failed unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      throw const StorageFailure('unknown', 'File operation failed.');
    }
  }
}

/// Map-backed [StorageRepository] for tests and for `flutter run` without a
/// configured Storage bucket.
@visibleForTesting
class InMemoryStorageRepository implements StorageRepository {
  final Map<String, Uint8List> files = {};

  /// Set to a code to make the next call throw, for error-path tests.
  String? failWith;

  @override
  String avatarPath(String userId) => 'users/$userId/avatar.jpg';

  @override
  String attachmentPath(String userId, String noteId, String fileName) =>
      'users/$userId/notes/$noteId/$fileName';

  void _maybeFail() {
    final code = failWith;
    if (code != null) {
      failWith = null;
      throw StorageFailure(code, 'Injected failure: $code');
    }
  }

  @override
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    _maybeFail();
    files[path] = bytes;
    return 'memory://$path';
  }

  @override
  Future<String> downloadUrl(String path) async {
    _maybeFail();
    if (!files.containsKey(path)) {
      throw const StorageFailure(
        'object-not-found',
        'That file no longer exists.',
      );
    }
    return 'memory://$path';
  }

  @override
  Future<Uint8List?> readBytes(String path) async {
    _maybeFail();
    return files[path];
  }

  @override
  Future<void> delete(String path) async {
    _maybeFail();
    files.remove(path);
  }

  @override
  Future<List<String>> list(String directory) async {
    _maybeFail();
    final prefix = directory.endsWith('/') ? directory : '$directory/';
    return files.keys.where((k) => k.startsWith(prefix)).toList()..sort();
  }
}

final storageRepositoryProvider = Provider<StorageRepository>(
  (ref) => FirebaseStorageRepository(ref.watch(firebaseStorageProvider)),
);
