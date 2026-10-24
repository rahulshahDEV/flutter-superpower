# Native Engineering: Android and iOS

Read this when the task crosses Dart into build configuration, plugins, signing, permissions,
or operating-system behavior. `native-diagnostics.md` covers runtime evidence;
`platform-channels.md` covers custom Kotlin/Swift integration. Keep existing project tooling.

## Establish the exact build

Record Flutter/Dart version, flavor/entrypoint, build mode, target OS/device, package or bundle
ID, and last working commit. Read the first actionable compiler/task error, not just the final
"Gradle task failed" line. Reproduce with the same command before changing versions.

```bash
flutter doctor -v
flutter --version
dart pub deps --style=compact
flutter run --flavor dev -t lib/main_dev.dart --verbose
```

Use the app's actual flavor; omit flavor/target flags for an unflavored project. Keep logs
local and sanitize them before sharing. Don't print signing properties or environment files.

## Android build diagnosis

1. Inspect `settings.gradle(.kts)`, app/root build files, `gradle-wrapper.properties`, version
   catalogs, and plugin requirements. Identify AGP, Gradle, Kotlin, compile/target/min SDK,
   Java toolchain, Kotlin JVM target, and any NDK/CMake versions actually used.
2. Run `./gradlew --version` from `android/`; compare its JVM with `flutter doctor -v` and
   Android Studio's Gradle JDK. A terminal's `java -version` alone doesn't identify all three.
3. Check compatibility in current AGP/Gradle/Kotlin docs for those exact versions. Change
   only the incompatible pair; don't upgrade Flutter, AGP, Kotlin, and plugins together.
4. Run `./gradlew tasks --all`, then rerun the failing variant task with `--stacktrace`.
   Use `./gradlew :app:dependencies` or `dependencyInsight` with the actual variant's
   configuration for dependency conflicts. Avoid debug logging if it exposes credentials.
5. For manifest merge/resource errors, inspect the merged manifest and merger report for the
   failing variant. Check exported components, placeholders, namespace vs applicationId,
   resources, and permission declarations in both app and plugins.

JDK used to run Gradle, Java source compatibility, Kotlin bytecode target, Android SDK API
availability, and desugaring are different settings. Don't impose "Java 17 everywhere" or
assume desugaring enables every Java API. See [Android's JDK guide](https://developer.android.com/build/jdks)
and the [Flutter migration guide](https://docs.flutter.dev/release/breaking-changes/android-java-gradle-migration-guide);
verify their recommendations against the installed toolchain.

Release-only failure: compare signing, environment, manifest and shrinker output. Narrow keep
rules to an evidenced reflective/native entry point; don't keep the entire application or
permanently disable R8 to mask the cause. Preserve release mapping/native symbols for diagnosis.

Prefer `fdev apk dev -t lib/main_dev.dart --debug`; fallback:
`flutter build apk --flavor dev -t lib/main_dev.dart --debug`.
For release parity use `fdev appbundle prod -t lib/main_prod.dart`; fallback:
`flutter build appbundle --flavor prod -t lib/main_prod.dart`.
These commands build; they do not prove installation or runtime correctness.

## iOS build diagnosis

1. Identify the selected Xcode (`xcode-select -p`, `xcodebuild -version`), scheme,
   configuration, deployment target, architecture, and destination. Inspect the workspace,
   xcconfig chain, Podfile/lockfile and/or Swift package resolution used by this app.
2. Use `xcodebuild -list -workspace ios/Runner.xcworkspace` to inspect a standard Flutter
   workspace; substitute its actual name. Match shared schemes to CI and Flutter flavors.
3. Classify compile/link/module errors separately from signing/export failures. Check target
   membership, plugin-generated integration, deployment targets, framework architecture, and
   app/extension dependencies. Don't edit Generated.xcconfig or generated registrants.
4. CocoaPods projects: use the repository's Bundler setup if present, then `pod install`
   from `ios/` to respect the lockfile. `fdev pod update` (raw `pod update`) intentionally
   updates dependencies; it is not the default repair for a failed build. Don't delete
   Podfile.lock or deintegrate everything before identifying a resolution problem.
5. SwiftPM projects: inspect package resolution and generated Flutter integration. Don't
   remove CocoaPods while a plugin still needs it or introduce duplicate dependency wiring.
   Match the app's Flutter version, not a recipe for a newer version.
6. Signing: match bundle ID, team, certificate, provisioning profile, entitlements, export
   method and destination. An App Store Connect API key isn't a signing certificate.
   Keep credentials outside Git; inspect names/expiry/identifiers without printing secrets.

Flutter's native dependency defaults evolve; consult the
[SwiftPM integration guide](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers)
for the installed release before migrating. Existing mixed integrations need a staged change.

Prefer `fdev ios prod -t lib/main_prod.dart`; fallback:
`flutter build ios --flavor prod -t lib/main_prod.dart`.
Use `flutter build ios --no-codesign` only for a deliberately unsigned compile check;
use `flutter build ipa` with the project's export options for an actual archive/export.
Unsigned or simulator success does not establish device signing or store readiness.

## Native feature completion

- Wire flavors, entitlements, capabilities, permission purpose strings and manifests in the
  same feature change. Read public config explicitly; Gradle does not automatically load
  Flutter's dotenv assets. Client-shipped API configuration is not a server secret.
- Follow mobile-permissions.md and permission-capabilities.md for status/prompt ownership.
  Request permissions in context; handle denied, restricted, permanently denied, and return
  from Settings. Don't invent an Info.plist usage key for every permission: use the current
  platform/plugin requirements (notifications, for example, use authorization APIs).
- Register deep links on both native and Dart sides; test cold/warm launch and unknown input.
- Treat services, receivers, activities, app extensions and background workers as lifecycle
  owners. See `platform-channels.md` for cleanup and background execution decisions.
- After native-code/plugin-registration changes, stop and rebuild/reinstall. Hot reload or
  hot restart cannot compile a newly added native implementation.

## Verification and handoff

Run format → codegen if needed → analyze → test, then build each affected platform/variant.
For codegen prefer `fdev gen`; fallback `dart run build_runner build --delete-conflicting-outputs`.
Exercise the feature on a relevant device, including denial/interruption/resume. Report exact
commands, artifact, OS and remaining gaps. External portal configuration, device-only behavior,
missing signing material, and inaccessible crash symbols stay explicitly unverified.
