# Riverpod Architecture

Apply `state-selection.md` first. Use `flutter_riverpod`; inspect lockfile and existing
manual/generated conventions before picking syntax. New flows prefer Notifier/AsyncNotifier
over introducing legacy StateNotifier APIs. Do not migrate existing flows incidentally.

## Structure and dependency graph

Within `features/<feature>/`, retain data sources/models/repository implementations in
`data/` and plain entities/repository contracts/use cases in `domain/`. Presentation owns:

```text
presentation/
  providers/orders_providers.dart   # repository composition + read-only queries
  notifiers/orders_notifier.dart    # commands and async orchestration
  state/orders_state.dart           # only when AsyncValue alone is insufficient
  pages/orders_screen.dart
  widgets/order_tile.dart
```

Put feature-independent clients in `core/network/` and their provider composition in a
shared composition module; the app root mounts ProviderScope. Constructor-inject clients
into repositories; only the provider/notifier layer knows Ref. Feature providers compose
repositories/use cases. Avoid adding GetIt/Injectable alongside this graph; if an existing
app uses GetIt for infrastructure, expose each existing instance once through a provider
and keep disposal with its original owner.

## State and UI

- Provider: synchronous dependency/derived value; FutureProvider/StreamProvider: read-only
  query/stream; Notifier: mutable synchronous flow; AsyncNotifier: async commands/state.
- Use AsyncValue for initial loading/data/error; an empty list is successful empty data.
  Convert Either failures deliberately into the flow's typed error/state, never silently
  turn Left into empty data. A custom immutable state can retain content plus action errors.
- Initialize in build, not a notifier constructor or widget build side effect. `ref.watch`
  declares reactive dependencies; `ref.read` invokes commands from callbacks. Dependency
  changes may rebuild state: decide which values reset versus persist.
- Parameterize queries by stable IDs/value-equal filters (families or generated parameters).
  Do not use mutable lists or BuildContext as cache keys. Scope account identity explicitly.
- Consumers watch only needed values (`select` where useful). Use UI `ref.listen` for
  transient effects; render loading/error/empty/content explicitly with retry callbacks.

## Lifetime and races

Choose automatic disposal for route/query state; generated providers enable it by default,
manual providers require an explicit choice. Use syntax supported by the installed major.
Keep app/session services alive only deliberately; record cache expiry/invalidation rules.
Register cancellation/subscription cleanup with `ref.onDispose`; cleanup must not mutate
other providers. After awaited commands, reject disposed owners and stale request IDs before
writing state; use the installed version's supported mounted/cancellation API. Disposal
alone does not resolve competing commands on a still-live notifier. Invalidate relevant
queries after successful mutations; clear account caches on logout. Do not close borrowed
clients from a disposable feature provider.

## Testing

Create an isolated ProviderContainer with repository overrides and dispose it after each
test (use ProviderContainer.test where supported). Keep an active subscription when testing
auto-dispose behavior; merely reading a provider may not keep it alive through awaits.
Await query futures or observe state transitions rather than arbitrary delays. Widget tests
mount ProviderScope with the same overrides. Assert failure translation, mutation invalidation,
family isolation, cancellation, latest-result behavior and session reset through public APIs.

Official sources (checked 2026-11-06): [providers](https://riverpod.dev/docs/concepts2/providers),
[automatic disposal](https://riverpod.dev/docs/concepts2/auto_dispose),
[testing](https://riverpod.dev/docs/how_to/testing). Consult the matching version docs.
