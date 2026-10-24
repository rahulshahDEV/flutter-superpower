# Codemagic Setup and Signing

Read before adding a release workflow. YAML examples and publication are in
`codemagic-workflows.md`. Guidance checked against official documentation on 2026-10-24;
verify live account UI and runner availability when implementing.

## Repository and toolchain

1. Connect the repository provider and grant access to the intended repository. Add the app
   in Codemagic and select YAML configuration. Put `codemagic.yaml` at repository root;
   for a monorepo, explicitly set the script working directory to the Flutter package.
2. Inventory actual Android product flavors, iOS shared schemes/configurations, entrypoints,
   bundle/application IDs, build mode, and configuration assets. CI cannot invent native
   flavors from `main_prod.dart` alone.
3. Select a machine with the needed toolchain: macOS/Xcode for iOS; Android may use Linux or
   macOS. Pin a tested Flutter release and supported Xcode/JDK/CocoaPods/Ruby versions.
   Record these choices in YAML; do not blindly copy an old SDK number from this skill.
4. Run the secret-free check workflow manually first. Confirm the intended commit and
   working directory, dependency resolution, generated files, analyzer, and tests.
5. Enable PR triggers only after check-only validation works. Release signing and store
   credentials belong only to trusted release workflows.

Source: [Codemagic YAML configuration](https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/).

## Variables, trust, and configuration

Create separate groups for public build configuration, signing, and publishing access.
Mark credentials secret and attach only the groups a workflow needs. Named integration and
keystore references in YAML are identifiers, not credentials. Never put keys in YAML.

PR code can change build scripts and YAML. Don't expose release secrets to untrusted PRs;
use provider permissions/trusted workflows as the boundary, not a shell `if` inside attacker-
editable code. Protect release branches/tags and restrict who can run privileged workflows.
Do not enable shell tracing around secrets. Masking is a last defense, not permission to log.

A CI variable is not automatically a Flutter asset or Dart define. Materialize the expected
non-secret `.env` files before building. Bundle only public runtime values; assets and
`--dart-define` do not hide secrets from users. Signing files and API credentials must never
be included in Flutter assets, artifacts, logs, or caches. Use restrictive file permissions
and remove temporary credential files after the job.

Source: [Environment groups](https://docs.codemagic.io/yaml-basic-configuration/configuring-environment-variables/).

## Android signing

Keep the existing upload key for an existing app. Do not generate a new one to bypass a
password problem. For a new app, `fdev signapk` can create the key; raw fallback is `keytool`
with a project-chosen alias, RSA parameters, and protected output path. Retain an encrypted
backup outside CI. Google Play app-signing and upload keys have different roles.

Upload the keystore in team Code signing identities → Android keystores with its passwords,
alias, and a reference such as `android_upload`. Reference it under `environment.android_signing`.
Codemagic supplies `CM_KEYSTORE_PATH`, `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS`, and
`CM_KEY_PASSWORD`. Connect those to the existing Gradle release signing configuration;
merely uploading the file does not change Gradle. For Kotlin DSL, the relevant block is:

```kotlin
android {
    signingConfigs {
        create("release") {
            storeFile = file(requireNotNull(System.getenv("CM_KEYSTORE_PATH")))
            storePassword = System.getenv("CM_KEYSTORE_PASSWORD")
            keyAlias = System.getenv("CM_KEY_ALIAS")
            keyPassword = System.getenv("CM_KEY_PASSWORD")
        }
    }
    buildTypes {
        getByName("release") { signingConfig = signingConfigs.getByName("release") }
    }
}
```

Merge this into the existing block; do not duplicate a `release` signing config. If local
builds use key.properties, preserve that path with an explicit environment/file selection.
A debug workflow must not eagerly require CI signing variables during Gradle configuration;
load this config only when signing inputs exist, and fail a release build if they are absent.
Check the artifact signer against the registered upload certificate, e.g. with `fdev sha`
(raw fallback `keytool -list -v -keystore <file>`), before first upload.

Source: [Android signing identities](https://docs.codemagic.io/yaml-code-signing/signing-android/).

## iOS signing and App Store Connect authentication

These are separate requirements:

- The signing identity is a distribution certificate **with its private key**, plus matching
  provisioning profiles for the app and every extension/capability.
- The App Store Connect API key authenticates supported Apple API/upload operations. It is
  not a replacement for a signing certificate or provisioning profile.

Choose one signing owner: Codemagic-managed identities, existing manual setup, or fastlane
match. Don't import two competing profile/certificate sets into one job.

For Codemagic-managed identities, add the Apple Developer Portal integration using the
team API key (.p8, issuer ID, key ID) with adequate permissions. In Code signing identities,
create/fetch or upload the distribution certificate and app-store profiles. Match the team,
bundle ID, entitlements, scheme, and profile expiration. Uploading a public .cer alone
without the private key is insufficient.

Select profiles using `environment.ios_signing.distribution_type: app_store` and
`bundle_identifier`, OR explicit certificate/profile reference lists; don't combine those
selection modes. Run `xcode-project use-profiles` before the IPA build; use its generated
export-options plist. Include extension profiles and correct bundle identifiers.

Source: [iOS identities and profile application](https://docs.codemagic.io/yaml-code-signing/signing-ios/).

## Store access and first upload

For Google Play, create a service account, enable required API access, and invite its email
in Play Console with the app/track permissions needed. Store the JSON credential in a secret
group. A Cloud role alone does not grant Play release rights. Complete the app record and
first manual upload/setup before relying on automated delivery.
[Google Play setup](https://docs.codemagic.io/yaml-publishing/google-play/).

For Apple, create the App Store Connect app record with the matching bundle ID; confirm
agreements and relevant account access. Name the API integration in YAML for publishing.
Archive/export first, then upload and inspect processing separately. Beta review, tester
distribution, store review, and public release are distinct actions.
[Apple publishing setup](https://docs.codemagic.io/yaml-publishing/app-store-connect/).

## Diagnose by stage

| Failure | Check first |
|---|---|
| No workflow starts | YAML location, source-branch YAML, webhook delivery, pattern syntax |
| Packages/codegen fail | Flutter pin, private package access, lockfile, build-hook compatibility |
| Android signs with debug key | release signingConfig binding, flavor overrides, key inputs |
| Android wrong key | upload certificate registered in Play; don't replace key casually |
| iOS no profile/private key | identity import, team, scheme, entitlements, extensions, expiration |
| IPA export fails | generated export options, distribution type, archive's signing |
| Store 401/403 | API key/account role/app access; signing success does not prove API access |
| Duplicate build number | allocation policy across all pipelines and manual uploads |
| Build succeeds but no artifact | actual flavor output path and artifact glob |

Record sanitized failing stage/log excerpts, not credential values. Run a clean trusted
build after repair; clearing caches is appropriate only for demonstrated stale artifacts.
