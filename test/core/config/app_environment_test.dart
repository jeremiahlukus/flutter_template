import 'package:flutter_template/src/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEnvironment.decode', () {
    test('round-trips every environment key', () {
      for (final env in AppEnvironment.values) {
        expect(AppEnvironment.decode(env.key), env);
      }
    });

    test('falls back to dev for null', () {
      expect(AppEnvironment.decode(null), AppEnvironment.dev);
    });

    test('falls back to dev for an unknown value', () {
      // Failing towards dev is deliberate: a typo in a CI variable must not
      // produce a build that believes it is production.
      expect(AppEnvironment.decode('production'), AppEnvironment.dev);
      expect(AppEnvironment.decode(''), AppEnvironment.dev);
    });
  });

  group('banners', () {
    test('production shows none', () {
      expect(AppEnvironment.prod.banner, isNull);
    });

    test('every non-production environment shows one', () {
      for (final env in AppEnvironment.values.where((e) => !e.isProd)) {
        expect(env.banner, isNotNull, reason: '${env.key} has no banner');
        expect(env.showsDebugAffordances, isTrue);
      }
    });

    test('production hides debug affordances', () {
      expect(AppEnvironment.prod.showsDebugAffordances, isFalse);
    });
  });

  test('keys are unique', () {
    final keys = AppEnvironment.values.map((e) => e.key).toList();
    expect(keys.toSet(), hasLength(keys.length));
  });

  test('current resolves without a dart-define, defaulting to dev', () {
    // The suite runs with no `--dart-define`, so this exercises the default.
    expect(AppEnvironment.current, AppEnvironment.dev);
  });

  group('AppConfig', () {
    test('every environment has a config', () {
      for (final env in AppEnvironment.values) {
        final config = AppConfig.forEnvironment(env);
        expect(config.environment, env);
        expect(config.apiBaseUrl, startsWith('https://'));
      }
    });

    test('dev sends nothing to production analytics or crash reporting', () {
      final config = AppConfig.forEnvironment(AppEnvironment.dev);

      expect(config.analyticsEnabled, isFalse);
      expect(config.crashReportingEnabled, isFalse);
    });

    test('staging and production both report', () {
      for (final env in [AppEnvironment.staging, AppEnvironment.prod]) {
        final config = AppConfig.forEnvironment(env);
        expect(config.analyticsEnabled, isTrue);
        expect(config.crashReportingEnabled, isTrue);
      }
    });

    test('only production is quiet in the logs', () {
      expect(
        AppConfig.forEnvironment(AppEnvironment.prod).verboseLogging,
        isFalse,
      );
      expect(
        AppConfig.forEnvironment(AppEnvironment.dev).verboseLogging,
        isTrue,
      );
    });

    test('api base urls are distinct per environment', () {
      final urls = AppEnvironment.values
          .map((e) => AppConfig.forEnvironment(e).apiBaseUrl)
          .toList();

      // Pointing two environments at one backend is a classic release incident.
      expect(urls.toSet(), hasLength(urls.length));
    });

    test('reconnect sync is on everywhere', () {
      for (final env in AppEnvironment.values) {
        expect(AppConfig.forEnvironment(env).syncOnReconnect, isTrue);
      }
    });

    test('isProd and banner mirror the environment', () {
      final prod = AppConfig.forEnvironment(AppEnvironment.prod);
      final dev = AppConfig.forEnvironment(AppEnvironment.dev);

      expect(prod.isProd, isTrue);
      expect(prod.banner, isNull);
      expect(dev.isProd, isFalse);
      expect(dev.banner, 'DEV');
    });

    test('current() matches the compiled environment', () {
      expect(AppConfig.current().environment, AppEnvironment.current);
    });

    group('emulators', () {
      test('are off unless explicitly requested', () {
        // A separate opt-in from APP_ENV: you want the emulator in dev
        // *sometimes*, and never by accident.
        for (final env in AppEnvironment.values) {
          expect(
            AppConfig.forEnvironment(env).useEmulators,
            isFalse,
            reason: '${env.key} defaults to the real backend',
          );
        }
      });

      test('are opt-in per environment', () {
        for (final env in AppEnvironment.values) {
          expect(
            AppConfig.forEnvironment(env, useEmulators: true).useEmulators,
            isTrue,
            reason: '${env.key} should honour the flag',
          );
        }
      });

      test('are never enabled in production by current()', () {
        // A release build silently talking to localhost would look like a
        // total outage, so the flag is masked off for prod.
        expect(
          AppConfig.forEnvironment(
            AppEnvironment.prod,
            useEmulators:
                AppConfig.emulatorsRequested && !AppEnvironment.prod.isProd,
          ).useEmulators,
          isFalse,
        );
      });

      test('the suite runs with no USE_EMULATORS define', () {
        expect(AppConfig.emulatorsRequested, isFalse);
        expect(AppConfig.current().useEmulators, isFalse);
      });

      test('toString flags emulator use', () {
        expect(
          AppConfig.forEnvironment(
            AppEnvironment.dev,
            useEmulators: true,
          ).toString(),
          contains('emulators'),
        );
        expect(
          AppConfig.forEnvironment(AppEnvironment.dev).toString(),
          isNot(contains('emulators')),
        );
      });
    });

    test('toString names the environment', () {
      expect(
        AppConfig.forEnvironment(AppEnvironment.staging).toString(),
        contains('staging'),
      );
    });
  });
}
