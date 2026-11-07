# Search concurrency baseline

Implemented in `lib/search_bloc.dart`; event classes, state fields, constructor, and repository signatures remain unchanged. No UI/backend changes or new dependencies.

A single concurrent event registration establishes ordering for changed-query and refresh intents. A shared generation rejects obsolete read successes and errors. Refresh uses the selected query; failed reads keep existing content. Read and save updates preserve the other operation's feedback.

Writes use an explicit FIFO future chain independent of reads. The operation ledger binds each ID to its first payload, suppresses duplicate pending/successful submissions, and allows retries only after failure with the same payload. Errors are caught within each queued write, so a failure cannot poison the next operation. Close drains all accepted writes, including events added immediately before close; completed handlers do not emit through closed emitters.

## Regression evidence

- Created controlled-future tests against the original implementation first. `flutter test` failed all 8 initial cases; `red-test.log` preserves the failures (including stale result restoration, duplicate calls, unhandled failures, and premature close completion).
- After the fix, added three focused cases for stale loading ownership, save success retaining a read error, and closing before event handlers start.
- `flutter test --reporter expanded`: **11 passed**, recorded in `green-test.log`.
- `flutter analyze`: **No issues found**, recorded in `analyze.log`.
- `dart format --output=none --set-exit-if-changed lib test`: exit 0; 2 files, 0 changes.

Tests instantiate the actual `SearchBloc`, submit actual events, control repository futures explicitly, and assert repository call order/counts plus completed write effects. Event-loop draining uses zero-duration scheduling, with no elapsed-time assumptions or arbitrary delays.

## Limits

Stale-state rejection does not cancel repository or server work. Closing waits for writes and therefore can remain pending indefinitely if the repository never completes one. Reads already issued may also complete after close; their handlers consume errors and discard state updates.

Deduplication lasts for this Bloc instance and its in-memory operation ledger; it does not guarantee exactly-once execution across process restarts or repository/server ambiguity (for example a server commit followed by a transport error). The ledger grows with distinct operation IDs for the instance lifetime. A retry is a new FIFO queue entry at retry submission time. Errors remain represented as strings through the supplied state API.

No skill instructions/references, other lanes, or parent acceptance checks were read. No commits, publishing, or global installs were performed.
