# Debugging

A principal engineer narrows uncertainty before editing. The skill supplies a repeatable
method, not a guarantee that every failure is diagnosable without logs, devices, or access.
Native builds: `native.md`. Crashes/hangs/device traces: `native-diagnostics.md`.
Custom bridges: `platform-channels.md`. Async ownership: `async-safety.md`.

## Reproduce and classify

Record expected/actual behavior, exact steps, frequency, first bad version, device/OS,
flavor/entrypoint, build mode, network/account state, and recent changes. Preserve the first
stack trace and its causal chain. A report names a symptom, not necessarily the faulty layer.
If reproduction is unavailable, add narrowly scoped safe instrumentation and state what
would distinguish the leading hypotheses; don't invent a root cause.

| Signal | First boundary to inspect |
|---|---|
| Build fails before Dart runs | Native toolchain/task output or dependency resolution |
| Wrong/missing UI | Actual Cubit state, provider scope, builder branch, layout constraints |
| Spinner forever | Every async completion/error path; swallowed errors; request ownership |
| Old data replaces new | Request ordering, cancellation, shared mutable state |
| Double fetch or action | Nested providers, build-time effects, repeated listeners/submission |
| Wrong screen/deep link | Router input, encoded IDs, redirect state, absent extras |
| 401 loop | Refresh ownership, retry marker, excluded auth paths, session invalidation |
| Offline classified as server error | Data source wrapping DioException too early |
| Overflow/hidden CTA | Constraints, text scale, keyboard/inset ownership, fixed heights |
| Only release fails | Native crash logs, signing/env, assertions, entry points, shrinking |
| Plugin unavailable | Platform support, registration, engine/isolate, full native rebuild |
| Slow/janky/hot | Profile trace; distinguish Dart, raster, native, I/O and background work |

## Evidence-driven loop

1. Preserve a failing reproduction or focused test. Check `git status` and recent diffs.
2. State a falsifiable hypothesis and the smallest observation that could disprove it.
3. Inspect at the boundary: breakpoint, state transition, sanitized timing/status metadata,
   minimal fixture, or native log. Use the tool suited to the failure; analyzer output cannot
   diagnose a native crash or backend outage.
4. Search all callers before changing a shared contract. Fix the responsible owner; avoid
   unrelated refactors, speculative retries, dependency upgrades, and broad configuration edits.
5. Re-run the original reproduction and add a regression check that fails without the fix.
   Check adjacent paths affected by the same contract. Multiple causes can coexist; explain
   each with evidence rather than assuming every incident must have one edit.
6. Remove temporary probes or retain only useful redacted telemetry. Report cause, evidence,
   change, test result, and anything not reproduced or verified.

A diagnostic experiment may temporarily change code, but label it as an experiment, keep it
small/reversible, and don't ship it as proof without confirming the causal link.

## Use the right tools

- Compile/type problems: `flutter analyze`; generated code: `fdev gen` (fallback
  `dart run build_runner build --delete-conflicting-outputs`). Never hand-edit generated files.
- UI: Inspector/constraints, breakpoints and a widget test at the failing size/text scale.
  Fix structure before scaling; adding `.w/.h` everywhere is not an overflow diagnosis.
- State: observe ordered transitions and request IDs, not just the final state. Verify one
  provider owns each factory Cubit, and disposed owners cannot receive late work.
- Data: compare a minimized redacted response fixture with the parser contract. Keep only
  allowlisted status, route template, timing, and correlation IDs in logs. Never dump auth
  headers, full payloads, arbitrary route extras, or personal data, even in dev.
- Network: capture request method/status/error category and server correlation ID; distinguish
  DNS/TLS/timeout, HTTP failure, parsing, auth and backend contract errors. Don't disable TLS
  validation as a fix or endlessly retry a non-idempotent write.
- Native/plugin: `flutter run --verbose`, failing Gradle/Xcode task and device logs. A Dart
  `MissingPluginException` does not prove a package bug; test registration and supported mode.
- Dependency/environment: `flutter doctor -v`, lockfile diff, `dart pub deps --style=compact`.
  Clean only for an evidenced stale artifact: `fdev clean` (fallback
  `flutter clean && flutter pub get`), then repeat the same reproduction.

## Common repairs, with proof

| Failure | Evidence required before repair |
|---|---|
| Missing GetIt registration | Annotation/interface binding and regenerated registration output |
| Emit after close | Async completion after disposal; cancellation/stale guard regression |
| Widget context after await | Owner unmounted during await; test navigate-away path |
| Failure swallowed | Trace repository fold and callback error observation |
| Widget test initializes Firebase | Inject/fake the dependency or test a smaller view; don't add a production empty catch |
| Keyboard covers action | Inspect viewInsets and Scaffold resizing; one padding owner, scrollable content |
| Release-only plugin crash | Native stack and correct build symbols; narrow config/native fix |
| Generic error copy | Inspect safe internal diagnostics; don't expose raw exceptions to the user |

Flutter framework errors and uncaught asynchronous errors use different handlers. Preserve
normal error presentation when adding reporting, and keep setup at the existing bootstrap
boundary. See [Flutter error handling](https://docs.flutter.dev/testing/errors) and
`app-bootstrap.md`; don't scatter competing global handlers through features.

## Stop and reassess

Reassess after repeated unsuccessful experiments: summarize observations, eliminate contradicted
hypotheses, and choose a different boundary or a smaller reproduction. Do not cycle through
clean/reinstall/retry commands without new evidence. Avoid silent catches, unsafe casts,
`dynamic`/`!` workarounds, disabling validation, or destructive data resets.

If blocked, provide the smallest actionable request: the exact sanitized log, device action,
configuration identifier, or permission needed, plus the check that becomes possible with it.
Continue independent work and clearly distinguish confirmed findings from hypotheses.
