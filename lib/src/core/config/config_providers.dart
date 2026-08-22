import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/core/config/app_environment.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Overridden in tests to exercise per-environment behaviour without rebuilding.
final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.current());

/// Version and build number, read from the platform bundle.
///
/// Async because the lookup crosses a platform channel. Surfaced in Settings so
/// a bug report can name an exact build.
final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

/// `1.2.3 (45)`, or a placeholder while the lookup is in flight.
final appVersionProvider = Provider<String>((ref) {
  final info = ref.watch(packageInfoProvider).value;
  if (info == null) return '—';
  return '${info.version} (${info.buildNumber})';
});
