# Dependency Intelligence

A dependency is a permanent maintenance cost. Add one only when the ladder below bottoms out.

## The ladder

1. **Flutter/Dart SDK** covers it? Use it (`showDatePicker`, `AnimatedSwitcher`, `Share` via
   the share sheet on supported platforms, `jsonDecode`, `compute`, `RefreshIndicator`).
2. **Existing project code** covers it? Reuse `core/widgets`, `core/utils`, `core/extensions`.
3. **Already-installed dependency** covers it? Use it — never add a second package for the same
   concern (two HTTP clients, two image loaders, two state solutions).
4. **New package** — justify it in one sentence: what breaks without it, why the SDK/project
   can't do it, and why this package over the alternatives.

## Before adding — evaluate

```bash
flutter pub outdated                      # currency of what's already there
dart pub deps --style=compact | head -40  # transitive weight
```

Check: last publish date, open issue health, platform support (android/ios/web), null-safety
and current SDK constraint, license, transitive count, and whether it is a federated official
plugin (prefer official/first-party for platform channels).

Never add packages that compete with the architecture: a second state-management, routing, DI,
networking, or model-codegen solution is an architectural migration, not a dependency choice.

## House-pinned choices (do not replace)

`flutter_bloc` · `get_it` + `injectable` · `go_router` · `dio` · `dartz` + `equatable` ·
`json_serializable` (+ `freezed` where the app already uses it) · `flutter_screenutil` ·
`google_fonts` · `shared_preferences` (+ `flutter_secure_storage` where present).

## Adding correctly

```bash
flutter pub add <pkg>            # adds with caret constraint
flutter pub get
fdev gen                         # if the package ships builders
flutter analyze && flutter test
```

- Pin a major (`^x.y.z`); avoid `any`.
- If the package needs native setup (permissions, pods, gradle), do that in the same change —
  see `native.md`.
- Update the PR/report with the one-sentence justification.

## Removing correctly

```bash
flutter pub remove <pkg>
fdev clean                       # clean + pub get
flutter analyze && flutter test
```

Delete the code that existed only for it (dead wrappers, adapters, constants). Check
`dart pub deps --style=compact` for orphans you can also drop.

## Anti-patterns

| Smell | Reality |
|---|---|
| "It saves 20 lines" | You now own upgrades, CVEs, and SDK breakage for 20 lines. |
| Two packages for one concern | Pick one; migrate the other out. |
| A package for one screen | Inline the 30 lines or use the SDK. |
| Adding during a bugfix | Separate change, separate justification, separate verification. |
| Abandoned package (2+ years) | Fork cost is real; find a maintained alternative or inline it. |
