// ignore_for_file: implementation_imports

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth2/src/credentials.dart';

// Project imports:
import 'package:flutter_template/auth/infrastructure/credentials_storage/credentials_storage.dart';

class SecureCredentialsStorage implements CredentialsStorage {
  SecureCredentialsStorage(this._storage);

  final FlutterSecureStorage _storage;
  static const _key = 'oath2_credentials';

  @visibleForTesting
  Credentials? cachedCredentials;

  @override
  Future<Credentials?> read() async {
    if (cachedCredentials != null) {
      return cachedCredentials;
    }
    final credentialJson = await _storage.read(key: _key);
    if (credentialJson == null) {
      return null;
    }
    try {
      return cachedCredentials = Credentials.fromJson(credentialJson);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(Credentials credentials) {
    cachedCredentials = credentials;
    return _storage.write(key: _key, value: credentials.toJson());
  }

  @override
  Future<void> clear() {
    cachedCredentials = null;
    return _storage.delete(key: _key);
  }
}
