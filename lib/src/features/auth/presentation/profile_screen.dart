import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/app/theme/design_tokens.dart';
import 'package:flutter_template/src/core/errors/failure_messages.dart';
import 'package:flutter_template/src/features/auth/auth_providers.dart';
import 'package:flutter_template/src/features/auth/auth_repository.dart';
import 'package:flutter_template/src/features/notes/notes_providers.dart';
import 'package:flutter_template/src/features/storage/image_source_service.dart';
import 'package:flutter_template/src/features/storage/storage_repository.dart';
import 'package:flutter_template/src/l10n/l10n.dart';
import 'package:flutter_template/src/routing/app_routes.dart';
import 'package:go_router/go_router.dart';

/// The signed-in user's profile: rename, avatar upload, sign out, delete.
///
/// Doubles as the worked example of combining auth + Cloud Storage: the avatar
/// bytes go to Storage, and the resulting URL goes back onto the Firebase user
/// record so every other screen can read it from [currentUserProvider].
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  bool _seeded = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  /// Localised copy for whatever the auth controller last failed with.
  ///
  /// Falls back to [ifUnknown] (or generic copy) when the controller is not in
  /// an error state — which should not happen, but vague copy beats none.
  String _authError(AppLocalizations l10n, [String? ifUnknown]) {
    final error = ref.read(authControllerProvider).error;
    if (error is AuthFailure) return localisedAuthMessage(l10n, error);
    return ifUnknown ?? l10n.authGeneric;
  }

  Future<void> _rename() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _snack(context.l10n.enterNameFirst);
      return;
    }
    setState(() => _busy = true);
    final ok = await ref
        .read(authControllerProvider.notifier)
        .updateDisplayName(name);
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(
      ok
          ? context.l10n.nameUpdated
          : _authError(context.l10n, context.l10n.nameUpdateFailed),
    );
  }

  /// Lets the user choose a source, then uploads the picked image.
  ///
  /// Cancelling at any point is a no-op, not an error: backing out of a picker
  /// is normal behaviour and should not produce a message.
  Future<void> _changeAvatar() async {
    final l10n = context.l10n;
    final origin = await _chooseImageOrigin(l10n);
    if (origin == null || !mounted) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _busy = true);
    try {
      final bytes = await ref
          .read(imageSourceServiceProvider)
          .pickImage(origin);
      if (bytes == null || !mounted) return;

      final storage = ref.read(storageRepositoryProvider);
      final url = await storage.uploadBytes(
        path: storage.avatarPath(user.id),
        bytes: bytes,
        contentType: 'image/jpeg',
      );
      final ok = await ref
          .read(authControllerProvider.notifier)
          .updatePhotoUrl(url);
      if (!mounted) return;
      _snack(ok ? l10n.avatarUploaded : l10n.avatarUploadedProfileFailed);
    } on StorageFailure catch (e) {
      // The exception's own `message` is an English fallback for logs; the UI
      // maps the code. See core/errors/failure_messages.dart.
      if (mounted) _snack(localisedStorageMessage(l10n, e));
    } on ImagePickFailure {
      if (mounted) _snack(l10n.avatarPickFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<ImageOrigin?> _chooseImageOrigin(AppLocalizations l10n) =>
      showModalBottomSheet<ImageOrigin>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  l10n.avatarChooseSource,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ListTile(
                key: const ValueKey('avatar_from_camera'),
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.avatarFromCamera),
                onTap: () => Navigator.of(context).pop(ImageOrigin.camera),
              ),
              ListTile(
                key: const ValueKey('avatar_from_gallery'),
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.avatarFromGallery),
                onTap: () => Navigator.of(context).pop(ImageOrigin.gallery),
              ),
              ListTile(
                key: const ValueKey('avatar_cancel'),
                leading: const Icon(Icons.close),
                title: Text(l10n.cancel),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );

  Future<void> _signOut() async {
    final l10n = context.l10n;
    final confirmed = await _confirm(
      title: l10n.signOutTitle,
      message: l10n.signOutBody,
      action: l10n.signOut,
    );
    if (confirmed != true) return;

    // Local cache is per-user; leaving it would leak notes to the next sign-in.
    await ref.read(notesRepositoryProvider)?.clearCache();
    await ref.read(authControllerProvider.notifier).signOut();
  }

  Future<void> _deleteAccount() async {
    final l10n = context.l10n;
    final confirmed = await _confirm(
      title: l10n.deleteAccountTitle,
      message: l10n.deleteAccountBody,
      action: l10n.delete,
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    final ok = await ref.read(authControllerProvider.notifier).deleteAccount();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) _snack(_authError(context.l10n, context.l10n.deleteAccountFailed));
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String action,
  }) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          key: const ValueKey('confirm_cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('confirm_action'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        body: Center(
          key: const ValueKey('profile_signed_out'),
          child: Text(context.l10n.signedOut),
        ),
      );
    }

    if (!_seeded) {
      _seeded = true;
      _name.text = user.displayName ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        leading: IconButton(
          key: const ValueKey('profile_back'),
          // Tooltips double as semantics labels; an icon-only button without
          // one is silence to a screen reader.
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed(AppRoute.notes.name),
        ),
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  key: const ValueKey('profile_avatar'),
                  radius: 40,
                  foregroundImage:
                      user.photoUrl != null && user.photoUrl!.startsWith('http')
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: Text(
                    user.initials,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (user.email != null)
                  Text(
                    user.email!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (!user.isEmailVerified && !user.isAnonymous)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Chip(
                      key: const ValueKey('unverified_chip'),
                      avatar: const Icon(Icons.warning_amber_rounded, size: 16),
                      label: Text(l10n.emailNotVerified),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            key: const ValueKey('display_name_field'),
            controller: _name,
            decoration: InputDecoration(labelText: l10n.displayNameLabel),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            key: const ValueKey('save_name_button'),
            onPressed: _busy ? null : _rename,
            child: Text(l10n.saveName),
          ),
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton.icon(
            key: const ValueKey('upload_avatar_button'),
            onPressed: _busy ? null : _changeAvatar,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(l10n.uploadAvatar),
          ),
          const Divider(height: 40),
          ListTile(
            key: const ValueKey('sign_out_tile'),
            leading: const Icon(Icons.logout),
            title: Text(l10n.signOut),
            onTap: _busy ? null : _signOut,
          ),
          ListTile(
            key: const ValueKey('delete_account_tile'),
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.deleteAccount,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: _busy ? null : _deleteAccount,
          ),
        ],
      ),
    );
  }
}
