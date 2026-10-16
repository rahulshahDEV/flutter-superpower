---
name: codemagic-ci-cd-manager
description: Generate per-app Codemagic workflows for Android/iOS and dev/prod, configure signing and secure groups, and trigger or inspect authorized builds.
---

# codemagic-ci-cd-manager

Work from the factory root. Inspect `AGENTS.md`, the app's `app.yaml`, registry,
existing implementation and working tree first. Reuse existing settings; make the
smallest changes and never replace important configuration without reviewing its
diff. Ask only for essential missing identity or account information. Run relevant
checks, report failures with redacted evidence, and distinguish completed, blocked,
and unverified work. Never fabricate build or publishing success.

Read [shared operating rules](../../../docs/skills.md) and run
`python3 automation/scripts/factory.py --help` before using unfamiliar options.

Read [Codemagic setup](../../../docs/codemagic.md). Verify current official YAML
and REST API documentation before changing provider-specific fields.

1. Inspect app registry, `codemagic.yaml`, managed markers, workflow generation,
   app/platform enablement and credential-group names.
2. Run `python3 automation/scripts/factory.py ci-generate`. Review the diff;
   preserve custom workflows and reject unsafe overwrites.
3. Use explicit generated app/flavor/platform workflow entries. Dynamic app
   selection means selecting an existing workflow ID, not arbitrary YAML runtime
   expansion. Use scoped change patterns for app files plus relevant shared
   packages/infrastructure so unrelated apps do not rebuild.
4. Ensure each workflow resolves dependencies, formats/checks, conditionally
   generates code, analyzes/tests, builds the selected AAB or signed IPA, and
   retains artifacts. Independent app version/build values come from its config.
5. Configure Android keystores and Apple integration/profiles through Codemagic
   signing facilities and per-app secure groups. Validate IDs match signing
   identities. Never print credentials or include them in generated artifacts.
6. Testing publication must be explicitly enabled for authorized internal Play /
   TestFlight targets. Production upload/submission requires fresh approval tied
   to the concrete app, version, artifact and destination.
7. For a local build plan use `build battery_analyzer --flavor prod --platform
   android`. For an authorized paid CI trigger use `ci-trigger battery_analyzer
   --flavor prod --platform android --execute`. Prefix these subcommands with
   `python3 automation/scripts/factory.py`.
8. Record the actual API build ID and check `status --provider codemagic --id ID`.
   Distinguish queued, building, build success, publishing and confirmed store
   status. Stop on failures; include redacted logs and actionable next steps.

Never trigger paid builds just because configuration was requested. Configure a
supported failure notification destination with supplied values; do not invent
email addresses or claim a notification was sent.

