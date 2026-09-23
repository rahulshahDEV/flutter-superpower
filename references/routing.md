# Routing (go_router)

One router per app, centralized in `core/router/`. Screens own their path.

## AppRouter

```dart
// core/router/app_router.dart
@singleton
class AppRouter {
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  GoRouter get router => _router;

  late final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: SplashScreen.path,
    debugLogDiagnostics: AppConfig.instance.isDev,
    redirect: (context, state) => getIt<AppRouteGuard>().handleRedirect(state),
    routes: [
      GoRoute(
        path: SplashScreen.path,
        name: SplashScreen.routeName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: OrdersScreen.path,
        name: OrdersScreen.routeName,
        builder: (context, state) => const OrdersProvider(),
      ),
      GoRoute(
        path: OrderDetailScreen.path, // '/order/:orderId'
        name: OrderDetailScreen.routeName,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'];
          if (orderId == null || orderId.isEmpty) return const OrdersScreen(); // safe fallback
          return OrderDetailProvider(orderId: orderId);
        },
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text(StringConstants.pageNotFound))),
  );
}
```

Large route sets split into builders, all in `core/router/`: `app_auth_routes.dart`,
`app_shell_routes.dart`, `app_profile_routes.dart` — each returns `List<RouteBase>` and
is spread into `routes:`.

## Screen path constants

```dart
class OrdersScreen extends StatelessWidget {
  static const String path = '/orders';
  static const String routeName = 'orders';
  ...
}

// parameterized:
class OrderDetailScreen extends StatelessWidget {
  static const String path = '/order/:orderId';
  static const String routeName = 'order-detail';
  static String pathFor(String id) => '/order/$id';
}
```

Never hardcode a route string at a call site; always reference the screen's constant.

## Passing arguments

**Default: primitives (ids) go in the path.** The router passes the primitive to the
provider; the cubit fetches the full object. Query parameters are only a deep-link
fallback:

```dart
GoRoute(
  path: PetProfileScreen.path, // '/pet/:petId'
  name: PetProfileScreen.routeName,
  builder: (context, state) {
    final petId = state.pathParameters['petId'] ??
        state.uri.queryParameters['petId']; // deep-link fallback
    if (petId == null || petId.isEmpty) return const HomeScreen(); // safe fallback
    return PetProfileProvider(petId: petId); // cubit fetches by id
  },
),
```

**Whole object** (e.g. already-loaded item for instant render): typed route-data class
in `presentation/routes/` parsed from `state.extra` with `fromExtra`:

```dart
// presentation/routes/edit_pet_route_data.dart
class EditPetRouteData {
  const EditPetRouteData({required this.pet, this.fromOnboarding = false});
  final Pet pet;
  final bool fromOnboarding;

  static EditPetRouteData? fromExtra(Object? extra) => switch (extra) {
        EditPetRouteData data => data,
        Pet pet => EditPetRouteData(pet: pet),
        _ => null,
      };
}
```

```dart
GoRoute(
  path: EditPetScreen.path,
  name: EditPetScreen.routeName,
  builder: (context, state) {
    final data = EditPetRouteData.fromExtra(state.extra);
    if (data == null) return const PetsScreen(); // safe fallback
    return EditPetProvider(data: data);
  },
),
```

Never `extra as Foo`. Parse args in the router (not the screen); the screen stays args-free.
Do not parse the same argument in both the router and the cubit — router passes, cubit fetches.

## Navigation from UI

Context extensions in `core/extensions/context_extensions.dart`:

```dart
extension ContextExtensions on BuildContext {
  void goTo(String path, {Object? extra}) => go(path, extra: extra);
  void goReplace(String path, {Object? extra}) => replace(path, extra: extra);
  Future<T?> pushRoute<T>(String path, {Object? extra}) => push<T>(path, extra: extra);
  void popRoute<T extends Object?>([T? result]) => pop(result);
  bool get canPop => GoRouter.of(this).canPop();
}
```

Screens call `context.goTo(OrdersScreen.path)` — never raw `context.go(...)` or
`Navigator.push` (dialogs/sheets via `showDialog`/`showModalBottomSheet` are fine).

## Shells / bottom navigation

Two accepted approaches:

1. **IndexedStack shell (zoomies)** — one `Scaffold` + custom bottom bar; tab
   destinations are `GoRoute`s with `redirect:` that change the tab index and return the
   shell path.
2. **StatefulShellRoute.indexedStack (foundyou)** — 3 branches with per-tab
   `NavigatorKey`s, so each tab keeps its own stack. Use when tabs need independent
   push history.

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) =>
      MainNavigationPage(navigationShell: navigationShell),
  branches: [
    StatefulShellBranch(navigatorKey: _homeNavigatorKey, routes: [...]),
    StatefulShellBranch(navigatorKey: _chatNavigatorKey, routes: [...]),
  ],
)
```

## Guards / redirects

```dart
@lazySingleton
class AppRouteGuard {
  final Set<String> _protectedPrefixes = {'/orders', '/profile', '/settings'};
  final Set<String> _authRoutes = {'/sign-in', '/sign-up'};

  String? handleRedirect(GoRouterState state) {
    final isLoggedIn = getIt<LocalStorageService>().getString(StorageKeys.accessToken) != null;
    final loc = state.matchedLocation;
    if (!isLoggedIn && _protectedPrefixes.any(loc.startsWith)) return SignInScreen.path;
    if (isLoggedIn && _authRoutes.contains(loc)) return MainScreen.path;
    return null; // null = proceed
  }
}
```

A startup coordinator (`resolveLaunchDestination()`) decides intro → onboarding → auth →
main for splash.

## Deep links & FCM taps

`FcmTapRouteHandler` maps notification payload → route path (+ extra). Cold-start
payloads are consumed once the router exists (`markAppReady()` + `consumePendingNotificationRoute()`).
Unknown payloads are ignored, never throw.

## Navigation helpers

Cross-feature flows go in `presentation/utils/<flow>_navigation.dart` top-level functions
(e.g. `openUserProfile(context, userId)`), so screens don't import other features' widgets.
