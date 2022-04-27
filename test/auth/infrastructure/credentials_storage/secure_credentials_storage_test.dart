// Package imports:
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oauth2/oauth2.dart';
import 'package:test/test.dart';

// Project imports:
import 'package:flutter_template/auth/infrastructure/credentials_storage/secure_credentials_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('SecureCredentialsStorage', () {
    const mockCredentialJson = '''
{
  "accessToken" : "d50d9fd00acf797ac409d5890fcc76669b727e63",
  "tokenType" : "Bearer",
  "expiresIn" : 1295998,
  "refreshToken" : "TZzj2yvtWlNP6BvG6UC5UKHXY2Ey6eEo80FSYax6Yv8",
  "scopes" :  ["admin"]
}''';
    group('.read', () {
      test("returns the cached credentials if it's not null", () async {
        final FlutterSecureStorage mockFlutterSecureStorage = MockFlutterSecureStorage();

        final secureCredentialsStorage = SecureCredentialsStorage(mockFlutterSecureStorage);

        final mockCredentials = Credentials.fromJson(mockCredentialJson);

        secureCredentialsStorage.cachedCredentials = mockCredentials;

        final actualCredential = await secureCredentialsStorage.read();
        final expectedCredential = Credentials.fromJson(mockCredentialJson);

        expect(
          actualCredential?.toJson(),
          expectedCredential.toJson(),
        );
      });

      test('returns null if FlutterSecureStorage reurns null when its key is read', () async {
        final FlutterSecureStorage mockFlutterSecureStorage = MockFlutterSecureStorage();

        when(() => mockFlutterSecureStorage.read(key: any(named: 'key'))).thenAnswer((_) => Future.value());

        final secureCredentialsStorage = SecureCredentialsStorage(mockFlutterSecureStorage);

        final actualCredential = await secureCredentialsStorage.read();
        const Credentials? expectedCredential = null;

        expect(actualCredential, expectedCredential);
      });

      test('returns the exact Credentials return by FlutterSecureStorage when its key is read', () async {
        final FlutterSecureStorage mockFlutterSecureStorage = MockFlutterSecureStorage();

        when(() => mockFlutterSecureStorage.read(key: any(named: 'key')))
            .thenAnswer((_) => Future.value(mockCredentialJson));

        final secureCredentialsStorage = SecureCredentialsStorage(mockFlutterSecureStorage);

        final actualCredential = await secureCredentialsStorage.read();
        final expectedCredential = Credentials.fromJson(mockCredentialJson);

        expect(
          actualCredential?.toJson(),
          expectedCredential.toJson(),
        );
      });

      test(
          'returns null if Credentials.fromJson() attempts returns a FormatException trying to parse a badly formatted JSON',
          () async {
        final FlutterSecureStorage mockFlutterSecureStorage = MockFlutterSecureStorage();

        const badlyFormattedJson = '';

        when(() => mockFlutterSecureStorage.read(key: any(named: 'key')))
            .thenAnswer((_) => Future.value(badlyFormattedJson));

        final secureCredentialsStorage = SecureCredentialsStorage(mockFlutterSecureStorage);

        final actualCredential = await secureCredentialsStorage.read();
        const Credentials? expectedCredential = null;

        expect(
          actualCredential,
          expectedCredential,
        );
      });
    });

    group('.save', () {
      test("calls FlutterSecureStorage 's write method", () async {
        final FlutterSecureStorage mockFlutterSecureStorage = MockFlutterSecureStorage();

        when(
          () => mockFlutterSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer(Future<void>.value);

        final secureCredentialsStorage = SecureCredentialsStorage(mockFlutterSecureStorage);

        final mockCredentials = Credentials.fromJson(mockCredentialJson);

        await secureCredentialsStorage.save(mockCredentials);

        verify(
          () => mockFlutterSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).called(1);
      });
    });

    group('.clear', () {
      test("calls FlutterSecureStorage 's delete method", () async {
        final FlutterSecureStorage mockFlutterSecureStorage = MockFlutterSecureStorage();

        when(
          () => mockFlutterSecureStorage.delete(
            key: any(named: 'key'),
          ),
        ).thenAnswer(Future<void>.value);

        final secureCredentialsStorage = SecureCredentialsStorage(mockFlutterSecureStorage);

        await secureCredentialsStorage.clear();
        verify(
          () => mockFlutterSecureStorage.delete(
            key: any(named: 'key'),
          ),
        ).called(1);
      });
    });
  });
}
