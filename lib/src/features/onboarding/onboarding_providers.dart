import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/database/app_database.dart';
import 'package:flutter_template/src/features/settings/setting_keys.dart';

/// Whether the intro has been seen, persisted on the device.
///
/// Device-local rather than per-account on purpose: onboarding explains the
/// *app*, so a returning user on a new phone should see it again, and signing
/// into a second account on the same phone should not.
class OnboardingController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final stored = await ref
        .watch(appDatabaseProvider)
        .readSetting(SettingKeys.onboardingCompleted);
    return stored == 'true';
  }

  Future<void> complete() async {
    state = const AsyncValue.data(true);
    await ref
        .read(appDatabaseProvider)
        .writeSetting(SettingKeys.onboardingCompleted, 'true');
  }

  /// Clears the flag. Exposed for tests and for a "replay the intro" affordance.
  Future<void> reset() async {
    state = const AsyncValue.data(false);
    await ref
        .read(appDatabaseProvider)
        .removeSetting(SettingKeys.onboardingCompleted);
  }
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, bool>(
      OnboardingController.new,
    );

/// Synchronous view used by the route guard.
///
/// Defaults to **true** while the read is in flight, so a returning user never
/// sees a flash of onboarding on a cold start. The cost is that a genuinely
/// first-run user waits one frame, which is invisible.
final onboardingCompletedProvider = Provider<bool>(
  (ref) => ref.watch(onboardingControllerProvider).value ?? true,
);
