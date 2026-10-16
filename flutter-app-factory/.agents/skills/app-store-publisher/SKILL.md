---
name: app-store-publisher
description: Prepare App Store Connect metadata, validate signed IPA identity, deploy authorized TestFlight builds and prepare reviewed App Store submissions.
---

# app-store-publisher

Work from the factory root. Inspect `AGENTS.md`, the app's `app.yaml`, registry,
existing implementation and working tree first. Reuse existing settings; make the
smallest changes and never replace important configuration without reviewing its
diff. Ask only for essential missing identity or account information. Run relevant
checks, report failures with redacted evidence, and distinguish completed, blocked,
and unverified work. Never fabricate build or publishing success.

Read [shared operating rules](../../../docs/skills.md) and run
`python3 automation/scripts/factory.py --help` before using unfamiliar options.

Read [iOS publishing](../../../docs/ios-publishing.md) and
[credential checklist](../../../docs/credentials.md). Prefer App Store Connect
API and supported Apple upload tools through Codemagic for binary delivery.

1. Resolve the app record, production bundle ID, version/build number, platform
   and requested TestFlight/App Store destination. Inspect enabled capabilities.
2. Run factory `metadata battery_analyzer` and `validate battery_analyzer --release`.
   Inspect IPA Info.plist, signing entitlements/provisioning profile, version and
   artifact hash using available Apple tooling. A filename does not prove identity.
3. Prepare truthful localized metadata/release notes, screenshots, privacy/support
   URLs, App Privacy, export compliance, age rating, reviewer access and required
   account agreements. Do not invent legal or privacy answers.
4. Use configured Apple integration/API credentials with least necessary access.
   Initial developer enrollment, app record, certificates/profiles and agreements
   may require owner action. Keep .p8 keys and signing passwords outside source.
5. Plan `release battery_analyzer --version 1.2.0 --build-number 12 --targets
   testflight` through `python3 automation/scripts/factory.py`.
   Add `--execute --authorize-testing` only after authorization for the concrete
   TestFlight deployment and CI cost. Do not automatically submit for production.
6. Inspect `python3 -m automation.publishing.apple --help` for the direct adapter.
   Its read-only `status --bundle-id BUNDLE_ID --app-id APP_ID --version VERSION
   --build-number NUMBER` queries build processing/beta details. Use app-specific
   journals for writes and never re-upload a build already delivered by CI.
   `python3 -m automation.publishing.apple_metadata --help` describes separately
   planned/authorized version-localization writes; app-info fields are separate.
7. Poll the returned build and App Store Connect records. Distinguish upload,
   processing, encryption/compliance questions, internal testing, external beta
   review and App Store review. External testers may require beta review.
8. Report confirmed states with IDs and timestamps; processing does not mean
   available to testers, and TestFlight success does not mean publicly released.

A production submission/release requires fresh explicit approval tied to reviewed
app/version/build/destination. Never bypass Apple review or automatically answer
contracts, export compliance or privacy declarations without factual input.

