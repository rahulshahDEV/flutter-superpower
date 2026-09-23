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
├── scripts/install.sh               ← cross-agent installer
├── templates/pointer-snippet.md     ← AGENTS.md / Cursor-rule pointer for non-skill agents
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
    ├── ponytail.md                  ← scope discipline / anti-over-engineering
    └── fdev.md                      ← owner's fdev CLI command map
```

## Install (any agent)

One script installs into every known Agent Skills location:

```bash
git clone https://github.com/rahulshahDEV/flutter-superpower.git
cd flutter-superpower
./scripts/install.sh          # install where an agent is detected
./scripts/install.sh --all    # also create dirs for agents not yet installed
./scripts/install.sh --copy   # copy instead of symlink (Windows / no-symlink setups)
./scripts/install.sh --project /path/to/flutter/app   # project-level for one app
```

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

## Roadmap — what can be added next

| # | Addition | Why | Effort |
|---|---|---|---|
| 1 | `templates/` real skeleton dart files | copy-paste speed instead of reading prose | S |
| 0 | ~~cross-agent installer + pointer snippet~~ | done (`scripts/install.sh`, `templates/`) | — |
| 2 | `scripts/new_app.sh` — scaffolds the whole core/ + di/ + flavors | zero-to-running in one command | M |
| 3 | `scripts/new_feature.sh <name>` — generates the full feature tree + stubs | feature loop becomes mechanical | M |
| 4 | ~~testing reference~~ | done (`references/testing.md`) | — |
| 5 | ~~CI/CD reference~~ | done (`references/ci-cd.md`) | — |
| 6 | ~~chat/realtime reference~~ | done (`references/chat-realtime.md`) | — |
| 7 | ~~maps/location/health reference~~ | done (`references/maps-location-health.md`) | — |
| 8 | ~~payments reference~~ | covered by presigned upload + `fdev` docs; add gateway detail if needed | S |
| 9 | `evals/` retrieval + pressure tests for the skill | proves compliance, not just presence | M |
| 10 | Keep in sync with `fdev` releases (new commands) | CLI is the owner's daily driver | S |

Priority if continuing: **1 → 2 → 3 → 9** (turns the skill from reference into a generator
with proof it works).
