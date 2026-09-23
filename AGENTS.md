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

## Verify before commit

```bash
# 1. Private deny-list check: run the client/project-name list kept OUTSIDE this repo
#    against all markdown — must return nothing.
# 2. Every reference must be linked from SKILL.md:
grep -rn "references/" SKILL.md | wc -l
```

Then read the diff for contradictions, commit with a changelog entry, push.

## Install (for agents testing the skill)

```bash
ln -sfn "$PWD" ~/.claude/skills/flutter-superpower
ln -sfn "$PWD" ~/.agents/skills/flutter-superpower
```
