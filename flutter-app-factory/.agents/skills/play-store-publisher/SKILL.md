---
name: play-store-publisher
description: Prepare Android metadata and validate AAB identity/signing, then upload authorized internal testing builds or prepare an explicitly approved production release.
---

# play-store-publisher

Work from the factory root. Inspect `AGENTS.md`, the app's `app.yaml`, registry,
existing implementation and working tree first. Reuse existing settings; make the
smallest changes and never replace important configuration without reviewing its
diff. Ask only for essential missing identity or account information. Run relevant
checks, report failures with redacted evidence, and distinguish completed, blocked,
and unverified work. Never fabricate build or publishing success.

Read [shared operating rules](../../../docs/skills.md) and run
`python3 automation/scripts/factory.py --help` before using unfamiliar options.

Read [Android publishing](../../../docs/android-publishing.md) and
[credential checklist](../../../docs/credentials.md). Use the Google Play
Developer API or configured Codemagic Google Play publisher, not browser
automation where an official API supports the operation.

1. Resolve app/flavor/version, artifact and destination track. Production release
   requires fresh explicit approval tied to the reviewed release.
2. Run factory `metadata battery_analyzer` and `validate battery_analyzer --release`.
   Inspect actual AAB manifest application ID, versionCode/versionName, signing,
   target SDK and artifact hash using available official Android tools.
3. Prepare accurate localized metadata and release notes from real changes.
   Check required screenshots, privacy policy, Data Safety, content rating, ads
   declaration, app access instructions and account-specific testing requirements.
4. Verify account registration, app creation and initial Play setup are complete.
   API access and a service account with least necessary Play Console permissions
   are initial manual setup. Never commit the service-account key.
5. Plan `release battery_analyzer --version 1.2.0 --build-number 12 --targets
   play-internal` through `python3 automation/scripts/factory.py`.
   Only add `--execute --authorize-testing` when this exact testing deployment
   and its CI cost have been authorized. Do not retry an uncertain upload blindly.
6. Inspect `python3 -m automation.publishing.play --help` for direct adapter
   planning, authorized publishing or status checks. A `status` call with an
   existing `--edit-id` reads that edit; without it, the adapter reports a local
   receipt and does not prove live track state. Use app-specific journal paths
   rather than the shared default. Do not upload through the adapter if CI
   already uploaded this version code.
7. Poll Codemagic and the store API using returned identifiers. Capture Play edit,
   track/release status and matching version code where accessible.
8. Report separately: artifact built, upload accepted, processing/review, track
   release status, and tester availability. Build success or API upload acceptance
   is not proof that the application is publicly live.

Production is deliberately outside the default testing command. Prepare and
review the exact publisher/API action first, then obtain approval before mutation.
Keep signing secrets in CI and stop when critical validation or store checks fail.

