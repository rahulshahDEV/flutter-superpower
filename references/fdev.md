# fdev — Owner's Flutter Dev CLI (use by default)

`fdev` is the owner's own CLI (pub.dev/packages/fdev, repo `rahulshahDEV/fdev`,
publisher `rahulsha.com.np`). **Prefer `fdev` over raw commands for codegen, builds,
clean, env, keystores, and swagger models.** Run all commands from the Flutter project root.

Install / verify:

```sh
dart pub global activate fdev
fdev version
fdev doctor
```

## Command map

| Task | Use | Instead of |
|---|---|---|
| Regenerate codegen (injectable, json_serializable, freezed) | `fdev gen` (watch: `fdev gen --watch`; extra args after `--`) | `dart run build_runner build --delete-conflicting-outputs` |
| Clean + fetch packages | `fdev clean` | `flutter clean && flutter pub get` |
| Android APK build | `fdev apk [flavor] [-t lib/main_dev.dart] [--debug|--profile] [--split-per-abi] [--dart-define K=V]` | `flutter build apk ...` |
| Android App Bundle | `fdev appbundle [flavor] [-t ...] [--debug|--profile] [--dart-define K=V]` | `flutter build appbundle ...` |
| iOS build (macOS only) | `fdev ios [flavor] [-t ...] [--debug|--profile] [--dart-define K=V]` | `flutter build ios ...` |
| Launcher icons | `fdev icons [-f config.yaml] [-p public/]` | `dart run flutter_launcher_icons` |
| Native splash | `fdev splash [--flavor dev]` (`--remove` to revert) | `dart run flutter_native_splash:create` |
| Select env file | `fdev env dev|stage|prod` (`--list`, `--flutter-define`, `-o path`) | manual `.env` copying |
| Release notes | `fdev release-notes --notes "..." [--version X --build-number N]` | manual fastlane changelog |
| iOS pods | `fdev pod update` (alias `pod-update`) | `cd ios && pod update` |
| Android keystore | `fdev signapk [--file x.jks --alias upload]` | manual `keytool` |
| Keystore SHA | `fdev sha [--file x.jks]` (alias `keystore-sha`) | `keytool -list` |
| Swagger/OpenAPI models | `fdev swagger --file swagger.json --out lib/data/models/api_models.dart [--copy-with] [--watch]` (or `--url`, `--path/--method`, `--operation-id`) | hand-written DTOs |
| Graphify + Caveman agent setup | `fdev init [--agents cursor,claude-code,codex,antigravity]` | manual setup |
| Self-update | `fdev upgrade` | re-activating |

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
