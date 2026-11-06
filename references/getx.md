# GetX Architecture

Apply `state-selection.md` first. Use the installed `get` package APIs; do not mix stable
GetX 4 examples and prerelease GetX 5 APIs. GetX's state, DI and routing are independent
choices: preserve the app's router rather than replacing it just to use a controller.

## Feature-first structure

```text
features/orders/
  data/datasources/orders_remote_data_source.dart
  data/repositories/orders_repository_impl.dart
  domain/entities/order.dart
  domain/repositories/orders_repository.dart
  presentation/controllers/orders_controller.dart
  presentation/state/orders_state.dart
  presentation/bindings/orders_binding.dart
  presentation/pages/orders_screen.dart
  presentation/widgets/order_tile.dart
```

Controller is a presentation adapter, not a repository or HTTP client. Constructor-inject
plain repository/use-case contracts. Keep Get, Rx and GetxController out of domain/data.
A feature binding composes the controller; root composition owns app/session dependencies.
Limit Get.find to composition/view boundaries; never hide lookups in repository methods.
Do not also register the same service in GetIt/Injectable.

## State and rendering

- Choose Obx/GetX reactive state or GetBuilder's explicit update model per flow; avoid
  maintaining the same state in both. Obx must read its observable inside its builder;
  keep the observed subtree small. GetBuilder updates must target the intended IDs.
- Prefer one Rx immutable snapshot for a multi-field flow. Map repository Either into
  coherent initial/loading/empty/content/failure states; keep content during refresh and
  track row/action failures independently. Avoid unrelated Rx booleans that contradict.
- Prefer assigning a new snapshot/collection to mutating an entity invisibly. Keep Rx
  private and expose only the read/command surface consumers need.
- Start load in a chosen controller lifecycle or explicit route initialization, once.
  Do not call Get.put or initiate fetches on every widget build. UI owns navigation and
  transient feedback even though Get permits context-free global navigation.

## Route ownership and cleanup

With Get routing, associate a Bindings implementation with each GetPage and use lazy
controller registration when appropriate. Inspect SmartManagement mode and registration
options: route cleanup depends on them. Avoid permanent screen controllers and `fenix`
without a deliberate recreation policy. GetxService is for deliberate app-wide services,
not a default base class for every controller.

For GoRouter/Navigator, do not assume GetPage bindings or automatic route cleanup run.
Use a route wrapper with an explicit create/register/dispose contract (or directly own a
controller without global registration). For direct ownership, the wrapper must invoke
the installed version's supported initialization and teardown lifecycle exactly once;
construction alone does not run Get-managed lifecycle hooks. Remove that route's registration on teardown;
never delete a shared controller. Multiple instances require stable distinct tags and the
same tag at every registration/lookup/delete; test simultaneous detail routes.

Cancel streams/timers and dispose Workers from ever/debounce/interval in onClose; call
super.onClose. Widget text/focus controllers stay widget-owned. Check closed status and
request identity after awaits before publishing results. `onClose` alone does not cancel
futures or stop stale results overwriting later requests. Session changes must invalidate
old work and delete/reset user-scoped registrations; infrastructure has a separate lifetime.

## Testing

Construct controllers with fake repositories where possible; test intent → state through
public APIs. For global DI/routing tests enable the supported Get test mode and reset the
registry in teardown; restore test settings. Test binding entry/exit, reopening a route,
multiple tags, Worker/subscription disposal, failure/retry, latest-request wins, completion
after close and account reset. Widget tests must exercise the selected router's actual
ownership wrapper; a direct controller unit test cannot prove route cleanup.

Official source (checked 2026-11-06): [Get package documentation](https://pub.dev/packages/get)
for state models, Bindings, SmartManagement, Workers and lifecycle APIs.
