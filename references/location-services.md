# Location Access, Service Recovery and Fresh Fixes

Use for nearby search, maps, check-in, navigation or tracking. General request/settings
ownership lives in mobile-permissions.md. Inspect the app's current location plugins first;
reuse their status/request APIs rather than adding competing permission owners.

## Keep five conditions distinct

Permission grant, location-services enabled, precision authorization, provider availability
and fix quality are independent. A granted permission does not turn on GPS or guarantee a
fresh coordinate. A timeout doesn't prove permission was denied or that the network is off.
Use explicit outcomes for denied/requestable, blocked, restricted, service disabled,
insufficient precision/quality, timeout, unavailable provider and success.

The UI should match the cause: Allow location, Open app settings, Enable location services,
Try again, or Enter location manually. Do not collapse every failure into "Allow access".
Store a successful domain fix with coordinate, accuracy and capture time; map plugin Position
at the data boundary instead of exporting it throughout the domain.

## Foreground request flow

1. A user action declares its purpose: browsing nearby may accept coarse/cached data; a
   check-in may require a fresh fix within a documented accuracy/radius policy.
2. Check current permission and service state without prompting. If either blocks progress,
   present the relevant recovery. Both must be satisfied before position acquisition; there
   is no universal reason to show two native prompts back-to-back.
3. On the selected recovery action, request the minimum foreground grant OR resolve disabled
   location settings. Serialize native interactions and respect cancellation.
4. Re-read permission, precision and service status, then acquire one bounded fix. Keep a
   single in-flight operation shared by consumers; reject stale completions after reset,
   logout, route disposal or a newer explicit action.
5. Evaluate capture age and accuracy before using the fix. Update content or give a precise
   recovery; don't silently fall back to stale coordinates for a consequential action.

Prefer the installed geolocator APIs for status, request, location acquisition and settings.
On Android, a supported SettingsClient resolution can offer the native service-enablement
dialog. Some existing apps use location.requestService for that role; adding a second
location plugin needs a capability/maintenance justification. It must not become a second
position-stream or permission owner. Recheck serviceEnabled after the resolution completes.
Cancel leaves the service-disabled state; don't loop the dialog.

On iOS, the app cannot silently toggle Location Services. Distinguish app authorization from
global service availability, use supported app-settings navigation, and provide clear manual
instructions when a service-settings page cannot be opened. Avoid private Settings URL schemes.
Never open Settings automatically from a read method or every app resume.

## Precision and scope

Ask for foreground access for foreground jobs. On Android 12+, users can choose approximate
access; if precise location is justified, request fine/coarse as required together. On iOS,
reduced accuracy is separate from authorization. Inspect the installed plugin's precision
APIs; a temporary full-accuracy request also needs its declared purpose/native setup.
Support approximate access for compatible features. Explain why extra precision is required
for a specific operation rather than presenting approximate access as ordinary denial.

Background location is a separate product/platform decision. Request foreground first and
follow current OS-specific escalation. Check foreground-service types, notification rules,
background modes, entitlements, disclosures and battery policy for the actual target SDK.
Don't add Always/background permission because a one-shot request is slow or a screen resumes.
[Android precision and runtime flow](https://developer.android.com/develop/sensors-and-location/location/permissions/runtime).

## Quality, deadlines and cancellation

Define maximum age, acceptable horizontal accuracy and acquisition budget from the feature.
Check timestamp validity, finite/in-range coordinates, finite non-negative accuracy, and
clock tolerance. A stream's freshness must be evaluated against an advancing clock, not a
single cutoff captured when a long-lived subscription began. Cache only with time/quality
metadata and label approximate/stale results when the product allows them.

For a one-shot request, prefer the plugin's supported acquisition time limit. If selecting
the first acceptable stream sample, own the subscription and cancel it on success, timeout,
error and disposal. Future.timeout on stream.first alone doesn't guarantee its underlying
listener stops. Don't leave location collection running after returning a timeout to UI.
No fixed sleep can turn a cached fix into a fresh one.

Set accuracy/update interval/distance filtering to purpose. Nearby browsing usually doesn't
need continuous highest-accuracy tracking. A Dart microtask doesn't move native work off the
main thread or prove an ANR is fixed. Diagnose stalls using native-diagnostics.md.

## Providers, geofences and lifecycle

Use the plugin's normal provider selection first. Introduce forceLocationManager or a
Play Services check only for an evidenced compatibility problem or missing capability;
don't universalize a historical Android-version cutoff. Bound fallback attempts and record
sanitized provider/error metadata, never raw coordinate/position logs.

For a radius check, define how distance, measurement accuracy, freshness and boundary
uncertainty interact. Don't arbitrarily enlarge the radius or label a poor GPS reading as
fraud. isMocked is a limited signal, not reliable tamper proof; consequential eligibility
requires appropriate server policy. Handle ambiguous accuracy with retry/manual recovery.

Continuous streams require an explicit owner, foreground/background policy and cleanup.
Pause/cancel offscreen when tracking isn't needed. Resume rechecks availability once while
the relevant feature remains active; it doesn't re-prompt denied users or refetch from every
widget. Coalesce resume and service-status events with the same in-flight request guard.
Provider-selection caching is different from permission/service status: the latter must be
rechecked. Reverse geocoding is optional display work with its own timeout/cache/failure;
address failure must not erase a valid coordinate.

## Verify at each boundary

Fake adapters: GPS off + granted, GPS on + denied/blocked, approximate/precise, restricted,
resolution cancel, Settings return unchanged/granted, concurrent consumers, stale result,
provider failure, timeout cleanup, stale/poor fix rejection, logout/disposal and resume races.
Keep clock/quality rules pure for deterministic tests. Device checks: actual native dialog,
app/global settings, indoors/no fix, service toggle while active, permission revocation,
process restart and required background behavior. An airplane-mode test alone isn't a GPS test.

Sources: [geolocator](https://pub.dev/packages/geolocator),
[Android settings resolution](https://developer.android.com/develop/sensors-and-location/location/change-location-settings),
[location service API](https://pub.dev/packages/location),
[Apple location authorization](https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services).
