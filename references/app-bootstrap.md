# App Bootstrap and Flavors

Use the runnable `templates/app/` as the source of truth; do not copy a second,
version-pinned pubspec from prose. Existing applications keep their bootstrap conventions.

## Startup contract

Keep flavor entry points thin: `main_dev.dart` and `main_prod.dart` delegate to
`bootstrap(flavor:, envFile:)` in `app.dart`. Default `main.dart` selects dev.

Order: binding → load/validate config → platform UI policy → required local dependencies
→ router/root. Await each dependency before its consumer; never resolve GetIt before
`configureDependencies()` finishes. Keep binding initialization and `runApp` in the same
zone. Do not add `runZonedGuarded` around only half of startup.

Classify each startup task:

| Kind | Treatment |
|---|---|
| Required local config/storage/DI | Await, fail visibly if unavailable; don't run a half-initialized app |
| Session restoration | Resolve before protected navigation; use an explicit startup state if slow |
| Remote refresh, analytics, optional sync | After first frame, with timeout/error handling and lifecycle ownership |
| Permissions | Follow mobile-permissions.md; request at the relevant user action, not boot |

A remote outage must not produce an endless splash. Preserve usable cached state where
supported. No artificial splash delay. The minimal scaffold opens home directly; add a
startup coordinator only when there are actual asynchronous routing decisions.

Catch bootstrap failure at the entry boundary, report it without exposing config values,
and render a small independent failure surface. It must work without DI, router, custom
fonts, or loaded config. If offering retry, make initialization idempotent and reset partial
DI registrations/subscriptions first. Don't blindly call configureDependencies twice.

For an app with crash reporting, preserve Flutter's error presentation when installing
`FlutterError.onError`; route uncaught asynchronous errors via `PlatformDispatcher.onError`.
Returning true means handled, so only do so after recording the error. Redact credentials
and personal data. Test failures before config loads as well as after DI starts. Reporting
is not recovery; never silently swallow startup exceptions.

## Platform UI and fonts

Read `platform-ui.md` for orientation, edge-to-edge, system bars, and safe areas.
Read `fonts.md` before adding Google Fonts or shipping a custom family. The scaffold uses
system fonts and needs no font HTTP request to show the first frame.

## Configuration

`AppConfig` holds non-secret flavor values validated at startup. `.env` files bundled as
assets are readable by users; gitignore does not make them secret. Keep credentials on the
server, auth tokens in secure storage, and only public configuration in assets. Commit a
sample with keys and harmless example values. Validate URLs and required fields early.

DI owns infrastructure lifetimes. Route providers own screen Cubits. App-wide subscriptions
have a single owner and disposal path; don't start listeners from `build()`.

## Native flavors

Dart entry points alone do not create Android product flavors or iOS schemes.

- Android: add an environment flavor dimension, dev/prod product flavors, and app labels.
  Use a dev application ID suffix if both installs must coexist. Match Java/Kotlin and
  desugaring requirements to the installed plugins, not a stale copied Gradle block.
- iOS: create matching build configurations/schemes and xcconfig chains; verify the Podfile
  maps them correctly. Set deployment targets from supported OS policy and plugin minimums.
- Match Firebase registrations, deep links, signing, and app identifiers to each flavor.
- Verify native launch screen colors in light/dark mode to prevent a startup flash.

Prefer `fdev apk dev` for a dev APK; fallback:
`flutter build apk --flavor dev -t lib/main_dev.dart`.
Run with `flutter run --flavor dev -t lib/main_dev.dart` only after native flavors exist;
the unconfigured scaffold runs with `flutter run`.

## Firebase / FCM (only when required)

When needed: initialize Firebase with generated platform options before dependent DI
registrations; then register the top-level `@pragma('vm:entry-point')` background handler.
That isolate initializes Firebase itself and performs no navigation. Record failures;
do not throw into platform callbacks or hide them with empty catches.

The FCM service owns foreground/opened/token-refresh subscriptions and disposes them.
Defer permission prompts to an explained UX moment. Register refreshed tokens with the
backend through a feature use case. Queue cold-start taps until the router and session are
ready, consume each once, and validate payloads. Never block first paint on permission or
backend token registration. Add analytics/crash reporting only when required.

## Verify

```bash
dart format .
fdev gen # if annotations changed; fallback: dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Exercise cold and warm launch, missing config, storage failure, offline launch, resume, and
any notification/deep-link entry points the app supports. Record actual startup timing in
profile/release mode before optimizing it; analyzer output is not startup evidence.
