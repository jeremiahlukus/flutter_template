import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/app/theme/app_theme.dart';
import 'package:flutter_template/src/app/widgets/app_banners.dart';
import 'package:flutter_template/src/features/notes/notes_providers.dart';
import 'package:flutter_template/src/features/push/push_providers.dart';
import 'package:flutter_template/src/features/settings/settings_providers.dart';
import 'package:flutter_template/src/features/update/presentation/update_gate.dart';
import 'package:flutter_template/src/l10n/l10n.dart';
import 'package:flutter_template/src/l10n/l10n_providers.dart';
import 'package:flutter_template/src/routing/app_router.dart';

/// Root widget.
///
/// Intentionally thin: everything interesting is a provider, so tests pump this
/// inside a `ProviderScope` with overrides and exercise the real app rather than
/// a stand-in.
class TemplateApp extends ConsumerWidget {
  const TemplateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandProvider);

    // Nothing reads these, so watch them here to keep them alive for the app's
    // lifetime: one retries queued writes when the network returns, the other
    // keeps this device's push token registered.
    ref
      ..watch(reconnectSyncProvider)
      ..watch(pushRegistrarProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(brand),
      darkTheme: AppTheme.dark(brand),
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocales.supported,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => EnvironmentBanner(
        // Outside the router on purpose: a required update replaces the whole
        // app, so there is no route to navigate away to.
        child: UpdateGate(
          child: Column(
            children: [
              // Above the router's content so it is visible on every screen.
              const OfflineBanner(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}
