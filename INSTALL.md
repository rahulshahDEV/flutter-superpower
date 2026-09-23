# Install flutter-superpower (agent instructions)

You are an AI coding agent. Follow these steps exactly, then verify. This installs the
`flutter-superpower` skill into every Agent Skills location on this machine.

## 1. Fetch the repo

```bash
git clone --depth 1 https://github.com/rahulshahDEV/flutter-superpower.git "$HOME/.flutter-superpower"
```

If `$HOME/.flutter-superpower/.git` already exists, update instead:

```bash
git -C "$HOME/.flutter-superpower" pull --ff-only
```

## 2. Install into every agent location

```bash
"$HOME/.flutter-superpower/scripts/install.sh" --all
```

This symlinks the skill into `~/.claude/skills`, `~/.agents/skills`,
`~/.config/opencode/skills`, `~/.gemini/skills`, `~/.copilot/skills`, `~/.codex/skills`,
and `~/.cursor/skills` (plus Antigravity paths when present). On systems without symlinks,
use `--copy`.

Windows (PowerShell):

```powershell
iwr -useb https://raw.githubusercontent.com/rahulshahDEV/flutter-superpower/main/scripts/install.ps1 | iex
```

## 3. Project-level install (optional, per Flutter app)

```bash
"$HOME/.flutter-superpower/scripts/install.sh" --project /path/to/flutter/app
```

Adds `.claude/skills`, `.agents/skills`, `.opencode/skills`, and `.cursor/skills` links
inside that project.

## 4. Verify

```bash
test -f "$HOME/.claude/skills/flutter-superpower/SKILL.md" && echo OK
test -f "$HOME/.agents/skills/flutter-superpower/SKILL.md" && echo OK
```

Both must print `OK`. Then tell the user to restart their agent session (skills are
discovered at session start).

## 5. If the agent has no skill support

Append the pointer block from
`$HOME/.flutter-superpower/templates/pointer-snippet.md` to the project's `AGENTS.md` or
`CLAUDE.md`, replacing `<PATH-TO-SKILL>` with `$HOME/.flutter-superpower`. For Cursor,
save it as `.cursor/rules/flutter-superpower.mdc` instead.

## Notes

- Do not modify files inside the clone by hand; update with `git pull`.
- Never print tokens or secrets; this install needs none.
- Full documentation: `$HOME/.flutter-superpower/README.md`.
