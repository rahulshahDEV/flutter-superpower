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
- Load references on demand from `<PATH-TO-SKILL>/references/` — one file per topic
  (architecture, state/DI, routing, networking, models, design system, testing, debugging,
  senior behavior, reviews, audits, performance, security, accessibility, localization,
  dependencies, native, releases, stores, auth, CI/CD, Shorebird, and more). The full,
  current index is the References table in `<PATH-TO-SKILL>/SKILL.md`.

Non-negotiables: feature-first `data/domain/presentation` layers; `SafeCubit` + sealed or
freezed states; `get_it` + `injectable` DI; `go_router` with `static path/routeName`;
Dio + `Either<Failure, T>`; constants for every string/color/path/size; ScreenUtil +
`AppSizes`; the K-widget design system; dev/prod flavors; and the gate
`dart format .` → `fdev gen` (when annotations changed) → `flutter analyze` → `flutter test`.

Scope is lazy: reuse existing `core/` code and the SDK before adding packages, cubits, or
widgets (see `references/ponytail.md`).
