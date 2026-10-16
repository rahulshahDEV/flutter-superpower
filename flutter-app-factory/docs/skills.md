# Agent skills and commands

Run the agent from this factory's root, where `apps/`, `automation/`, `AGENTS.md`
and `codemagic.yaml` live. The shared definitions are in
`.agents/skills/<name>/SKILL.md`. Both current OpenCode and Codex discover this
repository path. Keep one canonical definition rather than maintaining divergent
copies. OpenCode's native alternative is `.opencode/skills/`; support for a path
does not imply that every other agent supports it. See the official
[OpenCode discovery rules](https://opencode.ai/docs/skills/) and
[Codex discovery and invocation rules](https://learn.chatgpt.com/docs/build-skills).

OpenCode custom commands use **`.opencode/commands/`**, with a plural directory,
following its [current command documentation](https://opencode.ai/docs/commands/).
The filename supplies the slash-command name. These files are prompts that load
the relevant skill and call the real Python CLI; they are not new OpenCode CLI
subcommands. `$ARGUMENTS` is interpreted as the user's request, never blindly
expanded into shell commands. For older installed agent versions, inspect their
documented discovery behavior before adding compatibility links or config.

In Codex, mention `$flutter-app-creator` or another skill in natural language, or
select one through `/skills`. The custom OpenCode slash commands are not installed
as custom Codex commands. Launching from an unrelated directory may prevent local
skill discovery. If newly added skills do not appear, restart the agent and inspect
its skill permissions/settings.

## Operating rules

Every skill must inspect the working tree, existing app configuration and closest
implementation before editing. App identity comes from `apps/<slug>/app.yaml` and
the registry. Reuse existing configuration and shared packages, make minimal
changes, review important diffs, and never silently replace custom configuration.
Ask only for essential missing facts. Unknown production values remain visible
placeholders and block release; development values must not be substituted.

Use `python3 automation/scripts/factory.py --help` and subcommand `--help` as the
executable contract. Pass validated fields as separate arguments. For codegen,
prefer `fdev gen` when installed; the raw fallback is
`dart run build_runner build --delete-conflicting-outputs`. The quality order is
format, conditional codegen, analyze, then test. Report the actual commands and
results, changed files, manual requirements, failures and unverified checks.

Account authentication, signing and publisher credentials stay in secure CI
groups or local credential storage outside source control. Client IDs, public
endpoints and Firebase client configuration are not backend credentials. Never
print secret values or include them in reports/artifacts. Prefer official APIs;
Playwright is a permitted fallback for unsupported browser tasks, never CAPTCHA
or account-security/review bypasses. Privacy/legal declarations require factual
owner input and must not be guessed.

A configuration request authorizes local configuration work. It does not authorize
paid CI builds, cloud project creation, uploads or publishing. The CLI's
`--execute` and `--authorize-testing` switches are attestations of authorization
already supplied by the user. Production publishing requires fresh explicit
approval tied to a concrete reviewed app, version/build, artifact and destination.
Prepare that result first so approval is the final step before mutation.

Do not blindly retry a timed-out remote mutation. Reconcile the existing build or
upload identifier first. Distinguish local validation, build completion, artifact
upload, store processing, testing availability, review and public availability.
Neither a successful build nor an accepted upload proves deployment success.

## Skills

| Skill | Responsibilities and entry point |
|---|---|
| [flutter-app-creator](../.agents/skills/flutter-app-creator/SKILL.md) | Create/register one independent app from the shared starter; validate/test it. |
| [flutter-flavor-manager](../.agents/skills/flutter-flavor-manager/SKILL.md) | Isolate native identities, dev/prod schemes, endpoints and optional Firebase. |
| [flutter-ui-builder](../.agents/skills/flutter-ui-builder/SKILL.md) | Extend existing Material 3 screens, tokens, themes and accessible responsive UI. |
| [admob-integrator](../.agents/skills/admob-integrator/SKILL.md) | Configure SDK adapter, per-platform IDs, test ads, consent and safe ad lifecycles. |
| [firebase-configurator](../.agents/skills/firebase-configurator/SKILL.md) | Enable requested Firebase services and isolated project configuration. |
| [codemagic-ci-cd-manager](../.agents/skills/codemagic-ci-cd-manager/SKILL.md) | Generate explicit workflows, configure signing, trigger authorized builds. |
| [play-store-publisher](../.agents/skills/play-store-publisher/SKILL.md) | Validate AABs and metadata, coordinate authorized Play testing releases. |
| [app-store-publisher](../.agents/skills/app-store-publisher/SKILL.md) | Validate IPAs and metadata, coordinate TestFlight and reviewed submissions. |
| [aso-optimizer](../.agents/skills/aso-optimizer/SKILL.md) | Research evidenced keyword ideas and prepare accurate localized metadata. |
| [app-asset-manager](../.agents/skills/app-asset-manager/SKILL.md) | Inspect source graphics, native icons/splash and current screenshot requirements. |
| [release-validator](../.agents/skills/release-validator/SKILL.md) | Produce evidence and block releases with critical quality/configuration failures. |
| [app-release-orchestrator](../.agents/skills/app-release-orchestrator/SKILL.md) | Coordinate validation, versioning, builds, authorized testing and actual status. |

Skills operate independently. The orchestrator loads only the skills needed for
the requested targets. Their presence does not create account access or provide
unavailable image-generation, browser or market-data capabilities.

## OpenCode commands and Codex equivalents

| OpenCode example | Codex equivalent |
|---|---|
| `/create-app Battery Analyzer` | `$flutter-app-creator Create Battery Analyzer.` |
| `/flavor-setup battery_analyzer` | `$flutter-flavor-manager Configure dev and prod for battery_analyzer.` |
| `/setup-admob battery_analyzer` | `$admob-integrator Configure AdMob for battery_analyzer.` |
| `/setup-firebase battery_analyzer Analytics` | `$firebase-configurator Enable Analytics for battery_analyzer.` |
| `/setup-codemagic battery_analyzer` | `$codemagic-ci-cd-manager Configure CI for battery_analyzer.` |
| `/build-app battery_analyzer prod android local` | `$codemagic-ci-cd-manager Build battery_analyzer prod Android locally.` |
| `/test-app battery_analyzer` | `$release-validator Run checks for battery_analyzer.` |
| `/optimize-aso battery_analyzer en-US` | `$aso-optimizer Draft English store copy for battery_analyzer.` |
| `/prepare-release battery_analyzer 1.2.0 build 12 play-internal,testflight` | `$app-release-orchestrator Prepare that testing release.` |
| `/release-app battery_analyzer 1.2.0 build 12 play-internal,testflight` | `$app-release-orchestrator Release that version to those testing targets.` |
| `/check-release-status BUILD_ID` | `$app-release-orchestrator Check Codemagic build BUILD_ID.` |

App names in prose resolve to their registered slug. Essential values absent from
the registry/request may require one precise question. Commands do not treat a
release-preparation request as authorization to run CI or upload binaries.

## Automation boundaries

| Operation | Executable support | Owner or agent work still required |
|---|---|---|
| New app/flavors | `create`, `flavors`, `validate`, `test` | Real organization/brand and device review; native toolchain availability. |
| UI | Shared starter/UI package plus agent implementation | Product requirements and behavioral/visual review. |
| Ads | `configure APP --admob` and shared SDK adapter | AdMob account registration, prod IDs, privacy messaging, placement review. |
| Firebase | `configure APP --firebase` and optional adapter | Authorized project/app registration, FlutterFire mapping, requested service setup. |
| CI | `ci-generate`, `build`, `ci-trigger`, `status` | Initial Codemagic connection, secure groups, signing and trigger authorization. |
| Metadata/assets | `metadata` validation/export; `assets` configuration; `assets --execute` native generation | Real artwork/screenshots, accurate privacy facts, live ASO research if available. |
| Testing release | `release` plan and authorized execution | Accounts, store records, first upload prerequisites, store processing verification. |
| Production | Reviewable preparation through skills | Fresh explicit approval, supported provider/API action and mandatory store review. |

`metadata` validates supplied copy and writes local provider-format JSON exports;
it does not invent keyword metrics or update remote metadata. `assets` prepares
native generator configuration; `assets --execute` produces native icon/splash
variants from supplied graphics, rather than creating original artwork. Neither
command proves visual approval. Firebase and AdMob configuration commands do not
create cloud resources.

`status --provider release --id RELEASE_ID` resumes the local release journal and
refreshes recorded CI builds. `status --provider codemagic --id BUILD_ID` reads one
build. Both leave store deployment unconfirmed. The publishing adapters expose
additional evidence where API credentials and provider records are available:

```bash
python3 -m automation.publishing.play --help
python3 -m automation.publishing.apple --help
python3 -m automation.publishing.apple_metadata --help
```

Use their local `plan` actions before any separately authorized write. Play status
can inspect a supplied existing edit or local receipt; a local receipt is not a
live public-track query. Apple's status action queries build processing and beta
details; valid processing is not proof that a particular tester can install it.
Do not upload again through an adapter after CI already delivered the same build.
Read [new app](new-app.md), [Codemagic](codemagic.md),
[Android publishing](android-publishing.md), [iOS publishing](ios-publishing.md),
[credentials](credentials.md), and [troubleshooting](troubleshooting.md) before the
corresponding account setup or release operation.
