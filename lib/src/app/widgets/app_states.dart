import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/app/theme/design_tokens.dart';

/// Centred illustration + headline + body, with an optional action.
///
/// Every screen needs an empty state and they should all look the same; this is
/// the one place that layout is decided.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                message!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Failure state with the error text and, when given, a retry affordance.
///
/// Shows the real error rather than a bland apology: in a template, a developer
/// reading their own screen needs to know what broke. Swap [error] for a mapped
/// message before shipping to users if that leaks too much.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.title,
    this.error,
    this.onRetry,
    this.retryLabel,
    super.key,
  });

  final String title;
  final Object? error;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.error_outline,
      title: title,
      message: error?.toString(),
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              key: const ValueKey('error_retry_button'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel ?? 'Retry'),
            ),
    );
  }
}

/// The app's single loading affordance.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({this.label, super.key});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(label!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Renders an [AsyncValue] as data, loading, or error without the four-branch
/// `switch` that would otherwise appear in every screen.
///
/// [onEmpty] exists because "loaded, but there is nothing" is a distinct state
/// from "loading", and conflating them is the most common way an empty screen
/// ends up showing a spinner forever.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.data,
    this.errorTitle,
    this.errorKey,
    this.onRetry,
    this.isEmpty,
    this.onEmpty,
    this.loading,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T value) data;
  final String? errorTitle;

  /// Applied to the error state, so integration drivers can target it. Every
  /// state this widget can render needs a stable key for that reason.
  final Key? errorKey;
  final VoidCallback? onRetry;
  final bool Function(T value)? isEmpty;
  final Widget Function()? onEmpty;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncError<T>(:final error) => AppErrorState(
        key: errorKey,
        title: errorTitle ?? 'Something went wrong',
        error: error,
        onRetry: onRetry,
      ),
      AsyncValue<T>(:final value?) =>
        (isEmpty?.call(value) ?? false) && onEmpty != null
            ? onEmpty!()
            : data(value),
      // Loading, and the impossible data-less success case, share a spinner.
      _ => loading ?? const AppLoadingIndicator(key: ValueKey('async_loading')),
    };
  }
}
