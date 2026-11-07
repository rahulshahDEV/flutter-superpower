enum NoteStatus { synced, pending, conflict }

final class NoteRecord {
  const NoteRecord({
    required this.accountId,
    required this.noteId,
    required this.body,
    required this.serverVersion,
    required this.status,
  });
  final String accountId;
  final String noteId;
  final String body;
  final int serverVersion;
  final NoteStatus status;
}

final class PendingEdit {
  const PendingEdit({
    required this.operationId,
    required this.accountId,
    required this.noteId,
    required this.body,
    required this.baseVersion,
    this.status = NoteStatus.pending,
  });
  final String operationId;
  final String accountId;
  final String noteId;
  final String body;
  final int baseVersion;
  final NoteStatus status;
}

abstract interface class NoteTransaction {
  NoteRecord? readNote(String accountId, String noteId);
  void putNote(NoteRecord note);
  List<PendingEdit> edits(String accountId);
  void putEdit(PendingEdit edit);
  void deleteEdit(String operationId);
}

abstract interface class LocalNoteStore {
  T transaction<T>(T Function(NoteTransaction transaction) action);
}

sealed class NoteWriteResult {
  const NoteWriteResult();
}

final class NoteAccepted extends NoteWriteResult {
  const NoteAccepted(this.version);
  final int version;
}

final class NoteConflict extends NoteWriteResult {
  const NoteConflict(this.serverBody, this.serverVersion);
  final String serverBody;
  final int serverVersion;
}

abstract interface class NoteServer {
  Future<NoteWriteResult> write(PendingEdit edit);
}

// Complete this presentation-independent coordinator; keep its public surface.
final class NoteSyncService {
  NoteSyncService(this.store, this.server, this.newId);
  final LocalNoteStore store;
  final NoteServer server;
  final String Function() newId;
  void signIn(String accountId) => throw UnimplementedError();
  void signOut() => throw UnimplementedError();
  void edit(String noteId, String body) => throw UnimplementedError();
  NoteRecord? get(String noteId) => throw UnimplementedError();
  Future<void> sync() => throw UnimplementedError();
  void close() => throw UnimplementedError();
}
