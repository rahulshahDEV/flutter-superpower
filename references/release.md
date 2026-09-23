# Release Engineering

Mechanical pass: `scripts/release-check.sh /path/to/app` (read-only; reports what it can
verify and explicitly lists what it cannot). Manual checklist below.

## Version & identity

```
[ ] pubspec.yaml version bumped: X.Y.Z+N (N monotonic)
[ ] Android versionCode/versionName derive from pubspec (or bumped consistently)
[ ] iOS build number matches (or is managed by the tooling)
[ ] App name/icon/splash correct per flavor (fdev icons / fdev splash)
```

## Environment & flavors

```
[ ] Flavor entrypoints exist (lib/main_dev.dart, lib/main_prod.dart)
[ ] .env.prod BASE_URL points at production — never a dev/staging host
[ ] .env.dev never points at production
[ ] Firebase project matches the flavor (or per-flavor env is wired)
[ ] No debug flags enabled in the release path (mock data, verbose logging, dev menus)
```

## Signing & build

```
[ ] Android release signing uses the release keystore (not debug) — fdev sha to verify
[ ] iOS provisioning profile + certificate valid for the distribution target
[ ] R8/ProGuard enabled with the project's keep rules
[ ] Split ABI / app bundle strategy as intended
[ ] Obfuscation flags set if the project uses them
[ ] `fdev appbundle prod -t lib/main_prod.dart` (and `fdev ios prod ...`) succeeds
```

## Permissions & privacy

```
[ ] Manifest/Info.plist permissions match actual features (least privilege)
[ ] Usage-description strings present and accurate
[ ] Privacy manifest / data-safety declarations updated if data collection changed
```

## Integrations

```
[ ] Push: FCM config per flavor, APNs key uploaded, channels created, permission timing sane
[ ] Deep links: schemes/associated domains match, routes resolve, fallback screen exists
[ ] Analytics/crash reporting: correct project, scrubbing configured, no PII in events
[ ] Payments/keys: live keys only in prod flavor, sandbox keys in dev
```

## Logging & security

```
[ ] AppLogger is dev-only (release silent) — no print() anywhere
[ ] No tokens/secrets in logs or crash reports
[ ] Debug banner off, dev-only screens/routes unreachable in release
```

## Store & notes

```
[ ] Store metadata / screenshots current (if changed)
[ ] fdev release-notes --notes "..." writes the fastlane changelog
[ ] Version tagged in git; release notes match the changelog
[ ] Post-release: install the store build on a real device and smoke-test login + core flow
```

## Honest reporting

`release-check.sh` can verify files, config, and build commands. It **cannot** verify App Store
Connect, Play Console, provisioning profiles, or a real device install. Anything it cannot
check goes under "Not verified" in the report — never imply a store submission was validated.
