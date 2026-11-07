# Baseline migration result

Implemented using only TASK.md, the supplied adapter/pubspec, and ordinary Dart/SQLite knowledge. No skills, root repository, sibling lanes, or acceptance files were read. All work stayed in this baseline directory; no commits, publishing, global installations, UI, platform or backend changes.

## Implementation

- Preserved Draft and DraftDatabase public APIs and the existing sqlite3 dependency.
- Fresh databases create schema 3, including defaults and drafts_updated_at index.
- Schema 1 -> 2 -> 3 and schema 2 -> 3 migrations add columns without rewriting rows. One BEGIN IMMEDIATE transaction includes every schema change, user_version update and afterMigrationStep invocation. Failures roll back the complete upgrade and close the handle.
- Versions above 3 throw UnsupportedError. Errors never trigger deletion or recreation of the database.
- Adapter reads/writes timestamps and JSON string-list tags. Explicit-column v2 SQL continues working against additive schema 3. Opening with an old binary does not downgrade user_version.

## Actual validation

Environment: Flutter 3.38.9 stable, Dart 3.10.8, resolved sqlite3 2.9.4.

Commands executed successfully:

- `flutter pub get` — dependencies resolved; generated pubspec.lock.
- `dart format lib test` — formatted implementation/tests.
- `flutter analyze` — No issues found.
- `flutter test` — 10 tests passed.
- `dart format --output=none --set-exit-if-changed lib test` — 2 files, 0 changed.

The tests use sqlite3.open with temporary on-disk SQLite files, not a map/mock engine. Old-version fixtures are created through SQL and closed before the adapter opens them. Tests cover:

1. Fresh schema 3: version/index/integrity check; save/reopen body, timestamps, escaped/Unicode tags and defaults; replacement and ordering.
2. On-disk schema 1 upgrade: ID/body preserved, timestamp/tags defaulted, hooks [2, 3], repeat open idempotent.
3. Schema 1 failure after step 2: full schema/version/row snapshot unchanged on a separate connection, successful retry.
4. Schema 1 failure after step 3: same full rollback and retry, including reversal of the completed intermediate step.
5. On-disk schema 2 upgrade: existing timestamp/ID/body preserved, tags defaulted, hook [3], repeat open idempotent.
6. Schema 2 failure after step 3: complete snapshot unchanged and retry succeeds.
7. Old v2 SQL after v3 upgrade: SELECT explicit columns, UPDATE existing row, INSERT new row; reopening through v3 preserves updated fields and existing tags, new rows have empty tags, version remains 3.
8. Future version 4 rejection: schema, version and row snapshot unchanged.
9. Corrupt file rejection: original 512 bytes retained exactly.
10. Existing unsupported version-zero drafts schema: create fails without replacing schema/data/version.

## Limits

Validation used the host SQLite library via sqlite3 and Flutter's host test runner. No device builds, mobile SQLite libraries, concurrent writers, process termination/power-loss scenarios, or real old-binary executable were tested. Old-binary compatibility was exercised through its stated explicit-column SQL on a separate SQLite connection. Tests inject Dart exceptions at each upgrade boundary; durability under abrupt process death relies on SQLite's transaction implementation. Unsupported version-zero files are not destructively recovered. Corrupt-file handling rejects and preserves the original file; this is not a repair utility.
