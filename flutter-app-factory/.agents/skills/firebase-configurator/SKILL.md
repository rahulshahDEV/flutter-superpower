---
name: firebase-configurator
description: Enable optional Firebase for a selected app with isolated dev/prod projects, Analytics or Crashlytics only when requested, and configuration validation.
---

# firebase-configurator

Work from the factory root. Inspect `AGENTS.md`, the app's `app.yaml`, registry,
existing implementation and working tree first. Reuse existing settings; make the
smallest changes and never replace important configuration without reviewing its
diff. Ask only for essential missing identity or account information. Run relevant
checks, report failures with redacted evidence, and distinguish completed, blocked,
and unverified work. Never fabricate build or publishing success.

Read [shared operating rules](../../../docs/skills.md) and run
`python3 automation/scripts/factory.py --help` before using unfamiliar options.

Read [Firebase setup](../../../docs/firebase.md) and
[official Flutter setup](https://firebase.google.com/docs/flutter/setup).

1. Keep Firebase disabled unless requested. Inspect adapters, plugin versions,
   initialization and existing Firebase project mappings.
2. Run `python3 automation/scripts/factory.py configure battery_analyzer --firebase`.
   This enables local integration; it does not register cloud projects or apps.
3. Resolve existing dev/prod Firebase project IDs and native application IDs.
   Project/app registration and authenticated FlutterFire operations require the
   user's authorization for those cloud resources. Inspect `flutterfire --help`
   and `flutterfire configure --help` before constructing installed CLI arguments.
4. Use independent environment projects and matching Android/iOS configuration.
   Ensure startup selects the correct FirebaseOptions; initialize Firebase only
   when enabled and configured. Check Android client package names and iOS
   bundle/project IDs against `app.yaml`.
5. Add only requested SDKs. Analytics must respect the consent design; Crashlytics
   requires handler wiring and verified symbol/mapping upload in the build flow.
   Do not route handled failures as fatal or expose sensitive user data in logs.
6. Native Firebase client configuration is not a service-account credential.
   Never commit admin SDK JSON, private signing keys or Firebase CI tokens.
   Follow the repo's policy for client configuration and inject CI files securely.
7. Run factory validation, dependency resolution and tests. Check both flavor
   builds when native tooling is available; report cloud registration, dashboard
   events or Crashlytics symbol upload as unverified until observed.

Never fall back to the development project when production configuration is
missing. Firebase authentication alone does not configure backend Security Rules;
record service-specific setup only when that service is requested.

