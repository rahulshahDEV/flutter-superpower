# Fastlane & Codemagic (mobile CI/CD)

Division of labor: **`fdev`** for local builds, **fastlane** for store automation, **Codemagic**
(or GitHub Actions) as the hosted runner. The release checklist in `release.md` stays the
single source of truth for *what* must be true; this file covers *how* it runs in CI.

## Fastlane

### Setup

```bash
gem install fastlane          # or: brew install fastlane
cd android && fastlane init   # creates android/fastlane/{Appfile,Fastfile}
cd ios && fastlane init       # creates ios/fastlane/{Appfile,Fastfile}
```

- `Appfile`: `app_identifier` (bundle ID), `apple_id`, `team_id`.
- `Fastfile`: one lane per job; keep them thin wrappers over the build commands.
- `.env` / `.env.default`: local defaults; secrets come from CI env vars, never committed.
- `fastlane/metadata/` is where `deliver`/`supply` read listing text and screenshots —
  `fdev release-notes` already writes the Android changelog path.

### Code signing

**Android** — keystore from env:

```ruby
keystore_path = ENV["ANDROID_KEYSTORE_PATH"]
keystore_password = ENV["ANDROID_KEYSTORE_PASSWORD"]
key_alias = ENV["ANDROID_KEY_ALIAS"]
key_password = ENV["ANDROID_KEY_PASSWORD"]
```

**iOS** — pick one:

- `match` (recommended): certificates/profiles in a private git repo, encrypted with
  `MATCH_PASSWORD`; CI uses `readonly: true`.
- App Store Connect API key: `app_store_connect_api_key(key_id:, issuer_id:, key_filepath:)`
  — no Apple ID password, ideal for CI.

### Example lanes

```ruby
default_platform(:android)

platform :android do
  lane :internal do
    sh("fdev gen")
    sh("flutter build appbundle --flavor prod -t lib/main_prod.dart --build-number=#{ENV['BUILD_NUMBER']}")
    supply(
      track: "internal",
      aab: "../build/app/outputs/bundle/prodRelease/app-prod-release.aab",
      release_status: "draft",          # promote manually after QA
      skip_upload_metadata: false,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end
end

platform :ios do
  lane :beta do
    api_key = app_store_connect_api_key(
      key_id: ENV["ASC_KEY_ID"], issuer_id: ENV["ASC_ISSUER_ID"],
      key_filepath: ENV["ASC_KEY_PATH"]
    )
    match(type: "appstore", readonly: true)
    sh("flutter build ipa --flavor prod -t lib/main_prod.dart --build-number=#{ENV['BUILD_NUMBER']}")
    pilot(api_key: api_key, skip_waiting_for_build_processing: true) # TestFlight
  end

  lane :release do
    deliver(force: true, submit_for_review: false) # metadata + binary, submit manually
  end
end
```

Key actions: `supply` (Play upload + track + metadata), `deliver` (App Store metadata/binary),
`pilot` (TestFlight), `match` (signing), `gym` (iOS build), `precheck` (metadata lint),
`increment_version_code`/`increment_build_number` (versioning, if the project uses them).

### Fastlane failure modes

| Symptom | Cause |
|---|---|
| `No provisioning profile` | match not run / profile expired / wrong team |
| Play upload 403 | service account missing release permissions |
| `Version code already used` | build number not incremented |
| Metadata rejected | text/screenshot limits (fastlane `precheck` catches some) |
| Keystore alias mismatch | env vars vs `key.properties` disagree |

## Codemagic

### codemagic.yaml (v2)

```yaml
workflows:
  pr-check:
    name: PR check
    max_build_duration: 30
    triggering:
      events: [pull_request]
    environment:
      flutter: 3.38.9            # pin; never float in CI
    cache:
      cache_paths:
        - ~/.pub-cache
        - $HOME/Library/Caches/CocoaPods
    scripts:
      - name: Deps + codegen
        script: |
          flutter pub get
          fdev gen
      - name: Format + analyze + test
        script: |
          dart format --set-exit-if-changed lib test
          flutter analyze
          flutter test

  release:
    name: Release
    max_build_duration: 90
    triggering:
      events: [tag]
      tag_patterns: ["v*"]
    integrations:
      app_store_connect: my_asc_key     # configured in the Codemagic UI
    environment:
      flutter: 3.38.9
      groups:
        - android_signing               # keystore + passwords (encrypted)
        - app_secrets                   # .env.prod contents as vars
      vars:
        BUNDLE_ID: com.example.app
    scripts:
      - name: Write secrets
        script: |
          echo "$ENV_PROD" > .env.prod
          echo "$ANDROID_KEYSTORE" | base64 --decode > android/app/upload-keystore.jks
          cat > android/key.properties <<EOF
          storePassword=$ANDROID_KEYSTORE_PASSWORD
          keyPassword=$ANDROID_KEY_PASSWORD
          keyAlias=$ANDROID_KEY_ALIAS
          storeFile=upload-keystore.jks
          EOF
      - name: Build Android
        script: flutter build appbundle --flavor prod -t lib/main_prod.dart --build-number=$PROJECT_BUILD_NUMBER
      - name: Build iOS
        script: flutter build ipa --flavor prod -t lib/main_prod.dart --build-number=$PROJECT_BUILD_NUMBER --export-options-plist=$HOME/export_options.plist
    artifacts:
      - build/app/outputs/bundle/**/*.aab
      - build/ios/ipa/*.ipa
    publishing:
      google_play:
        credentials: $GOOGLE_PLAY_SERVICE_ACCOUNT
        track: internal
      app_store_connect:
        auth: integration
        submit_to_testflight: true
        # submit_to_app_store: true   # flip when ready for review
      email:
        recipients: team@example.com
```

### Codemagic essentials

- **Environment groups**: all secrets (keystore base64, Play service account JSON, ASC API key,
  `.env.prod`) live in encrypted groups; reference by name; never echo them in scripts.
- **Signing**: iOS uses the App Store Connect integration + automatic signing (or a
  `keychain` script); Android uses the uploaded keystore via env vars.
- **Triggers**: `pull_request` for the check workflow, `tag v*` for release, `branch` patterns
  for nightly/beta. Keep PR workflow fast (<15 min): pub get → gen → format → analyze → test.
- **Caching**: `~/.pub-cache`, Gradle (`~/.gradle/caches`), CocoaPods — cuts minutes per run.
- **Versioning**: set `--build-number=$PROJECT_BUILD_NUMBER` (Codemagic provides it) so every
  upload is unique; keep `X.Y.Z` in pubspec.
- **Flutter pinning**: always pin the Flutter version in CI; floating stable breaks builds.
- **Publishing**: `google_play` track + `app_store_connect` (TestFlight first, `submit_to_app_store`
  only when the release checklist is green).

### Codemagic failure modes

| Symptom | Cause |
|---|---|
| Signing fails on iOS | ASC key expired/revoked, or bundle ID mismatch |
| Keystore errors | base64 decode line breaks; alias/password mismatch |
| Build number collision | not passing `--build-number` |
| Cache poisoning | stale pub/gradle cache after major SDK bump — clear it |
| `.env.prod` missing | group not attached to the workflow |

## House rules

- One automation stack per repo. If the project uses fastlane, extend its lanes; if it uses
  Codemagic, extend the YAML. Do not introduce the other one for a single task.
- CI runs the same gate as local: `dart format` → `fdev gen` → `flutter analyze` → `flutter test`
  (see `ci-cd.md`), then builds with the project's flavors.
- Secrets only in the CI provider's secret store; rotate on team changes.
- Store submission stays manual until the project explicitly opts into automated submission.
