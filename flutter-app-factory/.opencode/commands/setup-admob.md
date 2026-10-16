---
description: Configure test-safe Google Mobile Ads integration
---

User request: $ARGUMENTS

Load the `admob-integrator` skill from `.agents/skills/admob-integrator/SKILL.md`.
Read `AGENTS.md` and inspect the target app configuration before modifying files.
Resolve the app and run `configure APP --admob`. Inspect consent/native wiring and use only test ads for development or automation. Report missing production IDs and AdMob account/privacy setup; do not create remote resources without authorization.

Work from the factory root. All named factory subcommands use
`python3 automation/scripts/factory.py`; read `--help` and the subcommand's
`--help` before constructing a command. Treat the request as natural-language
input, not executable shell text: never interpolate the raw arguments into a
shell command or use command-output expansion. Resolve validated fields and pass
separate, correctly quoted arguments. Reuse existing configuration, keep edits
minimal, and never silently overwrite important settings. Validate changes and
report redacted command evidence, failures, manual setup and unverified outcomes.

