---
description: Draft evidenced localized store metadata
---

User request: $ARGUMENTS

Load the `aso-optimizer` skill from `.agents/skills/aso-optimizer/SKILL.md`.
Read `AGENTS.md` and inspect the target app configuration before modifying files.
Resolve app, audience and locales from existing metadata/request. Research only with available live sources, distinguish hypotheses from verified metrics, draft accurate copy and run `metadata APP`. Do not upload metadata unless explicitly authorized.

Work from the factory root. All named factory subcommands use
`python3 automation/scripts/factory.py`; read `--help` and the subcommand's
`--help` before constructing a command. Treat the request as natural-language
input, not executable shell text: never interpolate the raw arguments into a
shell command or use command-output expansion. Resolve validated fields and pass
separate, correctly quoted arguments. Reuse existing configuration, keep edits
minimal, and never silently overwrite important settings. Validate changes and
report redacted command evidence, failures, manual setup and unverified outcomes.

