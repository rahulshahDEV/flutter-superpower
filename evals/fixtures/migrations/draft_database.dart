import 'package:sqlite3/sqlite3.dart';

final class Draft {
  Draft({
    required this.id,
    required this.body,
    this.updatedAt = 0,
    List<String> tags = const [],
  }) : tags = List.unmodifiable(tags);
  final String id;
  final String body;
  final int updatedAt;
  final List<String> tags;
}

// Existing schema-1 adapter. Keep API callers compatible while adding schema evolution.
final class DraftDatabase {
  DraftDatabase._(this._database);
  final Database _database;

  static DraftDatabase open(
    String path, {
    void Function(int)? afterMigrationStep,
  }) {
    final db = sqlite3.open(path);
    final version =
        db.select('PRAGMA user_version').single['user_version'] as int;
    if (version == 0) {
      db.execute(
        'CREATE TABLE drafts (id TEXT PRIMARY KEY, body TEXT NOT NULL)',
      );
      db.execute('PRAGMA user_version = 1');
    } else if (version != 1) {
      db.dispose();
      throw UnsupportedError('Unsupported schema');
    }
    return DraftDatabase._(db);
  }

  List<Draft> readDrafts() => _database
      .select('SELECT id, body FROM drafts ORDER BY id')
      .map((row) => Draft(id: row['id'] as String, body: row['body'] as String))
      .toList();

  void saveDraft(Draft draft) {
    _database.execute('INSERT OR REPLACE INTO drafts(id, body) VALUES (?, ?)', [
      draft.id,
      draft.body,
    ]);
  }

  void dispose() => _database.dispose();
}
