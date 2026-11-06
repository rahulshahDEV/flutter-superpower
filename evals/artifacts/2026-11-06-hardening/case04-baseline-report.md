# Independent baseline

Task: fix replacement-request ordering through the public `OrdersCubit.load()` API. No skill, reference files, repository outside this lane, sibling lanes, or reports were read. No commits or external actions were performed.

## Cause and fix

Each call previously emitted whichever result completed next. Overlapping requests could finish out of order, so a superseded request replaced the newest list or error, or ended its loading state prematurely. Existing `safeEmit` only checks whether the Cubit is closed; it does not associate a result with a particular request.

Each `load()` now increments a private generation counter, captures it before awaiting the use case, and ignores results whose generation is no longer current. Both success and failure use the same guard. The public API, use case, repository, UI, and backend are unchanged. `safeEmit` continues protecting completion after close. Requests still run to completion; this solution suppresses stale state rather than cancelling network work.

## Regression evidence

`test/orders_request_ordering_test.dart` uses controlled Completers in a repository fake and the actual `GetOrders` use case. It calls public `load()` twice and resolves requests in chosen order without timing delays.

Before editing production code, `flutter test test/orders_request_ordering_test.dart --reporter expanded` produced **1 passed, 5 failed**. `RED.log` preserves the assertion failures:

- Older success overwrites newest success.
- Older success overwrites newest failure.
- Older failure overwrites newest success.
- Older failure overwrites newest failure.
- Older completion changes state while the newest request remains pending.

The sixth check, completion after close, already passed. An initial test compilation error from the `dartz.Order` import collision was corrected before this behavioral red run; this was not counted as the reproduction.

After the fix:

- `dart format lib/features/orders/presentation/cubit/orders/orders_cubit.dart test/orders_request_ordering_test.dart`: formatted successfully.
- `flutter test test/orders_request_ordering_test.dart --reporter expanded`: **6 passed**, `GREEN.log`.
- `flutter analyze`: **No issues found**, `ANALYZE.log`.
- `flutter test --reporter expanded`: **24 passed**, `TEST.log`.

The logs capture actual Flutter output. Commands redirected their output and then displayed the files, so shell wrapper exit codes are not separately preserved as Flutter exit statuses; the explicit pass/fail summaries above are the evidence.

## Scope and limits

This fixture has no filter parameter, so tests distinguish the returned order lists and control completion through the public replacement operation as requested. Real filter UI/backend integration was not exercised. The latest request may finish with either success or failure, and that result owns visible state. The implementation retains the repository's typed Either failure contract; exceptional throws outside that contract are not expanded in scope. No real cancellation was introduced.

`ORIGINAL_CUBIT.dart.txt` was preserved untouched. SHA-256: `2c0ae8c88d3552dcaf3c94272dbc350bde2a7ebdf8fbc677a61b4e847e242cea`.
