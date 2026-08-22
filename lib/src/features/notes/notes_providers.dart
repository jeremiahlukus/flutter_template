import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/core/analytics/analytics_service.dart';
import 'package:flutter_template/src/core/config/config_providers.dart';
import 'package:flutter_template/src/core/connectivity/connectivity_service.dart';
import 'package:flutter_template/src/core/logging/app_logger.dart';
import 'package:flutter_template/src/core/paging/page_window.dart';
import 'package:flutter_template/src/core/providers/firebase_providers.dart';
import 'package:flutter_template/src/database/app_database.dart';
import 'package:flutter_template/src/features/auth/auth_providers.dart';
import 'package:flutter_template/src/features/notes/note.dart';
import 'package:flutter_template/src/features/notes/notes_repository.dart';

/// Null while signed out — notes are per-user and there is no sensible
/// anonymous collection to point at.
final notesRepositoryProvider = Provider<NotesRepository?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return NotesRepository(
    firestore: ref.watch(firestoreProvider),
    database: ref.watch(appDatabaseProvider),
    analytics: ref.watch(analyticsServiceProvider),
    userId: user.id,
  );
});

/// How many rows the list has asked for. Grown by the scroll handler.
final notesWindowProvider = NotifierProvider<PageWindowController, PageWindow>(
  PageWindowController.new,
);

final notesProvider = StreamProvider<List<Note>>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  if (repo == null) return Stream.value(const <Note>[]);
  return repo.watchNotes(limit: ref.watch(notesWindowProvider).size);
});

/// A single note by id, sourced from the already-loaded list so opening the
/// editor never triggers another read.
final noteProvider = Provider.family<Note?, String>((ref, id) {
  final notes = ref.watch(notesProvider).value ?? const <Note>[];
  for (final note in notes) {
    if (note.id == id) return note;
  }
  return null;
});

final pendingSyncCountProvider = Provider<int>((ref) {
  final notes = ref.watch(notesProvider).value ?? const <Note>[];
  return notes.where((n) => n.pendingSync).length;
});

class NotesController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  NotesRepository get _repo {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) {
      throw const NotesFailure('signed-out', 'You must be signed in.');
    }
    return repo;
  }

  Note draft() => _repo.draft();

  Future<bool> save(Note note) => _guard(() => _repo.save(note));

  Future<bool> delete(String id) => _guard(() => _repo.delete(id));

  Future<SyncReport?> sync() async {
    state = const AsyncValue<void>.loading();
    try {
      final report = await _repo.sync();
      state = const AsyncValue<void>.data(null);
      return report;
    } on NotesFailure catch (error, stackTrace) {
      state = AsyncValue<void>.error(error, stackTrace);
      return null;
    }
  }

  Future<bool> _guard(Future<void> Function() action) async {
    state = const AsyncValue<void>.loading();
    try {
      await action();
      state = const AsyncValue<void>.data(null);
      return true;
    } on NotesFailure catch (error, stackTrace) {
      state = AsyncValue<void>.error(error, stackTrace);
      return false;
    }
  }
}

final notesControllerProvider = AsyncNotifierProvider<NotesController, void>(
  NotesController.new,
);

/// Retries queued writes whenever the device comes back online.
///
/// Closes the loop that [NotesRepository.save] opens: a failed remote write is
/// left queued, and something has to notice the network returning. That
/// something is here rather than in a screen, so it keeps working while the user
/// is on any tab — and it only fires on an offline→online *transition*, never on
/// the initial status emission, which would sync on every cold start.
class ReconnectSyncCoordinator {
  ReconnectSyncCoordinator(this._ref) {
    _subscription = _ref.listen<AsyncValue<NetworkStatus>>(
      networkStatusProvider,
      _onStatusChanged,
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<NetworkStatus>> _subscription;

  NetworkStatus? _previous;
  var _syncing = false;

  /// Number of syncs this coordinator has triggered. For assertions.
  @visibleForTesting
  int triggeredSyncs = 0;

  Future<void> _onStatusChanged(
    AsyncValue<NetworkStatus>? _,
    AsyncValue<NetworkStatus> next,
  ) async {
    final status = next.value;
    if (status == null) return;

    final wasOffline = _previous == NetworkStatus.offline;
    _previous = status;

    if (!status.isOnline || !wasOffline) return;
    if (!_ref.read(appConfigProvider).syncOnReconnect) return;
    // A slow sync must not be started twice by a flapping connection.
    if (_syncing) return;

    final repo = _ref.read(notesRepositoryProvider);
    if (repo == null) return;

    _syncing = true;
    triggeredSyncs++;
    try {
      final report = await repo.sync();
      AppLogger.instance.i('Reconnect sync: $report');
    } finally {
      _syncing = false;
    }
  }

  void dispose() => _subscription.close();
}

/// Kept alive for the app's lifetime by `TemplateApp`.
final reconnectSyncProvider = Provider<ReconnectSyncCoordinator>((ref) {
  final coordinator = ReconnectSyncCoordinator(ref);
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
