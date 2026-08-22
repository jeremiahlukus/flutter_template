import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/app/theme/app_semantic_colors.dart';
import 'package:flutter_template/src/app/theme/design_tokens.dart';
import 'package:flutter_template/src/core/config/app_environment.dart';
import 'package:flutter_template/src/core/config/config_providers.dart';
import 'package:flutter_template/src/core/connectivity/connectivity_service.dart';
import 'package:flutter_template/src/l10n/l10n.dart';

/// Slides in from the top while the device is offline.
///
/// Deliberately informational, not alarming: writes still succeed offline
/// ([spec 0002]), so the copy tells the user their work is safe rather than
/// implying failure.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final colors = AppSemanticColors.of(context);

    return AnimatedSize(
      duration: AppDurations.quick,
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: isOnline
          ? const SizedBox(width: double.infinity)
          : Material(
              key: const ValueKey('offline_banner'),
              color: colors.warningContainer,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 16,
                        color: colors.onWarningContainer,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          context.l10n.offlineBanner,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onWarningContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// Corner ribbon naming the environment, on every build except production.
///
/// The single cheapest way to stop someone filing a bug — or worse, running a
/// demo — against the wrong backend.
class EnvironmentBanner extends ConsumerWidget {
  const EnvironmentBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = ref.watch(appConfigProvider).banner;
    if (label == null) return child;

    return Banner(
      key: const ValueKey('environment_banner'),
      message: label,
      location: BannerLocation.topEnd,
      color: switch (ref.watch(appConfigProvider).environment) {
        AppEnvironment.dev => Colors.teal,
        AppEnvironment.staging => Colors.deepOrange,
        AppEnvironment.prod => Colors.transparent,
      },
      child: child,
    );
  }
}
