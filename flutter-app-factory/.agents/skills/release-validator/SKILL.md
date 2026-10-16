---
name: release-validator
description: Check app quality, native identities/flavors, versioning, ads/privacy/signing and store metadata, producing evidence that blocks unsafe releases.
---

# release-validator

Work from the factory root. Inspect `AGENTS.md`, the app's `app.yaml`, registry,
existing implementation and working tree first. Reuse existing settings; make the
smallest changes and never replace important configuration without reviewing its
diff. Ask only for essential missing identity or account information. Run relevant
checks, report failures with redacted evidence, and distinguish completed, blocked,
and unverified work. Never fabricate build or publishing success.

Read [shared operating rules](../../../docs/skills.md) and run
`python3 automation/scripts/factory.py --help` before using unfamiliar options.

Read [release guide](../../../docs/release.md). Resolve the app and requested
version/flavor/platform/track before evaluating readiness.

1. Inspect `app.yaml`, native files, metadata and proposed diff. Do not accept
   configuration declarations as proof of binary behavior.
2. Run `python3 automation/scripts/factory.py validate battery_analyzer --release`.
   Run `metadata battery_analyzer` and `assets battery_analyzer` as relevant.
3. Run `python3 automation/scripts/factory.py test battery_analyzer`: formatting,
   conditional generation (`fdev gen`, raw fallback
   `dart run build_runner build --delete-conflicting-outputs`), analysis then
   tests. If the CLI does not include a required gate, run it explicitly.
4. Verify actual canonical/dev identities, endpoint isolation, version/build
   agreement, native build settings and matching signing/provisioning. Check
   Firebase project selection only when enabled.
5. Verify development and automated tests cannot request production ads. Check
   UMP consent gating, app/ad-unit IDs, tracking/permission declarations and
   actual Data Safety/App Privacy answers against installed SDK behavior.
6. Check required store metadata/assets, support/privacy URLs, access details,
   target SDK/toolchain requirements and store/account prerequisites.
7. For built artifacts inspect manifest/plist/signing and record checksum. CI
   signing and remote store readiness remain unverified without provider evidence.
8. Emit a report with passed checks, critical blockers, warnings and unverified
   checks. Include exact commands, exit status, artifact/version/commit identity
   and redacted evidence. Block the requested release on critical failure.

Static validation alone does not certify store policy compliance or deployment
readiness. Missing secrets should be reported by name/presence only. Never print
credential values or mark checks successful because tools were unavailable.

