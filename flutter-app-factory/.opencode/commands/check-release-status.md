---
description: Check an existing build or release without retriggering
---

User request: $ARGUMENTS

Load the `app-release-orchestrator` skill from `.agents/skills/app-release-orchestrator/SKILL.md`.
Read `AGENTS.md` and inspect the target app configuration before modifying files.
Resolve the provider/build ID or local release ID from the request or recorded release evidence. Run `status --provider codemagic --id BUILD_ID` for one build, or `status --provider release --id RELEASE_ID` for the release journal. The journal does not confirm store deployment. When credentials/tools permit, inspect corresponding store status through the publishing skills too. Report build, upload, processing and testing states separately. Do not start or retry builds.

Work from the factory root. All named factory subcommands use
`python3 automation/scripts/factory.py`; read `--help` and the subcommand's
`--help` before constructing a command. Treat the request as natural-language
input, not executable shell text: never interpolate the raw arguments into a
shell command or use command-output expansion. Resolve validated fields and pass
separate, correctly quoted arguments. Reuse existing configuration, keep edits
minimal, and never silently overwrite important settings. Validate changes and
report redacted command evidence, failures, manual setup and unverified outcomes.

