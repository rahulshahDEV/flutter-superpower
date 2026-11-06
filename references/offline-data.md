# Offline Data and Synchronization

Load when a feature must read or write without a usable connection. Do not add a database,
queue or connectivity package to a feature whose contract is online-only. Start with the
existing repository and `networking-and-errors.md`; persistence evolution lives in
`persistence-migrations.md` and durable execution in `lifecycle-restoration.md`.

## Decide the feature contract

Record which operations work offline, how long cached data is useful, whether stale data
is labelled, and how users recover from an unsynchronized write. Connectivity is a hint;
the actual request result decides reachability. Authorization and monetary eligibility may
need authoritative server validation even while cached content remains visible.

| Requirement | Repository policy |
|---|---|
| Online-only mutation | Confirm remote success before reporting saved; retain editable input on failure |
| Cached read fallback | Attempt remote with bounded timeout; return valid local data with freshness metadata on failure |
| Local-first reads | Observe the local store; remote refresh commits into that same store |
| Offline writes | Commit local change and durable pending operation atomically; expose pending/failed/synced status |

Choose one authoritative read model per feature. In local-first flows, UI observes database
changes rather than independently appending HTTP results to a second in-memory list. Remote
responses update the repository's store transactionally, then its stream emits the snapshot.
Keep transport, database records and synchronization metadata out of presentation/domain
contracts unless a domain concept such as pending confirmation belongs there.

## Durable write workflow

1. Assign an operation identity once when the user intent is accepted; keep it across retries.
   Include account/tenant identity, target resource, schema version, payload, attempt status
   and a server version/precondition when the API supports optimistic concurrency.
2. In one local transaction, save the optimistic change and pending operation. If either
   write fails, report failure; don't display an unpersisted change as safely queued.
3. A single logical sync owner claims eligible work. Coordinate concurrent foreground and
   scheduled workers using the store's transaction/lease mechanism, not widget booleans.
4. Submit using backend-supported idempotency or reconcile an ambiguous timeout before
   retrying. A client operation ID alone cannot force an arbitrary server to deduplicate.
5. Commit acknowledgement and canonical server data together. Interrupted work stays
   recoverable: a crash after server success but before local acknowledgement must not
   create a second business operation when replayed.
6. Retry transient failures with bounded backoff/jitter and a retry budget; pause for session
   recovery. Validation/conflict failures need correction, reconciliation or explicit discard,
   not endless replay. Observe and expose failed work instead of silently dropping it.

Scope the queue to the account. Logout/account changes stop old workers and reject their
late responses; decide whether pending user work is retained, exported or explicitly removed.
Never replay one user's queued writes with another user's credentials.

## Conflicts, deletion and retention

Choose server-authoritative replacement, version-checked merge, or user conflict resolution
per operation. Do not use local-clock last-write-wins for high-value data without a product
contract. Reject a stale acknowledgement that would overwrite a newer local edit. Deletes
may need tombstones until peers/server acknowledge them. Define cache TTL, maximum size,
sensitive-data policy, cleanup and whether evicted data can safely be fetched again.

For pagination, store query identity/cursor with the corresponding snapshot; deduplicate by
stable identity and define how refresh invalidates pages. Do not merge pages from different
filters/accounts. A network error must not erase still-valid cached content.

## Verification recipe

Use a fake clock, controlled transport and the actual local-store adapter where possible:

- Empty cache + offline → deliberate unavailable state; warm cache + offline → labelled data.
- Local write failure → neither optimistic row nor orphan queue record survives.
- Relaunch with pending work → operation resumes; repeated delivery creates one server effect.
- Server success + lost acknowledgement → reconcile/retry without a duplicate business write.
- New local edit while old upload completes → preserve/reconcile the newer edit.
- Two workers + same operation → one logical claim; expired claim can recover after interruption.
- Logout/account switch during sync → no cross-account read/write or late restoration.
- Permanent failure/conflict → actionable status; retry/discard follows the agreed policy.

Fake-backed tests establish repository policy; device restart and real backend integration
are required for claims about persistence, OS scheduling and server idempotency.

Sources: [Flutter offline-first architecture](https://docs.flutter.dev/app-architecture/design-patterns/offline-first),
[Flutter SQL persistence](https://docs.flutter.dev/app-architecture/design-patterns/sql).
