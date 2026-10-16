---
name: admob-integrator
description: Integrate the official Google Mobile Ads Flutter SDK with dev test ads, production IDs, consent gating and safe banner/interstitial/rewarded lifecycles.
---

# admob-integrator

Work from the factory root. Inspect `AGENTS.md`, the app's `app.yaml`, registry,
existing implementation and working tree first. Reuse existing settings; make the
smallest changes and never replace important configuration without reviewing its
diff. Ask only for essential missing identity or account information. Run relevant
checks, report failures with redacted evidence, and distinguish completed, blocked,
and unverified work. Never fabricate build or publishing success.

Read [shared operating rules](../../../docs/skills.md) and run
`python3 automation/scripts/factory.py --help` before using unfamiliar options.

Read [ads setup](../../../docs/ads.md) and current official
[SDK setup](https://developers.google.com/admob/flutter/quick-start) and
[UMP consent guidance](https://developers.google.com/admob/flutter/privacy).

1. Inspect `packages/ads`, dependencies, startup, native manifests/plists and
   per-environment app/ad-unit IDs. Reuse the shared adapter.
2. Run `python3 automation/scripts/factory.py configure battery_analyzer --admob`.
   Inspect its changes; this configures local integration, not AdMob account apps.
3. Resolve the official `google_mobile_ads` dependency with `flutter pub get`
   in the app after dependency changes. Match installed SDK APIs and constraints.
4. Configure Android app-ID metadata and iOS GADApplicationIdentifier per flavor.
   Distinguish app IDs (tilde) from unit IDs (slash). Dev and all automated tests
   use Google's documented test IDs or SDK test-device configuration.
5. Use supplied production IDs only in production configuration. IDs are public
   client identifiers; secure credential groups hold service credentials, not
   secrets embedded in Dart. Missing prod IDs block release, not dev usage.
6. Before ad requests, update consent, show required UMP forms, then check
   `canRequestAds`. Provide required privacy-options access. Treat tracking
   authorization separately and request it only when the app actually tracks.
7. Handle load/show failure, disposal and single-use full-screen instances.
   Banners must reserve space away from controls; interstitials only at natural
   transitions; rewarded ads require opt-in and reward only from the SDK reward
   callback. No automated taps or production-ad requests.
8. Run validation/tests with fake ads. Review Data Safety/App Privacy, policy,
   app-ads.txt and account privacy messaging with the owner before release.

Do not claim that enabling the adapter completes consent policy setup or approves
monetization. AdMob account creation/registration and privacy-message setup require
an authorized account workflow; report these initial manual requirements.

