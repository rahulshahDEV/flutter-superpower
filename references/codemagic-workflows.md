# Codemagic Workflows

Complete account/signing setup in `codemagic-setup.md` first. These are build-only examples;
publishing is a separately enabled step. Examples assume a root Flutter app with wired prod
flavors, `lib/main_prod.dart`, committed `.env.sample`, and generated files gitignored.

## Check workflow

Replace `REPLACE_WITH_TESTED_FLUTTER` before use. Add private dependency access only if
required and safe for the workflow. The example copies harmless sample config for tests;
projects requiring more fixtures should supply test configuration, not production secrets.

```yaml
workflows:
  checks:
    name: Flutter checks
    max_build_duration: 30
    environment:
      flutter: REPLACE_WITH_TESTED_FLUTTER
    triggering:
      events: [pull_request]
      branch_patterns:
        - pattern: main
          include: true
          source: false
      cancel_previous_builds: true
    scripts:
      - name: Resolve and verify
        script: |
          set -eu
          cp .env.sample .env.dev
          cp .env.sample .env.prod
          flutter pub get
          dart format --output=none --set-exit-if-changed lib test
          if command -v fdev >/dev/null 2>&1; then
            fdev gen
          else
            dart run build_runner build --delete-conflicting-outputs
          fi
          flutter analyze
          flutter test --coverage
    artifacts:
      - coverage/lcov.info
```

Install a pinned fdev version in the environment if using it; don't assume it is preinstalled.
No builders in the app? Remove the generation step. For a verified Dart build-hook failure,
use the documented `--force-jit` fallback from `fdev.md`; don't add it without evidence.
Generated files are rebuilt, not committed or checked for tracked diffs.

## Signed Android artifact

Add this workflow beneath the same `workflows` mapping. `production_config` supplies
`ENV_PROD` containing public production config and `RELEASE_BUILD_NUMBER`, allocated above
all existing uploads. `android_upload` is the uploaded signing identity. The Gradle release
config must consume its variables. This intentionally has no automatic trigger/publication.

```yaml
  android-artifact:
    name: Signed production Android artifact
    max_build_duration: 60
    environment:
      flutter: REPLACE_WITH_TESTED_FLUTTER
      android_signing: [android_upload]
      groups: [production_config]
    scripts:
      - name: Prepare and verify
        script: |
          set -eu
          umask 077
          : "${ENV_PROD:?Missing production config}"
          : "${RELEASE_BUILD_NUMBER:?Allocate a unique build number}"
          printf '%s\n' "$ENV_PROD" > .env.prod
          cp .env.sample .env.dev
          flutter pub get
          dart format --output=none --set-exit-if-changed lib test
          if command -v fdev >/dev/null 2>&1; then fdev gen; else
            dart run build_runner build --delete-conflicting-outputs
          fi
          flutter analyze
          flutter test
      - name: Build AAB
        script: |
          set -eu
          fdev appbundle prod -t lib/main_prod.dart \
            --build-number="$RELEASE_BUILD_NUMBER"
    artifacts:
      - build/app/outputs/bundle/prodRelease/*.aab
      - build/app/outputs/mapping/prodRelease/mapping.txt
```

Install the pinned fdev CLI before this workflow, or replace the build command with
`flutter build appbundle --flavor prod -t lib/main_prod.dart --build-number="$RELEASE_BUILD_NUMBER"`.
fdev 0.1.6 supports the explicit build-number flag; verify help on another version.

## Signed iOS artifact

Clone the Android workflow as `ios-artifact`, remove android_signing, and select a macOS
machine supported by the account. Retain the same preparation/quality-gate scripts. Replace
its environment and final build step with these fragments (not separate complete workflows):

```yaml
environment:
  flutter: REPLACE_WITH_TESTED_FLUTTER
  xcode: REPLACE_WITH_TESTED_XCODE
  groups: [production_config]
  ios_signing:
    distribution_type: app_store
    bundle_identifier: com.example.app
```

```yaml
- name: Apply profiles and export IPA
  script: |
    set -eu
    xcode-project use-profiles
    flutter build ipa --flavor prod -t lib/main_prod.dart \
      --build-number="$RELEASE_BUILD_NUMBER" \
      --export-options-plist="$HOME/export_options.plist"
```

Replace the bundle identifier, pins, and artifact list with `build/ios/ipa/*.ipa` and the
archive dSYM files required for symbolication. Use actual shared schemes; match flavor
capitalization. `fdev ios` builds an iOS app, not a signed IPA export, so raw `flutter build
ipa` is intentional. `--no-codesign` validates compilation only and cannot prove distribution.

## Triggers and build numbers

After manual validation, optionally add a protected-tag trigger to an artifact workflow:

```yaml
triggering:
  events: [tag]
  tag_patterns:
    - pattern: 'v*'
      include: true
```

A tag pattern is a mapping, not a string list. Tag triggers aren't restricted by branch
patterns; enforce trusted tag creation and intended commit independently. A tag is not proof
that tests passed or publication was authorized. Review the YAML used from the source ref.
[Trigger semantics](https://docs.codemagic.io/yaml-running-builds/starting-builds-automatically/).

Keep marketing version in pubspec. A CI counter is not automatically above historical store
uploads. Seed or offset it, or use a central allocator; serialize release jobs to prevent
parallel jobs selecting the same next number. Re-uploading the same build needs a new number
where required, but retrying an upload must first check whether the first request succeeded.
Record the assigned number with the commit and artifacts.
[Codemagic versioning](https://docs.codemagic.io/knowledge-codemagic/build-versioning/).

## Explicit publishing step

Once authorized, attach publishing credentials only to the corresponding trusted workflow.
For Google Play, add `publishing.google_play` with `credentials: $GOOGLE_PLAY_SERVICE_ACCOUNT`,
`track: internal`, and `submit_as_draft: true` for a draft upload. Draft is not available to
testers until completed. Confirm first-upload prerequisites and the intended release status.
[Google Play publishing](https://docs.codemagic.io/yaml-publishing/google-play/).

For Apple, add `integrations.app_store_connect: asc_upload` using the configured integration
name, then `publishing.app_store_connect.auth: integration`. Set `submit_to_testflight` and
`submit_to_app_store` deliberately; uploading alone does not require submitting to review.
Do not expire other builds or choose beta groups without the intended distribution scope.
[Apple publishing](https://docs.codemagic.io/yaml-publishing/app-store-connect/).

If fastlane owns uploads, call its explicit upload lane and omit Codemagic store publishing
to prevent duplicate submission. Never rebuild a second, different binary just for upload.

## Validate and retain evidence

Parse YAML locally and validate against Codemagic's current schema/editor; syntax alone is
insufficient. Run checks without credentials, then a trusted artifact-only build, inspect
signing/identity/version, then authorized upload and store processing. Retain AAB/IPA,
checksums, symbol files, test reports, sanitized logs, commit, toolchain, flavor, and build
number. Do not archive signing material, environment dumps, or private API keys.
