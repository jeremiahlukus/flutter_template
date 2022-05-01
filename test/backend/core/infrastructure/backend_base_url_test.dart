// Dart imports:

// Flutter imports:

// Package imports:
import 'package:platform/platform.dart';
import 'package:test/test.dart';

// Project imports:
import 'package:flutter_template/backend/core/infrastructure/backend_base_url.dart';

void main() {
  group('.backendUrl', () {
    group('When in debug mode', () {
      tearDown(() {
        BackendConstants.platform = null;
      });

      test('returns the value of BackendConstants().backendBaseUrl when IOS', () async {
        BackendConstants.isDebugMode = true;
        BackendConstants.platform = FakePlatform(operatingSystem: Platform.iOS);

        final actualAuthorizationUrl = BackendConstants().backendBaseUrl();
        const expectedAuthorizationUrl = '127.0.0.1:3000';

        expect(actualAuthorizationUrl, expectedAuthorizationUrl);
      });
      test('returns the value of BackendConstants().backendBaseUrl when Android', () async {
        BackendConstants.isDebugMode = true;
        BackendConstants.platform = FakePlatform(operatingSystem: Platform.android);

        final actualAuthorizationUrl = BackendConstants().backendBaseUrl();
        const expectedAuthorizationUrl = '10.0.2.2:3000';

        expect(actualAuthorizationUrl, expectedAuthorizationUrl);
      });
    });

    test('returns the value of BackendConstants().backendBaseUrl when in release mode', () async {
      BackendConstants.isDebugMode = false;

      final actualAuthorizationUrl = BackendConstants().backendBaseUrl();
      const expectedAuthorizationUrl = 'someUrl';

      expect(actualAuthorizationUrl, expectedAuthorizationUrl);

      BackendConstants.isDebugMode = false;
    });
  });
}
