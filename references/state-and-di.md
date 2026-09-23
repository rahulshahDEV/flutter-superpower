# State Management & Dependency Injection

## SafeCubit base

```dart
// core/cubit/safe_cubit.dart
abstract class SafeCubit<State> extends Cubit<State> {
  SafeCubit(super.initialState);

  void safeEmit(State state) {
    if (!isClosed) emit(state);
  }
}
```

Every cubit extends `SafeCubit` and calls `safeEmit`. Never raw `emit`.

## States — two accepted shapes

**A. Sealed Equatable (zoomies style)** — no codegen:

```dart
sealed class LoginState extends Equatable {
  const LoginState();
  @override
  List<Object?> get props => const [];
}

final class LoginInitial extends LoginState { const LoginInitial(); }
final class LoginLoading extends LoginState { const LoginLoading(); }
final class LoginSuccess extends LoginState {
  const LoginSuccess(this.session);
  final AuthSession session;
  @override
  List<Object?> get props => [session];
}
final class LoginFailure extends LoginState {
  const LoginFailure(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
```

**B. Freezed union (foundyou/meltdown style)** — codegen, always 4 canonical variants:

```dart
// presentation/cubit/orders/orders_state.dart — separate file, always
part 'orders_state.freezed.dart';

@freezed
class OrdersState with _$OrdersState {
  const factory OrdersState.initial() = _Initial;
  const factory OrdersState.loading() = _Loading;
  const factory OrdersState.loaded({required List<Order> orders}) = _Loaded;
  const factory OrdersState.failed({required Failure failure}) = _Failed;
}
```

(Some existing apps colocate state via `part` in the cubit file — that is app variance.
New code: separate `_state.dart` file.)

Rules: freezed names are `initial/loading/loaded/failed`; sealed names are
`Initial/Loading/Success/Failure`. Fresh app defaults to sealed; use freezed only when
states carry many fields or the app already uses freezed. No booleans like `isLoading`
inside `loaded` — model the variant. Paginated states may add
`page/hasReachedMax/isLoadingMore` fields plus computed getters (`bool get canLoadMore`).

## Cubit

```dart
@injectable
class OrdersCubit extends SafeCubit<OrdersState> {
  OrdersCubit(this._getOrders) : super(const OrdersState.initial());

  final GetOrders _getOrders;
  int _latestRequestId = 0;

  Future<void> load() async {
    final requestId = ++_latestRequestId;
    safeEmit(const OrdersState.loading());

    final result = await _getOrders(const NoParams());
    if (isClosed || requestId != _latestRequestId) return; // stale guard

    result.fold(
      (failure) => safeEmit(OrdersState.failed(failure: failure)),
      (orders) => safeEmit(OrdersState.loaded(orders: orders)),
    );
  }
}
```

Cubit rules:
- Depends only on use cases / repositories (constructor-injected).
- No `BuildContext`, no navigation, no `TextEditingController`, no `SnackBar`, no `getIt` lookups inside.
- Validation before API calls → `safeEmit(XFailure(ValidationFailure(StringConstants.missingX)))`.
- Multi-value results: records `Future<({Failure? failure, Order? order})>` or extra state fields.
- Deferred side effects that need context are exposed as state the UI listens to, or return a record the screen acts on.

## Binding to UI

**Simple screen** — create cubit in the screen's own `BlocProvider`:

```dart
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  static const String path = '/orders';
  static const String routeName = 'orders';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrdersCubit>()..load(),
      child: const _OrdersView(),
    );
  }
}
```

**Screen with args / heavy init** — provider wrapper widget, living in
`presentation/widgets/<flow>_provider.dart`:

```dart
class OrdersProvider extends StatelessWidget {
  const OrdersProvider({required this.userId, super.key});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrdersCubit>()..init(userId),
      child: const OrdersScreen(),
    );
  }
}
```

Router builds `OrdersProvider(userId: ...)`; the screen stays args-free.
Constructor convention: pass individual fields (1–3 args) straight through; pass the
whole route-data object (`OrdersProvider(data: data)`) when the payload is large or
already parsed by the router. Init method naming: `init(args)` when the cubit needs
arguments, `load()` when it just fetches — never both.

**Consumption:**

```dart
BlocConsumer<OrdersCubit, OrdersState>(
  listener: (context, state) {
    if (state is OrdersFailure) AppSnackBar.showError(context, state.failure.message);
    if (state is OrderSaved) context.popRoute();
  },
  builder: (context, state) => switch (state) {
    OrdersInitial() || OrdersLoading() => const LoadingWidget(),
    OrdersFailure(:final failure) => ErrorStateWidget(message: failure.message, onRetry: ...),
    OrdersSuccess(:final orders) when orders.isEmpty => const EmptyStateWidget(...),
    OrdersSuccess(:final orders) => _OrderList(orders: orders),
  },
)
```

Sealed shape shown (`OrdersInitial/OrdersLoading/OrdersSuccess/OrdersFailure`). Freezed apps
use `state.maybeMap(...)` / `state.maybeWhen(...)` / `state.mapOrNull(...)` instead.

**App-root cubits** — only for cross-screen state (current user, theme, badges, cart):

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => getIt<CurrentUserCubit>()..loadFromStorage()),
    BlocProvider.value(value: getIt<NotificationBadgeCubit>()), // singleton cubit
  ],
  child: MaterialApp.router(...),
)
```

## Local UI state

Ephemeral state does NOT get a cubit. Always local:
- `TextEditingController`s, `FocusNode`s, animation controllers.
- Toggles: obscure-password, expansion tiles, selected tab, scroll position.
- Pure layout state: `setState` or `ValueNotifier<T>` (+`ValueListenableBuilder`) when the value must be passed down.
- Flow controllers spanning a few screens with no async work: `ValueNotifier` (or a small `InheritedWidget` scope for wide flows).

A cubit is warranted only when at least one is true:
- The state comes from an async call (API/storage) and must survive rebuilds and navigation.
- Multiple widgets/screens read or mutate the same **async or state-machine** state (shared state with no async work stays a `ValueNotifier`/`InheritedWidget`).
- The state is a real state machine (loading/success/failure/pagination).

Rule of thumb: if it can be expressed with `setState` and never leaves one widget subtree, it is not a cubit.

## DI — get_it + injectable

```dart
// di/injection.dart
final getIt = GetIt.instance;

@InjectableInit(initializerName: 'init', preferRelativeImports: false, asExtension: true)
Future<void> configureDependencies({bool reset = false}) async {
  if (reset) await getIt.reset();
  await getIt.init();
}
```

```dart
// di/register_module.dart
@module
abstract class RegisterModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @lazySingleton
  FirebaseMessaging get firebaseMessaging => FirebaseMessaging.instance;

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();
}
```

Annotation rules:

| Thing | Annotation |
|---|---|
| Cubit (per screen) | `@injectable` |
| Cubit (app-wide/singleton) | `@Singleton()` |
| Repository impl | `@LazySingleton(as: XRepository)` |
| Data source impl | `@LazySingleton(as: XRemoteDataSource)` — always register against the abstract class, since features depend on the interface. Plain `@lazySingleton` only if the data source genuinely has no abstract class (presentation-only features, e.g. splash). |
| Use case | `@lazySingleton` |
| Clients/services/singletons | `@lazySingleton` |
| Router | `@singleton` |
| Plugins / prefs | `@module` + `@preResolve` |

Rules:
- Never hand-edit `injection.config.dart`; regenerate with
  `dart run build_runner build --delete-conflicting-outputs`.
- `getIt<X>()` is called in `create:` of providers or route builders — not inside widget `build` bodies, and never before `configureDependencies()` completes.
- `main()` order: `dotenv.load` → `AppConfig.initialize` → `Firebase.initializeApp` → `configureDependencies()` → `getIt<FcmService>().initialize()` → `runApp`.
- Dispose lifecycle services with `@disposeMethod` where supported.
