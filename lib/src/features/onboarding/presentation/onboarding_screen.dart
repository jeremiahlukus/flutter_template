import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/app/theme/design_tokens.dart';
import 'package:flutter_template/src/features/onboarding/onboarding_providers.dart';
import 'package:flutter_template/src/l10n/l10n.dart';
import 'package:flutter_template/src/routing/app_routes.dart';
import 'package:go_router/go_router.dart';

/// Three-page intro, shown once per device before sign-in.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Page> _pages(AppLocalizations l10n) => [
    _Page(Icons.devices_outlined, l10n.onboardingTitle1, l10n.onboardingBody1),
    _Page(
      Icons.cloud_off_outlined,
      l10n.onboardingTitle2,
      l10n.onboardingBody2,
    ),
    _Page(Icons.lock_outline, l10n.onboardingTitle3, l10n.onboardingBody3),
  ];

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider.notifier).complete();
    // The guard reacts to the flag, but navigating explicitly avoids depending
    // on a redirect for what is a direct user action.
    if (mounted) context.goNamed(AppRoute.notes.name);
  }

  void _next(int lastIndex) {
    if (_page >= lastIndex) {
      _finish();
    } else {
      _controller.nextPage(
        duration: AppDurations.moderate,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = _pages(l10n);
    final isLast = _page == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: TextButton(
                  key: const ValueKey('onboarding_skip'),
                  onPressed: _finish,
                  child: Text(l10n.onboardingSkip),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                key: const ValueKey('onboarding_pages'),
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) => pages[index],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: AppDurations.quick,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxs,
                    ),
                    height: 8,
                    width: i == _page ? 24 : 8,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.pill,
                      color: i == _page
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: FilledButton(
                key: const ValueKey('onboarding_next'),
                onPressed: () => _next(pages.length - 1),
                child: Text(
                  isLast ? l10n.onboardingDone : l10n.onboardingNext,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Scrollable, not a bare Column: at a 2x text scale the headline and body
    // together exceed a phone's height, and an intro screen that clips its own
    // explanation is worse than one the user has to scroll.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 88, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
