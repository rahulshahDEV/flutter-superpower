---
name: flutter-app-creator
description: Create and register an independent Flutter app in the App Factory monorepo using the shared starter, identifiers and dev/prod environments.
---

# flutter-app-creator

Work from the factory root. Inspect `AGENTS.md`, the app's `app.yaml`, registry,
existing implementation and working tree first. Reuse existing settings; make the
smallest changes and never replace important configuration without reviewing its
diff. Ask only for essential missing identity or account information. Run relevant
checks, report failures with redacted evidence, and distinguish completed, blocked,
and unverified work. Never fabricate build or publishing success.

Read [shared operating rules](../../../docs/skills.md) and run
`python3 automation/scripts/factory.py --help` before using unfamiliar options.

Read [new app guide](../../../docs/new-app.md).

1. Resolve a display name, Dart-safe slug and reverse-DNS organization from the
   request and repository settings. Reuse known identifiers. Missing organization
   may remain an explicit placeholder for development; release must reject it.
2. Inspect `apps/` and registry for collisions before creating directories. An
   existing app means inspect or resume it, never silently regenerate it.
3. Run `python3 automation/scripts/factory.py create --name "Battery Analyzer"
   --slug battery_analyzer --org com.example` with the actual requested values.
   This example organization is a placeholder, not a publishable identity.
4. Inspect the generated Android/iOS identities, dev/prod entry points, shared
   package dependencies, feature structure, metadata and `app.yaml`.
5. Run `python3 automation/scripts/factory.py validate battery_analyzer` and
   `python3 automation/scripts/factory.py test battery_analyzer`.
6. Report generated files and exact check results. Name remaining placeholders and
   native build prerequisites; a scaffold is not a published application.

Generate only the requested app. Add features through the established house
architecture; local state stays local and async flows use SafeCubit.

