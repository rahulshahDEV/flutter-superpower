# Maps, Location, Health/Steps

Platform-heavy features. Wire permissions first, then providers, then UI. Test on a real
device — emulators fake location and have no step data.

## Permissions (permission_handler)

| Feature | Android | iOS |
|---|---|---|
| Current location | `ACCESS_FINE_LOCATION` (+ `COARSE`) | `NSLocationWhenInUseUsageDescription` |
| Background/geofence | `ACCESS_BACKGROUND_LOCATION` | `NSLocationAlwaysAndWhenInUseUsageDescription` |
| Step counting | `ACTIVITY_RECOGNITION` (API 29+) | HealthKit entitlement + `NSHealthShareUsageDescription` |
| Camera (QR/photo) | `CAMERA` | `NSCameraUsageDescription` |
| Photos | `READ_MEDIA_IMAGES` (API 33+) | `NSPhotoLibraryUsageDescription` |

Rules:
- Ask in context (at the check-in tap, not cold start); explain the why in the dialog copy
  (from `StringConstants`).
- Handle `permanentlyDenied` with a settings redirect (`openAppSettings()`), never a dead end.
- One `PermissionHandlerService` in `core/services/` wrapping `permission_handler`; features
  call it, never the plugin directly.

## Location provider selection (Android is the hard part)

| Situation | Use |
|---|---|
| Default, Play Services available | `geolocator` with `LocationSettings(accuracy: LocationAccuracy.high)` (Fused) |
| Play Services missing/outdated, or known OEM bugs | force Android `LocationManager` provider |
| Battery-sensitive continuous tracking | medium accuracy + distance filter (e.g. 10–25 m) |

Implement a small `LocationManagerUtil.shouldForceLocationManager()` (checks API level,
Play Services availability via `google_api_availability`) and branch — do not hardcode one
provider. iOS always uses CoreLocation via `geolocator`.

Patterns:
- **Check-in geofence**: fetch target lat/lng, `Geolocator.distanceBetween` vs allowed radius
  (server-configured, e.g. 100–200 m); show distance feedback before allowing check-in.
- Location only on **user action or app resume** (and only when logged in); no background
  stream unless the feature requires it. Always cancel subscriptions in `dispose`.
- `geocoding` for reverse address display; cache results per coordinate.
- Never block the UI thread on location: show a loader, timeout after ~15 s with a retry.

## Google Maps

- `google_maps_flutter`; API key injected at build time:
  - Android: `manifestPlaceholders["GOOGLE_MAPS_API_KEY"]` read from `.env.<flavor>` by a
    gradle helper (fallback: gradle property → env var → `local.properties`).
  - iOS: key in `AppDelegate`/xcconfig from the same env value.
- Render `Marker`s + `Circle` (geofence) from state; camera via `CameraPosition`.
- Static map previews: use the Static Maps URL through `ImageRenderer` instead of a live map
  when interaction isn't needed (cheaper, works offline in lists).
- `maps_launcher`/`url_launcher` to open directions in the native app — don't rebuild navigation.

## Health / steps

- `health` package. Android → Health Connect (needs the Health Connect manifest
  `androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE` + declared read types); iOS → HealthKit
  with the entitlement.
- Read **today's total steps** (`HealthDataType.STEPS`, `today` window) and **merge
  conservatively**: when multiple sources report (phone + watch), take the higher count —
  never sum (double counting).
- Refresh on app resume only; step reads are expensive and permission-gated.
- Cache the last value in `LocalStorageService` so the UI has something to show before the
  async read completes; shimmer while loading.
- Android activity-recognition permission denial → show inline explainer + retry, not a
  blocking dialog loop.

## Common failures

| Symptom | Fix |
|---|---|
| Location works debug, not release | API key restricted to wrong package/SHA; add release SHA (`fdev sha`) |
| `PlatformException(PERMISSION_DENIED)` after "Allow" | permission request raced with settings; re-check `Permission.location.status` |
| Steps always 0 on emulator | no sensor data — test on device |
| Health Connect "not available" | app not installed/updated, or manifest types missing |
| Geofence check passes at desk | radius too large / mock location enabled — flag mock locations |
| Battery drain complaints | high-accuracy stream left running; enforce distance filter + stop on pause |

## Verification

- Real device pass: grant → deny → permanently deny → settings grant flows.
- Airplane mode: graceful failure message, retry path.
- Background → resume: location/step refresh fires once, no duplicate calls.
- Unit-test the pure parts (distance math, provider selection, step merge) — see `testing.md`.
