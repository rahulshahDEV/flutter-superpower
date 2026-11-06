# Runnable state-stack examples

This isolated Flutter test package implements one order-history flow with four native
state owners. It is a test fixture and teaching example, not a generated production app.
The repository contract and immutable state are shared values; orchestration lives in
each stack's own owner rather than a custom state-management superclass.

| Stack | Owner | Composition and disposal |
|---|---|---|
| Riverpod | Notifier, automatic disposal | Nested ProviderScope overrides repository, account and flow provider |
| Provider | ChangeNotifier view model | ChangeNotifierProvider.create owns disposal |
| GetX | GetxController + immutable Rx snapshot | Explicit tagged registration/deletion by a StatefulWidget route wrapper |
| Event Bloc | Bloc + OrdersRequested event | BlocProvider.create closes; Concurrent reads use request identity and emit.isDone |

Each lives under `lib/features/orders/`. `domain/orders_repository.dart` defines plain
entities and a typed result contract. `presentation/orders_state.dart` models initial,
loading, loaded/empty, failure and refresh retention. Stack owners live in `notifiers/`,
`viewmodels/`, `controllers/` and `bloc/`; `pages/orders_routes.dart` supplies minimal
rendering and route-like lifetime wrappers. The deliberately small Order value omits Equatable because no entity equality is used.
The sealed OrdersResult is this fixture's app-defined typed result contract; an existing
app keeps its Either/Failure family rather than adopting a second error stack.
UI copy uses constants, but app-wide design tokens/flavors are outside this focused fixture.
There is no transport adapter: a controlled
fake repository in the test completes typed outcomes without a backend or plugin.

Run from the skill repository root:

```bash
tests/state-stacks.sh
```

The runner copies only source/configuration files to a temporary workspace, resolves
packages, checks formatting, analyzes, and runs widget tests. Raw package-local fallback:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --reporter expanded
```

No code generation is used. Last verified dependency resolution: Flutter 3.38.9 / Dart
3.10.8, flutter_riverpod 3.3.2, provider 6.1.5+1, get 4.7.3, flutter_bloc 9.1.1,
bloc 9.2.1 and bloc_concurrency 0.3.0. Constraints are compatibility ranges, not claims
about newest versions; the runner prints its resolution and runs against that graph.

## Behavioral matrix

The same nine widget scenarios run independently for each of the four stacks:

- One initial fetch per mount, loading then valid empty content.
- Typed failure, user retry, then content.
- Refresh loading and failure preserve usable content.
- Newer responses win over stale success and stale failure.
- Unmount during a request, late completion, reopen with a fresh owner.
- Two simultaneously mounted routes isolate account data.
- Account switch replaces ownership and rejects the old account's late response.
- Updating the account with an unchanged route key recreates the inner owner.
- Replacing the repository with an unchanged route key rejects the old source result.

A separate test protects snapshot immutability. Loading is static text so widget tests
can settle finite button/notification animations while fake requests remain pending.

## Ownership contract and limits

Wrappers recreate their inner owner when account/repository identity changes, even when
the caller retains the route key. For GetX supply a distinct tag per simultaneous route
instance; didUpdateWidget deletes the old registration before registering the new owner.
This example recreates owners rather than mutating an existing owner's dependencies. The explicit GetX
wrapper intentionally works without Get routing: its tests establish tagged registry
cleanup, not GetPage Bindings/SmartManagement behavior.

These tests establish Dart/widget behavior through actual stack composition. They do
not establish native navigation, HTTP/backend contracts, transport cancellation, secure
storage, OS process-death recovery, or behavior of every supported package version.
Ignoring late results does not cancel network work. The typed repository boundary must
translate real transport exceptions before returning a result in an application.

Passing this regression is not a behavior-evaluation verdict for an agent using the
skill. Run and independently score `evals/cases.md` case 43 to make that claim.
