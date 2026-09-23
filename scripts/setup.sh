#!/bin/sh
# One-command setup for flutter-superpower on macOS/Linux.
#
#   curl -fsSL https://raw.githubusercontent.com/rahulshahDEV/flutter-superpower/main/scripts/setup.sh | sh
#
# Flags are passed through to install.sh:
#   sh -s -- --all        # create dirs for agents not yet installed
#   sh -s -- --copy       # copy instead of symlink
#   sh -s -- --project /path/to/app
#
# Overrides: FSP_REPO_URL (git remote), FSP_DIR (clone location).

set -eu

REPO_URL="${FSP_REPO_URL:-https://github.com/rahulshahDEV/flutter-superpower.git}"
DEST="${FSP_DIR:-$HOME/.flutter-superpower}"

command -v git >/dev/null 2>&1 || { echo "error: git is required" >&2; exit 1; }

if [ -d "$DEST/.git" ]; then
  echo "Updating $DEST"
  git -C "$DEST" pull --ff-only >/dev/null
else
  echo "Cloning into $DEST"
  git clone --depth 1 "$REPO_URL" "$DEST" >/dev/null
fi

exec "$DEST/scripts/install.sh" "$@"
