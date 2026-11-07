Allow editing a note offline and sync it after relaunch without overwriting a newer server
edit. Implement the supplied NoteSyncService API using the existing transactional store and
versioned server contracts; don't add a database framework or another state stack.

Each accepted edit has a new stable operation ID (the injected generator returns globally
unique IDs), original version precondition and pending status. Local note and queue intent
commit atomically. A write/commit failure must not be reported as safely queued. Offline
sync failure retains pending data/identity; recreating the service with the same store
resumes it. Only server acknowledgement marks work synchronized. The server deduplicates
by account+operation ID before checking version and returns the original acceptance on retry.

Conflicts preserve the user's body, mark the note and that edit conflict, and stop automatic
replay of the conflict. Never overwrite the server blindly or drop conflicted local work.
An acknowledgement for an older local edit may update known server version but cannot
replace newer local input or mark a note fully synced while newer edits remain queued.

Application composition owns one active coordinator per account; repeated sync calls on
that coordinator coalesce rather than duplicating delivery. On logout/account switch/close,
ignore old in-flight completions and never deliver old-account queue items with another
account's credentials. Pending/conflicted work is retained per account on logout.

Tests can use one transactional fake store retained across coordinator reconstructions and
a versioned fake server. Model interruption before delivery and after server acceptance
but before local acknowledgement; prove one server effect after retry. No real persistence,
process-kill, scheduler or backend guarantee is claimed by those fakes. Report exact limits.
