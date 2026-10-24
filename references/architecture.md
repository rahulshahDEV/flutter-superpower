# Architecture, Folders, Naming

## Target tree (new app)

```
lib/
├── main.dart                  # thin dev entry; bootstrap in app.dart
├── main_dev.dart              # Flavor.dev → app.bootstrap()
├── main_prod.dart             # Flavor.prod → app.bootstrap()
├── firebase_options.dart      # FlutterFire generated
├── app.dart                   # App root widget: ScreenUtilInit + MaterialApp.router
├── core/                      # feature-independent except router composition
│   ├── config/                # app_config.dart (Flavor enum + AppConfig singleton)
│   ├── constants/             # api_constants.dart, app_constants.dart,
│   │                          # media_constants.dart, string_constants.dart
│   ├── cubit/                 # safe_cubit.dart
│   ├── error/                 # error.dart barrel, exceptions.dart, failures.dart,
│   │                          # api_exception_handler.dart, either_extensions.dart
│   ├── extensions/            # context_extensions.dart, datetime_extensions.dart,
│   │                          # size_extensions.dart (AppSizes), num_/string_ as needed
│   ├── models/                # shared value objects (geo_location, fcm_payload)
│   ├── network/               # dio_client.dart, presigned_upload_client.dart
│   ├── router/                # app_router.dart (+ app_route_extras.dart, guards)
│   ├── services/              # fcm_service.dart, fcm_background_handler.dart,
│   │                          # fcm_tap_route_handler.dart
│   ├── storage/               # local_storage_service.dart (+ StorageKeys)
│   ├── theme/                 # app_colors.dart, app_text_styles.dart, app_theme.dart
│   ├── usecases/              # usecase.dart (UseCase<T, Params> + NoParams)
│   ├── utils/                 # app_logger.dart, input_validators.dart, ...
│   ├── widgets/               # k_button.dart, k_text_field.dart, image_renderer.dart,
│   │                          # empty/error/loading state, app_snack_bar.dart,
│   │                          # bottom_sheet_divider.dart, shimmer wrappers
│   └── core.dart              # barrel: re-export core/ submodules
├── di/
│   ├── injection.dart         # getIt + @InjectableInit configureDependencies()
│   ├── injection.config.dart  # GENERATED — gitignored, never edit
│   └── register_module.dart   # @module: SharedPreferences, FirebaseMessaging, ...
└── features/
    └── <feature>/
        ├── data/
        │   ├── datasources/<feature>_remote_data_source.dart   # abstract + impl same file
        │   ├── models/<thing>_model.dart (+ .g.dart)
        │   ├── repositories/<feature>_repository_impl.dart
        │   └── services/                                       # feature-local stateful services
        ├── domain/
        │   ├── entities/<thing>.dart          # Equatable, plain
        │   ├── repositories/<feature>_repository.dart   # abstract, FutureEither<T>
        │   └── usecases/<name>.dart           # class <Name> implements UseCase<T, Params>
        └── presentation/
            ├── cubit/<flow>/<flow>_cubit.dart + <flow>_state.dart
            ├── pages/<name>_screen.dart
            ├── widgets/<name>_widget.dart
            ├── routes/<name>_route_data.dart  # typed state.extra payloads
            ├── skeleton/ or shimmer/          # page skeletons mirroring layout
            └── utils/                         # _utils.dart, _navigation.dart, _sync.dart
```

Simple features may be `presentation/`-only (splash) or flat (`onboarding`). Do not
create empty layers "for later" — a screen with no API call does not need data/domain.

## Layer rules

- `core/` is cross-cutting. The existing `core/router/` directory is an explicit application
  composition boundary and may import screens; DI is another composition boundary. No other
  core service/widget may import a feature. Keep business rules out of route assembly.
  Existing apps with `app/router/` keep that layout; don't migrate folders just for this rule.
- `domain/` has no Flutter or plugin imports; pure Dart packages such as `dartz`/`equatable`
  are allowed. Repository contracts expose domain types, never Dio responses or widget types.
- `data/` implements domain repos, owns models/JSON/plugins.
- `presentation/` owns cubits/pages/widgets. Screens never call data sources or Dio.
- One public responsibility per file; colocate sealed state variants, closely related enums,
  and a data-source interface/implementation where the templates do so.
- Dependencies point inward: presentation → domain ← data. UI may import data models only via entities; prefer domain types in cubits.
- Feature-to-feature imports are allowed for navigation helpers only (`_navigation.dart`); shared code moves to `core/`.

## Naming table (enforced)

| Kind | Suffix | Example |
|---|---|---|
| Screen/page | `_screen.dart` (some apps use `_page.dart` — match the app you're in) | `profile_screen.dart` → `ProfileScreen` |
| Reusable widget | `_widget.dart` | `profile_card_widget.dart` |
| Bottom sheet | `_bottom_sheet.dart` | `add_pet_bottom_sheet.dart` |
| Modal sheet | `_sheet.dart` | `logout_sheet.dart` |
| Provider wrapper | `_provider.dart` | `search_provider.dart` |
| Cubit / state | `_cubit.dart` / `_state.dart` | `login_cubit.dart` / `login_state.dart` |
| Use case | `_usecase.dart` or verb name | `sign_in_usecase.dart` / `get_pet.dart` |
| Repository | `_repository.dart` / `_repository_impl.dart` | `auth_repository_impl.dart` |
| Data source | `_remote_data_source.dart` | `auth_remote_data_source.dart` |
| Model | `_model.dart` | `app_user_model.dart` |
| Entity | `<thing>.dart` | `app_user.dart` |
| Route data | `_route_data.dart` | `pet_profile_route_data.dart` |
| Extensions / utils | `_extensions.dart` / `_utils.dart` | `context_extensions.dart` |
| Constants | `_constants.dart` or named (`api_constants.dart`) | `storage_keys.dart` |
| Text constants | `_text.dart` | `profile_text.dart` |
| Test | `_test.dart` | `search_cubit_test.dart` |

Files `snake_case.dart`; classes `UpperCamelCase`; private widgets `_Prefixed`.

## Imports & style

- Absolute imports only: `package:<app_name>/core/core.dart`, `package:<app_name>/features/...`.
- Order: `dart:` → blank → external `package:` → blank → `package:<app>/` (core → di → features).
- Barrels only for `core/core.dart`, `core/widgets/widgets.dart`, `core/error/error.dart`, `core/enums/enums.dart`. No feature-internal barrels.
- Dart 3 idioms: `switch` expressions, pattern matching (`if (x case final v?)`), sealed classes, `final class`, records for tuples, `unawaited()`.
- No `!` non-null assertions. Required fields + early returns + patterns instead.
- `withValues(alpha: x)` not `withOpacity`.
- `const` wherever possible; `ListView.builder` for lists.
- Comments: `///` doc comments explaining WHY on non-obvious logic. No AI/placeholder comments, no narration.
- Formatting gate: `dart format` (80-col), `flutter analyze` clean, `flutter test` green.

## Constants conventions

Every constants class is uninstantiable:

```dart
class AppConstants {
  AppConstants._();
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const int pageSize = 20;
}
```

- `StringConstants` — all user-visible copy, section-commented (`// ─── Auth ───`), parameterized strings as `static String fn(x) => '...'`.
- `ApiConstants`/`ApiEndpoints` — paths + `static String byId(String id) => '$base/$id'`.
- `MediaConstants`/`Media` — asset paths (`assets/images/...`).
- `StorageKeys` — SharedPreferences keys only.
- `ErrorConstants` — default failure messages.
- Enums carry metadata: `apiValue`, `key`, `displayName`, plus `static fromApiValue` throwing `ArgumentError` and `bool get isX` helpers.

## Feature skeleton (copy for a new feature)

```
features/orders/
├── data/
│   ├── datasources/orders_remote_data_source.dart
│   ├── models/order_model.dart
│   └── repositories/orders_repository_impl.dart
├── domain/
│   ├── entities/order.dart
│   ├── repositories/orders_repository.dart
│   └── usecases/get_orders.dart
└── presentation/
    ├── cubit/orders/orders_cubit.dart
    ├── cubit/orders/orders_state.dart
    ├── pages/orders_screen.dart
    ├── widgets/order_tile_widget.dart
    └── routes/orders_route_data.dart
```

Build order: entity → repository contract → model → data source → repo impl → use case →
state → cubit → widgets → screen → route. Bottom-up; each step compiles before the next.

## Decisions beyond folders

- Put a rule beside the data and lifecycle it governs. Domain owns business invariants;
  data owns transport/persistence mapping; presentation owns display state and user intent.
  Shared infrastructure goes in core only after genuine cross-feature use.
- Give mutable state one owner. Repositories own cache/write consistency; Cubits own flow
  state; widgets own focus/controllers. Define disposal and cancellation at creation time.
- Constructors make dependencies visible. Avoid service-locator calls hidden inside domain
  methods or helpers. Add an abstraction for a useful boundary, not one per method.
- Keep the house use-case seam for asynchronous features; don't create data/domain layers
  for static screens. Separate DTOs from richer domain entities when transport inheritance
  would violate domain invariants; prefer mapping over weakening the model.
- Snapshot mutable collections before exposing state. `final List<T>` only prevents
  reassignment. Do not mutate emitted data or share a writable cache list with a Cubit.
- Before changing a shared contract, inspect all callers and serialization/storage formats.
  Stage migrations with compatibility and rollback where persisted data is involved.
- Verify boundaries through meaningful tests: domain invariants, repository mapping,
  out-of-order requests, state preservation on failure, and disposal. A neat folder tree
  alone does not prove clean architecture.
