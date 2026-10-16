---
name: flutter-flavor-manager
description: Configure or repair dev/prod Flutter flavors, native identities, environment endpoints and environment-specific Firebase settings.
---

# flutter-flavor-manager

Work from the factory root. Inspect `AGENTS.md`, the app's `app.yaml`, registry,
existing implementation and working tree first. Reuse existing settings; make the
smallest changes and never replace important configuration without reviewing its
diff. Ask only for essential missing identity or account information. Run relevant
checks, report failures with redacted evidence, and distinguish completed, blocked,
and unverified work. Never fabricate build or publishing success.

Read [shared operating rules](../../../docs/skills.md) and run
`python3 automation/scripts/factory.py --help` before using unfamiliar options.

Read [architecture](../../../docs/architecture.md), then inspect Android Gradle,
iOS project configurations/schemes, entry points and current environment values.

1. Run `python3 automation/scripts/factory.py flavors battery_analyzer` using
   the registered slug. Preserve intentional existing native configuration.
2. Verify production uses the canonical application and bundle IDs; development
   uses distinct IDs, names and endpoints. Check feature flags and AdMob test IDs.
3. On Android inspect the actual Gradle DSL and product-flavor dimension. On iOS
   verify shared lowercase dev/prod schemes and Debug/Profile/Release variants,
   Flutter xcconfig inheritance and Podfile mappings.
4. If Firebase is enabled, select the matching project and native files for each
   environment; never copy a dev Firebase configuration into prod as a fallback.
5. Run `python3 automation/scripts/factory.py validate battery_analyzer`.
   Plan each flavor/platform with `build battery_analyzer --flavor dev
   --platform android`; use `--execute` for an authorized local build.
6. Check installed app identity and endpoint in a device/simulator when available;
   record native build checks that could not run.

Client configuration and Dart defines are recoverable from binaries. Keep backend
credentials out of all flavors. Release validation must fail for missing production
values instead of silently substituting dev settings. Follow current official
[Android](https://docs.flutter.dev/deployment/flavors) and
[iOS flavor guidance](https://docs.flutter.dev/deployment/flavors-ios).

