# Playbooks

## New App from zero

**Fast path:** `scripts/new_app.sh <name> --org com.example --title "My App"` does steps 1–5
below (verified: `flutter analyze` clean, tests pass) and prints the next commands. Read the
rest of this section for the manual path, flavors, and Firebase.

Do steps in order; the app compiles and runs after step 5, then each feature is additive.

1. **Create + clean**
   ```bash
   flutter create --org com.<org> --project-name <app> --platforms ios,android <app>
   ```
   Set `environment.sdk` to the Flutter SDK's Dart, trim generated counter app, write `analysis_options.yaml`.
2. **Pubspec baseline** — copy the starter from `app-bootstrap.md`. Add feature packages only when the feature lands. Declare assets dirs + `.env.dev`/`.env.prod`.
3. **Core foundations** (in this order, each file from the references):
   1. `core/config/app_config.dart` + `.env.sample`
   2. `core/constants/` — `string_constants.dart`, `api_constants.dart`, `app_constants.dart`, `media_constants.dart`
   3. `core/utils/app_logger.dart`
   4. `core/error/` — `exceptions.dart`, `failures.dart`, `either_extensions.dart`, `api_exception_handler.dart`
   5. `core/cubit/safe_cubit.dart`
   6. `core/usecases/usecase.dart`
   7. `core/theme/` — `app_colors.dart`, `app_text_styles.dart`, `app_theme.dart`
   8. `core/extensions/` — `context_extensions.dart`, `size_extensions.dart` (`AppSizes`)
   9. `core/storage/local_storage_service.dart` (+ `StorageKeys`)
   10. `core/network/dio_client.dart`
   11. `core/widgets/` — `k_button.dart`, `k_text_field.dart`, `image_renderer.dart`, `loading_widget.dart`, `empty_state_widget.dart`, `error_state_widget.dart`, `app_snack_bar.dart`, `bottom_sheet_divider.dart`
4. **DI** — `di/injection.dart`, `di/register_module.dart`; run build_runner; confirm `getIt<LocalStorageService>()` resolves.
5. **Bootstrap + shell** — `main.dart`, `main_dev.dart`, `main_prod.dart`, `app.dart`, `core/router/app_router.dart` with a splash route, `features/splash/presentation/pages/splash_screen.dart`. Run the app on dev flavor.
6. **Flavors** — Android/iOS config per `app-bootstrap.md`, `.vscode/launch.json`.
7. **Firebase/FCM** — `flutterfire configure`, wire `FcmService` + background handler (skip if app has no push).
8. **First real feature** — follow § New Feature below. Then verify.

## New Feature

**Fast path:** `scripts/new_feature.sh <name> --app /path/to/app` generates every file below
(sealed-state variant, codegen run, endpoint constant inserted) and prints the GoRoute snippet
to paste. Then replace the placeholder entity fields and logic. Manual order follows —
bottom-up, every step compiles before the next, route wired last.

1. **Entity** — `domain/entities/<thing>.dart` (Equatable, final fields, computed getters).
2. **Repository contract** — `domain/repositories/<feature>_repository.dart`:
   ```dart
   abstract class OrdersRepository {
     FutureEither<List<Order>> getOrders({required int page});
   }
   ```
3. **Model** — `data/models/order_model.dart` extends entity + `fromJson`/`toJson`/`copyWith` + `.g.dart`.
4. **Data source** — `data/datasources/orders_remote_data_source.dart`; abstract + `@LazySingleton(as:)` impl in the same file (plain `@lazySingleton` only if there is no abstract); uses `DioClient` + `ApiConstants`; throws typed exceptions.
5. **Repository impl** — `data/repositories/orders_repository_impl.dart`; `@LazySingleton(as: OrdersRepository)` + `with ApiExceptionHandler`; wraps each call in `safeApiCall`; maps models → entities.
6. **Use case** — `domain/usecases/get_orders.dart`; `@lazySingleton`; one-line delegation; params class extends Equatable.
7. **State** — `presentation/cubit/orders/orders_state.dart`. Sealed (fresh-app default): `OrdersInitial/OrdersLoading/OrdersSuccess/OrdersFailure`. Freezed: `initial/loading/loaded/failed`. Never mix the two naming schemes.
8. **Cubit** — `presentation/cubit/orders/orders_cubit.dart`; `@injectable`, extends `SafeCubit`, constructor-injected use case, stale-request guard, `.fold()` into states.
9. **Widgets** — `presentation/widgets/order_tile_widget.dart` etc.; consume state passed in; no cubit lookups inside leaf widgets unless truly local.
10. **Screen** — `presentation/pages/orders_screen.dart` with `static const path/routeName`; `BlocProvider(create: (_) => getIt<OrdersCubit>()..load())` or an `OrdersProvider` wrapper if it takes args; `BlocConsumer` + `switch`/`maybeMap` over states; snackbar for failures; skeleton while loading.
11. **Route** — register in `core/router/app_router.dart` (or a split route file in `core/router/`). This is the last wiring step. Primitive args go in the path; a route-data class in `presentation/routes/` only when passing a whole object.
12. **Text constants** — add any new copy to `StringConstants` / `<feature>_text.dart`.
13. **Verify** — see below; write one test.

## Multi-screen feature (list + detail)

Same playbook, applied per screen:
- **One cubit per screen/flow.** A detail screen that fetches by id gets its own
  `cubit/<flow>/` pair; do not grow the list cubit. Reuse the list cubit only when the
  detail screen renders data already loaded (no new fetch) and stays on top of it.
- **One repository per feature**, multiple use cases: add `get_order_detail.dart` beside
  `get_orders.dart`; both call the same repo interface.
- **Pass primitives in the path** (`/order/:orderId` → `state.pathParameters`) and fetch
  in the detail cubit. Use a route-data class only when passing a whole object (e.g. the
  already-loaded `Order` for instant render before refresh) — see `routing.md`.
- New copy for both screens goes in the same `<feature>_text.dart` / `StringConstants`.

## Editing an existing app

Before writing code:
1. Find the closest existing feature to what you're building and read it top-to-bottom.
2. Mirror its file names, state style (sealed vs freezed), snackbar, theming, and sizing exactly.
3. Only then write — consistency with the app in front of you beats this document when they differ.

## Verify

```bash
dart format .
dart run build_runner build --delete-conflicting-outputs   # ONLY if annotations/generated code changed
flutter analyze                                   # must be zero issues
flutter test                                      # must be green
```

Test conventions (all three apps): `flutter_test` only, no mocktail/mockito.
- Hand-written fakes: `class FakeOrdersRepository implements OrdersRepository { @override FutureEither<List<Order>> getOrders(...) async => Right([...]); }`
- Cubit test: arrange fake → `blocTest`-free style or plain `await cubit.load(); expect(cubit.state, isA<OrdersLoaded>());` + `addTearDown(cubit.close)`.
- `SharedPreferences.setMockInitialValues({})` before storage tests.
- One test per non-trivial unit: a parser, a validator, a cubit fold. Skip trivial getters.
- Paths mirror `lib/` (`test/features/orders/presentation/cubit/orders_cubit_test.dart`).

## Definition of done

- [ ] Feature compiles in all layers, route registered, screen reachable
- [ ] Loading / empty / error / success states all handled
- [ ] Failure message surfaces via snackbar; retry where sensible
- [ ] Strings/colors/sizes from constants; no inline literals
- [ ] `flutter analyze` clean, tests pass, formatted
- [ ] Generated files rebuilt if annotations changed
- [ ] One runnable check exists for non-trivial logic
