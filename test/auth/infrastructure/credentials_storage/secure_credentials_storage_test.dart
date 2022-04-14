import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_template/auth/infrastructure/credentials_storage/secure_credentials_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oauth2/oauth2.dart';
import 'package:test/test.dart';

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
      test(
          'returns null if FlutterSecureStorage reurns null when its key is read',
          () async {
        final FlutterSecureStorage mockFlutterSecureStorage =
            MockFlutterSecureStorage();

        when(() => mockFlutterSecureStorage.read(key: any(named: 'key')))
            .thenAnswer((_) => Future.value());

        final secureCredentialsStorage =
            SecureCredentialsStorage(mockFlutterSecureStorage);

        final actualCredentialJson = await secureCredentialsStorage.read();
        const Credentials? expectedCredentialJson = null;

        expect(actualCredentialJson, expectedCredentialJson);
      });

      test(
          'returns the exact Credentials return by FlutterSecureStorage when its key is read',
          () async {
        final FlutterSecureStorage mockFlutterSecureStorage =
            MockFlutterSecureStorage();

        when(() => mockFlutterSecureStorage.read(key: any(named: 'key')))
            .thenAnswer((_) => Future.value(mockCredentialJson));

        final secureCredentialsStorage =
            SecureCredentialsStorage(mockFlutterSecureStorage);

        final actualCredentialJson = await secureCredentialsStorage.read();
        final expectedCredentialJson = Credentials.fromJson(mockCredentialJson);

        expect(
          actualCredentialJson?.toJson(),
          expectedCredentialJson.toJson(),
        );
      });
    });

    group('.save', () {
      test("calls FlutterSecureStorage 's write method", () async {
        final FlutterSecureStorage mockFlutterSecureStorage =
            MockFlutterSecureStorage();

        when(
          () => mockFlutterSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer(Future<void>.value);

        final secureCredentialsStorage =
            SecureCredentialsStorage(mockFlutterSecureStorage);

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
        final FlutterSecureStorage mockFlutterSecureStorage =
            MockFlutterSecureStorage();

        when(
          () => mockFlutterSecureStorage.delete(
            key: any(named: 'key'),
          ),
        ).thenAnswer(Future<void>.value);

        final secureCredentialsStorage =
            SecureCredentialsStorage(mockFlutterSecureStorage);

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