# Provider Architecture

Apply `state-selection.md` first. This guide means the `provider` package, distinct from
Riverpod providers and BlocProvider. Use feature-first MVVM: ViewModel is the presentation
state owner; repositories and optional use cases retain data/business responsibilities.

## Structure and composition

```text
features/orders/
  data/datasources/orders_remote_data_source.dart
  data/repositories/orders_repository_impl.dart
  domain/entities/order.dart
  domain/repositories/orders_repository.dart
  presentation/viewmodels/orders_view_model.dart
  presentation/state/orders_state.dart
  presentation/providers/orders_providers.dart
  presentation/pages/orders_screen.dart
  presentation/widgets/order_tile.dart
```

Show each introduced type's shape when writing code examples; this tree is a file map,
not an implied set of interfaces to generate. Add only layers the feature actually needs.
Use Provider for plain dependencies and ChangeNotifierProvider for view models. Assemble
app/session repositories above feature routes with MultiProvider; create each screen's
view model at its route boundary, with constructor-injected repository/use-case contracts.
Do not import provider or BuildContext into domain/data, or look up services inside a VM.
GetIt/Injectable is not required; keep an existing infrastructure container only if already
used, with one instance/owner per service.

## State and dependency updates

- Extend ChangeNotifier; expose a read-only immutable state snapshot and intent methods.
  Keep setters private. Model mutually exclusive statuses explicitly, with unmodifiable
  collections and separate mutation/refresh status when keeping content visible.
- Map repository Either to state, including a meaningful failure and retry path. Notify
  after a coherent transition rather than after every field assignment.
- Initialize once in the provider creation path or a deliberate widget lifecycle callback;
  never trigger requests or synchronous notifier mutations from widget build.
- Use context.watch/Consumer for rendering; context.select/Selector for narrow slices;
  context.read for commands in callbacks. Do not keep BuildContext in the view model.
- For dependencies that can change (account/repository), use ProxyProvider or
  ChangeNotifierProxyProvider. Its update callback may run repeatedly: preserve the existing
  VM, explicitly update the dependency, invalidate old work and reset account-specific state.
  Do not create a replacement VM on every update or blindly reload unchanged dependencies.
- UI owns routing and transient feedback. Distinguish effects from persistent errors and
  consume them once; do not show a snackbar on each Consumer rebuild.

## Ownership and async safety

Use `create` for newly owned instances: ChangeNotifierProvider disposes the created VM.
Use `.value` to expose an existing instance, whose original owner remains responsible for
its lifetime. Never construct a fresh notifier inside `.value` or dispose a borrowed object.
Dispose timers/subscriptions/listeners in the VM's dispose, then call super.dispose.
Track disposal and request generation: after await, ignore results when disposed or stale;
notifyListeners after dispose is a bug. Cancel transport work where supported. Account
changes must advance the generation too. Widget focus/text controllers remain widget-owned.
Provider lazily creates by default: choose eager creation only for a real startup requirement.

## Testing

Instantiate VMs directly with fake repositories; observe public state and notifications.
Control futures to assert loading/content/empty/failure/retry, refresh retention, out-of-order
requests and completion after dispose. Test dependency replacement and logout isolation.
Widget tests mount the real provider wrapper with fakes, exercise selectors and user actions,
then unmount and verify that owned resources close exactly once. `.value` tests must verify
that the original owner, rather than the wrapper, disposes the notifier.

Official sources (checked 2026-11-06): [provider package](https://pub.dev/packages/provider),
[ChangeNotifierProvider ownership](https://pub.dev/documentation/provider/latest/provider/ChangeNotifierProvider-class.html),
[ChangeNotifierProxyProvider](https://pub.dev/documentation/provider/latest/provider/ChangeNotifierProxyProvider-class.html).
