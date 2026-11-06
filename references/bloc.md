# Event-driven Bloc

Use when the user requests Bloc events or an existing feature uses them. Cubit remains the
unspecified greenfield default; don't rewrite one into the other during a feature task.
Read `state-selection.md` for shared boundaries and `state-and-di.md` for BlocProvider
ownership, immutable state, listener effects and GetIt/Injectable composition.

## Files and responsibilities

```text
presentation/
  bloc/orders/orders_bloc.dart
  bloc/orders/orders_event.dart
  bloc/orders/orders_state.dart
  pages/orders_screen.dart
  widgets/order_tile_widget.dart
```

Use a sealed event family representing user/domain intent and a separate immutable state
family/snapshot. Colocate variants in their corresponding event/state files. Keep events
small: IDs, filters and validated inputs, never BuildContext or UI controllers. Inject
repository contracts/use cases through the Bloc constructor; register a fresh route-owned
Bloc with `@injectable` when using the default DI. UI adds events, builds state and performs
one-shot navigation/feedback through listeners. Domain/data never import Bloc.

## Choose concurrency per operation

`on<Event>(handler, transformer: ...)` controls a registration's event stream. Bloc's default
is concurrent. Use `bloc_concurrency` when its policy is needed; keep compatible installed
versions rather than copying a pinned version from prose.

| Policy | Appropriate contract | Risk to address |
|---|---|---|
| `restartable()` | Only the newest search/filter read matters | Previous HTTP/side effects may continue; guard/cancel work |
| `droppable()` | Ignore repeat submit/load-more while one operation runs | Dropped input is not queued; UI must make this intentional |
| `sequential()` | Every operation must run in order | Queue can grow; old input may become invalid before execution |
| `concurrent()` | Independent operations can safely overlap | Completion order is unspecified; avoid lost updates |

Each `on<T>` registration operates independently: sequential handlers for two different
event types do not serialize those types together. If load, refresh and filter compete for
one result, use one coherent registration/operation generation or an explicit coordinator.
If multiple write event types must share ordering, serialize them at a common operation
boundary. A global default transformer does not create a single queue across registrations.
Never register both a parent handler and overlapping subtype handlers unintentionally.

Cancellation of a handler is not cancellation of an HTTP request or a server write.
Transport cancellation needs its own token/owner; uncertain mutations need backend
idempotency/reconciliation (`networking-and-errors.md`). Restarting payment/save operations
can hide a completed write: choose the write contract before picking a transformer.

## Async and stream ownership

Await all asynchronous work that uses the handler's Emitter. After awaits, check
`emit.isDone` before emitting when cancellation is possible; do not keep emit in an
unawaited callback after the handler returns. Map typed repository failures deliberately.
Use `await emit.forEach`/`await emit.onEach` for handler-owned streams, with an observed
error path; choose the transformer that lets a later event replace a long-lived stream.
If the Bloc directly creates subscriptions/timers, cancel them in close, then call
super.close. Cancel owned transport before close when waiting work would otherwise hang.
Do not add events from callbacks after closure, or allow old-account results into a new
session. Emitter safety does not replace request identity or session-generation policy.

Refresh/action failures retain usable content with separate operation status. Pagination
needs duplicate-load prevention, cursor identity and retry state; every write must preserve
business validation regardless of UI button state. Events are not a substitute for policy.

## Verification

Use deterministic repository fakes/completers and public events/state. With `bloc_test`
where already used, assert relevant state sequences and externally visible effects:

- Same-type overlap: complete the newer search before the older one; newest data survives.
- Cross-type overlap: load then refresh/filter; prove the selected policy covers both.
- Duplicate submit: one backend effect when duplicates are intentionally ignored.
- Ordered writes: prove call order and failure behavior without arbitrary sleep durations.
- Stream replacement/error, route exit during work, and account change during a request.
- Widget/provider ownership: one initial event per instance; close once on route exit and
  create a fresh instance on reopening. Listener effects fire once per operation outcome.

Run format → codegen if needed (`fdev gen`; fallback: `dart run build_runner build
--delete-conflicting-outputs`) → analyze → test. Runnable state examples live in
`tests/stack_examples/`; their README/results describe actual coverage, not production
backend/device behavior. Do not report a fixture pass as an agent behavior-eval pass.

Official sources (checked 2026-11-06):
[Bloc event API](https://pub.dev/documentation/bloc/latest/bloc/Bloc/on.html),
[transformer policies](https://pub.dev/packages/bloc_concurrency),
[independent handlers](https://bloclibrary.dev/migration/),
[Emitter lifecycle](https://pub.dev/documentation/bloc/latest/bloc/Emitter-class.html).
