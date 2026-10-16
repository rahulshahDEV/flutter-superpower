---
description: Configure optional per-environment Firebase integration
---

User request: $ARGUMENTS

Load the `firebase-configurator` skill from `.agents/skills/firebase-configurator/SKILL.md`.
Read `AGENTS.md` and inspect the target app configuration before modifying files.
Resolve the app and requested Firebase services. Run `configure APP --firebase` only because Firebase was requested. Keep dev/prod projects separate; account registration and FlutterFire cloud operations require authorization.

Work from the factory root. All named factory subcommands use
`python3 automation/scripts/factory.py`; read `--help` and the subcommand's
`--help` before constructing a command. Treat the request as natural-language
input, not executable shell text: never interpolate the raw arguments into a
shell command or use command-output expansion. Resolve validated fields and pass
separate, correctly quoted arguments. Reuse existing configuration, keep edits
minimal, and never silently overwrite important settings. Validate changes and
report redacted command evidence, failures, manual setup and unverified outcomes.

