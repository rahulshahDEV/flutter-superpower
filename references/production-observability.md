# Production Observability

Load when adding diagnostics or preparing production support for critical flows. Reuse an
existing reporter; don't install analytics/crash SDKs for unrelated features. `AppLogger`
is dev-only and cannot prove production behavior. Follow `security.md` for redaction and
`native-diagnostics.md` for native symbols/traces.

## Define the reporting boundary

Choose a small reporting contract owned by infrastructure: record sanitized unexpected
errors with stack trace, severity, operation identity, release/environment and safe metadata.
Inject a fake reporter in tests. Domain types must not depend on a vendor SDK. Expected
validation/cancellation/offline outcomes normally belong in product state or aggregate
metrics rather than a crash issue per occurrence.

Define handled-versus-unhandled and fatal-versus-recoverable classification using the actual
SDK/platform semantics. Marking an error recorded doesn't make its failed operation succeed.
Pick one reporting owner for each path (repository boundary, state owner or global hook):
rethrowing the same reported exception into a global hook must not create duplicate issues.
Use exception/operation identity or a bounded deduplication mechanism, not suppression of all
later errors of the same type.

## Install and verify error capture

Preserve Flutter's error presentation when adding FlutterError.onError; route uncaught
root-isolate async errors through PlatformDispatcher.onError as appropriate. Preserve an
existing SDK's integration instead of overwriting its handlers with competing hooks. Keep
binding and runApp in the same zone. Capture early bootstrap failures through a reporter
that does not depend on the failed DI/config path, or explicitly retain safe local evidence.

Global Dart handlers do not establish native crash, ANR or spawned-isolate capture. Configure
those supported signals separately when required, including release symbols/source maps.
Do not return handled from a global callback merely to silence console output. Reporter
failure must not recursively report itself or replace the original failure with a new crash.

## Correlate useful context safely

A user intent can carry an opaque operation ID through state owner → repository → HTTP/job
metadata. Match request/trace IDs with backend support; don't add identity headers to arbitrary
hosts or signed upload URLs. Record route templates, outcome category, duration and attempt
count rather than full URLs, query strings, headers or bodies. Keep metrics labels bounded:
user IDs, resource IDs and free text are poor dimension keys.

Set environment, app version/build and OTA patch identity when applicable. Attach only
allowlisted context; remove user identity on logout and prevent cross-account breadcrumbs.
Define consent/legal requirements, sampling, retention, access control and deletion behavior
for the data actually collected. Scrub before export, not only in the dashboard.

## Release and ongoing health

For important operations, choose measurable outcomes: completion/failure rate, latency,
startup time or stuck pending jobs. Define denominator, time window, minimum sample size,
threshold, owner and response. Separate new-release regressions from an upstream outage.
Add alerts only for actionable conditions; avoid alerting on each expected network failure.

A post-release check confirms events/metrics carry the intended release/environment, crash
frames resolve, critical flow health is acceptable, and rollback/mitigation has an owner.
An uploaded artifact or successful SDK initialization is not proof telemetry arrived.

## Verification recipe

1. Fake-reporter tests: expected failure vs unexpected exception, original stack/context,
   exactly one report for a propagated failure, redaction, reporter failure and logout reset.
2. Controlled dev/test failures: framework callback, uncaught async operation and bootstrap
   before DI; verify user recovery and distinguish what each handler actually captures.
3. With an authorized test environment, send a uniquely identifiable harmless test event
   from the intended build. Confirm delivery in the correct project and inspect sanitized
   metadata and release identity. Don't deliberately crash a user's production session.
4. Test native/isolate capture and symbolication separately if claiming those signals.
5. Record commands/build/device, observed event ID or dashboard evidence, tested paths and
   gaps. Mock success proves the adapter contract, not vendor delivery.

Sources: [Flutter error handling](https://docs.flutter.dev/testing/errors),
[Flutter PlatformDispatcher error handler](https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/onError.html).
