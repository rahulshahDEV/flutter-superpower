# Native Engineering (Android / iOS)

Know when the problem is not Dart. Changing Flutter code to fix a gradle/pod/manifest problem
wastes time — read the native error first.

## Triage: is it native?

| Signal | Likely native |
|---|---|
| Fails only in release / only on device | signing, R8/ProGuard, entitlements |
| Fails at build before Dart runs | gradle, pods, manifest merge, xcconfig |
| Permission dialog never appears | manifest/Info.plist missing, OS-level denial |
| Push works foreground only | channel config, background handler, APNs |
| Deep link opens the app but no route | URL scheme / associated domains / intent filter |
| Plugin throws `MissingPluginException` | pod install / gradle sync / hot-restart needed |

Use `flutter run --verbose` for the real native log, then `flutter doctor -v` for toolchain state.

## Android

- **Flavors** (`android/app/build.gradle.kts`): `flavorDimensions += "environment"`,
  `productFlavors { dev; prod }`; `applicationId` per flavor when both must coexist;
  `resValue("string", "app_name", ...)`.
- **Keys**: `manifestPlaceholders` (maps key etc.) read from `.env.<flavor>`; fall back to
  gradle property → env var → `local.properties`.
- **Signing**: `android/key.properties` (gitignored) → `signingConfigs.release`; verify with
  `fdev sha` / `fdev signapk`. Never ship debug signing.
- **R8/ProGuard**: enabled for release; keep rules for serialized models and plugins that use
  reflection (`-keep class com.example.** { *; }` only as narrowly as needed).
- **Manifest**: permissions actually used, `android:exported` set on components with intent
  filters, network security config for any non-default TLS, deep-link intent filters.
- **Config**: `minSdk`/`targetSdk` deliberate; desugaring on for java.time; `google-services.json`
  gitignored; Java/Kotlin 17 for modern plugins.

## iOS

- **Flavors**: xcconfig chain (`Debug-dev`/`Release-prod` …) setting `FLUTTER_FLAVOR` and
  `FLUTTER_TARGET`; matching schemes (`Dev`/`Prod`).
- **Info.plist**: usage-description strings for every permission (camera, photos, location,
  notifications, tracking), URL schemes for deep links, background modes only if used.
- **Entitlements/capabilities**: push, associated domains, HealthKit, Sign in with Apple —
  enabled in the project AND the provisioning profile.
- **Pods**: `platform :ios, '15.0'` (or the app's minimum); after plugin changes run
  `fdev pod update` (or `flutter clean && flutter pub get && cd ios && pod install`).
- **Signing**: automatic signing with a team, or manual profiles — never commit certificates;
  App Store keys live in CI secrets.

## Flavor parity checklist

```
[ ] Entrypoints exist: lib/main_dev.dart, lib/main_prod.dart
[ ] Android productFlavors + iOS xcconfig/schemes wired
[ ] Env file per flavor (.env.dev/.env.prod) and BASE_URL differs
[ ] Firebase config per flavor (or one project + per-flavor env) — never dev→prod
[ ] App name/icon per flavor when required
[ ] Release signing configured for both platforms
```

## Rules

- Native config changes are part of the feature when the feature needs them — do them in the
  same change and verify with a real build.
- Never commit keystores, `.plist`/`google-services.json`, `key.properties`, or profiles.
- Prefer `fdev` commands (`fdev apk`, `fdev appbundle`, `fdev ios`, `fdev pod update`,
  `fdev icons`, `fdev splash`) with the raw fallback documented in `fdev.md`.
- If a native fix is outside the repo (App Store Connect, Play Console, provisioning portal),
  say so explicitly in the report under "Not verified".
