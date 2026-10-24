# CI/CD Engineering

CI reproduces the same gate as local: resolve dependencies, format → codegen if needed →
analyze → test, then build the affected native targets. `fastlane-codemagic.md` routes hosted
signing/delivery setup. Existing project workflow and explicit release scope take priority.

## Trust and reproducibility

Use separate check, artifact, and publishing workflows. Pull requests run without signing,
store, production backend, or OTA credentials. Untrusted code must not acquire credentials
via an attacker-editable YAML/script or a privileged trigger checking out PR code. Protect
release refs and publication environments using provider controls; a tag alone is not trust.

Pin a tested Flutter release, compatible native toolchain, and Ruby/fastlane where used.
Commit app pubspec.lock and other chosen dependency lockfiles. Prefer immutable action SHAs
when maintaining production workflows; version tags below are readable examples to resolve
and pin during setup. Record actual versions with artifacts. Don't float stable in CI.

## GitHub Actions check example

Replace the Flutter pin before use. This is a root Flutter package with codegen, public sample
config and gitignored generated Dart files. No production secrets are needed for unit tests.

```yaml
name: Flutter checks
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
permissions:
  contents: read
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: REPLACE_WITH_TESTED_FLUTTER
          channel: stable
          cache: true
      - name: Prepare and resolve
        run: |
          cp .env.sample .env.dev
          cp .env.sample .env.prod
          flutter pub get
      - run: dart format --output=none --set-exit-if-changed lib test
      - name: Generate
        run: |
          if command -v fdev >/dev/null 2>&1; then
            fdev gen
          else
            dart run build_runner build --delete-conflicting-outputs
          fi
      - run: flutter analyze
      - run: flutter test --coverage
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: coverage
          path: coverage/lcov.info
```

Remove generation when no builders exist. Never ask agents to commit `.g.dart`,
`.freezed.dart`, or injection.config.dart in this house style; rebuild before analyze.
Projects intentionally tracking generated files may add their own freshness check.
Install a pinned fdev version if relying on it; don't assume hosted images include it.

## Build and publish stages

- Android: select compatible JDK/SDK/Gradle from the app, then build the actual flavor.
  Prefer `fdev appbundle prod -t lib/main_prod.dart --build-number=<number>`; fallback
  `flutter build appbundle --flavor prod -t lib/main_prod.dart --build-number=<number>`.
- iOS: macOS with selected Xcode and project CocoaPods/SwiftPM setup. An unsigned compile
  check uses `flutter build ios --no-codesign`; a signed export uses `flutter build ipa`
  with flavor/entrypoint/export options. Simulator success does not prove archive/signing.
- Allocate build numbers centrally or with an offset/seed above existing store uploads.
  Prevent concurrent releases from choosing the same number. Marketing version stays in pubspec.
- Keep configuration assets public and separate from signing/upload credentials. Use protected
  files with restrictive permissions; don't dump environment variables or upload credential dirs.
- Run `scripts/release-check.sh <app>` as a mechanical supplement, then inspect its output.
  Blockers return nonzero; warnings and unverified external checks still need review.
- Deliver the verified artifact to the intended destination only. Keep one upload owner;
  don't call fastlane and Codemagic publishing for the same artifact/store in one workflow.

## Cache and artifact policy

Cache package/native dependencies with keys tied to toolchain and lockfiles. Don't cache
signing files, private API keys, or arbitrary environment directories. A cache miss must
still build successfully. Avoid routine clean/pod update rituals; investigate stale artifacts.

Retain binaries, checksums, commit/tool versions, flavor, package IDs, build number, tests,
coverage where useful, dSYMs, R8 mappings, native/Dart symbols as applicable. Restrict access
and retention for crash/test artifacts that contain user data. Match symbols to exact builds;
OTA adds a patch identifier. Use `native-diagnostics.md` for symbolication.

## Verification and release recovery

Validate YAML and provider schema, run a secret-free check, then a trusted signed artifact
build. Inspect signer/version/identity before authorized upload. Confirm store processing,
tester availability and release status separately. A green YAML parser proves syntax only.
On timeout, inspect remote upload state before retrying; use the same artifact when valid.
Keep previous release artifacts and a recovery plan; a rollback cannot automatically undo
persisted data migrations. For OTA, follow `shorebird.md` rather than rebuilding with plain Flutter.
