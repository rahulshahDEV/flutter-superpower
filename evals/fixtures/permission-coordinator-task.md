Implement a foreground location coordinator for nearby browsing/check-in using the supplied
LocationGateway contract. No native plugins, UI or live services are needed for this task.
Keep the public gateway contract unchanged. Implement lib/location_coordinator.dart and add
meaningful tests. The coordinator is pure Dart; use Flutter's existing test dependency.

Required public API:

- LocationCoordinator(LocationGateway gateway, {required DateTime Function() now,
  required Duration maxAge, required double maxAccuracyMeters, required Duration readTimeout})
- Future<LocationResult> locate({bool interactive = false})
- Future<bool> openSettings()
- Future<LocationResult?> onResumed()
- Future<void> dispose()

A passive call checks availability without requesting permissions, enabling services or opening
Settings. Explicit interactive calls may request missing access/services and must preserve the
specific failure/cancellation category. A blocked or restricted grant must never auto-open
Settings. openSettings is a separate user action; a successfully launched page isn't a grant.
On return, recheck once without prompting. Resume events from the permission dialog itself
mustn't duplicate work. Concurrent callers must share the active attempt. Request at most one
fresh fix once access and service are ready. Enforce maximum age, finite/in-range coordinates
and finite/non-negative acceptable accuracy using the supplied clock and policy. Acquisition
failure or timeout must clean up pending native work. Dispose must cancel owned read work,
suppress stale success and prevent future requests. Keep callbacks/resources out of domain
state and never log coordinates. Report what you implemented, commands run and anything unverified.
