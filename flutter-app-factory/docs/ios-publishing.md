# iOS publishing

Use the generated Codemagic iOS workflow for routine signed builds. Direct tools provide
official Apple delivery, metadata updates, and verifiable TestFlight status. Run commands
from the factory root. They do not submit an application for production review.

## Initial manual setup

1. Join the Apple Developer Program, accept agreements, complete tax/banking and required
   trader information, register the production bundle ID and capabilities, and create the
   App Store Connect app record. Keep dev and prod identities separate.
2. Configure distribution certificates/profiles and the Codemagic App Store Connect
   integration. Store signing material in Codemagic; never commit a `.p12`, `.p8`, or
   provisioning profile.
3. Create a team App Store Connect API key with minimum required app/build permissions.
   Set `ASC_KEY_ID`, `ASC_ISSUER_ID`, and `ASC_PRIVATE_KEY_PATH` securely. The last variable
   points to a protected local key file, never inline key material. Individual API keys
   are not supported by these tools. See [credentials](credentials.md).
4. Install current supported Xcode on macOS and select it with your standard developer
   tool setup. Check Apple's current SDK/upload requirements at release time; they change.
   [Apple build upload requirements](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds)
5. Configure internal testers and an internal TestFlight group. External testing may
   require Beta App Review and is intentionally not auto-submitted here.

## Local artifact plan

```bash
python3 -m automation.publishing.apple plan \
  --bundle-id org.example.app --app-id 1234567890 \
  --artifact apps/app_one/build/ios/ipa/app_one.ipa
```

Planning reads the IPA without extraction and verifies its primary bundle ID, marketing
version, build number, ZIP integrity, and presence of code-signature resources. It does
not authenticate or contact Apple. Apple's online validation still establishes signing,
entitlement, provisioning, and submission compatibility.

## Authorized binary delivery

After the user authorizes the upload of this version:

```bash
python3 -m automation.publishing.apple upload \
  --bundle-id org.example.app --app-id 1234567890 \
  --artifact apps/app_one/build/ios/ipa/app_one.ipa \
  --journal .factory/releases/app_one-ios-1.2.0-12.json \
  --authorize-upload
```

The client verifies the numeric app ID against the bundle ID through App Store Connect,
checks for an existing version/build, validates with `xcrun altool --validate-app`, then
delivers with `xcrun altool --upload-package`. Apple deprecates `--upload-app` in favor
of `--upload-package`. Add `--provider-id` if the account needs provider disambiguation.
The key is copied into a private temporary directory for altool and removed on exit.
[Apple altool reference](https://help.apple.com/asc/appsaltool/en.lproj/static.html)

The successful result is a delivery receipt. Processing, export compliance, TestFlight
eligibility, and review remain separate states. This implementation uses Apple's native
upload tool; it does not send IPA bytes to an unrelated metadata endpoint.

## Confirm processing and internal TestFlight

```bash
python3 -m automation.publishing.apple status \
  --bundle-id org.example.app --app-id 1234567890 \
  --version 1.2.0 --build-number 12
```

Status returns the actual build, processing state, beta build details, and available beta
review state. A `VALID` build alone is insufficient evidence of tester availability.
[Apple build query](https://developer.apple.com/documentation/appstoreconnectapi/get-v1-builds)

After obtaining the exact build and internal group IDs, and authorization to distribute:

```bash
python3 -m automation.publishing.apple testflight \
  --bundle-id org.example.app --app-id 1234567890 \
  --build-id BUILD_RESOURCE_ID --group-id INTERNAL_GROUP_RESOURCE_ID \
  --authorize-write
```

The client verifies both resources belong to the selected app, rejects expired/unprocessed
builds and external groups, assigns the relationship only if missing, and reads it back.
It reports group assignment separately from `internalBuildState`; tester availability
is true only for Apple's `IN_BETA_TESTING` state. Users still need valid tester membership.
[Add builds to a beta group](https://developer.apple.com/documentation/appstoreconnectapi/post-v1-betagroups-_id_-relationships-builds)

## Version metadata and production preparation

Prepare reviewed JSON mapping locales to `description`, `keywords`, `promotionalText`,
`whatsNew`, `supportUrl`, and `marketingUrl`. Fields may be partial. Keywords are limited
to 100 UTF-8 bytes; description and release notes to 4000 characters; promotional text
to 170. App name/subtitle/privacy URL belong to app info and must be managed separately.
[Apple platform fields](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)

```bash
python3 -m automation.publishing.apple_metadata plan \
  --bundle-id org.example.app --app-id 1234567890 \
  --metadata apps/app_one/store/apple-version.json
```

Only after reviewing and authorizing the edits, run `apply` with the same arguments plus
`--version-id APP_STORE_VERSION_RESOURCE_ID --authorize-write`. The client checks ownership,
creates or updates locale resources, and verifies values by reading them back. Applying
promotional text may affect an existing product page; review the target version first.
[Modify version localization](https://developer.apple.com/documentation/appstoreconnectapi/patch-v1-appstoreversionlocalizations-_id_)

Use `python3 -m automation.publishing.apple releases --bundle-id org.example.app
--app-id 1234567890` on one shell line to retrieve actual App Store version/review states.
The client returns Apple's response including pagination links; inspect subsequent pages
if needed. Before production submission, obtain explicit approval for app/version/build,
review screenshots, privacy labels/manifests, permissions, IDFA/ATT decisions, encryption,
age rating, support URL, review contact/demo access, and release timing. Submit through
App Store Connect after approval; Apple's review is mandatory. Do not label TestFlight,
delivery, or a pending review as a public release.

## Retry safely

Keep private ignored journals and use one journal per artifact. Successful deliveries are
not repeated. An interrupted delivery blocks automatic re-upload: query the exact
marketing version/build and inspect Apple's delivery history first. Reconcile unknown
outcomes manually before deliberately starting another attempt. Increment build numbers
for genuinely new artifacts; never reuse a build number to hide an upload failure.
