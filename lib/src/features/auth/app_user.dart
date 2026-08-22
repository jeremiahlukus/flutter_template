import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// The app's own notion of a signed-in user.
///
/// Screens and providers depend on this instead of Firebase's [User] so that
/// swapping the auth backend (or testing) does not ripple through the UI.
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.isEmailVerified,
    required this.isAnonymous,
  });

  /// Adapts a Firebase [User]. Kept as the single conversion point.
  factory AppUser.fromFirebase(User user) => AppUser(
    id: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoURL,
    isEmailVerified: user.emailVerified,
    isAnonymous: user.isAnonymous,
  );

  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;
  final bool isAnonymous;

  /// Best available human label, falling back through name → email → 'Guest'.
  String get label {
    final name = displayName;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final mail = email;
    if (mail != null && mail.trim().isNotEmpty) return mail.trim();
    return 'Guest';
  }

  /// Uppercase initials for avatar placeholders, at most two characters.
  String get initials {
    final parts = label
        .split(RegExp(r'[\s@._-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
  }) => AppUser(
    id: id,
    email: email,
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    isAnonymous: isAnonymous,
  );

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.email == email &&
      other.displayName == displayName &&
      other.photoUrl == photoUrl &&
      other.isEmailVerified == isEmailVerified &&
      other.isAnonymous == isAnonymous;

  @override
  int get hashCode => Object.hash(
    id,
    email,
    displayName,
    photoUrl,
    isEmailVerified,
    isAnonymous,
  );

  @override
  String toString() => 'AppUser($id, $email)';
}
