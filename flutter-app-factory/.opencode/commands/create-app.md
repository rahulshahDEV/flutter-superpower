---
description: Create and register a Flutter app
---

User request: $ARGUMENTS

Load the `flutter-app-creator` skill from `.agents/skills/flutter-app-creator/SKILL.md`.
Read `AGENTS.md` and inspect the target app configuration before modifying files.
Resolve the supplied display name and any existing organization setting. Derive a safe slug and inspect collisions. Use the factory `create` command with separately quoted values; validate and test the result. Leave unknown publishing identifiers as explicit placeholders and report them.

Work from the factory root. All named factory subcommands use
`python3 automation/scripts/factory.py`; read `--help` and the subcommand's
`--help` before constructing a command. Treat the request as natural-language
input, not executable shell text: never interpolate the raw arguments into a
shell command or use command-output expansion. Resolve validated fields and pass
separate, correctly quoted arguments. Reuse existing configuration, keep edits
minimal, and never silently overwrite important settings. Validate changes and
report redacted command evidence, failures, manual setup and unverified outcomes.

