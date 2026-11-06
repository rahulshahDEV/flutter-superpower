# Orders request-ordering fix

Implemented:
- `OrdersCubit.load()` now gives each replacement read an increasing request identity. Only the latest started request can publish its result, for both success and typed failure, including while that latest request is pending.
- Closed Cubits reject new loads and ignore outstanding completions through the existing lifecycle-safe emission contract.
- No filter UI, backend, state schema, dependency, or DI annotation changes.

Cause and reproduction:
- The original Cubit awaited each repository request independently and folded every completion directly into state. Starting load A, starting B, finishing B with the latest list, then finishing A with the older list replaced B's state with A's list.
- A regression calls the real public `load()` with a real `GetOrders` and a handwritten controlled `OrdersRepository`. Repository futures use Completers, with no sleeps, private-method access, or production timing assumptions.
- Before the production change, the new regression failed with:

```text
Expected: OrdersSuccess:<OrdersSuccess([Order(latest, Latest selection)])>
  Actual: OrdersSuccess:<OrdersSuccess([Order(older, Older selection)])>
00:00 +0 -1: Some tests failed.
```

Files changed:
- `lib/features/orders/presentation/cubit/orders/orders_cubit.dart`
- `test/features/orders/presentation/cubit/orders/orders_cubit_test.dart` (new, 14 cases)
- This report and evidence logs: `regression-red.log`, `regression-green.log`, `format.log`, `analyze.log`, `tests-green.log`.
- `ORIGINAL_CUBIT.dart.txt` preserved without edits.

Verification:
- First focused regression red: `flutter test --reporter expanded test/features/orders/presentation/cubit/orders/orders_cubit_test.dart` — 1 behavioral failure against the original implementation (recorded in `regression-red.log`). An earlier test setup import collision was corrected before recording this meaningful red result.
- First focused regression green: the same command after the fix — `00:00 +1: All tests passed!` (recorded in `regression-green.log`).
- Expanded regression coverage: old/latest success and failure combinations in both completion orders; latest loading state remains while stale work finishes; empty latest result; ordinary failure/retry; pending success/failure after close; loads after close.
- `dart format .` — `Formatted 52 files (1 changed) in 0.05 seconds.` Only the added test needed formatting.
- `flutter analyze` — `No issues found! (ran in 1.6s)`.
- `flutter test --reporter expanded` — `00:00 +32: All tests passed!` (14 new Cubit cases plus the existing suite).
- Codegen unnecessary: generated annotations and schemas unchanged.

Not verified:
- Device interaction, native builds, real filter UI, and real backend ordering. The supplied task explicitly places UI/backend outside this fixture; the public load boundary is the reproduced and tested contract.

Notes:
- Existing network requests are not canceled; their stale completions are ignored. This retains repository signatures and keeps request ownership local to the Cubit.
- Existing feature-first/Cubit/Equatable/GetIt/Injectable conventions retained. Only this workspace and the matching skill/references were inspected; no sibling lanes or root test/artifacts inspected, no commits or external actions.
