import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/app/theme/design_tokens.dart';
import 'package:flutter_template/src/app/widgets/app_states.dart';
import 'package:flutter_template/src/features/update/app_version.dart';
import 'package:flutter_template/src/features/update/update_providers.dart';
import 'package:flutter_template/src/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

/// Wraps the app and replaces it entirely when the build is unsupported.
///
/// A gate rather than a dismissible banner: a *required* update means this
/// client can no longer talk to the backend correctly, so letting the user
/// continue produces confusing failures rather than an honest explanation.
///
/// An optional update is not gated at all — nagging is not the same as
/// informing, and Settings is the right place for "a newer version exists".
class UpdateGate extends ConsumerWidget {
  const UpdateGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(updateBlocksUseProvider)) return child;
    return const UpdateRequiredScreen();
  }
}

class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final storeUrl = ref.watch(updatePolicyProvider).value?.storeUrl;

    return Scaffold(
      body: AppEmptyState(
        key: const ValueKey('update_required'),
        icon: Icons.system_update,
        title: l10n.updateRequiredTitle,
        message: l10n.updateRequiredBody,
        // No action when there is no URL — a button that does nothing is worse
        // than no button.
        action: storeUrl == null
            ? null
            : FilledButton.icon(
                key: const ValueKey('update_action'),
                onPressed: () => launchUrl(
                  Uri.parse(storeUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.updateAction),
              ),
      ),
    );
  }
}

/// A quiet row for Settings when a newer version exists.
class OptionalUpdateTile extends ConsumerWidget {
  const OptionalUpdateTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(updateRequirementProvider) != UpdateRequirement.optional) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final policy = ref.watch(updatePolicyProvider).value;
    final storeUrl = policy?.storeUrl;

    return ListTile(
      key: const ValueKey('optional_update_tile'),
      leading: const Icon(Icons.system_update),
      title: Text(l10n.updateOptionalTitle),
      subtitle: Text(
        policy?.latest == null
            ? l10n.updateOptionalBody
            : '${l10n.updateOptionalBody} (${policy!.latest})',
      ),
      trailing: storeUrl == null
          ? null
          : const Icon(Icons.open_in_new, size: 18),
      onTap: storeUrl == null
          ? null
          : () => launchUrl(
              Uri.parse(storeUrl),
              mode: LaunchMode.externalApplication,
            ),
    );
  }
}

/// Padding constant kept so the gate participates in the design system.
const updateGatePadding = AppSpacing.lg;
