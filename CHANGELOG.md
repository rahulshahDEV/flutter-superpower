# Changelog

## 1.4.0

- Easy setup for any agent: `INSTALL.md` (agent-executable instructions),
  `scripts/setup.sh` (macOS/Linux `curl | sh`), `scripts/install.ps1` (Windows PowerShell).
- Remote setup clones to `~/.flutter-superpower` and installs into all agent locations;
  re-running updates the clone. Verified end-to-end in a clean home directory.
- README: easy-setup section (agent prompt, one-liners, manual, project-level).

## 1.3.0

- `templates/app/` — full skeleton (core, di, theme, router, widgets, splash/home) copied by
  `scripts/new_app.sh`; verified `flutter analyze` clean + tests pass.
- `templates/feature/` — data/domain/presentation feature scaffold with sealed states;
  `scripts/new_feature.sh` generates it, runs codegen, inserts the endpoint constant, and
  prints the GoRoute snippet; verified analyze clean + tests pass.
- Documented the Dart 3.10+ `--force-jit` codegen workaround (native build hooks in the
  package graph) across SKILL.md, playbooks, app-bootstrap, and fdev references.
- Fixed generator edge cases: injectable annotation name collisions (`show lazySingleton`),
  wildcard lint, duplicate endpoint insertion.

## 1.2.0

- Cross-agent compatibility: `scripts/install.sh` (Claude Code, opencode, Codex, Gemini CLI,
  Copilot CLI, Cursor, Antigravity; `--all`, `--copy`, `--project` modes).
- `templates/pointer-snippet.md` for agents without native skill support
  (AGENTS.md / CLAUDE.md / Cursor rule).
- SKILL.md frontmatter now declares `license` + portable `metadata.version`;
  body verified agent-neutral.

## 1.1.0

- Added `references/debugging.md`, `references/testing.md`, `references/ci-cd.md`,
  `references/chat-realtime.md`, `references/maps-location-health.md`,
  `references/reviewing.md` (two-axis diff review).
- SKILL.md: "When NOT to use", REQUIRED markers in the workflow, Red flags section,
  Rationalizations table, Evidence-before-done gate, `license: MIT`.
- Added `AGENTS.md` and this changelog.
- Removed all client/project names and local paths from the skill (public repo hygiene).

## 1.0.0

- Initial skill: 12 laws, workflow, quick reference, common mistakes.
- References: architecture, state-and-di, routing, networking-and-errors,
  models-and-storage, theme-and-design-system, app-bootstrap, playbooks, ponytail, fdev.
- QA pass: fixed state-naming contradictions, unified route-argument patterns,
  clarified provider wrapper location, DI annotation rules, verify command order.
