// Parent-held checks, withheld until each implementation is complete.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:migration_eval/draft_database.dart';

int version(Database db) =>
    db.select('PRAGMA user_version').single.values.single as int;

void seed(String path, int versionNumber) {
  final db = sqlite3.open(path);
  try {
    db.execute('CREATE TABLE drafts (id TEXT PRIMARY KEY, body TEXT NOT NULL)');
    if (versionNumber >= 2) {
      db.execute(
        'ALTER TABLE drafts ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (versionNumber >= 3) {
      db.execute(
        "ALTER TABLE drafts ADD COLUMN tags_json TEXT NOT NULL DEFAULT '[]'",
      );
      db.execute('CREATE INDEX drafts_updated_at ON drafts(updated_at)');
    }
    db.execute('INSERT INTO drafts(id, body) VALUES (?, ?)', [
      'kept',
      'Unfinished draft',
    ]);
    if (versionNumber >= 2) {
      db.execute('UPDATE drafts SET updated_at = 12345 WHERE id = ?', ['kept']);
    }
    db.execute('PRAGMA user_version = $versionNumber');
  } finally {
    db.dispose();
  }
}

Map<String, Object?> snapshot(String path) {
  final db = sqlite3.open(path);
  try {
    return {
      'version': version(db),
      'schema': db
          .select(
            'SELECT type, name, tbl_name, sql FROM sqlite_master ORDER BY type, name',
          )
          .map((row) => Map<String, Object?>.from(row))
          .toList(),
      'rows': db
          .select('SELECT * FROM drafts ORDER BY id')
          .map((row) => Map<String, Object?>.from(row))
          .toList(),
    };
  } finally {
    db.dispose();
  }
}

void expectTargetSchema(Database db) {
  expect(version(db), 3);
  expect(
    db
        .select("PRAGMA index_info('drafts_updated_at')")
        .map((row) => row['name']),
    ['updated_at'],
  );
  final columns = {
    for (final row in db.select("PRAGMA table_info('drafts')"))
      row['name']: row,
  };
  expect(columns['id']?['pk'], 1);
  expect(columns['body']?['notnull'], 1);
  expect(columns['updated_at']?['notnull'], 1);
  expect(columns['updated_at']?['dflt_value'], '0');
  expect(columns['tags_json']?['notnull'], 1);
  expect(columns['tags_json']?['dflt_value'], "'[]'");
}

void main() {
  late Directory directory;
  late String path;
  setUp(() {
    directory = Directory.systemTemp.createTempSync(
      'draft-migration-acceptance-',
    );
    path = '${directory.path}/drafts.sqlite';
  });
  tearDown(() => directory.deleteSync(recursive: true));

  for (final source in [1, 2]) {
    test('schema $source upgrades on disk and survives reopen', () {
      seed(path, source);
      final adapter = DraftDatabase.open(path);
      final draft = adapter.readDrafts().single;
      expect(draft.id, 'kept');
      expect(draft.body, 'Unfinished draft');
      expect(draft.updatedAt, source == 1 ? 0 : 12345);
      expect(draft.tags, isEmpty);
      adapter.saveDraft(
        Draft(
          id: 'new',
          body: 'New draft',
          updatedAt: 987,
          tags: ['work', 'later'],
        ),
      );
      adapter.dispose();
      final raw = sqlite3.open(path);
      expectTargetSchema(raw);
      expect(
        raw.select("PRAGMA index_list('drafts')").map((row) => row['name']),
        contains('drafts_updated_at'),
      );
      raw.dispose();
      final reopened = DraftDatabase.open(path);
      final saved = reopened.readDrafts().singleWhere(
        (draft) => draft.id == 'new',
      );
      expect(saved.updatedAt, 987);
      expect(saved.tags, ['work', 'later']);
      reopened.dispose();
    });
  }

  test('fresh install is schema 3 and stores full draft values', () {
    final adapter = DraftDatabase.open(path);
    expect(adapter.readDrafts(), isEmpty);
    adapter.saveDraft(
      Draft(id: 'x', body: 'first', updatedAt: 1, tags: ['one']),
    );
    adapter.saveDraft(Draft(id: 'x', body: 'changed', updatedAt: 2, tags: []));
    expect(adapter.readDrafts().single.body, 'changed');
    expect(adapter.readDrafts().single.tags, isEmpty);
    adapter.dispose();
    final raw = sqlite3.open(path);
    expectTargetSchema(raw);
    raw.dispose();
  });

  for (final source in [1, 2]) {
    for (final stop in [2, 3].where((step) => step > source)) {
      test(
        'migration failure from $source after step $stop preserves old schema and values',
        () {
          seed(path, source);
          final before = snapshot(path);
          expect(
            () => DraftDatabase.open(
              path,
              afterMigrationStep: (step) {
                if (step == stop) throw StateError('Injected interruption');
              },
            ),
            throwsStateError,
          );
          final raw = sqlite3.open(path);
          expect(version(raw), source);
          final columns = raw
              .select("PRAGMA table_info('drafts')")
              .map((row) => row['name'])
              .toList();
          expect(
            columns,
            source == 1 ? ['id', 'body'] : ['id', 'body', 'updated_at'],
          );
          expect(
            raw.select('SELECT body FROM drafts WHERE id = ?', [
              'kept',
            ]).single['body'],
            'Unfinished draft',
          );
          raw.dispose();
          expect(snapshot(path), before);
          final recovered = DraftDatabase.open(path);
          expect(recovered.readDrafts().single.id, 'kept');
          recovered.dispose();
        },
      );
    }
  }

  test('future version rejection preserves actual file bytes and data', () {
    seed(path, 4);
    final before = File(path).readAsBytesSync();
    expect(() => DraftDatabase.open(path), throwsA(isA<UnsupportedError>()));
    expect(File(path).readAsBytesSync(), before);
    final raw = sqlite3.open(path);
    expect(version(raw), 4);
    expect(
      raw.select('SELECT body FROM drafts').single['body'],
      'Unfinished draft',
    );
    raw.dispose();
  });

  test('corrupt bytes are not replaced with an empty database', () {
    final bytes = List<int>.generate(160, (i) => (i * 19) % 256);
    File(path).writeAsBytesSync(bytes);
    expect(() => DraftDatabase.open(path), throwsA(isA<SqliteException>()));
    expect(File(path).readAsBytesSync(), bytes);
  });

  test(
    'v2 SQL can update and insert with defaults on v3 throughout rollback window',
    () {
      seed(path, 2);
      DraftDatabase.open(path).dispose();
      final oldBinary = sqlite3.open(path);
      oldBinary.execute(
        'UPDATE drafts SET body = ?, updated_at = ? WHERE id = ?',
        ['Old binary edit', 456, 'kept'],
      );
      oldBinary.execute(
        'INSERT INTO drafts(id, body, updated_at) VALUES (?, ?, ?)',
        ['old-insert', 'Written by v2', 789],
      );
      expect(
        oldBinary.select('SELECT id, body, updated_at FROM drafts'),
        hasLength(2),
      );
      expect(version(oldBinary), 3);
      oldBinary.dispose();
      final adapter = DraftDatabase.open(path);
      final records = adapter.readDrafts();
      expect(
        records.singleWhere((draft) => draft.id == 'kept').body,
        'Old binary edit',
      );
      expect(
        records.singleWhere((draft) => draft.id == 'old-insert').tags,
        isEmpty,
      );
      adapter.dispose();
    },
  );
}
