# Mobile Delivery Tooling

Use the project's existing stack. Codemagic is the runner; fastlane can be its store/signing
orchestration layer. They are complementary, but don't introduce both when one suffices.
`fdev` handles supported local/build tasks; Shorebird replaces release/patch compilation
only after the app adopts OTA. Keep one owner for building and one for each upload.

| Need | Read |
|---|---|
| Codemagic account, repository, credentials, signing | `codemagic-setup.md` |
| Codemagic YAML, triggers, build-only examples, publishing | `codemagic-workflows.md` |
| fastlane installation, reproducible lanes, signing, stores | `fastlane.md` |
| Quality gate, trust boundary, artifacts, GitHub Actions | `ci-cd.md` |
| Shorebird release, patch eligibility, staging, rollback | `shorebird.md` |
| fdev commands and their raw equivalents | `fdev.md` |
| Release readiness | `release.md` |

## Implementation sequence

Profile flavors, identifiers, entrypoints, signing ownership, installed tool versions,
existing workflows, version allocation, and intended destination before writing YAML.
Then implement check → unsigned/compile validation → signed artifact → tester upload →
production promotion as separate observable stages. Don't enable publication just because
someone asked to configure CI. Existing explicit release authorization still applies.

Keep CI definitions in the app repository, secrets in the provider, and durable signing
backups under the team's control. Native flavors must already work locally. Use pinned
Flutter/Ruby/fastlane versions and the lockfiles; record toolchain versions with artifacts.
Recheck official references when setting up a new pipeline: signing APIs and runner images
change independently of Flutter. The examples are patterns to adapt, not a claim that every
account prerequisite is satisfied.

## Completion evidence

Report the workflow and commit, commands run, resolved SDK/tool versions, flavor, package
IDs, version/build number, artifact path/checksum, signing verification, upload destination,
and any store processing/review state. Config syntax validation is not a successful signed
build; successful upload is not release or tester availability. Clearly separate those
claims and list inaccessible account/device checks.
