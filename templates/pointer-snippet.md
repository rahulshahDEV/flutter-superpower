<!--
For agents without native skill support (or as a project-level guarantee):

- AGENTS.md / CLAUDE.md  → paste the block below (fill in the real path)
- Cursor rule           → save as .cursor/rules/flutter-superpower.mdc with:
                          ---
                          description: Flutter house style
                          globs: ["**/*.dart"]
                          alwaysApply: true
                          ---
                          (then the block below)
-->

## Flutter work: follow the flutter-superpower skill

Before writing or changing any Flutter code, read and follow:

- Entry point: `<PATH-TO-SKILL>/SKILL.md`
- Load references on demand from `<PATH-TO-SKILL>/references/`
  (senior-mode, architecture, state-and-di, routing, networking-and-errors,
  models-and-storage, theme-and-design-system, app-bootstrap, playbooks, debugging,
  testing, reviewing, auditing, performance, app-optimization, security, accessibility, localization,
  dependencies, native, release, auth-social, store-release, fastlane-codemagic,
  shorebird, ci-cd, chat-realtime, maps-location-health, ponytail, fdev).

Non-negotiables: feature-first `data/domain/presentation` layers; `SafeCubit` + sealed or
freezed states; `get_it` + `injectable` DI; `go_router` with `static path/routeName`;
Dio + `Either<Failure, T>`; constants for every string/color/path/size; ScreenUtil +
`AppSizes`; the K-widget design system; dev/prod flavors; and the gate
`dart format .` → `fdev gen` (when annotations changed) → `flutter analyze` → `flutter test`.

Scope is lazy: reuse existing `core/` code and the SDK before adding packages, cubits, or
widgets (see `references/ponytail.md`).
