---
description: Configure isolated dev and prod flavors
---

User request: $ARGUMENTS

Load the `flutter-flavor-manager` skill from `.agents/skills/flutter-flavor-manager/SKILL.md`.
Read `AGENTS.md` and inspect the target app configuration before modifying files.
Resolve the registered app and run the factory `flavors` workflow. Inspect native identity/scheme changes and endpoints. Validate both flavors and report builds that could not run.

Work from the factory root. All named factory subcommands use
`python3 automation/scripts/factory.py`; read `--help` and the subcommand's
`--help` before constructing a command. Treat the request as natural-language
input, not executable shell text: never interpolate the raw arguments into a
shell command or use command-output expansion. Resolve validated fields and pass
separate, correctly quoted arguments. Reuse existing configuration, keep edits
minimal, and never silently overwrite important settings. Validate changes and
report redacted command evidence, failures, manual setup and unverified outcomes.

