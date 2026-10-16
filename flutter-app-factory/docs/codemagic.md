# Codemagic setup

Run the factory as the root of its own GitHub repository. Codemagic reads
`codemagic.yaml` from the repository root. The copy bundled inside the skill
repository is a starter workspace; do not connect its parent skill repository
and expect a nested YAML file to be discovered.

The factory generates six explicit workflows per Android+iOS app:

| Workflow suffix | Result | Store action |
| --- | --- | --- |
| `dev-android-build` | Debug APK, development identity | None |
| `dev-ios-build` | Unsigned simulator app | None |
| `prod-android-build` | Signed release AAB | None |
| `prod-ios-build` | Signed distribution IPA | None |
| `prod-android-internal` | Signed release AAB | Google Play internal track |
| `prod-ios-testflight` | Signed distribution IPA | Upload and request TestFlight processing |

Every key begins with the app slug, for example
`battery_analyzer-prod-android-internal`. A production flavor identifies the
runtime environment; it does not authorize public production publishing.
No public production publisher or automatic build trigger is generated.
Starting any remote build requires authorization because it can consume paid
minutes. Internal/TestFlight workflows also require authorization to upload.

## Initial setup

1. Import the monorepo in Codemagic and grant access only to its GitHub repository.
2. Set `deployment.codemagic_app_id` to the Codemagic repository application ID.
   Each app in this monorepo may reference the same Codemagic application ID.
3. Create separate secret variable groups per app and environment. Use
   `deployment.environment_groups.dev` and `.prod`; the fallback imports
   `deployment.environment_group` only for prod and `<slug>_dev` for dev.
4. Upload an Android upload keystore under Code signing identities and set
   `android.signing_reference` to its reference. Codemagic supplies
   `CM_KEYSTORE_PATH`, `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS`, `CM_KEY_PASSWORD`.
   Generated Gradle release signing reads these variables and fails when absent.
5. Upload Apple distribution certificates and provisioning profiles matching
   each production bundle ID. The YAML uses `ios_signing` with `app_store` and
   the configured bundle identifier, then runs `xcode-project use-profiles`.
   Register capabilities and create profiles in the Apple developer account.
6. Create an App Store Connect integration in Codemagic Team integrations.
   Set `deployment.app_store_connect_integration` to its reference name.
   Keep the `.p8` private key in Codemagic, never in this repository.
7. Add the Play service account JSON as a **Secret** variable in the prod group.
   Its variable name defaults to `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` and can
   be changed using `deployment.play_credentials_variable`. Grant this service
   account only the required Play Console app and release permissions.
8. Complete store app records, agreements, privacy disclosures, required listing
   assets, and first-upload requirements. API access cannot complete account
   verification or bypass store review. New Google Play apps may require a first
   upload in Play Console before API publishing works.
9. Add verified email recipients with `deployment.notification_emails`. Generated
   email notifications include build failures and successes. Without recipients
   configured, email notifications are inactive; use the Codemagic dashboard.

Nonsecret configuration example (inside an app's `deployment` mapping):

```yaml
provider: codemagic
codemagic_app_id: REPLACE_ME
branch: main
environment_groups:
  dev: battery_analyzer_dev
  prod: battery_analyzer_prod
app_store_connect_integration: REPLACE_ME
play_credentials_variable: GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
notification_emails: []
testflight_groups: []
```

Firebase-enabled apps additionally require their flavor-specific Firebase files
in the selected secret environment group. `ci-prepare` validates their identities
and materializes them before the build. Never give the dev group prod credentials.
AdMob IDs and Firebase client configuration identify public client integrations;
private signing keys and service accounts remain server-side secrets.

## Generate and inspect

From the factory root:

```bash
python3 -m pip install -r automation/requirements.txt
python3 automation/scripts/factory.py ci-generate
```

Generation reads each `apps/<slug>/app.yaml`, preserves independent version and
build numbers, and refuses to overwrite a handwritten `codemagic.yaml`.
Edit configuration and regenerate; review the diff before committing it.
Increase each app's build number before another store upload. Retrying an upload
with a used build number fails; the factory does not guess the latest store number.

Each workflow prepares config, resolves dependencies, validates, analyzes/tests
the app and shared packages, applies signing for release archives, and builds.
Production workflows require the release validator to pass. Artifacts are
collected from that app's paths, rather than from unrelated app output folders.

Automatic webhooks are opt-in. After reviewing build cost and branch protection,
you may add `triggering.events: [push]` and appropriate branch patterns to selected
development workflows. Incorporate that choice in the generator if it should
survive regeneration. Each generated workflow already has `when.changeset.includes`
for its app, `packages/`, and `automation/`. Shared package changes intentionally
affect consumers. Codemagic always includes changes to `codemagic.yaml`; a skip
decision happens after fetching source and can still consume build resources.
Do not attach release credentials or store publishers to untrusted PR workflows.

## Build API and status

Set `CODEMAGIC_API_TOKEN` in the caller's secure environment. Do not put it in a
command argument, configuration file, shell history, or logs. The factory's
`build` and release commands select an existing workflow key, then use the
documented `POST https://api.codemagic.io/builds` endpoint. The API accepts the
Codemagic application ID, YAML workflow key, and branch. It does not construct
arbitrary dynamic workflows. API-started builds ignore webhook branch filters;
the agent must validate the requested app, environment, branch and authorization.

`automation/workflows/ci.py` also provides the Python functions
`generate(root)`, `trigger(token, application_id, workflow_id, branch)` and
`status(token, build_id)`. The trigger performs one POST without retries to avoid
duplicate billable builds. Responses and errors are reduced to safe fields; raw
provider payloads and authentication values are never logged.

Status uses `GET https://codemagic.io/api/v3/builds/<build_id>` and reads
`data.status`. `finished` means the build completed; `failed`, `canceled`,
`timeout`, and `skipped` are unsuccessful terminal outcomes. There is no separate
`success` status. Store distribution remains unconfirmed until its API verifies
the uploaded artifact and target track or TestFlight availability. Apple
post-processing runs asynchronously and may continue after a successful build.
Check publishing logs and App Store Connect when that step is delayed.

## Validation and maintenance

```bash
python3 -m unittest discover -s automation -p test_ci.py -v
```

The offline tests cover app selection, isolated environment groups, absent public
production publishers, release validation, idempotence, overwrite protection,
API response filtering and status semantics. Generated fixtures were additionally
validated against Codemagic's official JSON schema during implementation. IDEs
can use the schema directive in generated YAML; schema validation cannot verify
credentials, signing entitlement, build-machine access, or store readiness.

Verified official references:

- [YAML structure and JSON schema](https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/)
- [Flutter build and signing configuration](https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/)
- [iOS signing identities](https://docs.codemagic.io/yaml-code-signing/signing-ios/)
- [Monorepo changeset conditions](https://docs.codemagic.io/yaml-running-builds/starting-builds-automatically/)
- [Build trigger API](https://docs.codemagic.io/rest-api/builds/)
- [Build status API and status values](https://docs.codemagic.io/integrations/jenkins-integration/)
- [Google Play publishing](https://docs.codemagic.io/yaml-publishing/google-play/)
- [App Store Connect and asynchronous post-processing](https://docs.codemagic.io/yaml-publishing/app-store-connect/)
- [Email notifications](https://docs.codemagic.io/yaml-notification/email/)
