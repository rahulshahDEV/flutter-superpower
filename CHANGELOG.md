# Changelog

## 2.3.0

- README: "Before / after (measured)" section — real timings (scaffold 19.1 s → 46 files,
  feature 9.8 s → 10 files, audit of a 530-file app 0.9 s, verify 8.2 s) with the manual
  baseline clearly labeled as an estimate; reproducible commands included.
- README: removed the roadmap table (all items shipped or automated).

## 2.2.0

- `references/app-optimization.md` — level-wise optimization playbook (Level 0 baseline →
  Level 4 advanced), each technique with cost, gain, and a skip-when condition, plus a
  decision matrix (implement / plan / skip) and a plan template to hand to the user.
- `evals/setup.sh` — reproducible eval setups (base feature + case defect).
- Eval batch 2 run and recorded (`evals/RESULTS.md`): cases 04, 07, 08, 15, 17 all PASS,
  independently re-verified.
- `tests/consistency.sh`: SKILL.md word budget, reference line budget, and `fdev` command
  sync (documented commands must exist in `fdev --help`).
- `dependencies.md`: constraint-only bumps clarified (allowed, reported, no lock change).

## 2.1.0

- Repo hygiene: `CODE_OF_CONDUCT.md` (Contributor Covenant 3.0), `CONTRIBUTING.md`,
  `SECURITY.md`, `.gitattributes`, PR template, bug/feature issue templates.
- Removed GitHub Actions CI — the tests run locally by design; `tests/consistency.sh` and
  `tests/run.sh` must be green before commit/release. Docs updated accordingly.
- Added `evals/RESULTS.md` with recorded behavior-eval runs.

## 2.0.0

Senior Flutter Developer upgrade — behavior, engineering intelligence, tooling, and evals.
Existing architecture, laws, templates, generators, and quality gates unchanged.

**Senior behavior**
- `senior-mode.md`: project profile, greenfield/existing/migration modes, requirement→task,
  layer ownership, change-impact analysis with LOW/MEDIUM/HIGH risk, edge-case engine,
  Step 6 self-review (11 axes), Definition of Done, evidence report, ownership rules.
- SKILL.md: Senior mode section; workflow entries for existing app, audit, migration.

**Engineering intelligence (new references)**
- `performance.md` (evidence-first: rebuilds, lists, images, startup, memory)
- `security.md` (secrets, log redaction, storage, transport, deep links, release hardening)
- `accessibility.md` (semantics, targets, text scaling, contrast, focus, motion)
- `localization.md` (StringConstants vs ARB, plurals, intl, RTL)
- `dependencies.md` (ladder, evaluation, add/remove, house-pinned choices)
- `native.md` (Android/iOS triage, flavors, signing, pods, parity checklist)
- `release.md` (release checklist) + `store-release.md` (Play Console + App Store Connect,
  review rejections, honest limits)
- `auth-social.md` (Google + Apple sign-in end to end: platform setup, token exchange,
  session, failure mapping, common errors)
- `fastlane-codemagic.md` (fastlane lanes + signing + actions; codemagic.yaml workflows,
  secrets, caching, publishing; failure modes)
- `shorebird.md` (OTA code push: patchability rules, releases/patches, tracks, CI tokens,
  store compliance, failure modes)

**Tooling**
- `scripts/audit.sh` gains `--perf` (raw images, MediaQuery.of, shrinkWrap, large assets).
- `scripts/release-check.sh` — read-only release readiness with explicit "cannot verify" list.
- `tests/consistency.sh` — links, version sync, placeholders, script syntax, README index.
- `tests/run.sh` — installer + scaffold + generator + audit regression (Flutter).
- `evals/` — 20 behavior cases + protocol.
- `.github/workflows/ci.yml` — consistency + regression jobs.

**Docs**
- README: senior behavior, "what happens when you ask for a feature", full reference index.
- AGENTS.md: eval/regression rules and the fdev sync procedure.

## 1.5.0

- Senior developer behavior: `references/senior-mode.md` — project profile, three modes
  (greenfield / existing / migration), requirement→task conversion, layer ownership and
  change-impact analysis, Definition of Done, evidence report format, ownership rules,
  blocked-report format. Existing project conventions explicitly outrank the defaults;
  the existing architecture is never replaced.
- Audit capability: `references/auditing.md` + `scripts/audit.sh` (read-only mechanical
  audit: stack profile, layer leaks, file sizes, print/TODO/ignore smells, inline colors,
  secrets, unbounded lists, test coverage signal, format/analyze/test). Verified on a
  generated app (all green) and validated on a large production codebase.
- SKILL.md: Senior mode section, workflow entries (existing app, audit, migration),
  updated description triggers. Pointer snippet reference list updated.

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
