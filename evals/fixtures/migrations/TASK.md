Upgrade saved drafts from schema 1 to 3 without deleting user data; support our rollback
window. This is a Flutter app's existing SQLite adapter, not a request to replace the DB.

Schema 1: drafts(id TEXT PRIMARY KEY, body TEXT NOT NULL).
Schema 2 adds updated_at INTEGER NOT NULL DEFAULT 0.
Schema 3 adds tags_json TEXT NOT NULL DEFAULT '[]' and index drafts_updated_at on updated_at.
Fresh installs use schema 3. v1/v2 files must upgrade preserving all IDs/body/timestamps.
Use the actual SQLite engine and on-disk old-version fixtures, not map-only migration tests.

Keep the provided Draft and DraftDatabase public API. afterMigrationStep is a failure-injection
hook called after each version step; a failure during any upgrade must leave the entire
previous schema/version/data intact when reopened. Reject future schema versions (>3)
without modifying their data/version. Do not delete corrupt/unsupported databases.

Rollback window: our previous v2 binary reads/writes explicit id/body/updated_at columns.
Its SQL must continue to work on v3, including defaults for new records. A binary rollback
does not reverse the schema. The old binary does not reject additive future columns.

Implement and verify through real adapter/engine tests. No UI, device build, new database
framework, or native/backend integration is requested. Report what was actually tested.
