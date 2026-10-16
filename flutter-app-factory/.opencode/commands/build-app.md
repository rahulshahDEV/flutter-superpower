---
description: Plan or run a selected local or Codemagic build
---

User request: $ARGUMENTS

Load the `codemagic-ci-cd-manager` skill from `.agents/skills/codemagic-ci-cd-manager/SKILL.md`.
Read `AGENTS.md` and inspect the target app configuration before modifying files.
Resolve app, flavor, platform and local-versus-CI intent from the request. Run `build APP --flavor FLAVOR --platform PLATFORM` first for a local build plan. `--execute` runs that local build when requested. Use `ci-trigger` only if CI and its cost were authorized; inspect --help for precise flags. Report actual IDs/status.

Work from the factory root. All named factory subcommands use
`python3 automation/scripts/factory.py`; read `--help` and the subcommand's
`--help` before constructing a command. Treat the request as natural-language
input, not executable shell text: never interpolate the raw arguments into a
shell command or use command-output expansion. Resolve validated fields and pass
separate, correctly quoted arguments. Reuse existing configuration, keep edits
minimal, and never silently overwrite important settings. Validate changes and
report redacted command evidence, failures, manual setup and unverified outcomes.

