# flutter-superpower

One Claude/opencode skill that makes any Flutter app come out in the owner's
structure — distilled from three real production apps plus the owner's own
`fdev` CLI, with scope discipline (ponytail) built in.

| App | Path | Signature traits |
|---|---|---|
| **zoomies** | `/Volumes/mcoders/zoomies` | 901 files · SafeCubit + sealed Equatable states · Dio + `ApiResponseHandler` · `AppSemanticColors` ThemeExtension · route-data classes · Socket.IO chat · presigned S3 uploads |
| **foundyou** | `/Volumes/mcoders/found-you-flutter` | 530 files · freezed cubit states · UseCase classes · `CustomSnackBar` · `KButton` · StatefulShellRoute · X25519/AES chat crypto · secure storage |
| **meltdown** | `/Volumes/mcoders/meltdown/flutter-app` | 1061 files · `http` + `http_interceptor` · `ErrorHandler` funnel · freezed states · `BaseScaffold` · ValueNotifier local state · Sentry + Amplitude · health/steps + QR |

All three independently converged on the same house style. This repo is the skill.

## What it enforces

- Feature-first clean architecture: `lib/features/<x>/{data,domain,presentation}` + `lib/core/` + `lib/di/`
- `flutter_bloc` Cubits + `SafeCubit` + sealed/freezed states
- `get_it` + `injectable` DI (`@injectable` cubits, `@LazySingleton(as:)` repos)
- `go_router` with `static const path/routeName` per screen + typed route-data
- `dio` + `Either<Failure, T>` + `safeApiCall`/`ErrorHandler`
- `json_serializable` models extending Equatable entities
- Centralized constants: colors, text styles, strings, API paths, storage keys
- `flutter_screenutil` (390×844 / 375×812) + `AppSizes` tokens
- Design system: `KButton`, `KTextField`, `ImageRenderer`, empty/error/loading, shimmer, custom snackbar
- dev/prod flavors via `dotenv` + `AppConfig`/`FlavorConfig`
- `AppLogger` dev-only; `flutter analyze` + `flutter test` + `dart format` gate
- **Ponytail scope discipline** (built in): reuse before write, Material/SDK before
  packages, local state before cubits, fewest files, smallest diff, one check per
  non-trivial logic path
- **`fdev` CLI** (pub.dev/packages/fdev): prefer it for codegen, builds, clean, env,
  keystores, and Swagger model generation

## Layout

```
flutter-superpower/
├── README.md
├── SKILL.md                         ← entry point: 12 laws, workflow, quick reference
└── references/
    ├── architecture.md              ← layers, folders, naming, feature template
    ├── state-and-di.md              ← cubits, states, injectable wiring
    ├── routing.md                   ← go_router, route data, guards, shells
    ├── networking-and-errors.md     ← DioClient, interceptors, Either, logging
    ├── models-and-storage.md        ← entities/models/json, prefs, secure storage
    ├── theme-and-design-system.md   ← colors, text, sizing, K-widgets, strings
    ├── app-bootstrap.md             ← main(), flavors, DI boot, Firebase/FCM
    ├── playbooks.md                 ← new-app-from-zero + new-feature recipes
    ├── ponytail.md                  ← scope discipline / anti-over-engineering
    └── fdev.md                      ← owner's fdev CLI command map
```

## Install

```bash
ln -sfn /Volumes/mcoders/fluttersuperpower ~/.claude/skills/flutter-superpower
ln -sfn /Volumes/mcoders/fluttersuperpower ~/.agents/skills/flutter-superpower
```

The skill folder name and the frontmatter `name: flutter-superpower` are what agents
match on — no nested duplicate folder needed.

## Roadmap — what can be added next

| # | Addition | Why | Effort |
|---|---|---|---|
| 1 | `templates/` real skeleton dart files | copy-paste speed instead of reading prose | S |
| 2 | `scripts/new_app.sh` — scaffolds the whole core/ + di/ + flavors | zero-to-running in one command | M |
| 3 | `scripts/new_feature.sh <name>` — generates the full feature tree + stubs | feature loop becomes mechanical | M |
| 4 | `references/testing.md` — fake-repo pattern (no mocktail), cubit tests | all 3 apps test this way; currently spread across playbooks | S |
| 5 | `references/ci-cd.md` — GitHub Actions: format → analyze → test → build flavors | repos reference CI expectations but no template | S |
| 6 | `references/chat-realtime.md` — Socket.IO lifecycle + crypto key exchange | hardest cross-cutting feature to rebuild | M |
| 7 | `references/maps-location-health.md` — geolocator/maps, steps, permissions matrix | platform-heavy, high re-discovery cost | M |
| 8 | `references/payments.md` — eSewa/Khalti + presigned upload patterns | Nepal-specific, easy to forget details | S |
| 9 | `tests/` — baseline pressure + retrieval tests per writing-skills TDD | proves an agent actually follows the house style | M |
| 10 | Keep in sync with `fdev` releases (new commands) | CLI is the owner's daily driver | S |

Priority if continuing: **1 → 2 → 3 → 4** (turns the skill from reference into a generator).
