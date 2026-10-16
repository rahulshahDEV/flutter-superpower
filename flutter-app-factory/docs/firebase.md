# Firebase setup

Firebase is optional and stays disabled unless requested. Local configuration
never creates cloud projects — registration needs the owner with an
authorized Google account. Official reference:
[FlutterFire setup](https://firebase.google.com/docs/flutter/setup).

## 1. Register (owner, manual, needs authorization)

Create **separate dev and prod** Firebase projects. Register the Android app
(package name = the flavor's `android_application_id`) and the iOS app
(bundle ID = the flavor's `ios_bundle_id`) in the matching project.
Record the two project IDs.

## 2. Configure (agent)

```bash
python3 automation/scripts/factory.py configure battery_analyzer --firebase
```

Set `firebase.enabled: true`, the requested services (`analytics`,
`crashlytics`), and per-flavor `firebase_project` in `apps/<slug>/app.yaml`.
Map the projects with FlutterFire (`flutterfire configure` — inspect
`--help` first, needs authorization), adding only requested SDKs. Startup must
select `FirebaseOptions` per flavor and initialize only when enabled.

## Rules

- Never fall back to the dev project when prod configuration is missing;
  release validation rejects that.
- `google-services.json` / `GoogleService-Info.plist` are client config, not
  secrets — but admin SDK JSON, CI tokens, and private keys never enter the
  repo. Inject CI copies via secure files; `.gitignore` already excludes them.
- Analytics must respect the app's consent design. Crashlytics needs handler
  wiring plus verified symbol/mapping upload in the build flow.
- Firebase auth alone configures no backend Security Rules; record
  service-specific setup only for requested services.
- Dashboard events and symbol uploads count as unverified until observed.
