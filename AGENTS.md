# AGENTS.md — editing this skill

This repo **is** the `flutter-superpower` skill. `SKILL.md` is the entry point agents load;
`references/` is loaded on demand.

## Rules for changes

- Keep `SKILL.md` scannable: laws, workflow, red flags, evidence gate, quick reference,
  reference index. Deep detail goes to `references/`, never into SKILL.md.
- One topic per reference file. If a file grows past ~200 lines, split it.
- Every new reference must be linked in SKILL.md (workflow or reference table) and in README.
- No client/project names, local absolute paths, tokens, or secrets anywhere in this repo.
- Examples must be self-contained (no dangling class names) and match the house style the
  skill teaches. If an example introduces a type, show its shape somewhere in the same file.
- Contradiction check before committing: state names (sealed vs freezed), DI annotations,
  verify command order, route-argument rules must agree across SKILL.md + references.
- Prefer `fdev` commands in docs; always give the raw fallback.
- `templates/**` and `scripts/**` are part of the skill: keep them in sync with the
  references (state shape, annotations, verify order) and re-run the smoke test after
  editing — `scripts/new_app.sh demo_app --dir <tmp>` then `flutter analyze` must be clean,
  and `scripts/new_feature.sh orders --app <tmp>` must also analyze clean and pass
  `flutter test`.

## Verify before commit

```bash
# 1. Private deny-list check: run the client/project-name list kept OUTSIDE this repo
#    against all markdown — must return nothing.
# 2. Every reference must be linked from SKILL.md:
grep -rn "references/" SKILL.md | wc -l
```

Then read the diff for contradictions, commit with a changelog entry, push.

## Release

1. Bump `metadata.version` in SKILL.md and add a `CHANGELOG.md` section (both must match).
2. Commit and push.
3. Tag and release:
   ```bash
   git tag -a vX.Y.Z -m "vX.Y.Z"
   git push origin main --tags
   gh release create vX.Y.Z --title "vX.Y.Z" \
     --notes-file <(sed -n '/^## X.Y.Z/,/^## /p' CHANGELOG.md | sed '$d')
   ```
4. Never move or delete a published tag; cut a new patch version instead.

## Install (for agents testing the skill)

```bash
ln -sfn "$PWD" ~/.claude/skills/flutter-superpower
ln -sfn "$PWD" ~/.agents/skills/flutter-superpower
```
