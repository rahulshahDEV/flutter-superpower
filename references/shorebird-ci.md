# Shorebird in CI and Delivery Pipelines

Read `shorebird.md` first. Keep check, baseline release, staged patch and promotion as distinct
jobs. Hosted setup/signing: `codemagic-setup.md`; upload lanes: `fastlane.md`.

## Toolchain and credentials

Install a controlled Shorebird version using the supported installer/distribution and verify
`shorebird --version` plus `shorebird doctor`. Pin the Flutter version on baseline releases;
patches use the target release's revision. Shorebird does not install the required Android
SDK/JDK or Apple Xcode/signing setup. Avoid floating tool upgrades during a release job.
[Generic CI setup](https://docs.shorebird.dev/code-push/ci/generic/).

Create a scoped, expiring API key in Shorebird Console → Account → API Keys, or the team's
supported service-account setup. Store it as protected `SHOREBIRD_TOKEN`; never log it or
put it in app assets. Legacy login:ci tokens are obsolete; consult current migration docs
rather than generating one. Separate development and production app permissions where possible.
Set CI noninteractive behavior using the installed client's documented options. Never use
noninteractive confirmation to turn an unspecified target into production publication.

CI API credentials must not be exposed to untrusted PR code, even for a dry run. If validating
against a remote private baseline needs credentials, use a trusted workflow/ref and the
least required access. Secret-free PR tests remain valuable without a Shorebird upload.

## Codemagic patch validation example

This is a manually selected, dry-run workflow for an already adopted/flavored app. Replace
SDK pins, attach the protected group `ota_validation` with SHOREBIRD_TOKEN, public ENV_PROD,
and RELEASE_VERSION. A runner image/install step must provision the controlled Shorebird
binary on PATH. It is intentionally a validation job, not a publishing trigger.

```yaml
workflows:
  ota-validate:
    name: Validate a specific Android patch
    max_build_duration: 60
    environment:
      flutter: REPLACE_WITH_MATCHING_FLUTTER
      groups: [ota_validation]
    scripts:
      - name: Prepare inputs
        script: |
          set -eu
          umask 077
          : "${SHOREBIRD_TOKEN:?Missing scoped credential}"
          : "${ENV_PROD:?Missing public production config}"
          : "${RELEASE_VERSION:?Choose the exact baseline}"
          printf '%s\n' "$ENV_PROD" > .env.prod
          cp .env.sample .env.dev
          shorebird --version
          shorebird doctor
          flutter pub get
          dart format --output=none --set-exit-if-changed lib test
          if command -v fdev >/dev/null 2>&1; then fdev gen; else
            dart run build_runner build --delete-conflicting-outputs
          fi
          flutter analyze
          flutter test
      - name: Validate against baseline
        script: |
          set -eu
          shorebird patch android --flavor prod -t lib/main_prod.dart \
            --release-version="$RELEASE_VERSION" --track=staging --dry-run
```

Match public config/defines and dependency inputs to the original release; a modified dotenv
asset is still an asset difference. Configure the runner's signed native build inputs when
required. For iOS, use macOS with appropriate Xcode/export/profile setup. An unsigned
validation does not establish a valid distribution artifact.
[Codemagic integration](https://docs.shorebird.dev/code-push/ci/codemagic/).

## Baseline release job

Reuse the trusted artifact workflow and signing configuration. Replace its Flutter compiler
step with `shorebird release android` or `shorebird release ios`, including explicit flavor,
entrypoint, Flutter version, allocated build number, defines, and export options as needed.
Keep one compiler owner: never run fdev appbundle afterwards and upload that different binary.
Use fastlane/Codemagic only to publish the actual Shorebird artifact to stores. Retain
matching Dart/native symbols and release inputs for patch reproducibility.

## Stage, promote and recover

After dry-run validation and intended publication, a separate job runs the exact patch
command without `--dry-run` on staging. Capture app/release/platform/flavor/patch number and
commit. Test it on a device subscribed to that track, then promote that exact patch number
via the verified CLI/Console operation. Don't rebuild source and call it the tested patch.
Maintain intended production access separately from validation when the account supports it.

Fastlane may invoke the CLI from an existing lane with checked environment inputs; use the
project's established orchestration rather than installing a second upload stack. Verify
current plugin/CLI compatibility before introducing the fastlane Shorebird plugin.
[Fastlane integration](https://docs.shorebird.dev/code-push/ci/fastlane/).

A successful command is not a fleet-wide activation guarantee. Monitor by baseline version,
patch number and track; retain the rollback operation and compatible previous state. On a
failed/timeout upload, query remote patch state before retrying. Avoid publishing multiple
patches accidentally. Rollback doesn't reverse server writes or local schema migrations.
