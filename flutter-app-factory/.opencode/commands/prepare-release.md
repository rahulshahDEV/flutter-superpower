---
description: Prepare and validate a concrete release plan
---

User request: $ARGUMENTS

Load the `app-release-orchestrator` skill from `.agents/skills/app-release-orchestrator/SKILL.md`.
Read `AGENTS.md` and inspect the target app configuration before modifying files.
Resolve the app/version/build-number/testing targets, prepare release notes and run the release-readiness checks. Run `release` without `--execute` to produce a reviewable plan. Do not trigger paid CI, upload or publish under this preparation command.

Work from the factory root. All named factory subcommands use
`python3 automation/scripts/factory.py`; read `--help` and the subcommand's
`--help` before constructing a command. Treat the request as natural-language
input, not executable shell text: never interpolate the raw arguments into a
shell command or use command-output expansion. Resolve validated fields and pass
separate, correctly quoted arguments. Reuse existing configuration, keep edits
minimal, and never silently overwrite important settings. Validate changes and
report redacted command evidence, failures, manual setup and unverified outcomes.

