---
name: flutter-superpower
description: Recommend packages and integration approaches, or build, extend, audit, debug and refactor Flutter apps with feature-first architecture, Bloc/Cubit, Riverpod, Provider or GetX, stack-appropriate DI, and deliberate UI and platform decisions. Use for Flutter implementation, native integration/debugging, and Codemagic/fastlane/Shorebird delivery; existing project conventions take priority over these defaults.
license: MIT
metadata:
  version: "2.13.0"
---

# Flutter Superpower

Build with **feature-first architecture, selected state/DI, GoRouter, Dio + Either,
centralized theme/strings, ScreenUtil, K-widgets and dev/prod flavors.**

**Scope:** follow project conventions; add only what the task uses (`references/ponytail.md`).

## When NOT to use

- Standalone non-Flutter apps or Dart CLIs; native integration inside a Flutter app is in scope.
- Throwaway snippets with no app context; typo/one-line copy fixes.
- Conflicting house style: follow the project unless migration is requested.

## Senior mode — own the task

Advice-only requests → `references/feature-advice.md`; otherwise implement and verify.

1. **Profile before changing** — inspect pubspec, `lib/`, routing, DI, state, networking,
   models, widgets, theme, tests, platform config, env. State the profile
   before planning.
2. **Priority:** explicit choice > project conventions > defaults. Greenfield → select state/DI first.
   Existing project → mirror the project and
   improve incrementally. Migration → only when explicitly requested, staged, verified
   after each stage.
3. **Decide before coding:** observable acceptance, ownership, reuse, blast radius (`rg`
   dependents); substantial work → `references/task-planning.md`.
4. **Own required work:** state, validation, DI, routes, constants, platform config and tests.
   Ask when blocked.
5. **Self-review** architecture, scope, UI, correctness, security and regression; fix findings,
   verify.
6. **Implementation evidence:** Implemented / Files changed /
   Verification (format, analyze, test, build) / Not verified / Notes.

Behavior: `references/senior-mode.md`. Audits: `references/auditing.md`.

## The 12 laws

1. Feature-first: `lib/features/<feature>/{data,domain,presentation}`. `core/` never imports `features/`, except route assembly in `core/router/`.
2. Select state/DI first: user choice > existing conventions > Cubit default. Read `references/state-selection.md`; Riverpod, Provider and GetX are supported. Keep one owner per state; no implicit migration.
3. Cubit: separate files under `presentation/cubit/<flow>/`. Default sealed states: `Initial/Loading/Success/Failure`; freezed: `initial/loading/loaded/failed` for existing/field-heavy apps. Mirror the existing state shape.
4. State owners never hold `BuildContext`, navigate, or own `TextEditingController`s. UI navigates; state owners map repository results.
5. Cubit default DI = `get_it` + `injectable`. `@injectable` cubits, `@LazySingleton(as: XRepository)` impls, `@module` for plugins. Never `GetIt` inside widgets except `getIt<X>()` at provider/route creation.
6. Honor the selected/existing router. For default `go_router`/`AppRouter`: screens own `static const String path` + `routeName`. IDs in paths, shareable filters in queries; transient objects via typed `state.extra` with a `fromExtra` fallback. Navigate with `context.goTo/pushRoute/popRoute/goReplace`.
7. Data flow = data source throws typed exceptions → repository wraps `safeApiCall`/`errorHandler` → returns `FutureEither<T>` (`Either<Failure, T>`) → selected state adapter → UI shows failure message. One `Failure` type family per app.
8. Models: Equatable entities with final fields; `@JsonSerializable` wire models extend entities by default (mapping exception: `architecture.md`). Generated `.g.dart`/`.freezed.dart` are gitignored and rebuilt, never hand-edited.
9. Centralize copy, assets, API paths, colors and storage keys in project constants/localizations. No inline user-facing strings or hex colors in widgets.
10. Sizing via `AppSizes` tokens and bounded ScreenUtil design scaling, applied once. Constraints choose layouts; preserve user text scaling and logical-pixel touch minimums.
11. Reuse the design system before writing UI: `KButton`, `KTextField`, `ImageRenderer`, `EmptyStateWidget`, `ErrorStateWidget`, `LoadingWidget`, shimmer wrapper, custom snackbar (`AppSnackBar`/`CustomSnackBar`), `BottomSheetDivider`. New shared widget → promote to `core/widgets/` only when a second feature needs it.
12. Config via flavors `dev`/`prod` (`lib/main_dev.dart`, `lib/main_prod.dart`) + `flutter_dotenv` + `AppConfig`/`FlavorConfig`. Quality gate: `dart format .` → (`fdev gen`, or `dart run build_runner build --delete-conflicting-outputs`, if annotations/generated code changed) → `flutter analyze` → `flutter test`. Prefer the owner's `fdev` CLI for builds/codegen — see `references/fdev.md`.

## Workflow

```
Suggest/compare integration? → references/feature-advice.md (recommendation + migration path)
UI work?      → references/ui-workflow.md (brief, states, implementation, visual evidence)
State stack?  → references/state-selection.md, then the selected stack guide
New Cubit app? → scripts/new_app.sh <name>; then references/playbooks.md § New App
                (flavors, Firebase, manual path)
Cubit feature? → scripts/new_feature.sh <name> --app <dir> (all layers + codegen + route
                snippet); manual order in references/playbooks.md § New Feature
Existing app? → REQUIRED: references/senior-mode.md (profile first; project conventions
                beat these defaults), then mirror the closest existing feature
Bug?          → REQUIRED: references/debugging.md; native/runtime → native-diagnostics.md
CI/CD or OTA? → references/fastlane-codemagic.md → the matching setup/operations guide
Tests?        → REQUIRED: references/testing.md
Audit?        → REQUIRED: references/auditing.md + scripts/audit.sh <app> [--tests] [--perf]
Reviewing?    → REQUIRED: references/reviewing.md
Large exploration/review? → REQUIRED: references/agent-delegation.md
Migration?    → references/senior-mode.md § Migration (explicit request only, staged)
Ship to a store?   → REQUIRED: references/play-console.md (Play) or
                appstore-console.md (Apple)
Optimize?     → references/app-optimization.md (level-wise; implement / plan / skip)
```

Behavior needs a runnable check (`references/testing.md`).

## Quick reference

| Concern | Decision |
|---|---|
| State/DI | Explicit choice or existing stack; otherwise Cubit. Scripts/templates generate Cubit only; alternatives use manual workflow (`state-selection.md`) |
| Cubit screen with args | `XProvider` wrapper in `presentation/widgets/<flow>_provider.dart`; `getIt<XCubit>()..init(args)` in `create`; simple screens call `..load()` directly in the screen's own `BlocProvider` |
| Result | `FutureEither<T>` + `EitherX` (`valueOrNull`, `handle`) + `safeApiCall` mixin |
| Cubit errors to user | `AppSnackBar.showError(context, failure.message)` in `BlocListener` |
| Theme | `AppColors` palette → `AppSemanticColors` ThemeExtension → `context.semanticColors` (or `AppColors` + `context.theme`) |
| Text | `AppTextStyles.x.copyWith(color: ...)` — never raw `TextStyle(fontSize:)` |
| Storage | `LocalStorageService` (SharedPreferences) + `StorageKeys`; secrets → `flutter_secure_storage` |
| Logging | `AppLogger.d/i/w/e` — dev-only, never `print` |
| Firebase | Only when required; Core + Messaging for push. `FcmService` + `@pragma('vm:entry-point')` background handler |
| Uploads | presigned URL client, never multipart through the auth client |
| Simplest solution | climb the `ponytail.md` ladder first |
| Cubit scaffolding | `scripts/new_app.sh <name>` / `scripts/new_feature.sh <name> --app <dir>`; preflight rejects incompatible apps |
| Existing project | profile first; project conventions win; improve incrementally (`references/senior-mode.md`) |
| Audit | `scripts/audit.sh <app> [--tests] [--static]` + agent review per `references/auditing.md` |
| Blocked? | report: Blocked / Evidence / Needs / Default I would use |

## References

| File | Load when |
|---|---|
| `references/architecture.md` | folder layout, naming table, layer rules, feature skeleton |
| `references/task-planning.md` | acceptance criteria, runnable slices, dependencies, resume checkpoints |
| `references/boundary-design.md` | useful interfaces, test boundaries, safe simplification |
| `references/state-selection.md` | stack choice, common boundaries, scaffold limitations |
| `references/riverpod.md` | Riverpod structure, providers, lifecycle, testing |
| `references/provider.md` | Provider structure, ChangeNotifier, ownership, testing |
| `references/getx.md` | GetX structure, bindings, reactive state, cleanup, testing |
| `references/bloc.md` | event Bloc, concurrency policy, cancellation, tests |
| `references/feature-boundaries.md` | public feature contracts, shared domain, dependency cycles |
| `references/offline-data.md` | optional local/remote ownership, queued writes, reconciliation |
| `references/persistence-migrations.md` | schema upgrades, recovery, compatibility, fixtures |
| `references/lifecycle-restoration.md` | drafts, restoration, resume, durable background work |
| `references/production-observability.md` | reporting, correlation, privacy, release health |
| `references/state-and-di.md` | cubits, states, providers, injectable wiring, local UI state |
| `references/routing.md` | go_router, route data, guards, shells/bottom nav |
| `references/networking-and-errors.md` | Dio, interceptors, token refresh, Either, failures, logging |
| `references/models-and-storage.md` | entities vs models, JSON, SharedPreferences, secure storage |
| `references/theme-and-design-system.md` | colors, typography, sizing, K-widgets, strings |
| `references/app-bootstrap.md` | startup ordering/failure, flavors, optional Firebase/FCM |
| `references/platform-ui.md` | orientation policy, edge-to-edge, system overlays, insets |
| `references/fonts.md` | system/bundled/Google Fonts delivery, licenses, offline verification |
| `references/ui-workflow.md` | screen brief, component ownership, states, visual verification |
| `references/playbooks.md` | building a new app or feature end-to-end + verification |
| `references/ponytail.md` | scope discipline: what to skip, reuse, or delete; anti-over-engineering |
| `references/fdev.md` | owner's `fdev` CLI: codegen, builds, clean, env, keystores, swagger models |
| `references/debugging.md` | any bug, crash, wrong state, or "works in debug only" |
| `references/testing.md` | test boundaries, fakes, widget/layout checks, deterministic async |
| `references/integration-testing.md` | device journeys, bindings, bootstrap, runners, CI evidence |
| `references/component-previews.md` | SDK preview support, state matrix, injected fixtures, limitations |
| `references/ci-cd.md` | GitHub Actions, secrets, release flow |
| `references/chat-realtime.md` | Socket.IO chat, E2E crypto, optimistic send |
| `references/maps-location-health.md` | map integration and routing to platform-data guides |
| `references/mobile-permissions.md` | request UX, status/recovery, settings return, prompt ownership |
| `references/permission-capabilities.md` | camera/photos, notifications, Bluetooth, files, other capabilities |
| `references/location-services.md` | GPS enablement, precision, fresh fixes, timeout/stream cleanup |
| `references/health-data.md` | health scopes, read privacy, steps aggregation, refresh ownership |
| `references/reviewing.md` | reviewing a diff: Standards + Spec axes, smell baseline |
| `references/senior-mode.md` | task ownership: profile, modes, decisions, self-review, DoD, evidence report |
| `references/auditing.md` | auditing an existing app: dimensions, severity, report format |
| `references/performance.md` | rebuilds, lists, images, startup, memory — measure before fixing |
| `references/app-optimization.md` | level-wise optimization plan with implement/plan/skip calls |
| `references/async-safety.md` | callback failures, mounted checks, cleanup |
| `references/forms-and-input.md` | validation, focus, controllers, keyboard |
| `references/adaptive-layout.md` | layouts by available width |
| `references/value-objects.md` | money, units, dates, and time |
| `references/data-export-and-restore.md` | versioned backups, safe imports, exports |
| `references/design-review.md` | visual and accessibility review before release |
| `references/design-quality.md` | anti-pattern tells, motion tokens, critique checklist |
| `references/agent-delegation.md` | parallel, read-only exploration and review when agents are available |
| `references/security.md` | secrets, log redaction, storage, transport, release hardening |
| `references/accessibility.md` | semantics, touch targets, text scaling, contrast, focus, motion |
| `references/localization.md` | StringConstants vs ARB, plurals, intl formatting, RTL |
| `references/feature-advice.md` | suggestion mode, packages vs interop, simplest plan, upgrade/exit path |
| `references/dependencies.md` | add/remove discipline, evaluation, house-pinned choices |
| `references/native.md` | Android/iOS build triage, toolchains, flavors, signing |
| `references/native-diagnostics.md` | crashes, ANRs, logs, symbols, Instruments/Perfetto |
| `references/platform-channels.md` | Kotlin/Swift bridges, Pigeon, threading, lifecycle |
| `references/device-tooling.md` | runtime MCP/Inspector, optional flutter_skill, test conversion |
| `references/android-automation.md` | optional ARTEMIS, Android task lifecycle, traces, outcome assertions |
| `references/release.md` | release checklist + `scripts/release-check.sh` |
| `references/auth-social.md` | Google & Apple sign-in end to end: platform setup, exchange, errors |
| `references/store-release.md` | Play + App Store submission, review rejections |
| `references/play-console.md` | Play Console in-browser: setup-to-production via user browser |
| `references/appstore-console.md` | App Store Connect in-browser: TestFlight-to-release |
| `references/fastlane-codemagic.md` | choose delivery tooling and its setup sequence |
| `references/codemagic-setup.md` | account/repository, signing, secrets, store access |
| `references/codemagic-workflows.md` | YAML checks, artifacts, triggers, publishing |
| `references/fastlane.md` | Bundler, match, artifact upload lanes, recovery |
| `references/shorebird-ci.md` | authenticated CI validation, release/patch/promotion ownership |
| `references/shorebird.md` | OTA code push: patchability, tracks, CI, compliance |

## Red flags — STOP and correct

- Writing asynchronous UI before its state contract; adding Cubits for purely local UI.
- Files violating the selected stack's layer/naming rules (`architecture.md`, `state-selection.md`).
- Inline color, user-visible string, or route path.
- Navigation violating the selected router conventions; business-layer navigation.
- `try/catch` that swallows, `!`, `dynamic`, `late` as a crutch.
- Editing a generated file, or committing `.g.dart`/`.freezed.dart`/`injection.config.dart`.
- "I'll add the test after" — after means never.
- Claiming implementation complete without analyzer/test evidence.

## Implementation evidence

For implementation, report exact results; advice reports sources and unverified assumptions:

```bash
dart format .
fdev gen          # only if annotations/generated code changed
                  # Dart 3.10+ build-hook error? fdev gen -- --force-jit
flutter analyze   # must be 0 issues
flutter test      # must be all green
```

Exercise the changed screen in dev. Report skipped steps under "Not verified".

Fixes for the common failures live with their topic: state/DI (`state-and-di.md`), routing
(`routing.md`), network/errors (`networking-and-errors.md`), UI/constants
(`theme-and-design-system.md`), models/storage (`models-and-storage.md`).
