# Android publishing

The normal release path is the generated Codemagic workflow. The direct publisher is an
independent recovery/integration tool using Google's official edits API. Planning is local;
uploading requires explicit authorization. Run these commands from the factory root.

## Initial manual setup

1. Create the Play Console app, confirm its permanent application ID, complete developer
   verification, agreements, app access, content rating, Data safety, ads declarations,
   privacy policy, target audience, and any account-specific testing requirements.
2. Configure Play App Signing and retain the upload keystore in secure storage. Give
   Codemagic the upload key and passwords through its signing/secret facilities.
3. Complete the initial Console upload/setup. Google documents edits as operating on
   existing apps with an initial uploaded artifact; legal publishing consents remain
   Console tasks. Do not promise that the API creates a new store app.
   [Google edits guide](https://developers.google.com/android-publisher/edits)
4. Enable the Android Publisher API and grant a service account access to this specific
   app and required testing tracks. Set `GOOGLE_APPLICATION_CREDENTIALS` to a protected,
   temporary credential file outside source control, or use an appropriate Application
   Default Credentials identity. See [credentials](credentials.md).
5. Install the Python requirements, Java, and Google's bundletool. Set `BUNDLETOOL_JAR`
   to the verified local bundletool JAR. Uploads fail closed without manifest validation.

## Prepare and validate

The app configuration selects the production identifier even for an internal testing
release. `dev` IDs represent a different application and require a separate store record.
Run the factory release validator first, then inspect the signed AAB:

```bash
python3 -m automation.publishing.play plan \
  --package-id org.example.app \
  --artifact apps/app_one/build/app/outputs/bundle/prodRelease/app-prod-release.aab \
  --track internal
```

This checks ZIP structure and signing certificate presence. With `BUNDLETOOL_JAR` set,
it also verifies the manifest package/version and JAR integrity. Planning never authenticates
or sends network requests. Signature presence alone does not establish that the upload
certificate is the one registered in Play; Google validates that on upload.

Release notes are a reviewed UTF-8 text file, at most 500 characters per locale. Optional
listing JSON uses the exact Google fields:

```json
{
  "en-US": {
    "title": "Example Utility",
    "shortDescription": "A clear description of the utility.",
    "fullDescription": "Explain actual features, limitations, and privacy behavior."
  }
}
```

The client validates title 30, short description 80, and full description 4000 character
limits. Asset upload and policy questionnaires remain separate tasks.

## Upload after authorization

Only run this after the user has authorized uploading this app/version to internal testing:

```bash
python3 -m automation.publishing.play publish \
  --package-id org.example.app \
  --artifact apps/app_one/build/app/outputs/bundle/prodRelease/app-prod-release.aab \
  --track internal --release-status completed \
  --release-notes apps/app_one/store/release-notes.txt \
  --journal .factory/releases/app_one-android-1.2.0-12.json \
  --authorize-upload
```

`draft` is the default release status and does not distribute a build. Choose `completed`
explicitly for an authorized testing release. The client creates/resumes an edit, checks
existing bundle hashes, uploads the AAB, updates the selected track, reads it back,
validates the edit, and commits it. These are official Google endpoints:
[bundle upload](https://developers.google.com/android-publisher/api-ref/rest/v3/edits.bundles/upload),
[tracks](https://developers.google.com/android-publisher/api-ref/rest/v3/edits.tracks),
[commit](https://developers.google.com/android-publisher/api-ref/rest/v3/edits/commit).

The track update replaces the selected track's releases with the new bundle. It blocks
existing staged/halted rollouts; review specialized delivery or retained-version needs
before using it. Other tracks are not changed. Optional `--metadata FILE.json` updates
the supplied localized listings in the same edit. The commit requests
`ERROR_IF_IN_REVIEW` to preserve an existing review rather than cancel it.

Production additionally requires a fresh, explicit user approval covering app, version,
track, and release behavior, then `--track production --approve-production`. A flag is a
record of approval supplied by the operator, never a substitute for asking the user.

## Receipts, status, and recovery

```bash
python3 -m automation.publishing.play status \
  --package-id org.example.app --track internal \
  --journal .factory/releases/app_one-android-1.2.0-12.json
```

Without `--edit-id`, status reads the local receipt and explicitly says live store status
was not queried. `--edit-id ID` reads an existing uncommitted edit and track through the
API without creating another edit. Final availability, review, managed publishing,
tester enrollment, and production visibility must be confirmed in Play Console.
An accepted edit is never reported as a publicly live application.

Keep ignored journals between retries and archive them with private release logs.
Use a separate journal per artifact/target; do not run competing publishers for one app.
Read requests retry transient errors; writes do not blindly retry. If upload completion
is uncertain, the same edit can reconcile the bundle by version code and SHA256. If
creation/commit completion is uncertain, the client blocks and requires Console
reconciliation. Never delete a receipt just to force another upload. A stale lock may
be removed only after confirming no publisher process remains active.

An expired edit or a concurrent Console change can invalidate the edit. Reconcile the
actual uploaded version and track first, then deliberately start a new journal if needed.
No CAPTCHA automation, legal-consent automation, or review bypass is provided.
