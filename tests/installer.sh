#!/bin/sh
# Installer regression: isolated source fixture and fake HOME; no real installations.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
WORK=$(mktemp -d "${TMPDIR:-/tmp}/flutter-superpower-installer.XXXXXX")
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
SRC="$WORK/source"
mkdir -p "$SRC/scripts" "$SRC/references" "$SRC/templates/app/.dart_tool" \
  "$SRC/templates/app/build" "$SRC/assets" "$SRC/.git" "$SRC/flutter-app-factory"
cp "$ROOT/scripts/install.sh" "$SRC/scripts/install.sh"
printf 'fixture skill\n' > "$SRC/SKILL.md"
printf 'fixture license\n' > "$SRC/LICENSE"
printf 'fixture reference\n' > "$SRC/references/storage.md"
printf 'template\n' > "$SRC/templates/app/pubspec.yaml"
printf 'template env\n' > "$SRC/templates/app/.env.dev"
printf 'executable\n' > "$SRC/scripts/tool.sh"
chmod +x "$SRC/scripts/tool.sh"
printf '\000\001\377\200binary\000' > "$SRC/assets/test.bin"
for artifact in .git/config flutter-app-factory/private.txt local-secret.txt \
  templates/app/.dart_tool/cache templates/app/build/output \
  templates/app/pubspec.lock templates/app/.flutter-plugins-dependencies \
  templates/app/.DS_Store templates/app/model.g.dart templates/app/key.properties; do
  printf 'must not ship\n' > "$SRC/$artifact"
done
FAKE_HOME="$WORK/home"
mkdir -p "$FAKE_HOME"
mkdir -p "$SRC/tests/fixtures"
printf 'fixture\n' > "$SRC/tests/fixtures/example.txt"
HOME="$FAKE_HOME" sh "$SRC/scripts/install.sh" --all --copy > "$WORK/install.log"
TARGET="$FAKE_HOME/.agents/skills/flutter-superpower"
for payload in SKILL.md LICENSE references/storage.md templates/app/pubspec.yaml \
  templates/app/.env.dev scripts/install.sh scripts/tool.sh tests/fixtures/example.txt assets/test.bin; do
  test -f "$TARGET/$payload" || { echo "missing payload: $payload" >&2; exit 1; }
done
test -x "$TARGET/scripts/tool.sh"
cmp "$SRC/assets/test.bin" "$TARGET/assets/test.bin"
for artifact in .git flutter-app-factory local-secret.txt templates/app/.dart_tool \
  templates/app/build templates/app/pubspec.lock templates/app/.flutter-plugins-dependencies \
  templates/app/.DS_Store templates/app/model.g.dart templates/app/key.properties; do
  test ! -e "$TARGET/$artifact" || { echo "unexpected artifact: $artifact" >&2; exit 1; }
done
# Existing directory contents must survive both copy and symlink reinstallation.
printf 'keep\n' > "$TARGET/local.txt"
printf 'new source\n' > "$SRC/SKILL.md"
HOME="$FAKE_HOME" sh "$SRC/scripts/install.sh" --all --copy > "$WORK/reinstall.log"
printf 'fixture skill\n' > "$WORK/expected"
cmp "$WORK/expected" "$TARGET/SKILL.md"
test -f "$TARGET/local.txt"
HOME="$FAKE_HOME" sh "$SRC/scripts/install.sh" --all > "$WORK/relink.log"
test ! -L "$TARGET"
test -f "$TARGET/local.txt"
# Existing regular files are also preserved.
FILE_TARGET="$FAKE_HOME/.claude/skills/flutter-superpower"
rm -rf "$FILE_TARGET"
printf 'keep file\n' > "$FILE_TARGET"
HOME="$FAKE_HOME" sh "$SRC/scripts/install.sh" --all --copy > "$WORK/file.log"
printf 'keep file\n' > "$WORK/expected-file"
cmp "$WORK/expected-file" "$FILE_TARGET"
# A fresh symlink install remains supported and is idempotent.
LINK_PROJECT="$WORK/link-project"
mkdir -p "$LINK_PROJECT"
sh "$SRC/scripts/install.sh" --project "$LINK_PROJECT" > "$WORK/project.log"
test -L "$LINK_PROJECT/.agents/skills/flutter-superpower"
sh "$SRC/scripts/install.sh" --project "$LINK_PROJECT" > "$WORK/project-again.log"
# Recursive targets fail before any install directory is created.
mkdir -p "$SRC/project"
if sh "$SRC/scripts/install.sh" --copy --project "$SRC/project" > "$WORK/recursive.log" 2>&1; then
  echo 'recursive destination accepted' >&2; exit 1
fi
test ! -e "$SRC/project/.claude"
# The same guard resolves symlink parents outside the source tree.
ln -s "$SRC/project" "$WORK/project-alias"
if sh "$SRC/scripts/install.sh" --copy --project "$WORK/project-alias" > "$WORK/alias.log" 2>&1; then
  echo 'symlink recursive destination accepted' >&2; exit 1
fi
test ! -e "$SRC/project/.claude"
# Exercise a missing ancestor below a symlink, as used by global installs.
ln -s "$SRC/project" "$WORK/home-alias"
if HOME="$WORK/home-alias" sh "$SRC/scripts/install.sh" --all --copy > "$WORK/home-alias.log" 2>&1; then
  echo 'symlink HOME recursive destination accepted' >&2; exit 1
fi
test ! -e "$SRC/project/.claude"
# Invoking the source itself through a symlink must use the same physical boundary.
ln -s "$SRC" "$WORK/source-alias"
if sh "$WORK/source-alias/scripts/install.sh" --copy --project "$SRC/project" > "$WORK/source-alias.log" 2>&1; then
  echo 'symlink source recursive destination accepted' >&2; exit 1
fi
test ! -e "$SRC/project/.claude"
echo 'INSTALLER PASS: payload, exclusions, binary/modes, existing paths, symlinks, containment'
