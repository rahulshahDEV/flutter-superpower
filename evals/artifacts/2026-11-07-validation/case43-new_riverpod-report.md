# Orders history implementation evidence

## Implemented

Profile: a new Flutter package named `stack_eval`, Flutter SDK and lints only, one supplied pure-Dart OrdersRepository contract, no application bootstrap, platform targets, existing state stack, design system or routing conventions. Applied `<SKILL>/SKILL.md` and its state-selection, selected-stack, architecture, state/DI, testing, UI, scope and planning references. Used the manual feature path; no native app generator.

Selected stack: **Riverpod 3.3.2**.

Auto-disposed NotifierProvider overridden inside an isolated ProviderScope per route owner. OrdersNotifier initializes in build; ref.onDispose invalidates pending work. No shared route cache or second container/DI stack.

Public API: `OrdersRoute(repository: ..., accountId: ..., key: ...)` in the requested file. Fetch/loading, safe failure text, empty success, order IDs and Retry are visible. Retry can replace a pending read and refresh content. A failed refresh preserves the previous orders. Every result checks both lifetime and request generation; stale success and failure are rejected. Repository identity uses `identical`, so dependency changes on a stable public widget key get a new owner. Reopening creates fresh state, and simultaneous routes remain independent. Repositories are borrowed and never closed. Thrown unexpected errors use safe fallback text without exposing internals.

Immutable sealed snapshots distinguish initial/loading/loaded/failed. Repository success data is copied into an unmodifiable presentation list. Domain contract remains untouched. No data implementation or forwarding use case was needed for the supplied repository boundary. Copy is centralized in feature text constants; the view uses standard Material layout/widgets and inherited theme, without unused app bootstrap, flavors, network, platform, routing or design-system scaffolding.

## Files changed

- `lib/features/orders/presentation/notifiers/orders_notifier.dart`
- `lib/features/orders/presentation/orders_text.dart`
- `lib/features/orders/presentation/pages/orders_route.dart`
- `lib/features/orders/presentation/providers/orders_providers.dart`
- `lib/features/orders/presentation/state/orders_state.dart`
- `lib/features/orders/presentation/widgets/orders_content.dart`
- `pubspec.yaml` / `pubspec.lock`: selected stack dependencies only.
- `test/orders_route_test.dart`: eight public-widget behavior checks.

## Verification

Commands executed from this package, using the installed Flutter toolchain:

```text
dart format .
Formatted 8 files (0 changed) in 0.02 seconds.
flutter analyze
Waiting for another flutter command to release the startup lock...
Analyzing new_riverpod...
No issues found! (ran in 1.7s)
flutter test --reporter expanded
00:00 +0: loading <APP>/test/orders_route_test.dart
00:00 +0: initializes once; failure retries into empty and content
00:00 +1: refresh retains content and latest request alone publishes
00:00 +2: same-key account replacement resets data and pending results
00:00 +3: same-key repository replacement rejects old completion
00:00 +4: leaving and reopening creates fresh state; borrowed repo remains usable
00:00 +5: two mounted routes have independent owner and lifecycle
00:00 +6: thrown internals use safe recovery text
00:00 +7: narrow layout supports large text and long failure
00:00 +8: All tests passed!
```

All eight widget tests passed. They cover initialization once across rebuilds, loading/failure/retry/empty/content, refresh retention, overlapping requests with reversed success and failure completions, same-key account and repository replacement, unmount/reopen with late completion, simultaneous route ownership and removing one route, safe unexpected-error text, and 320x640 layout at 2x text scale. Controlled Completers make async order deterministic. No arbitrary sleeps, external service calls or mocks were used.

Initial verification found a fixture issue: removing the first unkeyed Expanded parent recreated its sibling route. Keying the parent slots corrected the intended persistent-route scenario; the implementation did not change for this finding.

## Not verified

No platform/device build or manual screenshot review: these packages deliberately contain no native targets or application entry point. Widget layout and behavioral evidence do not claim native visual/runtime validation. No backend, transport cancellation API or release work is in scope. Underlying futures cannot be canceled by the supplied contract, so late results are ignored. No generated annotations changed; code generation was unnecessary.
