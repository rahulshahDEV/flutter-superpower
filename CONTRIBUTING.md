# Contributing

This repo **is** the `flutter-superpower` skill. Changes are judged by one standard: does an
agent that reads the skill produce better Flutter work in the owner's architecture?

## Before you change anything

Read `AGENTS.md` — it holds the edit rules. In short:

- `SKILL.md` stays scannable; depth goes to `references/` (one topic per file, split past ~200 lines).
- Every new reference must be linked from `SKILL.md` and listed in `README.md`.
- No client/project names, local absolute paths, tokens, or secrets anywhere.
- Examples must be self-contained and match the style the skill teaches.
- Contradiction check: state names, DI annotations, verify order, and route-argument rules must
  agree across `SKILL.md` + references.
- `templates/**` and `scripts/**` are part of the skill — keep them in sync with the references.

## Workflow

1. Fork and branch: `feat/*`, `fix/*`, `docs/*`.
2. Make the change — smallest diff that solves it (see `references/ponytail.md`).
3. Update, in the same change:
   - `CHANGELOG.md` (and `metadata.version` in `SKILL.md` when behavior changes),
   - the affected reference(s),
   - an eval case if expected behavior changed (`evals/`),
   - `README.md` if files were added.
4. Run the tests:
   ```bash
   tests/consistency.sh      # fast: links, version sync, placeholders, script syntax
   tests/run.sh              # Flutter: installer + scaffold + generators + audits
   ```
   Both must pass. If `tests/run.sh` needs a toolchain you don't have, say so in the PR.
5. Open a PR using the template; keep it one logical change.

## What gets rejected

- Architecture changes to the skill's defaults (Cubit/GetIt/GoRouter/Dio/Either) — the skill's
  identity is fixed; propose a migration *reference*, not a rewrite.
- Duplicated instructions across files (single source of truth per topic).
- Version/changelog drift.
- Generated files edited by hand (`injection.config.dart`, `*.g.dart`, `*.freezed.dart`).
- Marketing claims that can't be demonstrated.

## Reporting bugs / proposing features

Use the issue templates. For behavior bugs ("the agent did X instead of Y"), include the exact
task prompt, what the agent did, and which reference it should have followed.

## Code of conduct

Participation is covered by `CODE_OF_CONDUCT.md`.

## License

By contributing you agree your contribution is licensed under the MIT license (see `LICENSE`).
