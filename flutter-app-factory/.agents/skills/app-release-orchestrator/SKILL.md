---
name: app-release-orchestrator
description: Coordinate validated per-app releases through Codemagic to authorized Play internal testing and TestFlight, track actual outcomes and gate production approval.
---

# app-release-orchestrator

Work from the factory root. Inspect `AGENTS.md`, the app's `app.yaml`, registry,
existing implementation and working tree first. Reuse existing settings; make the
smallest changes and never replace important configuration without reviewing its
diff. Ask only for essential missing identity or account information. Run relevant
checks, report failures with redacted evidence, and distinguish completed, blocked,
and unverified work. Never fabricate build or publishing success.

Read [shared operating rules](../../../docs/skills.md) and run
`python3 automation/scripts/factory.py --help` before using unfamiliar options.

Read [release guide](../../../docs/release.md) and the target publishing guide.
Use the other factory skills for their concrete responsibilities; do not assume
their external capabilities are configured merely because their files exist.

1. Identify registered app, target platforms, prod flavor, requested independent
   version/build number and destination. Preserve existing authorization; resolve
   essential ambiguity before a remote mutation.
2. Inspect working tree, app/native configuration and release history. Update
   version through the factory's release preparation, then inspect the diff.
3. Run the release-validator workflow: format, conditional codegen, analyze/test,
   flavors/identifiers, AdMob test-vs-production isolation and consent, Firebase
   isolation if enabled, signing requirements, metadata and assets.
4. Generate factual release notes and review store requirements. Stop on critical
   failures or missing legal/account facts. Prepare a concrete release plan.
5. Plan with `python3 automation/scripts/factory.py release battery_analyzer
   --version 1.2.0 --build-number 12 --targets play-internal,testflight`.
   A plan is neither a paid build nor an upload.
6. If the user has authorized this testing deployment and CI cost, execute the
   same reviewed command with `--execute --authorize-testing`. Treat the flag
   as an attestation of user authorization, not a source of authorization.
7. Record the returned release ID and build IDs. Poll `python3
   automation/scripts/factory.py status --provider release --id RELEASE_ID` for
   the resumable local journal, or `status --provider codemagic --id BUILD_ID`
   for one remote build, with bounded backoff. Verify the correct workflow,
   commit, version and target; stop on terminal failure. Never retrigger just
   because a request timed out; first reconcile its existing build state.
8. Verify artifact identity/hash/signing and publisher response where tools permit.
   The release journal tracks CI and deliberately leaves deployment unconfirmed.
   Use the publishing skills and their official API adapters to gather available
   Play track or App Store processing/TestFlight evidence separately.
   Build success alone cannot prove testing availability or store publication.
9. Report each platform separately: validation, build ID/status, artifact,
   upload/processing/testing state, evidence and remaining owner actions.

Production publication is excluded from the default testing CLI. Prepare a
reviewable concrete release action, then require fresh explicit approval bound to
app/version/build/artifact/destination immediately before production mutation.
Use official APIs; Playwright is a fallback only for permitted unsupported tasks,
never CAPTCHA, review, account-security or consent bypasses.

