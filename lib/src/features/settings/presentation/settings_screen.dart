import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/app/theme/app_brand.dart';
import 'package:flutter_template/src/app/theme/design_tokens.dart';
import 'package:flutter_template/src/core/config/config_providers.dart';
import 'package:flutter_template/src/features/notes/notes_providers.dart';
import 'package:flutter_template/src/features/notes/presentation/notes_screen.dart';
import 'package:flutter_template/src/features/push/push_providers.dart';
import 'package:flutter_template/src/features/push/push_service.dart';
import 'package:flutter_template/src/features/settings/settings_providers.dart';
import 'package:flutter_template/src/features/update/presentation/update_gate.dart';
import 'package:flutter_template/src/l10n/l10n.dart';
import 'package:flutter_template/src/l10n/l10n_providers.dart';
import 'package:flutter_template/src/routing/app_routes.dart';
import 'package:go_router/go_router.dart';

/// App preferences, all persisted to the local Drift database.
///
/// Doubles as a live preview of the design system: changing the accent colour
/// re-derives the entire Material 3 scheme in place.
///
/// Chrome is separate from content on purpose. A fork with a tab bar wants these
/// settings on a top-level destination, where a back arrow would invite the user
/// to look for a screen that is not there — so pass `showBackButton: false`, or
/// skip this widget entirely and drop [SettingsSections] into your own
/// `Scaffold`. Every section below is public for the same reason: adding your own
/// should not mean editing this file, because an edited file is what makes the
/// next template pull a conflict.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({this.showBackButton = true, super.key});

  /// Whether to show a back arrow. False for a top-level tab destination.
  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        leading: showBackButton
            ? IconButton(
                key: const ValueKey('settings_back'),
                // Tooltips double as semantics labels; an icon-only button
                // without one is silence to a screen reader.
                tooltip: l10n.back,
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.goNamed(AppRoute.notes.name),
              )
            : null,
      ),
      body: const SettingsSections(),
    );
  }
}

/// The settings content, without any chrome.
///
/// Use this directly to interleave your own sections:
///
/// ```dart
/// ListView(children: const [
///   MyAccountSection(),
///   ThemeModeSection(),
///   AnalyticsSection(),
/// ])
/// ```
class SettingsSections extends ConsumerWidget {
  const SettingsSections({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(appConfigProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.maxContentWidth,
        ),
        child: ListView(
          children: [
            SettingsSectionHeader(l10n.sectionAppearance),
            const ThemeModeSection(),
            const BrandSection(),
            const Divider(),
            SettingsSectionHeader(l10n.sectionLanguage),
            const LanguageSection(),
            const Divider(),
            SettingsSectionHeader(l10n.sectionNotifications),
            const PushSection(),
            const Divider(),
            SettingsSectionHeader(l10n.sectionPrivacy),
            const AnalyticsSection(),
            const Divider(),
            SettingsSectionHeader(l10n.sectionSync),
            const SyncSection(),
            const Divider(),
            SettingsSectionHeader(l10n.sectionAbout),
            const OptionalUpdateTile(),
            ListTile(
              key: const ValueKey('app_version_tile'),
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.appVersion),
              trailing: Text(ref.watch(appVersionProvider)),
            ),
            // Only meaningful off production, and a production user seeing
            // "prod" would just be noise.
            if (!config.isProd)
              ListTile(
                key: const ValueKey('environment_tile'),
                leading: const Icon(Icons.dns_outlined),
                title: Text(l10n.environmentLabel),
                trailing: Text(config.environment.key),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class ThemeModeSection extends ConsumerWidget {
  const ThemeModeSection({super.key});

  static String label(AppLocalizations l10n, ThemeMode mode) => switch (mode) {
    ThemeMode.system => l10n.themeSystem,
    ThemeMode.light => l10n.themeLight,
    ThemeMode.dark => l10n.themeDark,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    // RadioGroup (Flutter 3.32+) owns the selection; the tiles are plain radios
    // that inherit it.
    return RadioGroup<ThemeMode>(
      groupValue: ref.watch(themeModeProvider),
      onChanged: (value) {
        if (value != null) {
          ref.read(themeModeControllerProvider.notifier).set(value);
        }
      },
      child: Column(
        children: [
          for (final mode in ThemeMode.values)
            RadioListTile<ThemeMode>(
              key: ValueKey('theme_${ThemeModeController.encode(mode)}'),
              value: mode,
              title: Text(label(l10n, mode)),
            ),
        ],
      ),
    );
  }
}

/// Horizontal swatch row. Tapping one re-seeds the whole theme.
class BrandSection extends ConsumerWidget {
  const BrandSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(brandProvider);

    return ListTile(
      key: const ValueKey('brand_picker'),
      title: Text(context.l10n.accentColour),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Wrap(
          runSpacing: AppSpacing.xxs,
          children: [
            for (final brand in AppBrand.values)
              // An IconButton wrapper, not a bare InkWell: the swatch is 32dp
              // and a 32dp tap target fails the Material 48dp minimum. The
              // visual stays 32dp; only the hit area grows.
              IconButton(
                key: ValueKey('brand_${brand.name}'),
                tooltip: brand.label,
                onPressed: () =>
                    ref.read(brandControllerProvider.notifier).set(brand),
                icon: AnimatedContainer(
                  duration: AppDurations.quick,
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: brand.seed,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: brand == selected
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: brand == selected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LanguageSection extends ConsumerWidget {
  const LanguageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(localeProvider);

    return RadioGroup<Locale?>(
      groupValue: selected,
      onChanged: (value) =>
          ref.read(localeControllerProvider.notifier).set(value),
      child: Column(
        children: [
          // Null is a real choice, not an absence: it means "follow the system".
          RadioListTile<Locale?>(
            key: const ValueKey('locale_system'),
            value: null,
            title: Text(l10n.languageSystem),
          ),
          for (final locale in AppLocales.supported)
            RadioListTile<Locale?>(
              key: ValueKey('locale_${locale.languageCode}'),
              value: locale,
              title: Text(AppLocales.nameOf(locale)),
            ),
        ],
      ),
    );
  }
}

/// Opt-in for push, plus the OS permission it depends on.
///
/// Two gates, shown as one row: the in-app preference and the system
/// permission. Requesting permission only when the user turns the switch on is
/// deliberate — prompting unasked is the fastest way to get denied forever.
class PushSection extends ConsumerWidget {
  const PushSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final enabled = ref.watch(pushEnabledProvider);
    final permission = ref.watch(pushPermissionProvider).value;
    final blocked = permission == PushPermission.denied;

    return SwitchListTile(
      key: const ValueKey('push_switch'),
      value: enabled && !blocked,
      title: Text(l10n.pushTitle),
      subtitle: Text(blocked ? l10n.pushBlocked : l10n.pushSubtitle),
      // A hard denial is final until the user changes it in system settings, so
      // leaving the switch live would let them toggle something with no effect.
      onChanged: blocked
          ? null
          : (value) async {
              if (value) {
                final granted = await ref
                    .read(pushServiceProvider)
                    .requestPermission();
                ref.invalidate(pushPermissionProvider);
                if (!granted.canDeliver) return;
              }
              await ref.read(pushEnabledControllerProvider.notifier).set(value);
            },
    );
  }
}

class AnalyticsSection extends ConsumerWidget {
  const AnalyticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final analytics = ref.watch(analyticsEnabledControllerProvider);

    return SwitchListTile(
      key: const ValueKey('analytics_switch'),
      value: analytics.value ?? true,
      title: Text(l10n.analyticsTitle),
      subtitle: Text(l10n.analyticsSubtitle),
      onChanged: analytics.isLoading
          ? null
          : (value) => ref
                .read(analyticsEnabledControllerProvider.notifier)
                .set(value),
    );
  }
}

class SyncSection extends ConsumerWidget {
  const SyncSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      children: [
        ListTile(
          key: const ValueKey('pending_sync_tile'),
          leading: const Icon(Icons.cloud_sync_outlined),
          title: Text(l10n.waitingToUpload),
          trailing: Text('${ref.watch(pendingSyncCountProvider)}'),
        ),
        ListTile(
          key: const ValueKey('sync_now_tile'),
          leading: const Icon(Icons.sync),
          title: Text(l10n.syncNowTooltip),
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            final report = await ref
                .read(notesControllerProvider.notifier)
                .sync();
            messenger.showSnackBar(
              SnackBar(content: Text(syncMessage(l10n, report))),
            );
          },
        ),
      ],
    );
  }
}

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
