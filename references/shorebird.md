# Shorebird — OTA Code Push

Shorebird pushes Dart-code updates to installed apps without a store review. Use it only when
the project opts in — it changes the build toolchain, so it is a project-level decision, never
a casual addition.

## How it works

- Apps built with Shorebird bundle a **modified Flutter engine** that checks for patches at
  startup on a background thread.
- A patch downloads in the background and applies on the **next launch** by default. For
  mandatory/immediate updates, check programmatically with `package:shorebird_code_push`
  (ShorebirdUpdater: `checkForUpdate`, `update`, `readCurrentPatch`).
- `shorebird release` is a drop-in for `flutter build` and uploads the compiled Dart artifacts;
  you still upload the `.aab`/`.ipa` to the stores yourself.
- `shorebird patch` diffs your Dart against the release and publishes the patch.

## What is patchable (enforced by the CLI)

| Change | Result |
|---|---|
| Dart code (app, generated, pure-Dart deps) | ✅ patch |
| Assets (images, fonts, pubspec assets) | ❌ new store release |
| Native code (Kotlin/Java/Swift/Obj-C), plugins with native changes | ❌ new store release |
| Flutter engine / Flutter version | ❌ new store release |

The CLI auto-detects native/asset changes and refuses the patch — but **content compliance is
your responsibility** (see Store compliance).

## Platform support

Android, iOS, macOS, Windows, Linux. Flavors are supported: each flavor gets its **own
`app_id`** in `shorebird.yaml`. Code obfuscation supported (Flutter 3.41.2+). Patch
signing/KMS supported.

## Setup

```bash
# install (macOS/Linux)
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash
shorebird doctor          # verifies toolchain + connectivity
shorebird login           # browser auth (local only)
shorebird init            # in the app root → creates shorebird.yaml (commit it; app_id is not secret)
```

Shorebird installs and uses its **own Flutter copy** (`~/.shorebird/bin/cache/flutter`),
separate from the system Flutter. Pin it in CI with `--flutter-version`.

## Releases & patches

```bash
# release (pin Flutter; pass extra flutter args after --)
shorebird release android --flavor prod -t lib/main_prod.dart --flutter-version=3.38.9
shorebird release ios     --flavor prod -t lib/main_prod.dart --flutter-version=3.38.9

# patch a specific release version (patch uses the release's exact Flutter version)
shorebird patch android --release-version=1.4.0+12
shorebird patch ios     --release-version=1.4.0+12 --track=staging

# test locally before publishing
shorebird preview
```

- Patches target one release version; unlimited patches per release; **one active patch at a
  time** (the latest wins).
- **Tracks**: `stable` is the default; create `staging`/`beta` tracks by naming them when
  patching, validate with a subset of devices, then publish the same patch to `stable`.
- A patch must be built from the same Flutter version as its release — Shorebird handles this
  automatically when you pass `--release-version`.

## CI

- Auth: create an API key in the Shorebird Console → `SHOREBIRD_TOKEN` env var
  (`shorebird login:ci` is deprecated; old tokens die Sept 2026).
- Replace `flutter build` with `shorebird release` / `shorebird patch` in the pipeline; the
  builder still needs JDK + Android SDK (and Xcode/CocoaPods for iOS).
- PR validation: `shorebird patch android --dry-run` (and/or `release --dry-run`) — builds and
  verifies without publishing.
- iOS without certificates on the runner: `--no-codesign` (the artifact then needs manual
  signing before distribution).
- CI runs non-interactively when `CI=true`/`SHOREBIRD_TOKEN` is set; `--no-confirm` forces it.
- Documented integrations exist for GitHub Actions and Codemagic — see `fastlane-codemagic.md`.

```yaml
# GitHub Actions sketch
- run: shorebird patch android --release-version=${{ env.RELEASE_VERSION }} --dry-run
  env: { SHOREBIRD_TOKEN: ${{ secrets.SHOREBIRD_TOKEN }} }
```

## Store compliance (do not skip)

- OTA updates must not change the app's primary purpose or bypass review for features that
  require it. Apple permits interpreted-code updates under its guidelines with conditions;
  both stores require patches to comply with behavioral policies.
- Keep patches to bug fixes, performance, and UX improvements inside the shipped feature set.
- Anything user-visible that changes the product's scope (new paid feature, new data
  collection, new permission) goes through a store release, not a patch.
- `release-check.sh` cannot judge patch compliance; record the reasoning in the release notes.

## Interaction with the house release flow

1. `release.md` checklist applies unchanged — a Shorebird release is still a store release.
2. Versioning: the patch targets `X.Y.Z+N`; bump the build number for every store release.
3. Flavors: keep one `app_id` per flavor in `shorebird.yaml`; `.env` handling is unchanged.
4. Local builds stay `fdev`; Shorebird replaces only the release/patch build commands for
   apps that adopted it.

## Failure modes

| Symptom | Cause |
|---|---|
| Patch never applies | App installed from a build made with plain `flutter build` (no Shorebird engine) |
| Patch "didn't work" | Applied on the *second* launch by design — or the user never restarted |
| `patch` refuses to build | Native or asset changes detected → cut a store release |
| Wrong flavor patched | `app_id` mismatch (each flavor has its own) |
| CI auth failure | Expired/revoked `SHOREBIRD_TOKEN`, or key lacks permission |
| Patch built against wrong Flutter | Missing `--release-version` (use it; it pins the release's engine) |
