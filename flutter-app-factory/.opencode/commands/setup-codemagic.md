---
description: Generate scoped per-app Codemagic workflows
---

User request: $ARGUMENTS

Load the `codemagic-ci-cd-manager` skill from `.agents/skills/codemagic-ci-cd-manager/SKILL.md`.
Read `AGENTS.md` and inspect the target app configuration before modifying files.
Inspect the app registry and existing YAML, run `ci-generate`, and review generated entries. Preserve important custom configuration and document missing per-app signing groups/integrations. Configuration does not authorize paid build triggers.

Work from the factory root. All named factory subcommands use
`python3 automation/scripts/factory.py`; read `--help` and the subcommand's
`--help` before constructing a command. Treat the request as natural-language
input, not executable shell text: never interpolate the raw arguments into a
shell command or use command-output expansion. Resolve validated fields and pass
separate, correctly quoted arguments. Reuse existing configuration, keep edits
minimal, and never silently overwrite important settings. Validate changes and
report redacted command evidence, failures, manual setup and unverified outcomes.

