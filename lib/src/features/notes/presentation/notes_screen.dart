import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/app/theme/design_tokens.dart';
import 'package:flutter_template/src/app/widgets/app_states.dart';
import 'package:flutter_template/src/features/auth/auth_providers.dart';
import 'package:flutter_template/src/features/notes/note.dart';
import 'package:flutter_template/src/features/notes/notes_providers.dart';
import 'package:flutter_template/src/features/notes/notes_repository.dart';
import 'package:flutter_template/src/l10n/l10n.dart';
import 'package:flutter_template/src/routing/app_routes.dart';
import 'package:go_router/go_router.dart';

/// Home screen: the user's notes, newest first.
///
/// Every tappable row carries a stable `ValueKey('note_<id>')`. That is not
/// decoration — it is what lets integration drivers (and `flutter-skill`) target
/// a specific row instead of guessing at screen coordinates.
class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notes = ref.watch(notesProvider);
    final pending = ref.watch(pendingSyncCountProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notesTitle),
        actions: [
          if (pending > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xxs),
              child: Chip(
                key: const ValueKey('pending_sync_chip'),
                visualDensity: VisualDensity.compact,
                label: Text(l10n.pendingCount(pending)),
              ),
            ),
          IconButton(
            key: const ValueKey('sync_button'),
            tooltip: l10n.syncNowTooltip,
            icon: const Icon(Icons.sync),
            onPressed: () => _sync(context, ref),
          ),
          IconButton(
            key: const ValueKey('settings_button'),
            tooltip: l10n.settingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.goNamed(AppRoute.settings.name),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xxs),
            child: IconButton(
              key: const ValueKey('profile_button'),
              tooltip: l10n.profileTooltip,
              // An IconButton rather than a bare InkWell around the avatar: the
              // avatar is 32dp, and a 32dp tap target fails the Material 48dp
              // accessibility minimum. IconButton supplies the padding.
              onPressed: () => context.goNamed(AppRoute.profile.name),
              icon: CircleAvatar(
                radius: 16,
                child: Text(
                  user?.initials ?? '?',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('new_note_button'),
        onPressed: () {
          final draft = ref.read(notesControllerProvider.notifier).draft();
          context.goNamed(
            AppRoute.noteEditor.name,
            pathParameters: {'id': draft.id},
            extra: draft,
          );
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.newNote),
      ),
      body: AsyncValueView<List<Note>>(
        value: notes,
        errorTitle: l10n.notesLoadErrorTitle,
        errorKey: const ValueKey('notes_error_state'),
        onRetry: () => ref.invalidate(notesProvider),
        isEmpty: (value) => value.isEmpty,
        onEmpty: () => AppEmptyState(
          key: const ValueKey('notes_empty_state'),
          icon: Icons.note_add_outlined,
          title: l10n.notesEmptyTitle,
          message: l10n.notesEmptyBody,
        ),
        loading: const AppLoadingIndicator(key: ValueKey('notes_loading')),
        data: (value) => _NotesList(notes: value),
      ),
    );
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final report = await ref.read(notesControllerProvider.notifier).sync();
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(syncMessage(l10n, report))),
    );
  }
}

/// User-facing summary of a sync attempt. A null [report] means it never ran.
///
/// A partial failure gets its own message: reporting plain "Synced" while writes
/// are still stuck would tell the user their work is safe when it is not.
String syncMessage(AppLocalizations l10n, SyncReport? report) {
  if (report == null) return l10n.syncFailed;
  if (!report.ok) return l10n.syncPartial(report.failed);
  return l10n.syncSuccess(report.pushed, report.pulled);
}

/// Paged list. Grows its window as the user approaches the bottom.
class _NotesList extends ConsumerStatefulWidget {
  const _NotesList({required this.notes});

  final List<Note> notes;

  @override
  ConsumerState<_NotesList> createState() => _NotesListState();
}

class _NotesListState extends ConsumerState<_NotesList> {
  final _controller = ScrollController();

  /// Whether the last query returned a full page, so more may exist.
  ///
  /// Cached in `build` rather than recomputed in the scroll handler, which runs
  /// outside the widget lifecycle and must not touch providers.
  bool _hasMore = false;

  /// Distance from the bottom at which the next page is requested.
  ///
  /// Ahead of the edge on purpose: asking only once the user has hit the very
  /// bottom guarantees they see a gap while the query runs.
  static const _prefetchExtent = 400.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_maybeLoadMore)
      ..dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - _prefetchExtent) {
      // Guarded here rather than in the controller: the controller holds only
      // the requested size, and the total lives on the derived window.
      if (_hasMore) ref.read(notesWindowProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final untitled = context.l10n.untitledNote;
    final notes = widget.notes;

    // A full page back means there is probably more; a short one is the end.
    // No count query needed. See [PageWindow.hasMoreAfter].
    _hasMore = ref.watch(notesWindowProvider).hasMoreAfter(notes.length);

    // No trailing "loading more" spinner, deliberately. The rows come from
    // SQLite, so a wider window is satisfied within a frame — there is never a
    // page genuinely in flight to show progress for, and a spinner parked at the
    // bottom of a long list implies work that is not happening. A
    // network-backed paged list would want one here.
    return ListView.separated(
      key: const ValueKey('notes_list'),
      controller: _controller,
      padding: AppSpacing.listBottom,
      itemCount: notes.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final note = notes[index];
        return ListTile(
          key: ValueKey('note_${note.id}'),
          title: Text(note.titleOr(untitled)),
          subtitle: note.preview.isEmpty ? null : Text(note.preview),
          trailing: note.pendingSync
              ? const Icon(Icons.cloud_upload_outlined, size: 18)
              : null,
          onTap: () => context.goNamed(
            AppRoute.noteEditor.name,
            pathParameters: {'id': note.id},
            extra: note,
          ),
        );
      },
    );
  }
}
