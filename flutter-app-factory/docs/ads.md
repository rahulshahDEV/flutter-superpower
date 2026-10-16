# AdMob setup

Local configuration only. Nothing here creates AdMob accounts, apps, or ad
units — those need the owner in the [AdMob console](https://apps.admob.com)
plus the [Flutter quick-start](https://developers.google.com/admob/flutter/quick-start)
and [privacy/UMP guidance](https://developers.google.com/admob/flutter/privacy).

## 1. Register (owner, manual)

Create one AdMob app per platform (Android + iOS) for each factory app.
Copy the two **app IDs** (tilde form, `ca-app-pub-…~…`) and create banner,
interstitial, and rewarded **unit IDs** (slash form) as needed.

## 2. Configure (agent)

```bash
python3 automation/scripts/factory.py configure battery_analyzer --admob
```

Then put the real IDs in `apps/<slug>/app.yaml` under `monetization`
(`android_app_id`, `ios_app_id`, per-platform `units`). Shared adapter:
`packages/ads`. After dependency changes: `flutter pub get` in the app.

## Rules

- Dev and every automated test use Google's documented **test IDs** — never
  production units. The adapter forces sample ads under
  `AUTOMATED_TEST=true`, debug builds, and unconfigured prod IDs.
- App IDs (tilde) go in the Android manifest / iOS plist; unit IDs (slash)
  in Dart. Do not swap them.
- Gate every ad request on UMP consent (`canRequestAds`), expose the privacy
  options entry point, and keep banners clear of controls, interstitials on
  natural transitions, rewarded strictly opt-in via the SDK reward callback.
- Missing prod IDs block release validation; that is intentional.
- Before release, review Data Safety / App Privacy answers, `app-ads.txt`,
  account privacy messaging, and placements with the owner.
