---
description: Run app quality checks and report failures
---

User request: $ARGUMENTS

Load the `release-validator` skill from `.agents/skills/release-validator/SKILL.md`.
Read `AGENTS.md` and inspect the target app configuration before modifying files.
Resolve the registered app. Run `validate APP` and `test APP`; inspect errors and report exact exit statuses. This is a quality check, not authorization for uploads, paid CI or release.

Work from the factory root. All named factory subcommands use
`python3 automation/scripts/factory.py`; read `--help` and the subcommand's
`--help` before constructing a command. Treat the request as natural-language
input, not executable shell text: never interpolate the raw arguments into a
shell command or use command-output expansion. Resolve validated fields and pass
separate, correctly quoted arguments. Reuse existing configuration, keep edits
minimal, and never silently overwrite important settings. Validate changes and
report redacted command evidence, failures, manual setup and unverified outcomes.

