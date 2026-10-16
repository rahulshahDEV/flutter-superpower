---
description: Execute an authorized release and track real outcomes
---

User request: $ARGUMENTS

Load the `app-release-orchestrator` skill from `.agents/skills/app-release-orchestrator/SKILL.md`.
Read `AGENTS.md` and inspect the target app configuration before modifying files.
Resolve app/version/build-number/targets and inspect the reviewable release plan. Testing deployment execution requires the user's authorization for the concrete targets and paid CI before `--execute --authorize-testing`. Production requires fresh explicit approval tied to the reviewed artifact/version/destination. Monitor and report confirmed per-platform outcomes; never infer upload success from build success.

Work from the factory root. All named factory subcommands use
`python3 automation/scripts/factory.py`; read `--help` and the subcommand's
`--help` before constructing a command. Treat the request as natural-language
input, not executable shell text: never interpolate the raw arguments into a
shell command or use command-output expansion. Resolve validated fields and pass
separate, correctly quoted arguments. Reuse existing configuration, keep edits
minimal, and never silently overwrite important settings. Validate changes and
report redacted command evidence, failures, manual setup and unverified outcomes.

