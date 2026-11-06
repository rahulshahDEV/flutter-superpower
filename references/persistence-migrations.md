# Persistence Schema Evolution

Load for database/schema changes, persisted model changes or a rollback touching local data.
Keep the existing storage engine unless migration is requested. Preferences, database schema,
backup-file format and server API versions are separate contracts; advancing one does not
implicitly migrate the others. Use `models-and-storage.md` for store selection.

## Plan before changing the schema

List the oldest supported installed schema, target schema, affected tables/records/indexes,
read/write callers, data volume, offline operations and supported app/OTA rollback range.
Define defaults from business semantics: missing price, authorization or identity fields
must not become permissive values merely to make old rows parse.

Keep migrations beside the storage adapter in data/infrastructure, not in widgets or model
constructors. One database opener owns migration before repositories start querying. Prevent
another isolate/worker from using an incompatible schema while the upgrade is in progress.

## Upgrade workflow

1. Add a monotonic version step using the engine's migration mechanism. Support direct
   upgrades from every supported old version by applying required steps in order.
2. Use a transaction for the schema/data step where supported. If the library's upgrade
   callback already owns a transaction, use its supplied transaction executor; don't start
   a conflicting nested transaction or query through an unrelated connection.
3. Add compatible fields/tables before replacing readers. Backfill in a bounded way, preserving
   primary keys, relationships and business values. Recreate relevant indexes/triggers and
   validate constraints. For large data, design a restartable phased migration and explicit
   readiness state instead of blocking startup without bounds.
4. Advance the persisted version only when that step's invariants hold. On failure retain
   recoverable old state or an explicit interrupted state and show a usable recovery surface.
   Do not catch an upgrade error, delete the database and claim success.
5. Reopen the upgraded database and exercise repository reads/writes; schema metadata alone
   cannot prove migrated values satisfy domain contracts.

An additive change can be compatible with old binaries; destructive rename/drop/type changes
usually need a staged expand → backfill → switch readers/writers → retire sequence. Choose
SQL supported by the bundled engine/library on the minimum supported OS, not a desktop CLI's
newer SQLite version. Follow the engine's documented safe table-rebuild procedure where needed.

## Rollback and corrupt data

A code rollback does not undo a persisted migration. Either keep the old binary compatible
through the rollback window, provide an explicitly supported downgrade, or block unsupported
schema access with a recovery/update path. OTA eligibility must include this decision.
Never silently reinterpret a newer schema as an older one.

Distinguish disposable cache from irreplaceable user-created data. Rebuilding a cache can be
acceptable under an explicit policy; deleting drafts or pending writes is not a generic
corruption fix. Preserve a safe recovery copy when appropriate, with encryption/retention and
free-space requirements. Backups/exports have their own validation and atomic restore path
in `data-export-and-restore.md`; a copied live database file may omit uncheckpointed state.

## Verification recipe

Keep sanitized fixture databases or deterministic builders for every supported old schema.
For each fixture, open through the production opener and check:

- Oldest → latest and intermediate → latest upgrades preserve identities, values and links.
- Fresh install and upgraded install produce equivalent usable repositories.
- Null/missing/unknown legacy values follow explicit validation or remediation policy.
- Failure midway leaves the previous transaction intact or a resumable phase; reopening
  doesn't rerun an already-completed destructive step.
- Indexes/constraints and new writes behave correctly after upgrade and after reopen.
- Pending offline operations and account isolation survive the transition.
- The previous supported binary can read/write the new schema throughout the stated rollback
  window, or an unsupported version is rejected without deleting data.

Run adapter/engine tests, not only mocked repository tests. Test representative data volume,
low-storage failure and device reopen when those risks matter. Record fixture versions and
which upgrade/rollback paths were exercised.

Sources: [Flutter SQL persistence](https://docs.flutter.dev/app-architecture/design-patterns/sql),
[SQLite schema-change semantics](https://www.sqlite.org/lang_altertable.html),
[SQLite transactions](https://www.sqlite.org/lang_transaction.html).
