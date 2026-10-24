# Device Crashes, Hangs and Performance

Use after `debugging.md` identifies a native/runtime boundary. Preserve evidence before
clearing logs, uninstalling, resetting permissions or deleting app data. Match the failing
build, flavor and device; release-only symptoms need release evidence.

## Capture a useful incident

Record commit/version/build number, platform/OS/device, process/launch state, time window,
steps and frequency. Save the complete relevant stack and causal chain, not just the last
line. Separate Dart exceptions, Java/Kotlin exceptions, native signals, ANRs, watchdog kills,
low-memory termination and ordinary lifecycle disposal; each needs different evidence.

## Android

```bash
adb devices -l
adb -s <serial> logcat -v threadtime
adb -s <serial> logcat -b crash -d
adb -s <serial> shell dumpsys meminfo <package-id>
```

Replace `<serial>` with the chosen device and `<package-id>` with the installed flavor's ID.
Start recording before reproduction; limit capture duration and retain the relevant window.
Android Studio Logcat can filter by app/process and show linked stack traces. Avoid a PID-only
filter when the process dies/restarts; it can hide the next launch and system kill reason.
Don't clear existing logs before capturing a crash. See
[Android Logcat](https://developer.android.com/studio/debug/logcat).

For an ANR, inspect blocked main-thread work and lock contention with a system trace; a
network timeout message alone isn't proof. A bugreport or native tombstone may require
additional device access and contains sensitive information: collect only when needed,
restrict sharing, and sanitize exports. Keep R8 mapping and native debug symbols for the
exact artifact; don't symbolicate with a nearby build's files.

## iOS

Collect the device crash report through Xcode Devices and Simulators/Organizer, plus device
console logs around reproduction. Match bundle ID, build and binary UUID with the archived
app/dSYM. Identify the exception/termination reason and triggered thread before blaming
Flutter. Symbolicate using the matching archive; unresolved addresses are not actionable
source locations. A jetsam termination is memory pressure, not necessarily a Dart exception.
See [Apple crash reports and device logs](https://developer.apple.com/documentation/xcode/diagnosing-issues-using-crash-reports-and-device-logs).

For reproducible native faults, attach Xcode/LLDB to the correct process and use exception or
symbolic breakpoints appropriate to the failure. For hangs or high CPU, use Instruments
Time Profiler; for leaks/growth, use Allocations/Leaks and the memory graph. Native view,
image, camera and codec allocations may grow while Dart heap looks stable.

## Flutter release symbols

When Dart obfuscation is enabled, retain the matching split-debug-info output as a release
artifact. Use `flutter symbolize -i <stack-file> -d <matching-symbol-file>` for the exact
architecture/build. These placeholders are local artifact paths; never use symbols from a
different release. Dart symbols, Android R8 mappings, native symbols and iOS dSYMs solve
different parts of the stack. See [Flutter obfuscation](https://docs.flutter.dev/deployment/obfuscate).
For OTA builds also record release version and patch number; see `shorebird.md`.

## Performance diagnosis

Use a representative physical device in profile mode for Flutter timing:
`flutter run --profile --flavor dev -t lib/main_dev.dart` (substitute the app's target).
Debug mode and simulator speed are not production performance measurements.

| Observed issue | First useful evidence |
|---|---|
| Frame jank | DevTools timeline: UI work vs raster work, slow frames and triggering action |
| Main-thread native stall | Android system trace/Perfetto or Instruments thread samples |
| Memory rises each visit | Repeated navigation plus Dart allocation snapshots and native memory trend |
| Slow cold launch | Time from process start through native launch, initialization and first useful UI |
| Battery/thermal impact | Repeated background jobs, wakeups, sensors, network and device energy trace |

Measure one repeatable scenario before/after on the same device/mode, with warm/cold state
specified. Inspect rebuilds, layout, parsing and synchronous work for UI-thread cost; inspect
images, effects and painting for raster cost. Don't add RepaintBoundary, isolates, caches or
native rewrites without evidence that they address the measured bottleneck. See
[Flutter profiling](https://docs.flutter.dev/perf/ui-performance).

Android system tracing helps correlate scheduling, CPU and platform work beyond the Dart
isolate; use Android Studio or the device's System Tracing/Perfetto capture appropriate to
its OS version. See [Android tracing](https://developer.android.com/topic/performance/tracing).
For long sessions, distinguish a stable cache plateau from unbounded growth; force-GC
observations alone don't prove native resources were released.

## Completion evidence

Reproduce the original failure after the fix and exercise nearby lifecycle states. Keep a
small regression test for the causal logic; use device/native integration for platform
behavior. Report the trace/log artifact, matching symbols, exact build/device, observed
before/after outcome, and untested cases. If symbols or hardware are missing, report the
result as a narrowed diagnosis, not a verified fix or a claimed performance improvement.
