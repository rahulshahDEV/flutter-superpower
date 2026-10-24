# Shorebird Release and OTA Operations

Adopt only when the project wants OTA; it changes distribution and compilation. Checked with
Shorebird 1.6.123 and official docs on 2026-10-24. Inspect installed help before using newer
features. CI integration: `shorebird-ci.md`; store readiness: `release.md`.

## Eligibility and adoption

| Change | Delivery |
|---|---|
| Dart logic/generated Dart compatible with the shipped native binary | Candidate for patch |
| Fonts, images, bundled assets | New store release |
| Native plugin/code/config/permissions/entitlements | New store release |
| Engine/Flutter upgrade | New store release |

Inspect the complete diff, pubspec/lockfile and native transitive dependencies. A Dart package
upgrade may still change native code or assets. The CLI compares release artifacts, but
passing that check alone doesn't establish behavioral or store-policy compatibility. Don't
bypass legitimate asset/native diffs with allow-diffs flags; those changes aren't delivered.
[Patch checks](https://docs.shorebird.dev/code-push/patch/).

Install through the official platform instructions, then run `shorebird --version` and
`shorebird doctor`. Local browser login uses `shorebird login`. Initialize from the app root
with `shorebird init` only after adoption is intended; inspect its diff and commit generated
public app configuration. Preserve the flavor-to-app-ID mapping it generates. Public IDs
aren't credentials; do not substitute production IDs into a dev flavor.
[Initialization](https://docs.shorebird.dev/code-push/initialize/).

## Establish the store baseline

Shorebird builds use its Flutter distribution. Record the selected Flutter version, build
inputs, flavor, target, public config, app ID, git commit, signing/export flags and version.
Replace TESTED_FLUTTER below with the tested version supported by Shorebird. Native flavors
and signing must already work. For an app at pubspec version `1.4.0+12`:

```bash
shorebird release android --flavor prod -t lib/main_prod.dart --flutter-version=TESTED_FLUTTER
shorebird release ios --flavor prod -t lib/main_prod.dart --flutter-version=TESTED_FLUTTER
```

These commands create/upload a Shorebird baseline; distribute the resulting AAB/IPA through
the usual store pipeline. Never replace it with a separately rebuilt plain-Flutter binary.
Install the distributed baseline and verify identity/version before testing a patch. A normal
Flutter debug build cannot demonstrate OTA delivery. Retain artifacts and matching symbols.
[Release workflow](https://docs.shorebird.dev/code-push/release/).

## Target, validate and stage a patch

1. Identify the exact installed release `X.Y.Z+N`, platform and flavor. Avoid `latest` when
   multiple releases/teams are active. Preserve compatible config/defines/entrypoint.
2. Run the normal format → codegen if needed → analyze → test gate using a compatible SDK.
3. Inspect patch eligibility and any persisted-data changes. Keep data migrations compatible
   with the base/prior patch where rollback is expected; code rollback doesn't undo data.
4. Validate against the chosen release, then explicitly publish to staging when intended:

```bash
shorebird patch android --flavor prod -t lib/main_prod.dart --release-version=1.4.0+12 --track=staging --dry-run
shorebird patch android --flavor prod -t lib/main_prod.dart --release-version=1.4.0+12 --track=staging
shorebird preview --app-id=PROD_APP_ID --release-version=1.4.0+12 --track=staging
```

Replace PROD_APP_ID with the production flavor ID in shorebird.yaml; preview 1.6.123 uses
app-id rather than a flavor flag. Repeat for iOS with its actual release/signing requirements. A patch resolves the release's
Flutter revision; don't change engines or silently select a different baseline. Staging
publication still uploads remotely. `--dry-run` builds/validates without uploading; it may
still require remote baseline access. Use it as validation, not as proof devices updated.

## Tracks, promotion and recovery

Track selection controls which patch a device receives. Publishing to staging does not put
ordinary stable users on that track. Use preview or the supported updater track selection
for testers. Built-in stable/beta/staging and newer custom-track tooling vary by CLI/runtime
version; verify current support before inventing track-management commands.
[Track behavior](https://docs.shorebird.dev/code-push/tracks/).

Record the patch number returned by upload, then promote that same tested patch:

```bash
shorebird patches promote --flavor prod --release-version=1.4.0+12 --patch-number=2
shorebird patches rollback --flavor prod --release-version=1.4.0+12 --patch-number=2
```

Those are remote mutations: choose the exact app/release/patch and intended operation first.
The Console provides an alternative on older clients. Rollback serves the highest eligible
prior patch or base release; it isn't instant removal from every offline device. Test
restart/check behavior and observe patch telemetry. Rolling back an already superseded patch
changes future fallback, not necessarily the currently served patch.
[Rollback semantics](https://docs.shorebird.dev/code-push/rollback/).

Default update behavior downloads in the background and activates on a subsequent launch.
Don't promise a live Dart-code hot swap. If the product needs explicit checks, evaluate
shorebird_code_push and model checking/downloading/restart-required/offline/error states.
Keep a usable fallback and respect user work rather than forcing a loop at launch.
[Update strategies](https://docs.shorebird.dev/code-push/update-strategies/).

## Operational evidence

Verify a device installed from the correct baseline: current patch before, staging update,
restart, current patch after, fixed behavior, offline launch, and rollback recovery. Test
real release conditions and collect app version/patch identity with sanitized crash telemetry.
Assess current store policies for the specific change; avoid claims that OTA is automatically
approved for every feature or that it can bypass review/permissions requirements.

| Failure | First check |
|---|---|
| No patch observed | Installed baseline has Shorebird, correct app/flavor/release/track, network/restart |
| Patch rejected | Native/asset diff and build inputs; store release may be required |
| Wrong version selected | Explicit release version, Android/iOS baseline distinction |
| Runtime failure after patch | Matching symbols, patch ID, native compatibility, rollback path |
| CI auth failure | API key scope/expiration and protected workflow secret group |

Report exact commands/versions and observed device behavior. Upload success, activation,
crash-free operation, promotion and rollback are separate claims.
