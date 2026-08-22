import 'package:flutter/foundation.dart';

/// A semantic version, comparable.
///
/// Hand-rolled rather than pulling in `pub_semver`: the app only ever compares
/// `major.minor.patch` from a store listing, and a dependency for three integers
/// is not worth the resolution risk.
@immutable
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch);

  /// Parses `1.2.3`, tolerating a build suffix (`1.2.3+45`) and a `v` prefix.
  ///
  /// Returns null rather than throwing: this value usually comes from a remote
  /// config a human typed, and one bad string should not crash the app on
  /// launch — it should mean "no update information".
  static AppVersion? tryParse(String? raw) {
    if (raw == null) return null;

    final cleaned = raw.trim().replaceFirst(RegExp('^v'), '').split('+').first;
    final parts = cleaned.split('.');
    if (parts.isEmpty || parts.length > 3) return null;

    final numbers = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part.trim());
      if (value == null || value < 0) return null;
      numbers.add(value);
    }

    return AppVersion(
      numbers[0],
      numbers.length > 1 ? numbers[1] : 0,
      numbers.length > 2 ? numbers[2] : 0,
    );
  }

  final int major;
  final int minor;
  final int patch;

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator <(AppVersion other) => compareTo(other) < 0;

  bool operator >=(AppVersion other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}

/// What the app should do about its version.
enum UpdateRequirement {
  /// Nothing to do.
  none,

  /// A newer version exists; mention it, but let the user carry on.
  optional,

  /// This version is below the supported floor and must not be used.
  required;

  bool get blocksUse => this == UpdateRequirement.required;
}

/// The remote answer to "is this build still OK?".
@immutable
class UpdatePolicy {
  const UpdatePolicy({this.minimumSupported, this.latest, this.storeUrl});

  /// Reads the policy document. Missing or unparseable fields become null,
  /// which resolves to [UpdateRequirement.none] — failing *open* on purpose,
  /// because a typo in a config document must not lock every user out.
  factory UpdatePolicy.fromMap(Map<String, dynamic> data) => UpdatePolicy(
    minimumSupported: _version(data['minimumSupported']),
    latest: _version(data['latest']),
    storeUrl: data['storeUrl'] is String ? data['storeUrl'] as String? : null,
  );

  /// `is` check rather than a cast: a config document with a number where a
  /// version string belongs is data to ignore, not an exception to propagate on
  /// app launch.
  static AppVersion? _version(Object? raw) =>
      raw is String ? AppVersion.tryParse(raw) : null;

  /// Builds below this must not be used.
  final AppVersion? minimumSupported;

  /// The newest available version.
  final AppVersion? latest;

  /// Where to send the user. Null hides the action button.
  final String? storeUrl;

  /// What [current] should do about this policy.
  UpdateRequirement requirementFor(AppVersion? current) {
    if (current == null) return UpdateRequirement.none;

    final floor = minimumSupported;
    if (floor != null && current < floor) return UpdateRequirement.required;

    final newest = latest;
    if (newest != null && current < newest) return UpdateRequirement.optional;

    return UpdateRequirement.none;
  }

  @override
  String toString() => 'UpdatePolicy(min: $minimumSupported, latest: $latest)';
}
