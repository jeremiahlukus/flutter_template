import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/core/config/config_providers.dart';
import 'package:flutter_template/src/core/logging/app_logger.dart';
import 'package:flutter_template/src/core/providers/firebase_providers.dart';
import 'package:flutter_template/src/features/update/app_version.dart';

/// Where the update policy lives.
///
/// A single Firestore document rather than Remote Config: it needs no extra SDK,
/// it is readable by the security rules already in place, and it can be edited
/// from the console during an incident without a release.
abstract final class UpdatePolicyLocation {
  static const collection = 'config';
  static const document = 'app_update';

  static String get path => '$collection/$document';
}

/// The current build's version, parsed.
final currentVersionProvider = Provider<AppVersion?>(
  (ref) => AppVersion.tryParse(ref.watch(packageInfoProvider).value?.version),
);

/// The remote policy.
///
/// Resolves to an empty policy on any failure. Failing *open* is deliberate: a
/// missing document, a permissions slip, or an offline launch must never look
/// like "your app is out of date and unusable".
final updatePolicyProvider = FutureProvider<UpdatePolicy>((ref) async {
  try {
    final snapshot = await ref
        .watch(firestoreProvider)
        .doc(UpdatePolicyLocation.path)
        .get();

    final data = snapshot.data();
    if (data == null) return const UpdatePolicy();
    return UpdatePolicy.fromMap(data);
  } catch (error) {
    AppLogger.instance.w('Could not read the update policy: $error');
    return const UpdatePolicy();
  }
});

/// What this build should do about its version.
final updateRequirementProvider = Provider<UpdateRequirement>((ref) {
  final policy = ref.watch(updatePolicyProvider).value;
  if (policy == null) return UpdateRequirement.none;
  return policy.requirementFor(ref.watch(currentVersionProvider));
});

/// True when the app must not be used until it is updated.
final updateBlocksUseProvider = Provider<bool>(
  (ref) => ref.watch(updateRequirementProvider).blocksUse,
);
