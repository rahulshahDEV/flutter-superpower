# Capability-Specific Permission Decisions

Use mobile-permissions.md for status, prompt ownership, settings return and UI behavior.
This is a decision index, not a manifest to copy. Verify installed plugin, target SDK and
supported OS versions before implementing each capability. Read/request only what is used.

| Capability | Minimum-access approach | Distinctions to preserve |
|---|---|---|
| Foreground location | While-in-use plus accuracy appropriate to this action | App grant, service enabled, approximate/precise, fix age/quality |
| Background tracking | Separate justified escalation and native execution setup | Foreground permission isn't background authorization/execution |
| In-app camera | Camera plugin permission and device availability | Grant, camera busy/unavailable, app resume/reinitialization |
| Audio capture/video with audio | Microphone only when recording audio, camera separately | Silent capture doesn't automatically need microphone |
| Pick photos/videos | System photo picker/selection grant where sufficient | Picked assets, limited library, full library are different scopes |
| Save/export/share a file | App sandbox, share sheet or document picker | Broad storage access usually isn't needed |
| Notifications | Ask after the user opts into the relevant notification benefit | Authorization, channel/category, push token, backend registration |
| Bluetooth | Installed plugin and OS-specific scan/connect/advertise needs | Permission, radio enabled, hardware support and paired connection |
| Contacts | System contact picker when a selected contact suffices | Limited/selected versus bulk address-book access |
| Calendar/reminders | Narrow operation-specific access | Write-only and full/read access can have different OS requirements |
| Steps/motion | Sensor-specific motion/activity access | Sensor permission is distinct from HealthKit/Health Connect data scope |
| Health records | Per-type read/write authorization | Platform availability, query result, read privacy and write status |
| Tracking/ads | Platform-specific tracking authorization only for covered tracking | Not a generic analytics, notification or login permission |
| Biometrics | Local authentication API, enrolled hardware and fallback policy | Not a normal requestable camera/fingerprint permission |

Location details: location-services.md. Health records/steps: health-data.md.

## Photos, camera and files

Don't request Permission.storage for every upload/download. Android scoped storage and
photo pickers change access by OS and chosen API. A system picker can provide only selected
media without broad READ_MEDIA_* access; full-library features have different requirements.
Check selected-photo/limited access on supported Android/iOS versions and let users choose
additional items through the supported picker. Limited access can be successful, not denial.

A picker can be cancelled or lose access later. Handle returned handles/URIs using the
plugin's documented copy/persist semantics if work must outlive the immediate flow. Don't
assume a path is permanent or that picking an image grants access to its whole directory.
For saving to Photos on iOS, request add-only access when that satisfies the operation;
check the plugin's exact usage-description requirements. Capturing via an external camera
intent and an embedded camera preview need different setup; inspect the selected plugin.
[Android photo picker](https://developer.android.com/training/data-storage/shared/photo-picker).

## Notifications

Android 13+ has POST_NOTIFICATIONS for non-exempt notifications; older targets/OS versions
have different prompting behavior. On iOS, distinguish authorized, denied and provisional
behavior; quiet delivery is not necessarily full visible-alert permission. Re-read current
settings and app/channel-level enablement. A valid FCM/APNs token does not establish alert
permission, and permission denial does not imply login/session failure.

Use one notification-permission owner. Don't request independently from permission_handler,
Firebase and a local-notifications plugin on the same screen. Pick the existing stack's
request path and translate its result into feature state. Requesting alerts, creating a
channel, registering a token and uploading it to the backend are separate operations.
[Android notification permission](https://developer.android.com/develop/ui/views/notifications/notification-permission).

## Bluetooth, nearby devices and local network

For Android 12+ scan/connect/advertise permissions depend on the operation and target SDK;
older releases have different location dependencies. neverForLocation assertions must match
actual use and can affect scan results; don't set them blindly. Nearby Wi-Fi access isn't
the same API/permission as BLE. Radio-off/service-disabled states need their own recovery.

On Apple platforms, inspect the selected plugin's Bluetooth usage strings and any local
network/multicast declarations separately. Missing discovery may be a network, entitlement,
protocol or hardware issue rather than requestable permission. Don't open settings repeatedly
when a peripheral is absent. Validate both authorization and the actual scan/connect result.
[Android Bluetooth requirements](https://developer.android.com/develop/connectivity/bluetooth/bt-permissions).

## Special access and restricted modes

Exact alarms, overlays, battery-optimization exemptions and broad file management can require
special-access screens/policy eligibility rather than a normal runtime dialog. Choose them
only when the feature needs that access; they are not standard setup for every mobile app.
A permission_handler enum doesn't guarantee the OS will show an ordinary request prompt.

Verify native declarations against installed plugin documentation. iOS privacy usage strings,
plugin compilation configuration, entitlements and privacy manifests serve different purposes;
a privacy manifest doesn't replace authorization or a purpose string. Don't enable all
permission macros, add unrelated usage keys, or migrate Pods/SwiftPM just for consistency.

## Test a capability matrix

List actual supported OS/device combinations with permission state, granted scope, hardware/
service state, active user action and expected recovery. Include revocation during operation,
Settings return, limited access, native cancellation and disposal. Keep a permission-free
fallback when the job supports one. Use real-device evidence for OS UI/hardware claims and
state exactly which checks remain unavailable. Never log the returned protected data to prove
permission works; log only sanitized capability/status/operation metadata.

Package setup reference: [permission_handler](https://pub.dev/packages/permission_handler).
