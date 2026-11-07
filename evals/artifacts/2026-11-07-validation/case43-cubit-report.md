# Order history implementation

Implemented:
- Public OrdersRoute(repository:, accountId:, key:) API with Loading, No orders, safe failure text, Retry and order IDs.
- Refresh keeps useful content on failure; latest request alone may publish.
- Rebuilds preserve the mounted owner; account/repository identity changes reset state. Route exit/reopen and simultaneous routes have isolated owners.
- The supplied repository is borrowed; domain contract and declared dependency stack remain unchanged.

Stack and ownership:
Existing Cubit precedent retained; route-owned BlocProvider creates OrdersCubit and loads once, then closes it on removal.

Files changed/created:
- lib/features/orders/presentation/cubit/orders/orders_cubit.dart
- lib/features/orders/presentation/cubit/orders/orders_state.dart
- lib/features/orders/presentation/pages/orders_route.dart
- lib/features/orders/presentation/utils/orders_text.dart
- lib/features/orders/presentation/widgets/orders_view_widget.dart
- pubspec.lock
- test/features/orders/orders_route_test.dart

Verification (Flutter 3.38.9 / Dart 3.10.8):
- flutter pub get: exit 0.
- dart format .: exit 0; Formatted test/features/orders/orders_route_test.dart
Formatted 8 files (1 changed) in 0.02 seconds.
- flutter analyze: exit 0; No issues found! (ran in 2.4s)
- flutter test --reporter expanded: exit 0; 7 widget tests passed. Actual output: `00:01 +7: All tests passed!`.
- Logs: pub-get.log, format.log, analyze.log, test.log.

Coverage:
- Initial loading, empty success, initial safe failure, retry recovery.
- Refresh failure preserves content; reverse completion order preserves latest result.
- Unchanged rebuild loads once; same-key account replacement clears content and rejects old completions.
- Same-key repository replacement rejects old completions.
- Exit/reopen uses a fresh owner and rejects abandoned work.
- Two simultaneous routes using the same repository/account remain independent.

Not verified:
- Device/runtime visuals and native builds: no runnable platform shell or device work was requested.
- Backend integration: supplied fake repository contract only. The contract has no cancellation/close API; pending reads are ignored safely, not transport-cancelled.

Notes:
- No competing state/DI library, release setup, backend or platform code added.
- Absolute package imports follow the skill architecture guide. Existing counter precedent remains unchanged.
- Tests use controlled Completers and bounded frames, without network or timing sleeps. Initial verification identified insufficient frame pumping, corrected before the final passing run.
