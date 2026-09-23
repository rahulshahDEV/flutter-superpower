#!/bin/sh
# Install flutter-superpower into every known Agent Skills location.
#
#   ./scripts/install.sh                 # install where an agent already exists
#   ./scripts/install.sh --all           # also create dirs for agents not detected
#   ./scripts/install.sh --copy          # copy instead of symlink (Windows / no-symlink setups)
#   ./scripts/install.sh --project PATH  # project-level install for one Flutter app
#
# Re-run any time; it is idempotent. Symlinked installs update with `git pull`.

set -eu

SRC="$(cd "$(dirname "$0")/.." && pwd)"
NAME="flutter-superpower"
MODE="detect"
COPY=0
PROJECT=""

usage() {
  sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --all) MODE="all" ;;
    --copy) COPY=1 ;;
    --project)
      shift
      [ $# -gt 0 ] || { echo "error: --project needs a path" >&2; exit 1; }
      PROJECT="$1"
      ;;
    -h|--help) usage ;;
    *) echo "error: unknown option: $1" >&2; usage ;;
  esac
  shift
done

install_into() {
  parent="$1"
  target="$parent/$NAME"

  # Detect mode: install when the skills dir OR its agent root already exists.
  if [ "$MODE" = "detect" ] && [ ! -d "$parent" ] && [ ! -d "$(dirname "$parent")" ]; then
    return 0
  fi

  mkdir -p "$parent"

  if [ -L "$target" ]; then
    if [ "$(readlink "$target")" = "$SRC" ]; then
      echo "ok       $target"
      return 0
    fi
    rm "$target"
  elif [ -d "$target" ]; then
    echo "SKIP     $target (real directory exists; remove it manually)"
    return 0
  fi

  if [ "$COPY" -eq 1 ]; then
    cp -R "$SRC" "$target"
    echo "copied   $target"
  else
    ln -s "$SRC" "$target"
    echo "linked   $target"
  fi
}

if [ -n "$PROJECT" ]; then
  [ -d "$PROJECT" ] || { echo "error: project path not found: $PROJECT" >&2; exit 1; }
  MODE="all" # project mode always creates the target dirs
  echo "Installing project-level skill into: $PROJECT"
  install_into "$PROJECT/.claude/skills"    # Claude Code, opencode
  install_into "$PROJECT/.agents/skills"    # opencode, Codex, Copilot CLI, Gemini CLI
  install_into "$PROJECT/.opencode/skills"  # opencode native
  install_into "$PROJECT/.cursor/skills"    # Cursor
  echo "Done. Commit the symlinks or add the skill dir to .gitignore — your choice."
  exit 0
fi

echo "Source: $SRC"
echo "Targets (mode: $MODE):"

# Always: the two universal cross-runtime locations.
install_into "$HOME/.claude/skills"      # Claude Code, opencode
install_into "$HOME/.agents/skills"      # opencode, Codex, Copilot CLI, Gemini CLI

# Agent-specific global locations (installed when detected, or with --all).
install_into "$HOME/.config/opencode/skills"          # opencode
install_into "$HOME/.gemini/skills"                   # Gemini CLI
install_into "$HOME/.copilot/skills"                  # GitHub Copilot CLI
install_into "$HOME/.codex/skills"                    # Codex
install_into "$HOME/.cursor/skills"                   # Cursor
install_into "$HOME/.gemini/antigravity/skills"       # Antigravity
install_into "$HOME/.antigravity/antigravity/skills"  # Antigravity (alt layout)

echo "Done. Restart or start a new agent session to pick up the skill."
