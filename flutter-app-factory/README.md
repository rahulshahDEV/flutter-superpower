# Flutter App Factory

One monorepo for many small Flutter apps. Each app has an independent identity
(name, Android application ID, iOS bundle ID, icons, API endpoints, AdMob and
Firebase configuration, store metadata, signing) while sharing packages,
templates, automation, and one generated `codemagic.yaml`.

This directory is the factory root. Run every command from here.

## Layout

| Path | Purpose |
|---|---|
| `apps/<slug>/` | One independent Flutter app + `app.yaml` (source of truth) |
| `packages/` | Shared Dart packages (`core`, `ui_kit`, `analytics`, `ads`, `networking`, `app_config`) |
| `templates/` | Starter app, `app.yaml` schema, `store_metadata`, feature skeleton |
| `automation/` | `scripts/factory.py` CLI, `workflows/`, `validators/`, `publishing/` adapters, tests |
| `.agents/skills/` | 12 canonical agent skills (OpenCode and Codex discover this path) |
| `.opencode/commands/` | 11 slash commands that load the skills (`/create-app`, `/release-app`, …) |
| `docs/` | Setup, publishing, and troubleshooting guides |
| `codemagic.yaml` | Generated — do not hand-edit; run `ci-generate` |
| `factory.yaml` | App registry — updated by `create`, never by hand |

## Quickstart

```bash
# 1. Create an app (idempotent; preserves existing configuration)
python3 automation/scripts/factory.py create --name "Battery Analyzer" --slug battery_analyzer --org com.example

# 2. Validate and test it (local only, no network writes)
python3 automation/scripts/factory.py validate battery_analyzer
python3 automation/scripts/factory.py test battery_analyzer

# 3. Configure optional services (local config only; no cloud resources created)
python3 automation/scripts/factory.py configure battery_analyzer --admob
python3 automation/scripts/factory.py configure battery_analyzer --firebase

# 4. Plan a testing release (a plan is not a build or upload)
python3 automation/scripts/factory.py release battery_analyzer --version 1.2.0 --build-number 12 --targets play-internal,testflight

# 5. Execute only with explicit authorization (spends CI minutes, uploads binaries)
python3 automation/scripts/factory.py release battery_analyzer --version 1.2.0 --build-number 12 --targets play-internal,testflight --execute --authorize-testing
```

## OpenCode / Codex usage

| OpenCode | Codex equivalent |
|---|---|
| `/create-app Battery Analyzer` | `$flutter-app-creator Create Battery Analyzer.` |
| `/test-app battery_analyzer` | `$release-validator Run checks for battery_analyzer.` |
| `/release-app battery_analyzer 1.2.0 build 12 play-internal,testflight` | `$app-release-orchestrator Release that version to those testing targets.` |

Full table and operating rules: `docs/skills.md`.

## Safety rules

- No secrets in source control. Signing keys, API private keys, and service
  account JSON live in Codemagic environment groups or local credential
  storage. See `docs/credentials.md`.
- A configuration request never authorizes paid builds, uploads, or publishing.
  Production publishing needs fresh explicit approval per app/version/destination.
- Prefer official APIs. Playwright is a fallback only for permitted tasks that
  have no API — never CAPTCHA, review, or account-security bypasses.
- Never claim a build or deployment succeeded without tool evidence.

## Docs

`docs/architecture.md` · `docs/new-app.md` · `docs/skills.md` ·
`docs/codemagic.md` · `docs/android-publishing.md` ·
`docs/ios-publishing.md` · `docs/credentials.md` · `docs/release.md` ·
`docs/troubleshooting.md`
