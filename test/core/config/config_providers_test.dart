import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/core/config/app_environment.dart';
import 'package:flutter_template/src/core/config/config_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('appConfigProvider', () {
    test('defaults to the compiled environment', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(appConfigProvider).environment,
        AppEnvironment.current,
      );
    });

    test('is overridable, so tests need no rebuild', () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.forEnvironment(AppEnvironment.staging),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(appConfigProvider).environment,
        AppEnvironment.staging,
      );
    });
  });

  group('appVersionProvider', () {
    test('formats version and build number', () async {
      final harness = TestHarness.create();
      await harness.container.read(packageInfoProvider.future);

      expect(harness.read(appVersionProvider), '1.2.3 (45)');
    });

    test('shows a placeholder while the platform lookup is in flight', () {
      final harness = TestHarness.create();

      // A dash, not a crash and not an empty string that collapses the row.
      expect(harness.read(appVersionProvider), '—');
    });

    test('reflects an overridden package info', () async {
      final harness = TestHarness.create(
        // Passed to the harness rather than via `extraOverrides`: overriding the
        // same provider twice in one container is an error.
        packageInfo: testPackageInfo(version: '9.9.9', buildNumber: '1'),
      );
      await harness.container.read(packageInfoProvider.future);

      expect(harness.read(appVersionProvider), '9.9.9 (1)');
    });
  });
}
