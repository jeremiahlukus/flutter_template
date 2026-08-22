import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/app/theme/design_tokens.dart';
import 'package:flutter_template/src/features/notes/note.dart';
import 'package:flutter_template/src/features/notes/notes_providers.dart';
import 'package:flutter_template/src/features/notes/notes_repository.dart';
import 'package:flutter_template/src/l10n/l10n.dart';
import 'package:flutter_template/src/routing/app_routes.dart';
import 'package:go_router/go_router.dart';

/// Create or edit a single note.
///
/// Resolves the note from the loaded list rather than re-reading it, so opening
/// the editor is instant and works offline. An id with no match is treated as a
/// brand-new note — that is the case when the FAB hands over a fresh draft.
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({required this.noteId, super.key});

  final String noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  bool _saving = false;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _body = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  /// Fills the fields once, the first time the note is available.
  ///
  /// Guarded by [_seeded] so a background sync cannot overwrite what the user is
  /// currently typing.
  void _seed(Note? note) {
    if (_seeded || note == null) return;
    _seeded = true;
    _title.text = note.title;
    _body.text = note.body;
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final existing = ref.read(noteProvider(widget.noteId));
    final base =
        existing ??
        Note(
          id: widget.noteId,
          title: '',
          body: '',
          updatedAt: DateTime.now().toUtc(),
        );

    final updated = base.copyWith(title: _title.text, body: _body.text);
    if (updated.isEmpty) {
      _snack(l10n.nothingToSave);
      return;
    }

    setState(() => _saving = true);
    final ok = await ref.read(notesControllerProvider.notifier).save(updated);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      context.goNamed(AppRoute.notes.name);
    } else {
      _snack(_saveFailureMessage(l10n));
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteNoteTitle),
        content: Text(l10n.deleteNoteBody),
        actions: [
          TextButton(
            key: const ValueKey('delete_cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('delete_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await ref.read(notesControllerProvider.notifier).delete(widget.noteId);
    if (mounted) context.goNamed(AppRoute.notes.name);
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  /// Why the save failed, in the user's language.
  ///
  /// A length violation is the user's to fix, so it must say which limit and
  /// what the number is. Anything else is transient and already queued locally.
  String _saveFailureMessage(AppLocalizations l10n) {
    final error = ref.read(notesControllerProvider).error;
    if (error is NotesFailure && error.code == 'too-long') {
      return _title.text.length > Note.maxTitleLength
          ? l10n.noteTitleTooLong(Note.maxTitleLength)
          : l10n.noteBodyTooLong(Note.maxBodyLength);
    }
    return l10n.saveFailedQueued;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final note = ref.watch(noteProvider(widget.noteId));
    _seed(note);
    final isNew = note == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? l10n.newNote : l10n.editNote),
        leading: IconButton(
          key: const ValueKey('editor_back'),
          // Tooltips double as semantics labels; an icon-only button without
          // one is silence to a screen reader.
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed(AppRoute.notes.name),
        ),
        actions: [
          if (!isNew)
            IconButton(
              key: const ValueKey('delete_note_button'),
              tooltip: l10n.deleteTooltip,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Wide windows get a centred column: a text field spanning a desktop
            // monitor is measurably harder to read.
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                children: [
                  TextField(
                    key: const ValueKey('note_title_field'),
                    controller: _title,
                    // Truncates a paste too, so the error path below is a
                    // backstop rather than the normal way to hit the limit.
                    maxLength: Note.maxTitleLength,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    textInputAction: TextInputAction.next,
                    style: Theme.of(context).textTheme.titleLarge,
                    decoration: InputDecoration(
                      labelText: l10n.noteTitleLabel,
                      hintText: l10n.noteTitleHint,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('note_body_field'),
                      controller: _body,
                      maxLength: Note.maxBodyLength,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      // The counter is noise on a body this long.
                      buildCounter:
                          (
                            _, {
                            required currentLength,
                            required isFocused,
                            required maxLength,
                          }) => null,
                      expands: true,
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        labelText: l10n.noteBodyLabel,
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    key: const ValueKey('save_note_button'),
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_saving ? l10n.savingNote : l10n.saveNote),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
