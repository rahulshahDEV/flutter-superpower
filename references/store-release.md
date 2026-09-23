# Store Release — Google Play & App Store

Everything here happens after `release.md`'s checklist is green. A script cannot submit for
you; this is the full manual path with the common rejection causes.

## Pre-flight (both stores)

```
[ ] release.md checklist green; release-check.sh has no ❌
[ ] version bumped: pubspec X.Y.Z+N (Android versionCode = N, iOS build = N, monotonic)
[ ] Release build installs and smoke-tests on a physical device
[ ] Privacy policy URL live; data-safety / privacy answers match actual collection
[ ] Account deletion path exists in-app (required by both stores when accounts are created)
```

## Google Play

**Signing**
1. Generate the upload keystore: `fdev signapk` (writes `android/app/keystore.jks` +
   `keystore.properties`; both gitignored).
2. Enroll in **Play App Signing** (default for new apps) — Google holds the app-signing key;
   you keep the upload key. Losing the upload key is recoverable; losing the app-signing key
   is not (keep it in two safe places).
3. Get fingerprints with `fdev sha` — needed for Google Sign-In and Maps API keys.

**Build & upload**

```bash
fdev appbundle prod -t lib/main_prod.dart      # AAB is required for new apps
```

**Tracks** — promote the same build: internal (fastest) → closed (alpha) → open (beta) →
production, with a staged rollout percentage (start 5–10%, watch Android vitals, then ramp).

**Listing**
- Title (30), short description (80), full description (4000)
- Screenshots: phone 2–8 (min 1080px on the long edge), 7" and 10" tablet if you ship to them
- Feature graphic 1024×500, app icon 512×512, promo video optional
- Data safety form, content rating questionnaire, target audience, ads declaration,
  news/COVID declarations if applicable

**Review** — first submission typically 1–7 days; updates hours. Frequent rejections:
- Data safety answers don't match actual SDK behavior (analytics/crash SDKs collect data)
- Sensitive permissions without justification (background location, all-files access,
  exact alarms) — remove or justify in the declaration
- Broken core functionality (testers hit crashes / login failures) — ship a stable build
- Missing/incorrect privacy policy URL
- Target API level below the current Play requirement (check yearly deadlines)
- Store listing impersonation / misleading claims

**Release notes** — `fdev release-notes --notes "..."` writes the fastlane changelog.

## App Store

**Signing**
1. Apple Developer Program membership; App ID in the portal (capabilities enabled).
2. Distribution certificate + App Store provisioning profile (or automatic signing with the
   team). For CI: an App Store Connect API key (issuer ID + key ID + `.p8`) stored as secrets.
3. Xcode: bundle ID, team, version/build fields; `flutter build ipa` / archive via
   `fdev ios prod -t lib/main_prod.dart` then Xcode Organizer or `xcodebuild -exportArchive`.

**TestFlight**
- Internal testers (up to 100, no review) → external testers (up to 10 000, beta review
  required). Test push, deep links, and purchases here before submitting.

**Versioning** — `CFBundleShortVersionString` = X.Y.Z, `CFBundleVersion` = build N (must
increase every upload, even for the same version). Keep in sync with pubspec.

**Metadata**
- Name (30), subtitle (30), description, keywords (100), support URL, marketing URL
- Screenshots per required device class (6.9" and 6.5" iPhone; iPad if supported), app previews
- App Privacy nutrition labels (must match code + SDKs), age rating, export compliance
  (encryption — usually "uses encryption" if HTTPS), content rights
- Review contact + demo account (if login is required, provide working test credentials)

**Review** — typically 24–48 h. Frequent rejections:
- **2.1** crash/incomplete features or broken demo account
- **5.1.1** permissions/privacy: missing purpose strings, collecting data not declared,
  requiring login before showing non-account content
- **3.1.1** digital goods sold outside IAP (use StoreKit/IAP for in-app digital purchases)
- **4.8** third-party sign-in without Sign in with Apple — see `auth-social.md`
- **2.3** hidden features, misleading metadata/screenshots
- Background location / tracking without clear justification and ATT handling

**Post-submit** — phased release (7 days), expedited review requests for critical fixes,
respond in App Store Connect Resolution Center with evidence when rejected.

## CI automation

- Secrets: Play service-account JSON, App Store Connect API key, keystore (base64),
  `key.properties`, profiles — never committed.
- Typical flow: build release AAB/IPA on tag → upload to internal/TestFlight track →
  manual promotion after QA.
- Keep the store credentials in the CI provider's secret store; rotate on team changes.

## Honest limits

`release-check.sh` verifies files/config only. Store submission, review outcomes, signing
validity, and device installs are manual — report them as "Not verified" unless actually done.
