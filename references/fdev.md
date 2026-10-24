# fdev — Owner's Flutter Dev CLI (use by default)

`fdev` is the owner's own CLI (pub.dev/packages/fdev). **Prefer `fdev` over raw
commands for codegen, builds, clean, env, keystores, and swagger models.** Run all
commands from the Flutter project root.

Verified on 2026-10-24 against installed fdev 0.1.6, top-level help and command help.
Source: [pub.dev package and documentation](https://pub.dev/packages/fdev).
Recheck the installed release before using new flags; this CLI evolves independently.

Install / verify:

```sh
dart pub global activate fdev 0.1.6 # use the project-approved version
fdev version
fdev doctor
```

## Command map

| Task | Use | Instead of |
|---|---|---|
| Regenerate codegen (injectable, json_serializable, freezed) | `fdev gen` (watch: `fdev gen --watch`; extra args after `--`) | `dart run build_runner build --delete-conflicting-outputs` |
| Codegen fails with `'dart compile' does not support build hooks` (Dart 3.10+, `objective_c` in the graph) | `fdev gen -- --force-jit` | `dart run build_runner build --delete-conflicting-outputs --force-jit` |
| Clean + fetch packages | `fdev clean` | `flutter clean && flutter pub get` |
| Android APK build | `fdev apk [flavor] [-t lib/main_dev.dart] [--debug|--profile] [--split-per-abi] [--dart-define K=V]` | `flutter build apk --flavor dev -t lib/main_dev.dart` |
| Android App Bundle | `fdev appbundle [flavor] [-t lib/main_prod.dart] [--debug|--profile] [--dart-define K=V]` | `flutter build appbundle --flavor prod -t lib/main_prod.dart` |
| iOS build (macOS only) | `fdev ios [flavor] [-t lib/main_prod.dart] [--debug|--profile] [--dart-define K=V]` | `flutter build ios --flavor prod -t lib/main_prod.dart` |
| Launcher icons | `fdev icons [-f config.yaml] [-p public/]` | `dart run flutter_launcher_icons` |
| Native splash | `fdev splash [--flavor dev]` (`--remove` to revert) | `dart run flutter_native_splash:create` |
| Select env file | `fdev env dev|stage|prod` (`--list`, `--flutter-define`, `-o path`) | manual `.env` copying |
| Release notes | `fdev release-notes --notes "..." [--version X --build-number N]` | manual fastlane changelog |
| iOS pods | `fdev pod update` (alias `pod-update`) | `cd ios && pod update` |
| Android keystore | `fdev signapk [--file x.jks --alias upload]` | manual `keytool` |
| Keystore SHA | `fdev sha [--file x.jks]` (alias `keystore-sha`) | `keytool -list` |
| Swagger/OpenAPI models | `fdev swagger --file swagger.json --out lib/data/models/api_models.dart [--copy-with] [--watch]` (or `--url`, `--path/--method`, `--operation-id`) | hand-written DTOs |
| Graphify + Caveman agent setup | `fdev init [--agents cursor,claude-code,codex,antigravity]` | manual setup |
| Self-update (intentional mutation) | `fdev upgrade` | `dart pub global activate fdev` |

## Command behavior and scope

- Builds default to release. `apk`, `appbundle`, and `ios` accept `--build-name`,
  `--build-number`, and extra Flutter build args after `--`. Explicit example:
  `fdev appbundle prod -t lib/main_prod.dart --build-number=42`; raw fallback:
  `flutter build appbundle --flavor prod -t lib/main_prod.dart --build-number=42`.
- `fdev ios` runs flutter build ios; use raw `flutter build ipa` for archive/export.
  It does not upload to stores, sign automatically, or configure native flavors.
- `fdev pod update` does clean → pub get → pod update and can change dependency resolution.
  For restoring locked dependencies, use `bundle exec pod install` from ios (or pod install
  if CocoaPods is managed without Bundler). Don't update Pods as routine debugging.
- `fdev signapk` writes android/app/keystore.jks and keystore.properties by default.
  Connect the actual properties path to Gradle; it isn't automatically key.properties.
  Keep credentials outside Git and preserve an existing app's registered upload key.
- `fdev env prod --flutter-define` prints values, so do not use it with secret-bearing files
  in shared logs. Shipped defines/assets are public configuration, not secret storage.
- In 0.1.6, `fdev upgrade --help` executes upgrade rather than showing help. Do not probe it
  in a read-only inventory. Inspect source/version documentation instead. `fdev init` also
  mutates project setup and can commit; its help is safe in the verified release.
- Pin fdev in CI, put Dart's global executable directory on PATH if needed, and record
  `fdev version`. Fall back to raw commands when unavailable; don't block a build on it.

## Agent setup and this skill

`fdev init [--agents cursor,claude-code,codex,antigravity]` sets up Graphify project
integration and the Caveman skill for the selected agents. It generates the project graph,
updates `.gitignore`, and commits setup files when run inside a Git repository. It needs
`graphify` and `npx` on `PATH`; without `--agents`, it selects Cursor, Claude Code, Codex, and
Antigravity.

This is separate from installing **Flutter Superpower**: `fdev init` does not install or
update this skill. Use this repository's `scripts/install.sh` (add `--project <app>` for a
project-level install). Run `fdev init` only when Graphify/Caveman setup is requested, after
checking the target project's Git state; it can create a commit.

## Notes for generated code

- `fdev swagger` emits **dependency-free** Dart models with manual `fromJson`/`toJson`
  and optional `copyWith` (`--copy-with`). Treat them as the manual-parse family in
  `models-and-storage.md`: place under `features/<x>/data/models/` (or `lib/models/` when
  app-wide), rename/reformat to house style (equatable, entities split) if the feature
  warrants it — do not leave generated style in presentation code.
- `fdev env` writes a single `.env` from `.env.dev`/`.env.stage`/`.env.prod` (also checks
  `env/`, `envs/`, `config/`). The house style loads `.env.<flavor>` via dotenv directly;
  use `fdev env` only when a project expects a single `.env` or dart-defines
  (`fdev env prod --flutter-define` prints the flags).
- `fdev apk/appbundle/ios` handle flavor + target + defines — match the repo's flavor
  entrypoints (`lib/main_dev.dart` / `lib/main_prod.dart`).

## Preferred verification sequence (house style + fdev)

```sh
dart format .
fdev gen                 # only if annotations/generated code changed
flutter analyze
flutter test
fdev apk dev             # or: fdev apk dev -t lib/main_dev.dart
```

If `fdev` is not installed on the machine, fall back to the raw commands in
`app-bootstrap.md § Verify` — never block on the CLI.
