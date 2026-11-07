import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_eval/note_sync.dart';

final class CommitFailure implements Exception {}

final class NetworkFailure implements Exception {}

final class MemoryStore implements LocalNoteStore, NoteTransaction {
  final notes = <(String, String), NoteRecord>{};
  final queue = <String, PendingEdit>{};
  bool failNextCommit = false;
  @override
  T transaction<T>(T Function(NoteTransaction) action) {
    final beforeNotes = Map.of(notes);
    final beforeQueue = Map.of(queue);
    try {
      final value = action(this);
      if (failNextCommit) {
        failNextCommit = false;
        throw CommitFailure();
      }
      return value;
    } catch (_) {
      notes
        ..clear()
        ..addAll(beforeNotes);
      queue
        ..clear()
        ..addAll(beforeQueue);
      rethrow;
    }
  }

  @override
  NoteRecord? readNote(String accountId, String noteId) =>
      notes[(accountId, noteId)];
  @override
  void putNote(NoteRecord note) => notes[(note.accountId, note.noteId)] = note;
  @override
  List<PendingEdit> edits(String accountId) => List.unmodifiable(
    queue.values.where((edit) => edit.accountId == accountId),
  );
  @override
  void putEdit(PendingEdit edit) => queue[edit.operationId] = edit;
  @override
  void deleteEdit(String operationId) => queue.remove(operationId);
}

final class ServerValue {
  const ServerValue(this.body, this.version);
  final String body;
  final int version;
}

final class VersionedServer implements NoteServer {
  final values = <(String, String), ServerValue>{};
  final accepted = <(String, String), NoteAccepted>{};
  final calls = <PendingEdit>[];
  int effects = 0;
  bool offline = false;
  bool loseNextAcknowledgement = false;
  Completer<void>? holdNextAccepted;
  @override
  Future<NoteWriteResult> write(PendingEdit edit) async {
    calls.add(edit);
    if (offline) throw NetworkFailure();
    final key = (edit.accountId, edit.operationId);
    final previous = accepted[key];
    if (previous != null) return previous;
    final current =
        values[(edit.accountId, edit.noteId)] ?? const ServerValue('', 0);
    if (edit.baseVersion != current.version) {
      return NoteConflict(current.body, current.version);
    }
    final result = NoteAccepted(current.version + 1);
    accepted[key] = result;
    values[(edit.accountId, edit.noteId)] = ServerValue(
      edit.body,
      result.version,
    );
    effects++;
    if (loseNextAcknowledgement) {
      loseNextAcknowledgement = false;
      throw NetworkFailure();
    }
    final hold = holdNextAccepted;
    holdNextAccepted = null;
    if (hold != null) await hold.future;
    return result;
  }
}

Future<void> drain() => Future<void>(() {});
// Error presentation is not part of sync()'s public contract. Inspect retained state/effects.
Future<Object?> attempt(Future<void> result) async {
  try {
    await result;
    return null;
  } catch (error) {
    return error;
  }
}

void main() {
  late MemoryStore store;
  late VersionedServer server;
  late NoteSyncService service;
  var nextId = 0;
  NoteSyncService create() =>
      NoteSyncService(store, server, () => 'operation-${++nextId}');
  void seed(
    String account, {
    String id = 'note',
    String body = 'original',
    int version = 1,
  }) {
    store.putNote(
      NoteRecord(
        accountId: account,
        noteId: id,
        body: body,
        serverVersion: version,
        status: NoteStatus.synced,
      ),
    );
    server.values[(account, id)] = ServerValue(body, version);
  }

  setUp(() {
    store = MemoryStore();
    server = VersionedServer();
    nextId = 0;
    seed('a');
    service = create()..signIn('a');
  });
  tearDown(() => service.close());

  test('local note and outbox either commit together or remain unchanged', () {
    store.failNextCommit = true;
    expect(
      () => service.edit('note', 'not committed'),
      throwsA(isA<CommitFailure>()),
    );
    expect(service.get('note')?.body, 'original');
    expect(store.edits('a'), isEmpty);
    service.edit('note', 'queued');
    expect(service.get('note')?.status, NoteStatus.pending);
    expect(store.edits('a').single.body, 'queued');
    expect(server.calls, isEmpty);
  });

  test(
    'offline queue survives coordinator reconstruction without changing operation ID',
    () async {
      service.edit('note', 'queued');
      final edit = store.edits('a').single;
      server.offline = true;
      await attempt(service.sync());
      expect(store.edits('a').single.operationId, edit.operationId);
      expect(service.get('note')?.status, NoteStatus.pending);
      service.close();
      service = create()..signIn('a');
      server.offline = false;
      await service.sync();
      expect(server.effects, 1);
      expect(
        server.calls.map((call) => call.operationId),
        everyElement(edit.operationId),
      );
      expect(service.get('note')?.status, NoteStatus.synced);
      expect(store.edits('a'), isEmpty);
      expect(nextId, 1);
    },
  );

  test(
    'lost acknowledgement replays one stable ID and produces one server effect',
    () async {
      service.edit('note', 'queued');
      final id = store.edits('a').single.operationId;
      server.loseNextAcknowledgement = true;
      await attempt(service.sync());
      expect(server.effects, 1);
      expect(store.edits('a').single.operationId, id);
      service.close();
      service = create()..signIn('a');
      await service.sync();
      expect(server.effects, 1);
      expect(server.calls.map((call) => call.operationId), [id, id]);
      expect(store.edits('a'), isEmpty);
      expect(service.get('note')?.body, 'queued');
      expect(service.get('note')?.serverVersion, 2);
    },
  );

  test('conflicts retain user input and stop automatic replay', () async {
    service.edit('note', 'local edit');
    server.values[('a', 'note')] = const ServerValue('new server edit', 2);
    await service.sync();
    expect(service.get('note')?.body, 'local edit');
    expect(service.get('note')?.status, NoteStatus.conflict);
    expect(store.edits('a').single.status, NoteStatus.conflict);
    expect(server.values[('a', 'note')]?.body, 'new server edit');
    final callCount = server.calls.length;
    await service.sync();
    expect(server.calls, hasLength(callCount));
  });

  test('old acknowledgement cannot overwrite a newer local edit', () async {
    service.edit('note', 'first edit');
    final hold = Completer<void>();
    server.holdNextAccepted = hold;
    final syncing = service.sync();
    await drain();
    service.edit('note', 'newer edit');
    hold.complete();
    await syncing;
    expect(service.get('note')?.body, 'newer edit');
    final remaining = store.edits('a');
    if (remaining.isNotEmpty) {
      expect(service.get('note')?.status, isNot(NoteStatus.synced));
      expect(remaining.any((edit) => edit.body == 'newer edit'), isTrue);
    } else {
      expect(server.values[('a', 'note')]?.body, 'newer edit');
    }
  });

  test(
    'logout rejects late acknowledgement and retains account-scoped pending work',
    () async {
      seed('b', body: 'b original');
      service.edit('note', 'a pending');
      final aId = store.edits('a').single.operationId;
      final hold = Completer<void>();
      server.holdNextAccepted = hold;
      final old = service.sync();
      await drain();
      service.signOut();
      expect(service.get('note'), isNull);
      service.signIn('b');
      service.edit('note', 'b pending');
      final newAccountSync = service.sync();
      await drain();
      hold.complete();
      await Future.wait([
        old,
        newAccountSync,
      ]).timeout(const Duration(seconds: 2));
      expect(store.edits('a').single.operationId, aId);
      expect(store.readNote('a', 'note')?.status, NoteStatus.pending);
      expect(server.calls.last.accountId, 'b');
      expect(service.get('note')?.body, 'b pending');
      service.signIn('a');
      await service.sync();
      expect(server.calls.last.operationId, aId);
      expect(server.effects, 2);
    },
  );

  test('overlapping sync calls coalesce on the active coordinator', () async {
    service.edit('note', 'queued');
    final hold = Completer<void>();
    server.holdNextAccepted = hold;
    final first = service.sync();
    final second = service.sync();
    await drain();
    expect(server.calls, hasLength(1));
    hold.complete();
    await Future.wait([first, second]);
    expect(server.effects, 1);
    expect(store.edits('a'), isEmpty);
  });

  test(
    'failed acknowledgement commit retains replayable work atomically',
    () async {
      service.edit('note', 'queued');
      final id = store.edits('a').single.operationId;
      final hold = Completer<void>();
      server.holdNextAccepted = hold;
      final sync = service.sync();
      await drain();
      store.failNextCommit = true;
      hold.complete();
      await attempt(sync);
      expect(store.edits('a').single.operationId, id);
      expect(service.get('note')?.status, NoteStatus.pending);
      await service.sync();
      expect(server.effects, 1);
      expect(store.edits('a'), isEmpty);
    },
  );

  test(
    'completion after close cannot acknowledge retained account work',
    () async {
      service.edit('note', 'pending');
      final id = store.edits('a').single.operationId;
      final hold = Completer<void>();
      server.holdNextAccepted = hold;
      final syncing = service.sync();
      await drain();
      service.close();
      hold.complete();
      await syncing;
      expect(service.get('note'), isNull);
      expect(store.edits('a').single.operationId, id);
      expect(store.readNote('a', 'note')?.status, NoteStatus.pending);
      service = create()..signIn('a');
      await service.sync();
      expect(server.effects, 1);
      expect(store.edits('a'), isEmpty);
    },
  );

  test(
    'a conflicted note does not prevent a different note from synchronizing',
    () async {
      seed('a', id: 'other');
      service.edit('note', 'conflicted');
      service.edit('other', 'valid');
      server.values[('a', 'note')] = const ServerValue('remote edit', 3);
      await service.sync();
      expect(service.get('note')?.status, NoteStatus.conflict);
      expect(service.get('other')?.status, NoteStatus.synced);
      expect(server.values[('a', 'other')]?.body, 'valid');
    },
  );
}
