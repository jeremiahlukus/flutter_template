import 'package:flutter/material.dart';
import 'package:flutter_template/src/app/widgets/app_banners.dart';
import 'package:flutter_template/src/core/config/app_environment.dart';
import 'package:flutter_template/src/core/connectivity/connectivity_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('OfflineBanner', () {
    testWidgets('is hidden while online', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);

      expect(find.byKey(const ValueKey('offline_banner')), findsNothing);
    });

    testWidgets('appears when the device goes offline', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);

      harness.connectivity.goOffline();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('offline_banner')), findsOne);
      expect(find.textContaining('Offline'), findsOne);
    });

    testWidgets('disappears again on reconnect', (tester) async {
      final harness = TestHarness.create(
        user: testUser(),
        network: NetworkStatus.offline,
      );
      await harness.pumpApp(tester);
      expect(find.byKey(const ValueKey('offline_banner')), findsOne);

      harness.connectivity.goOnline();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('offline_banner')), findsNothing);
    });

    testWidgets('the copy reassures rather than alarms', (tester) async {
      final harness = TestHarness.create(
        user: testUser(),
        network: NetworkStatus.offline,
      );
      await harness.pumpApp(tester);

      // Writes still succeed offline, so the banner must not imply failure.
      expect(
        find.text('Offline — changes are saved on this device'),
        findsOne,
      );
    });

    testWidgets('is localised', (tester) async {
      final harness = TestHarness.create(
        user: testUser(),
        network: NetworkStatus.offline,
      );
      await harness.database.writeSetting(SettingKeys.locale, 'es');
      await harness.pumpApp(tester);

      expect(find.textContaining('Sin conexión'), findsOne);
    });

    testWidgets('shows over the sign-in screen too', (tester) async {
      final harness = TestHarness.create(network: NetworkStatus.offline);
      await harness.pumpApp(tester);

      // Attached in the MaterialApp builder, so it is not per-screen wiring.
      expect(find.byKey(const ValueKey('offline_banner')), findsOne);
    });
  });

  group('EnvironmentBanner', () {
    testWidgets('is absent in production', (tester) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpApp(tester);

      expect(find.byKey(const ValueKey('environment_banner')), findsNothing);
    });

    testWidgets('shows DEV in development', (tester) async {
      final harness = TestHarness.create(
        user: testUser(),
        environment: AppEnvironment.dev,
      );
      await harness.pumpApp(tester);

      final banner = tester.widget<Banner>(
        find.byKey(const ValueKey('environment_banner')),
      );
      expect(banner.message, 'DEV');
    });

    testWidgets('shows STAGING in staging', (tester) async {
      final harness = TestHarness.create(
        user: testUser(),
        environment: AppEnvironment.staging,
      );
      await harness.pumpApp(tester);

      final banner = tester.widget<Banner>(
        find.byKey(const ValueKey('environment_banner')),
      );
      expect(banner.message, 'STAGING');
    });

    testWidgets('colours dev and staging differently', (tester) async {
      Color colourFor(WidgetTester t) => t
          .widget<Banner>(find.byKey(const ValueKey('environment_banner')))
          .color;

      final dev = TestHarness.create(
        user: testUser(),
        environment: AppEnvironment.dev,
      );
      await dev.pumpApp(tester);
      final devColour = colourFor(tester);

      final staging = TestHarness.create(
        user: testUser(),
        environment: AppEnvironment.staging,
      );
      await staging.pumpApp(tester);

      // Distinct on purpose: mistaking staging for dev is how a demo ends up
      // pointed at the wrong backend.
      expect(colourFor(tester), isNot(devColour));
    });

    testWidgets('passes the child through untouched in production', (
      tester,
    ) async {
      final harness = TestHarness.create(user: testUser());
      await harness.pumpWidget(
        tester,
        const EnvironmentBanner(child: Text('content')),
      );

      expect(find.text('content'), findsOne);
      expect(find.byType(Banner), findsNothing);
    });
  });
}
