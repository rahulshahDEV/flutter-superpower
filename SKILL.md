---
name: flutter-superpower
description: Use when building, scaffolding, or extending any Flutter app, project, feature, screen, cubit, repository, use case, API integration, theme, router, model, or Flutter architecture decision. Triggers on flutter app, new flutter project, feature-first clean architecture, cubit, bloc, get_it, injectable, go_router, dio, Either Failure, SafeCubit, AppConfig, FlavorConfig, ScreenUtil, KButton, KTextField, AppColors, AppTextStyles, route data, presigned upload, FCM. Enforces the owner's house style (proven across zoomies, found-you, meltdown) instead of generic Flutter advice.
---

# Flutter Superpower

Build any Flutter app the owner's way: **feature-first clean architecture,
Cubits + GetIt/Injectable, GoRouter, Dio + Either, centralized theme/strings,
ScreenUtil sizing, K-widget design system, dev/prod flavors.**

Reference implementations: `/Volumes/mcoders/zoomies`,
`/Volumes/mcoders/found-you-flutter`, `/Volumes/mcoders/meltdown/flutter-app`.
When a detail is missing here, read the matching app instead of inventing.

**Scope discipline (built in):** structure is non-negotiable, scope is lazy. Stop at
the first ladder rung that holds — (1) does it need to exist? (2) already in this
codebase (`core/widgets`, `core/utils`)? (3) Flutter/Material SDK? (4) platform feature?
(5) existing dependency? (6) one widget/one line? (7) only then: minimum working code.
Never add a package, abstraction, cubit, or widget the feature doesn't use. Full rules:
`references/ponytail.md`.

## The 12 laws

1. Feature-first: `lib/features/<feature>/{data,domain,presentation}`. `core/` never imports `features/`.
2. State = `flutter_bloc` Cubits only. Extend `SafeCubit`, emit via `safeEmit`. No Bloc events, no Riverpod/Provider/GetX.
3. Cubit + State live in separate files under `presentation/cubit/<flow>/`. Four canonical variants: sealed → `Initial/Loading/Success/Failure`; freezed → `initial/loading/loaded/failed`. Fresh app default: **sealed** (no codegen); switch to freezed only when states carry many fields or the app already uses freezed. Joining an app? Mirror its choice.
4. Cubits never hold `BuildContext`, navigate, or own `TextEditingController`s. UI navigates; cubit folds `Either`.
5. DI = `get_it` + `injectable`. `@injectable` cubits, `@LazySingleton(as: XRepository)` impls, `@module` for plugins. Never `GetIt` inside widgets except `getIt<X>()` at provider/route creation.
6. Routing = `go_router`, one `AppRouter`. Every screen owns `static const String path` + `routeName`. Args via typed `state.extra` route-data classes with a `fromExtra` fallback. Navigate with `context.goTo/pushRoute/popRoute/goReplace`.
7. Data flow = data source throws typed exceptions → repository wraps `safeApiCall`/`errorHandler` → returns `FutureEither<T>` (`Either<Failure, T>`) → cubit `.fold()` → UI shows failure message. One `Failure` type family per app.
8. Models: Equatable entities (plain, all-final, `props`); wire models `@JsonSerializable` **extend** entities; generated `.g.dart`/`.freezed.dart` are gitignored and rebuilt, never hand-edited.
9. All user-visible strings, asset paths, API paths, colors, and storage keys live in constants classes (`StringConstants`, `MediaConstants`/`Media`, `ApiConstants`/`ApiEndpoints`, `StorageKeys`, `AppColors`/`Colours`). Never inline a string or hex color in a widget.
10. Sizing via `flutter_screenutil` (`ScreenUtilInit` 390×844 or 375×812) + `.w/.h/.r/.sp` + `AppSizes` spacing/radius tokens. Never raw `EdgeInsets.only(left: 16)`.
11. Reuse the design system before writing UI: `KButton`, `KTextField`, `ImageRenderer`, `EmptyStateWidget`, `ErrorStateWidget`, `LoadingWidget`, shimmer wrapper, custom snackbar (`AppSnackBar`/`CustomSnackBar`), `BottomSheetDivider`. New shared widget → promote to `core/widgets/` only when a second feature needs it.
12. Config via flavors `dev`/`prod` (`lib/main_dev.dart`, `lib/main_prod.dart`) + `flutter_dotenv` + `AppConfig`/`FlavorConfig`. Quality gate: `dart format .` → (`fdev gen`, or `dart run build_runner build --delete-conflicting-outputs`, if annotations/generated code changed) → `flutter analyze` → `flutter test`. Prefer the owner's `fdev` CLI for builds/codegen — see `references/fdev.md`.

## Workflow

```
New app?      → references/playbooks.md § New App (order: create+clean → pubspec →
                core foundations → di → bootstrap+shell → flavors → Firebase →
                first feature → verify)
New feature?  → references/playbooks.md § New Feature (bottom-up: entity → repo
                contract → model → data source → repo impl → use case → state →
                cubit → widgets → screen → route → constants; wire route last)
Editing?      → read the closest existing feature first, mirror it exactly
Debugging?    → diagnose from the failure layer inward (UI ← cubit ← repo ← data source)
```

Every non-trivial unit ships with ONE runnable check (a small widget/unit test or
fake-repo cubit test) — see `references/playbooks.md § Verify`.

## Quick reference

| Concern | Decision |
|---|---|
| State | `SafeCubit<State>` + sealed/freezed state, `BlocProvider(create: (_) => getIt<XCubit>())` |
| Screen with args | `XProvider` wrapper in `presentation/widgets/<flow>_provider.dart`; `getIt<XCubit>()..init(args)` in `create`; simple screens call `..load()` directly in the screen's own `BlocProvider` |
| DI | `@injectable` / `@lazySingleton` / `@LazySingleton(as:)` / `@module` + `@preResolve` |
| Routing | `GoRoute(path: XScreen.path, name: XScreen.routeName, builder: ...)` |
| Network | `DioClient` (`@lazySingleton`) with auth interceptor + pretty logger (dev only) |
| Result | `FutureEither<T>` + `EitherX` (`valueOrNull`, `handle`) + `safeApiCall` mixin |
| Errors to user | `AppSnackBar.showError(context, failure.message)` in `BlocListener` |
| Theme | `AppColors` palette → `AppSemanticColors` ThemeExtension → `context.semanticColors` (or `AppColors` + `context.theme` for foundyou-style) |
| Text | `AppTextStyles.x.copyWith(color: ...)` — never raw `TextStyle(fontSize:)` |
| Storage | `LocalStorageService` (SharedPreferences) + `StorageKeys`; secrets → `flutter_secure_storage` |
| Logging | `AppLogger.d/i/w/e` — dev-only, never `print` |
| Firebase | Core + Messaging only (unless app needs more). `FcmService` + `@pragma('vm:entry-point')` background handler |
| Uploads | presigned URL client, never multipart through the auth client |
| Simplest solution | climb the ladder in `references/ponytail.md` before writing anything new |

## References

| File | Load when |
|---|---|
| `references/architecture.md` | folder layout, naming table, layer rules, feature skeleton |
| `references/state-and-di.md` | cubits, states, providers, injectable wiring, local UI state |
| `references/routing.md` | go_router, route data, guards, shells/bottom nav |
| `references/networking-and-errors.md` | Dio, interceptors, token refresh, Either, failures, logging |
| `references/models-and-storage.md` | entities vs models, JSON, SharedPreferences, secure storage |
| `references/theme-and-design-system.md` | colors, typography, sizing, K-widgets, strings |
| `references/app-bootstrap.md` | main(), flavors, DI boot, Firebase/FCM, pubspec starter |
| `references/playbooks.md` | building a new app or feature end-to-end + verification |
| `references/ponytail.md` | scope discipline: what to skip, reuse, or delete; anti-over-engineering |
| `references/fdev.md` | owner's `fdev` CLI: codegen, builds, clean, env, keystores, swagger models |

## Common mistakes

| Mistake | Fix |
|---|---|
| `BlocProvider` at app root for a screen cubit | create it in the route builder / provider widget |
| Business logic in widget | move to cubit; widget only reads state + calls methods |
| Raw hex color / inline string | constants file |
| New package for what core already has | search `core/widgets`, `core/utils` first |
| `extra as MyArgs` unchecked | route-data class with `fromExtra` + fallback screen |
| Editing `.g.dart` / `injection.config.dart` | change the source + run build_runner |
| Nested `FutureBuilder` for API state | cubit state machine |
| Relative imports in feature code | absolute `package:<app>/...` imports |
| `!` non-null assertions | required fields, `case final x?`, early return |
| `print()` | `AppLogger` |
