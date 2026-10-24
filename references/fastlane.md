# Fastlane Setup and Release Lanes

Use an existing lane layout when present. Examples below use a root `fastlane/Fastfile`,
run through Bundler from the Flutter project root; they intentionally upload artifacts built
and verified earlier. Account setup/signing prerequisites: `codemagic-setup.md`.

## Reproducible setup

Choose a maintained Ruby compatible with the selected fastlane release using a version
manager. Commit its version file plus Gemfile/Gemfile.lock. Prefer Bundler over system Ruby
or a floating global gem. Resolve initially, then review and pin the resolved dependency set:

```ruby
# Gemfile
source "https://rubygems.org"
gem "fastlane"
```

Run `bundle install`, then use `bundle exec fastlane lanes` to inspect lanes. CI uses the
committed lockfile with frozen/deployment Bundler configuration; don't run bundle update in
every build. Use `bundle update fastlane` only for a scoped upgrade with lane verification.
`fastlane init` is optional scaffolding: inspect its generated files and remove implicit
upload/build behavior that doesn't match the project's intended pipeline.
[Official installation](https://docs.fastlane.tools/getting-started/ios/setup/).

## Signing is separate from upload authentication

Android needs an existing upload keystore wired into Gradle, plus Play API access for upload.
An existing app must keep its registered upload key. `fdev signapk` is for intentionally
creating a new app's upload key (fallback: keytool); don't run it in release jobs.

For iOS, select one signing owner. With match, first configure a team-controlled encrypted
private repository or supported storage backend, initialize its Matchfile, and populate
certificates/profiles in a deliberate local/admin session. Include all extension bundle IDs.
CI reads with `readonly: true`; it must not regenerate/revoke certificates routinely.
Protect MATCH_PASSWORD, storage access, signing private keys, and API credentials separately.

An ASC API key authorizes Apple API/upload actions; it does not replace the certificate's
private key or provisioning profile. For ephemeral runners using match, `setup_ci` can create
a temporary keychain before match. Don't also import competing Codemagic-managed identities.
Use `app_store_connect_api_key` with key_id, issuer_id, and a protected .p8 file, or the
supported provider key-content mechanism. Never put values in the Fastfile.
[match setup](https://docs.fastlane.tools/actions/match/),
[API key authentication](https://docs.fastlane.tools/app-store-connect-api/).

## Build once, then upload explicitly

Before lanes run: resolve → format → codegen if needed → analyze → test. Use `fdev gen`
(fallback `dart run build_runner build --delete-conflicting-outputs`). Build Android with
`fdev appbundle prod -t lib/main_prod.dart --build-number=<allocated-number>`; fallback
`flutter build appbundle --flavor prod -t lib/main_prod.dart --build-number=<allocated-number>`.
For IPA use `flutter build ipa` and the project's signing/export options; `fdev ios` builds
an app, not an IPA export. Allocate numbers above existing uploads across every pipeline.

After build, verify identifier, version, flavor, signer, and checksum. Upload the exact
artifact; don't rebuild during upload. The root Fastfile below requires explicit absolute
artifact paths and protected credential paths supplied by CI or local environment:

```ruby
# fastlane/Fastfile
platform :android do
  desc "Upload an already verified AAB as an internal draft"
  lane :upload_internal do
    aab = ENV.fetch("AAB_PATH")
    UI.user_error!("AAB missing") unless File.file?(aab)
    upload_to_play_store(
      package_name: ENV.fetch("ANDROID_PACKAGE_NAME"),
      json_key: ENV.fetch("PLAY_JSON_PATH"),
      aab: aab,
      track: "internal",
      release_status: "draft",
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end
end

platform :ios do
  desc "Upload an already verified IPA without distributing it"
  lane :upload_beta do
    ipa = ENV.fetch("IPA_PATH")
    UI.user_error!("IPA missing") unless File.file?(ipa)
    key = app_store_connect_api_key(
      key_id: ENV.fetch("ASC_KEY_ID"),
      issuer_id: ENV.fetch("ASC_ISSUER_ID"),
      key_filepath: ENV.fetch("ASC_KEY_PATH")
    )
    upload_to_testflight(
      api_key: key,
      ipa: ipa,
      skip_submission: true,
      skip_waiting_for_build_processing: true
    )
  end
end
```

Run `bundle exec fastlane android upload_internal` or `bundle exec fastlane ios upload_beta`
only for an intended upload. Draft Android releases need completion before testers can use
them. Apple upload completion does not establish processing, beta review, tester distribution,
or production review. Keep promotion/distribution lanes separate and explicit.
[Play action](https://docs.fastlane.tools/actions/upload_to_play_store/),
[TestFlight action](https://docs.fastlane.tools/actions/upload_to_testflight/).

## Metadata, promotion and recovery

Keep listing metadata/screenshots versioned in the project's chosen fastlane metadata path.
`fdev release-notes --notes "Describe the change"` generates Android-style changelog files;
fallback: write `<versionCode>.txt` under the chosen locale's changelogs directory.
Check locale, length and versionCode; it doesn't submit store forms or generate iOS review notes.
Use deliver for intended Apple listing/review actions and supply for Play metadata/track
promotion. Query the current store build before retrying an interrupted upload: the server
may have accepted it even if the client timed out. Don't allocate/reupload blindly.

| Symptom | Evidence to inspect |
|---|---|
| Ruby/gem conflict | Selected Ruby, bundle platform/lockfile, actual fastlane version |
| Missing signing identity | Keychain/private key, match access, profile/team/entitlements |
| Apple 401 or 403 | Key issuer/role/app permissions; signing and API auth are independent |
| Play 403 | Service account's app/track access and API enablement |
| Duplicate build | Store state plus build-number allocator and concurrent jobs |
| IPA/AAB missing | Absolute supplied artifact path; lane working-directory convention |
| Processing rejection | Store processing error and artifact configuration, not just lane exit |

Validate Ruby syntax, inspect lane listing, and execute an artifact-only/signing build before
upload. Syntax checks do not validate action options or account access. Record the successful
stage, artifact checksum, store build and pending steps. Keep credential files out of artifacts
and clean temporary files/keychains through the runner's lifecycle. Don't use match nuke or
revoke signing identities as routine troubleshooting.
