# Maps and Platform Data Routing

Choose the matching focused guide before implementing a platform-data feature:

| Concern | Read |
|---|---|
| Prompt UX, statuses, settings return, lifecycle ownership | mobile-permissions.md |
| Camera/photos/notifications/Bluetooth/files and other grants | permission-capabilities.md |
| GPS/service enablement, fresh location, accuracy, providers | location-services.md |
| HealthKit/Health Connect, sensor scope, step aggregation | health-data.md |

Do not add every platform package/permission at app setup. Inspect the feature's concrete
capability and the existing app first; follow dependencies.md and native.md.

## Maps

Use the project's installed map provider. For Google Maps, native configuration and key
restrictions must match each platform/flavor, package/bundle identifier and signing identity.
Build-time configuration is public in a distributed client; protect the key with provider
restrictions rather than treating dotenv as secrecy. Check installed plugin docs for native
SDK minimums and the actual manifest/AppDelegate/xcconfig integration.

A map can display a supplied coordinate without reading the user's location. Ask for location
only when enabling a capability that needs it, such as the current-position layer or a
nearby action. Denied permission should still allow usable map/browse/manual search where
supported. Don't enable my-location controls until their grant is sufficient.

Render markers, selection and radius from feature state; UI owns map-controller commands
and cleanup. Use stable entity IDs and avoid resetting the camera on every unrelated state
emission. A reverse-geocoding failure doesn't invalidate the coordinate. Long lists often
need previews rather than multiple live map views; static map URLs still require network
unless an image is explicitly cached under provider terms. Don't promise offline support
from a static URL alone. Keep keys and coordinates out of diagnostic URLs/log dumps.

For directions, prefer an installed directions-launch capability or supported URI through
the existing URL launcher, with an unavailable-app fallback. Building turn-by-turn navigation
is a separate product/platform task. Validate coordinates/deep links at the boundary.

## Verification

Test no-location browsing, permission denial/recovery, approximate position, unavailable map
network/provider, selection/camera stability, route return and native configuration in the
affected release flavor. API key/SHA problems and OS location permission failures are distinct.
Verify signing metadata with fdev sha (fallback: keytool -list -v -keystore <file>); don't log
or upload private key material. Use native-diagnostics.md for real device/provider failures.
