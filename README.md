![Flutter Superpower](assets/banner.png)

# flutter-superpower

One agent skill that makes any Flutter app come out in the owner's structure —
battle-tested across multiple production Flutter apps, with scope discipline built in
and the owner's `fdev` CLI wired into the workflow.

## How it works

- The frontmatter `description` triggers the skill automatically on any Flutter task
  (new app, feature, screen, cubit, API, theme, router, bug, test).
- `SKILL.md` holds the 12 laws, workflow, red flags, rationalization table, and the
  evidence-before-done gate. Heavy detail lives in `references/` and is loaded only when
  the task needs it.
- **Structure is non-negotiable; scope is lazy.** The ponytail ladder is built in, so the
  skill enforces the house architecture while refusing unneeded packages, abstractions,
  and widgets.

## Senior developer behavior (built in)

The skill operates as the senior engineer who owns the task end to end:

- **Profile before changing** — architecture, state, routing, DI, networking, models, tests,
  design system, mode — then plan.
- **Existing project conventions > skill defaults > generic preference.** Greenfield uses the
  defaults; existing projects are mirrored, not rewritten; migrations only on request, staged.
- **Owns the obvious work** — states, validation, DI, routes, constants, tests, platform
  config — without asking about trivia.
- **Definition of Done + evidence report** (Implemented / Files changed / Verification /
  Not verified / Notes) — never "Done." without proof.
- **Audit capability** — `scripts/audit.sh <app> [--perf]` mechanical pass + agent review per
  `references/auditing.md`; release readiness via `scripts/release-check.sh <app>`.
- **Full lifecycle coverage** — auth (Google/Apple), performance, security, accessibility,
  localization, dependencies, native config, releases, store submission, fastlane/Codemagic,
  and Shorebird OTA updates.

### Verify it yourself

```bash
tests/consistency.sh   # links, version sync, placeholders, script syntax (seconds)
tests/run.sh           # installer + scaffold + feature generator + audits (needs Flutter)
```

Behavior cases live in `evals/` (protocol in `evals/README.md`, results in `evals/RESULTS.md`).
There is no CI by design — the tests run locally, and they must be green before a release.

See `CONTRIBUTING.md` to propose changes.

### What happens when you ask for a feature

```
"Implement order history with pagination"
  → profile the project (architecture, state, routing, DI, net, design system)
  → find the closest existing feature and mirror it
  → plan: entity → repo → model → data source → use case → state → cubit → UI → route → tests
  → implement all states (loading/error/empty/success) + edge cases
  → self-review the diff (layers, reuse, scope, security, regression)
  → verify: dart format · fdev gen · flutter analyze · flutter test
  → report: Implemented / Files changed / Verification / Not verified / Notes
```

## Before / after (measured)

Real run on this machine — macOS · Flutter 3.38.9 · Dart 3.10.8 · warm caches · 2026-09-24.
The "typical manual" column is a conservative **estimate** for producing the same verified
result by hand; it is not a controlled study. The measured column is reproducible with the
commands below.

| Task | Typical manual (estimate) | With flutter-superpower (measured) |
|---|---|---|
| New app skeleton — 46 Dart files: layers, DI, theme, router, constants, design system, tests | 2–4 h | **19.1 s** — `scripts/new_app.sh` |
| New feature — 10 files across data/domain/presentation + codegen + endpoint constant + route snippet | 1–2 h | **9.8 s** — `scripts/new_feature.sh` |
| Architecture audit of a 530-file production app | 1–2 h of manual review | **0.9 s** mechanical pass + agent review |
| Verify a change (format → analyze → test) | minutes, easy to skip | **8.2 s** — enforced by the evidence gate |
| Behavior compliance | — | **7/7 eval cases passed**, 40+ tests generated |

```
Measured pipeline timings (seconds, same machine)
scaffold app        ████████████████████ 19.1
generate feature    ██████████ 9.8
flutter test        ██████ 5.8
flutter analyze     ███ 2.5
audit (530 files)   █ 0.9
```

Reproduce: `scripts/new_app.sh bench --dir /tmp/bench` · `scripts/new_feature.sh orders --app /tmp/bench` ·
`scripts/audit.sh /path/to/app --static` · `tests/run.sh`.

## What it enforces

- Feature-first clean architecture: `lib/features/<x>/{data,domain,presentation}` + `lib/core/` + `lib/di/`
- `flutter_bloc` Cubits + `SafeCubit` + sealed/freezed states
- `get_it` + `injectable` DI (`@injectable` cubits, `@LazySingleton(as:)` repos)
- `go_router` with `static const path/routeName` per screen + typed route-data
- `dio` + `Either<Failure, T>` + `safeApiCall`/`ErrorHandler`
- `json_serializable` models extending Equatable entities
- Centralized constants: colors, text styles, strings, API paths, storage keys
- `flutter_screenutil` (390×844 / 375×812) + `AppSizes` tokens
- Design system: `KButton`, `KTextField`, `ImageRenderer`, empty/error/loading, shimmer, custom snackbar
- dev/prod flavors via `dotenv` + `AppConfig`/`FlavorConfig`
- `AppLogger` dev-only; `flutter analyze` + `flutter test` + `dart format` gate
- `fdev` CLI for codegen, builds, clean, env, keystores, Swagger models

## Layout

```
flutter-superpower/
├── README.md
├── SKILL.md                         ← entry point: laws, workflow, red flags, evidence gate
├── CHANGELOG.md
├── AGENTS.md                        ← guidance for agents editing this skill
├── INSTALL.md                       ← agent-executable install instructions
├── CODE_OF_CONDUCT.md · CONTRIBUTING.md · SECURITY.md · LICENSE
├── assets/                          ← banner and media assets
├── evals/                           ← 20 behavior cases + protocol + recorded results
├── tests/                           ← consistency.sh (fast) + run.sh (Flutter regression)
├── scripts/
│   ├── setup.sh                     ← one-command remote setup (curl | sh)
│   ├── install.ps1                  ← Windows installer
│   ├── install.sh                   ← cross-agent installer
│   ├── audit.sh                     ← read-only project audit (mechanical report)
│   ├── new_app.sh                   ← scaffold a full app skeleton (analyze-clean)
│   └── new_feature.sh               ← generate a feature: all layers + codegen + route snippet
├── templates/
│   ├── app/                         ← skeleton copied by new_app.sh
│   ├── feature/                     ← feature files copied by new_feature.sh
│   └── pointer-snippet.md           ← AGENTS.md / Cursor-rule pointer for non-skill agents
└── references/
    ├── architecture.md              ← layers, folders, naming, feature template
    ├── state-and-di.md              ← cubits, states, injectable wiring
    ├── routing.md                   ← go_router, route data, guards, shells
    ├── networking-and-errors.md     ← DioClient, interceptors, Either, logging
    ├── models-and-storage.md        ← entities/models/json, prefs, secure storage
    ├── theme-and-design-system.md   ← colors, text, sizing, K-widgets, strings
    ├── app-bootstrap.md             ← main(), flavors, DI boot, Firebase/FCM
    ├── playbooks.md                 ← new-app-from-zero + new-feature recipes
    ├── debugging.md                 ← loop, symptom→layer, house failure modes
    ├── testing.md                   ← fakes, cubit/widget/model tests, no mockito
    ├── ci-cd.md                     ← GitHub Actions, secrets, release flow
    ├── chat-realtime.md             ← Socket.IO, E2E crypto, optimistic send
    ├── maps-location-health.md      ← maps, geolocation, permissions, steps
    ├── reviewing.md                 ← two-axis diff review: Standards + Spec
    ├── senior-mode.md               ← senior engineer behavior: profile, modes, DoD, reports
    ├── auditing.md                  ← project audit dimensions + report format
    ├── performance.md               ← rebuilds, lists, images, startup, memory
    ├── app-optimization.md          ← level-wise optimization plan (implement/plan/skip)
    ├── security.md                  ← secrets, log redaction, storage, transport, hardening
    ├── accessibility.md             ← semantics, targets, text scaling, contrast, focus
    ├── localization.md              ← StringConstants vs ARB, plurals, intl, RTL
    ├── dependencies.md              ← add/remove discipline and evaluation
    ├── native.md                    ← Android/iOS triage, flavors, signing, pods
    ├── release.md                   ← release checklist + release-check.sh
    ├── auth-social.md               ← Google & Apple sign-in end to end
    ├── store-release.md             ← Play + App Store submission and rejections
    ├── fastlane-codemagic.md        ← fastlane lanes + codemagic.yaml
    ├── shorebird.md                 ← OTA code push: patchability, tracks, compliance
    ├── ponytail.md                  ← scope discipline / anti-over-engineering
    └── fdev.md                      ← owner's fdev CLI command map
```

## Install (any agent)

### Easy setup

**Let your agent do it** — paste into any agent that can fetch a URL:

> Fetch and follow https://raw.githubusercontent.com/rahulshahDEV/flutter-superpower/main/INSTALL.md

**One-liner (macOS / Linux):**

```bash
curl -fsSL https://raw.githubusercontent.com/rahulshahDEV/flutter-superpower/main/scripts/setup.sh | sh
```

**Windows (PowerShell):**

```powershell
iwr -useb https://raw.githubusercontent.com/rahulshahDEV/flutter-superpower/main/scripts/install.ps1 | iex
```

**Manual:**

```bash
git clone https://github.com/rahulshahDEV/flutter-superpower.git ~/.flutter-superpower
~/.flutter-superpower/scripts/install.sh          # install where an agent is detected
~/.flutter-superpower/scripts/install.sh --all    # also create dirs for agents not yet installed
~/.flutter-superpower/scripts/install.sh --copy   # copy instead of symlink
~/.flutter-superpower/scripts/install.sh --project /path/to/flutter/app   # one app only
```

Restart the agent session after installing — skills are discovered at session start.

| Agent | Global location(s) installed |
|---|---|
| Claude Code | `~/.claude/skills/flutter-superpower` |
| opencode | `~/.config/opencode/skills/…` + `~/.claude/skills/…` + `~/.agents/skills/…` |
| Codex | `~/.agents/skills/…` + `~/.codex/skills/…` |
| Gemini CLI | `~/.gemini/skills/…` + `~/.agents/skills/…` |
| GitHub Copilot CLI | `~/.copilot/skills/…` + `~/.agents/skills/…` |
| Cursor | `~/.cursor/skills/…` (or project `.cursor/skills/…`) |
| Antigravity | `~/.gemini/antigravity/skills/…` |

Project-level targets: `.claude/skills`, `.agents/skills`, `.opencode/skills`, `.cursor/skills`.

Rules that keep every harness happy:

- The skill **directory must be named `flutter-superpower`** — the frontmatter `name` matches it.
- Frontmatter uses only portable fields: `name`, `description`, `license`, `metadata`.
  `description` is under 1024 chars (the spec limit).
- Body is plain markdown — no agent-specific syntax or tools.

**Agents without skill support** (older Cursor, Windsurf, plain chat): paste
`templates/pointer-snippet.md` into the project's `AGENTS.md` / `CLAUDE.md`, or save it as a
`.cursor/rules/flutter-superpower.mdc` rule.

## Updating

The symlink points at the clone, so `git pull` updates every agent at once. No reinstall.

## When something goes wrong

- **Skill didn't trigger** — check the symlink target, then the task wording: mention
  "Flutter" + the artifact (screen/cubit/feature). Worst case, tell the agent to read
  `SKILL.md` first.
- **Agent skipped the house style** — quote the red-flags section back at it; the fix is
  usually a missing REQUIRED reference (playbooks/testing/debugging).
- **A reference contradicts reality** — the app in front of you wins; fix the reference in
  the same PR (`AGENTS.md` has the rules).

## Versioning & releases

- Version lives in three places, kept in sync: `SKILL.md` → `metadata.version`,
  `CHANGELOG.md`, and the git tag `vX.Y.Z`.
- Release flow: bump the three, commit, then tag and publish:
  ```bash
  git tag -a vX.Y.Z -m "vX.Y.Z"
  git push origin main --tags
  gh release create vX.Y.Z --title "vX.Y.Z" \
    --notes-file <(sed -n '/^## X.Y.Z/,/^## /p' CHANGELOG.md | sed '$d')
  ```

## License

MIT — see [LICENSE](LICENSE).
