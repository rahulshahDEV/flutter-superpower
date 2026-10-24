# Native Code and Platform Channels

Use native code when a required OS capability isn't adequately served by the SDK or an
existing maintained plugin. Inspect `dependencies.md` first. Keep native implementation in a
small plugin/module or the project's existing bridge, not spread across screen code.

## Design the contract first

Define supported platforms/OS versions, input/output schema, units, nullability, error codes,
permission behavior, cancellation, concurrency and ownership. Map plugin/native types into
domain values at the data boundary; Cubits and domain entities never depend on MethodChannel.
Unsupported platform, denied permission, unavailable hardware, cancelled operation and an
implementation fault are different outcomes, not one generic null.

| Need | Usual mechanism |
|---|---|
| Small request/response bridge | MethodChannel with an explicit typed Dart adapter |
| Larger structured API across Dart/Kotlin/Swift | Pigeon-generated contracts |
| Ongoing sensor/progress events | EventChannel with subscription ownership/backpressure |
| Existing C-compatible compute library | Evaluate Dart FFI with explicit memory/thread ownership |
| Embedded native UI | Platform views; assess composition, gestures, accessibility and cost |

Channel names, method names and codecs form a protocol. Validate values at both boundaries,
return an outcome once per invocation, and handle unknown methods explicitly. Preserve stable
machine-readable error codes and safe user copy; native diagnostics stay out of user messages.
Regenerate both sides after schema changes and keep generator/runtime versions compatible.
Consult [Flutter platform integration](https://docs.flutter.dev/platform-integration/platform-channels)
for the current codec, Pigeon and threading APIs rather than copying an old registrant.

## Thread and lifecycle ownership

- Keep expensive I/O and CPU work off the Android main/iOS main thread. Channel handlers may
  use supported background task queues; UI operations still require the platform's UI thread.
  A Dart `async` function alone doesn't move native work to another thread.
- Identify the owner: Flutter engine, Android Activity, iOS view/controller, service, or
  individual operation. Never retain an obsolete Activity/controller or callback after detach.
- For Activity-dependent Android plugins, handle attach/detach and configuration changes;
  don't assume an Activity exists in a background engine. Clean up listeners/receivers.
- Cancel subscriptions, native observers, pending tasks and timers when their owner ends.
  Define what happens to an outstanding Dart Future during cancellation/detach. Prevent
  double completion from racing success/cancel/error callbacks.
- For event streams, specify initial state, replay policy, frequency, buffering and disposal.
  Coalesce high-frequency events when the UI needs only the newest sample.
- Background isolates need supported plugin registration/messaging. Don't assume every
  plugin, stream callback, or UI API works from an isolate; verify the plugin's documented
  support and test the actual execution context.

## Permissions and background work

A permission request is a user flow, not a constructor side effect. Handle denial and a
later return from Settings; query current capability instead of trusting a cached grant.
Coordinate native dialogs with foreground lifecycle and avoid concurrent prompts.

A Dart isolate/timer is not persistent background execution. Select OS scheduling for work
that must survive process death; document deadlines, retry/idempotency, connectivity and
battery constraints. Android distinguishes in-process async work, scheduled tasks and
foreground services with restrictions. Use the
[Android background-task decision guide](https://developer.android.com/develop/background-work/background-tasks)
for the actual requirement and target SDK. Don't promise exact timing or bypass restrictions.

On iOS, check the specific background mode/API and entitlement for the capability. App
extensions have separate targets, lifetimes and resource limits; keep shared code compatible
with extension constraints and use configured shared containers when needed. Verify both
host and extension signing/configuration. See
[Flutter app extensions](https://docs.flutter.dev/platform-integration/ios/app-extensions).

## Debugging a bridge

Trace one operation across Dart adapter → channel → native handler → OS API → result/event.
Use one sanitized operation ID and timestamps; don't dump payloads. Check registration and
matching channel names before assuming serialization or threading is broken. After native
changes, stop and rebuild/reinstall; hot reload only updates Dart.

A timeout is a diagnostic signal, not cancellation of the native operation. Ensure an expired
caller cannot later mutate UI or receive a second result. For native crashes/hangs, capture
platform logs and symbols using `native-diagnostics.md`; a Dart catch can't recover a crashed
process.

## Verification

- Dart contract tests: success, malformed response, each error code, unsupported platform,
  cancellation and disposal. Mock channel transport only to test the adapter contract.
- Native tests: parsing/business rules without Flutter, plus lifecycle and thread handling.
- Device integration: real registration, permission allow/deny, rapid repeated calls, route
  exit, foreground/background, process relaunch and relevant hardware. Cover each platform
  claimed by the implementation.
- Treat bridge mocks as unit evidence only. Flutter integration tests drive Flutter UI; OS
  dialogs/native views may require native UI automation or a documented manual pass.
  See [Flutter integration tests](https://docs.flutter.dev/testing/integration-tests).

Report build/OS/device, tested paths and limitations. A simulator pass does not establish
camera/Bluetooth/background scheduling or production push/signing behavior on hardware.
