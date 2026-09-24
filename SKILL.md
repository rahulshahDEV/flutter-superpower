---
name: flutter-superpower
description: Use when building, scaffolding, extending, auditing, debugging, refactoring, or migrating any Flutter app or feature — as the senior engineer who owns the task end to end. Triggers on flutter app, implement this feature, add feature to existing app, existing codebase, flutter audit, refactor, migrate state management, cubit, bloc, get_it, injectable, go_router, dio, Either Failure, SafeCubit, AppConfig, FlavorConfig, ScreenUtil, KButton, AppTextStyles, route data, presigned upload, FCM. Enforces the owner's battle-tested house style, and for existing projects follows the project's conventions over the defaults.
license: MIT
metadata:
  version: "2.2.0"
---

# Flutter Superpower

Build any Flutter app the owner's way: **feature-first clean architecture,
Cubits + GetIt/Injectable, GoRouter, Dio + Either, centralized theme/strings,
ScreenUtil sizing, K-widget design system, dev/prod flavors.**

When a detail is missing here, read the closest existing feature in the app you're
working in and mirror it instead of inventing.

**Scope discipline (built in):** structure is non-negotiable, scope is lazy. Climb the
ladder — need it at all? already in `core/`? SDK? platform? existing dependency? one
line? — then write the minimum. Never add what the feature doesn't use. Full rules:
`references/ponytail.md`.

## When NOT to use

- Non-Flutter work (Dart CLI, React Native, native) — the structure is Flutter-specific.
- Throwaway snippets with no app context; typo/one-line copy fixes.
- A repo with a conflicting documented house style — follow the repo (unless asked to migrate).

Task adds or changes app code → use the skill. Task only reads/explains/reviews → use it as
the rubric, not the scaffold.

## Senior mode — own the task

You are the senior engineer on this codebase, not a code generator. Inspect first, decide
carefully, implement cleanly, verify everything, and never stop at partially working code.

1. **Profile before changing** — inspect pubspec, `lib/`, routing, DI, state, networking,
   models, widgets, theme, tests, platform config, env. State the profile (architecture,
   state, routing, DI, net, models, tests, design system, mode) before you plan.
2. **Priority order:** existing project conventions > this skill's defaults > generic
   preference. Greenfield → use the defaults. Existing project → mirror the project and
   improve incrementally. Migration → only when explicitly requested, staged, verified
   after each stage.
3. **Decide before coding:** which layer owns it, what already exists to reuse, what the
   blast radius is (`rg` every dependent of shared code before editing).
4. **Own the obvious work** without asking: states (loading/error/empty/success), validation,
   DI, route, constants, platform config, tests. Ask only when genuinely blocked — one
   precise question with your proposed default.
5. **Self-review the diff** before verifying: architecture, scope, reuse, UI, state, data,
   errors, tests, performance, security, regression. Fix findings, then run the gate.
6. **Never write "Done."** without the evidence block: Implemented / Files changed /
   Verification (format, analyze, test, build) / Not verified / Notes.

Full behavior spec: `references/senior-mode.md`. Audits: `references/auditing.md`.

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
New app?      → scripts/new_app.sh <name>; then references/playbooks.md § New App
                (flavors, Firebase, manual path)
New feature?  → scripts/new_feature.sh <name> --app <dir> (all layers + codegen + route
                snippet); manual order in references/playbooks.md § New Feature
Existing app? → REQUIRED: references/senior-mode.md (profile first; project conventions
                beat these defaults), then mirror the closest existing feature
Bug?          → REQUIRED: references/debugging.md
Tests?        → REQUIRED: references/testing.md
Audit?        → REQUIRED: references/auditing.md + scripts/audit.sh <app> [--tests] [--perf]
Reviewing?    → REQUIRED: references/reviewing.md
Migration?    → references/senior-mode.md § Migration (explicit request only, staged)
Optimize?     → references/app-optimization.md (level-wise; implement / plan / skip)
```

Everything else routes through the References table below (release, stores, auth, native,
CI/CD, Shorebird, security, a11y, l10n, performance, dependencies, chat, maps/health).

Every non-trivial unit ships with ONE runnable check (a small widget/unit test or
fake-repo cubit test) — see `references/testing.md` and `references/playbooks.md § Verify`.

**Violating the letter of these rules is violating the spirit of them.** "It's basically
the same thing" (a `Provider` instead of a cubit, `Navigator.push` instead of the router,
a raw `Color` "just this once") is the violation, not an exception to it.

## Quick reference

| Concern | Decision |
|---|---|
| Screen with args | `XProvider` wrapper in `presentation/widgets/<flow>_provider.dart`; `getIt<XCubit>()..init(args)` in `create`; simple screens call `..load()` directly in the screen's own `BlocProvider` |
| Result | `FutureEither<T>` + `EitherX` (`valueOrNull`, `handle`) + `safeApiCall` mixin |
| Errors to user | `AppSnackBar.showError(context, failure.message)` in `BlocListener` |
| Theme | `AppColors` palette → `AppSemanticColors` ThemeExtension → `context.semanticColors` (or `AppColors` + `context.theme`) |
| Text | `AppTextStyles.x.copyWith(color: ...)` — never raw `TextStyle(fontSize:)` |
| Storage | `LocalStorageService` (SharedPreferences) + `StorageKeys`; secrets → `flutter_secure_storage` |
| Logging | `AppLogger.d/i/w/e` — dev-only, never `print` |
| Firebase | Core + Messaging only (unless app needs more). `FcmService` + `@pragma('vm:entry-point')` background handler |
| Uploads | presigned URL client, never multipart through the auth client |
| Simplest solution | climb the ladder in `references/ponytail.md` before writing anything new |
| Scaffolding | `scripts/new_app.sh <name>` / `scripts/new_feature.sh <name> --app <dir>` (templates in `templates/`) |
| Existing project | profile first; project conventions win; improve incrementally (`references/senior-mode.md`) |
| Audit | `scripts/audit.sh <app> [--tests] [--static]` + agent review per `references/auditing.md` |
| Blocked? | report: Blocked / Evidence / Needs / Default I would use |

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
| `references/debugging.md` | any bug, crash, wrong state, or "works in debug only" |
| `references/testing.md` | writing any test; fakes, cubit/widget/model test patterns |
| `references/ci-cd.md` | GitHub Actions, secrets, release flow |
| `references/chat-realtime.md` | Socket.IO chat, E2E crypto, optimistic send |
| `references/maps-location-health.md` | maps, geolocation, permissions, health/steps |
| `references/reviewing.md` | reviewing a diff: Standards + Spec axes, smell baseline |
| `references/senior-mode.md` | task ownership: profile, modes, decisions, self-review, DoD, evidence report |
| `references/auditing.md` | auditing an existing app: dimensions, severity, report format |
| `references/performance.md` | rebuilds, lists, images, startup, memory — measure before fixing |
| `references/app-optimization.md` | level-wise optimization plan with implement/plan/skip calls |
| `references/security.md` | secrets, log redaction, storage, transport, release hardening |
| `references/accessibility.md` | semantics, touch targets, text scaling, contrast, focus, motion |
| `references/localization.md` | StringConstants vs ARB, plurals, intl formatting, RTL |
| `references/dependencies.md` | add/remove discipline, evaluation, house-pinned choices |
| `references/native.md` | Android/iOS triage, flavors, signing, pods |
| `references/release.md` | release checklist + `scripts/release-check.sh` |
| `references/auth-social.md` | Google & Apple sign-in end to end: platform setup, exchange, errors |
| `references/store-release.md` | Play + App Store submission, review rejections |
| `references/fastlane-codemagic.md` | fastlane + codemagic.yaml |
| `references/shorebird.md` | OTA code push: patchability, tracks, CI, compliance |

## Red flags — STOP and correct

- Writing a widget before the state/cubit contract exists.
- A new file that isn't in the layer table (`architecture.md`).
- Inline color, user-visible string, or route path.
- `Navigator.push` / raw `context.go` instead of `context.goTo/pushRoute`.
- `try/catch` that swallows, `!`, `dynamic`, `late` as a crutch.
- Editing a generated file, or committing `.g.dart`/`.freezed.dart`/`injection.config.dart`.
- "I'll add the test after" — after means never.
- Claiming done without pasting analyzer/test output.

**All of these mean: stop, fix the root, re-run the gate.**

## Rationalizations (and the reality)

| Excuse | Reality |
|---|---|
| "This screen is simple, skip the layers" | Simple screens skip cubits only if state is local — decide by the rule in `state-and-di.md`, not by feel. |
| "I'll refactor to the house style later" | Later never comes; the first version is what ships. |
| "Tests slow me down" | One small cubit test takes minutes; debugging the regression takes hours. |
| "The SDK package is basically the same as a new one" | Fewer dependencies, fewer upgrades, fewer CVEs — use the SDK. |
| "Just this once" for an inline color/string | Every exception becomes the precedent; constants exist so this can't be a judgment call. |
| "Provider/Riverpod is easier for this screen" | One state solution per app; mixing them doubles the mental model. |
| "The analyzer is wrong" | The analyzer is the cheapest reviewer; fix the code or justify with a comment. |
| "Works on my machine" | Check flavor, `.env`, device API level, release vs debug. |

## Evidence before claiming done

Run and paste the result (or summarize the exact output) — never assert success:

```bash
dart format .
fdev gen          # only if annotations/generated code changed
                  # Dart 3.10+ build-hook error? fdev gen -- --force-jit
flutter analyze   # must be 0 issues
flutter test      # must be all green
```

Then exercise the changed screen in the dev flavor. Skipped steps go under "Not verified" —
an unverified claim is a bug report against yourself.

Fixes for the common failures live with their topic: state/DI (`state-and-di.md`), routing
(`routing.md`), network/errors (`networking-and-errors.md`), UI/constants
(`theme-and-design-system.md`), models/storage (`models-and-storage.md`).
