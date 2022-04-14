// Package imports:
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth2/src/credentials.dart';

// Project imports:
import 'package:flutter_template/auth/infrastructure/credentials_storage/credentials_storage.dart';

// ignore: implementation_imports

class SecureCredentialsStorage implements CredentialsStorage {
  SecureCredentialsStorage(this._storage);

  final FlutterSecureStorage _storage;
  static const _key = 'oath2_credentials';
  Credentials? _cachedCredentials;

  @override
  Future<Credentials?> read() async {
    if (_cachedCredentials != null) {
      return _cachedCredentials;
    }
    final credentialJson = await _storage.read(key: _key);
    if (credentialJson == null) {
      return null;
    }
    try {
      return _cachedCredentials = Credentials.fromJson(credentialJson);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(Credentials credentials) {
    _cachedCredentials = credentials;
    return _storage.write(key: _key, value: credentials.toJson());
  }

  @override
  Future<void> clear() {
    _cachedCredentials = null;
    return _storage.delete(key: _key);
  }
}
