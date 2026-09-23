# CI/CD

Quality gate on every PR: **format → analyze → test**. Builds run on release branches/tags.
Use the owner's `fdev` CLI where installed; raw Flutter commands otherwise.

## GitHub Actions — PR checks

```yaml
# .github/workflows/ci.yml
name: CI
on:
  pull_request:
    branches: [develop, main]
  push:
    branches: [develop, main]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - run: flutter pub get

      - run: dart format --set-exit-if-changed lib test

      - name: Codegen (verify generated code is current)
        run: |
          dart run build_runner build --delete-conflicting-outputs
          git diff --exit-code -- '*.g.dart' '*.freezed.dart' || \
            (echo "Generated files are stale — run fdev gen and commit" && exit 1)

      - run: flutter analyze

      - run: flutter test --coverage

      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: coverage
          path: coverage/lcov.info
```

Notes:
- Generated files are gitignored in this house style, so the "stale generated code" step
  only makes sense in repos that commit them. If gitignored, just run codegen before analyze
  (no diff check).
- `dart format --set-exit-if-changed` is the enforcement; local habit is `dart format .`.

## Android build (dev flavor smoke)

```yaml
  build-android:
    needs: check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: '17' }
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - name: Write secrets
        run: |
          echo "${{ secrets.ANDROID_KEY_PROPERTIES }}" > android/key.properties
          echo "${{ secrets.GOOGLE_SERVICES_JSON }}" > android/app/google-services.json
          echo "${{ secrets.ENV_DEV }}" > .env.dev
          echo "${{ secrets.ENV_PROD }}" > .env.prod
      - run: flutter build apk --flavor dev -t lib/main_dev.dart --debug
```

iOS builds need `runs-on: macos-latest`, `pod install`, and an Apple signing setup
(certificate + provisioning profile secrets, or `--no-codesign` for compile-only checks).

## Secrets checklist (never commit)

| Secret | Where it goes |
|---|---|
| `.env.dev`, `.env.prod` | repo secrets → written in CI; local dev keeps real files gitignored |
| `android/key.properties` + keystore `.jks` | repo secrets (base64 the keystore) |
| `google-services.json`, `GoogleService-Info.plist` | repo secrets |
| App Store / Play credentials | CI environment secrets only |

Commit a `.env.sample` documenting every key. Never echo secret contents in logs.

## Release flow

The full release checklist lives in `release.md`; the mechanical pass is
`scripts/release-check.sh <app>`. CI's part:

1. `release-check.sh` runs on the release branch/tag (fails on hard blockers).
2. Tag `vX.Y.Z`; CI builds the release flavors.
3. `fdev appbundle prod -t lib/main_prod.dart` (or `flutter build appbundle ...`).
4. iOS: `fdev ios prod -t lib/main_prod.dart`, then archive/upload in Xcode.

## House CI rules

- `flutter analyze` must be zero issues — no `// ignore` without a reason comment.
- Tests must pass; new non-trivial logic adds at least one test in the same PR (see `testing.md`).
- One logical change per PR; branch names `feat/*`, `bugfixes/*`; no self-merge.
- CI failure fixes get a new commit, never a force-push over a reviewed branch.
