# Integration Tests for App Flows

Use when the relevant boundary requires a running app: startup/session restoration, routing,
plugin wiring, persistence across screens, or a critical user journey. Keep faster business
and component checks in testing.md. Runtime exploration: device-tooling.md.

## Prepare the app and test environment

Inspect existing integration_test/test_driver directories, SDK version, flavors, entrypoints,
DI reset, backend fixtures and test-device support before adding a harness. Use SDK packages:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

Merge these entries into pubspec, then run flutter pub get. Keep dependencies development-only.
Initialize IntegrationTestWidgetsFlutterBinding in the test entrypoint before invoking app
bootstrap. Use the app's actual dev/test configuration and wait for required initialization;
pumping its root widget alone can skip config/DI/session startup and test a different app.

For the standard WidgetTester-based integration_test flow, don't add a legacy
Flutter Driver extension to production main(). A chosen external interaction tool may have
its own debug harness; isolate it and verify requirements against its installed version.
Use one binding owner per entrypoint and clean test DI/session state between cases.

## Record a reproducible journey

Describe initial data/account state, user actions and observable assertions. Select a small
high-value path rather than an unbounded tour of every screen. Use deterministic fixtures or
a controlled test backend, unique test records and reversible cleanup. Never test a checkout
with production payment data or pollute unrelated user accounts.

Prefer semantic keys/scoped finders over coordinates. Inspect lazy lists after scrolling.
Wait for explicit screen/state markers with bounded timeouts; recurring spinners won't settle.
Assert user-visible results and persisted effects relevant to the test. Screenshot capture
is supporting evidence, not an assertion that an operation completed correctly.

For a regression found with MCP/flutter_skill, retain the original build/device conditions,
minimize the action sequence, and encode the same failure plus recovery path in a test. Keep
only the setup required for that failure; don't copy an entire exploratory session into CI.

## Run on the intended target

Choose an actual device ID from flutter devices. Example for a configured dev-flavor app:

```bash
flutter test integration_test/app_flow_test.dart -d DEVICE_ID --flavor dev
```

Replace DEVICE_ID and test path. The integration test is the Dart target; it explicitly
invokes the intended application bootstrap/entrypoint. For an unflavored app omit --flavor.
Check installed flutter test help for platform-specific flags and the project's runner.
Use flutter drive and its integrationDriver host script only where required by the selected
platform or existing profiling/test-lab workflow. Browser and hosted device-lab setups have
extra runner requirements; don't assume a mobile command works unchanged in either.

Run format → codegen if needed → analyze → test before the device flow. Prefer fdev gen;
fallback: dart run build_runner build --delete-conflicting-outputs. Don't use fdev ios as
proof an integration test ran; building and executing are different stages.

## Native boundaries and lifecycle

A Flutter UI test doesn't automatically control every native permission dialog, WebView,
system sheet or platform view. Use supported native UI automation or a documented manual
step when necessary. Mocked MethodChannel responses establish adapter behavior only.
Keep unit, widget, device, and backend assertions distinct in the report.

Exercise denial, navigation away during work, foreground/background, restart and deep-link
entry when the change touches those lifetimes. A normal in-process test restart isn't an
OS process-death test. Cold launch and persistence recovery may require orchestration
outside the test process. Preserve logs and exact build/symbol identity for native failures.

## CI and handoff

CI needs compatible SDKs/emulators or an authorized device-lab environment, deterministic
configuration, bounded execution and artifacts on failure. Keep test credentials scoped to
the test backend and outside untrusted PR execution. Record command, device/OS, flavor/mode,
commit, fixture identity, assertions, result and log/screenshot paths. A simulator run doesn't
establish hardware, production signing, background scheduling or store-push behavior.

Sources: [Flutter integration testing](https://docs.flutter.dev/testing/integration-tests),
[official agent integration workflow](https://github.com/flutter/agent-plugins/tree/main/skills/flutter-add-integration-test).
Use the installed SDK's primary guidance when an upstream workflow's runner assumptions differ.
