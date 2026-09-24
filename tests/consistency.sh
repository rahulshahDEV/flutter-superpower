#!/bin/sh
# Fast consistency checks for the skill repo itself (no Flutter toolchain needed).
#
#   tests/consistency.sh
#
# Exits non-zero on any failure.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAIL=0

ok() { printf '  \033[32m✅\033[0m %s\n' "$1"; }
bad() { printf '  \033[31m❌\033[0m %s\n' "$1"; FAIL=1; }

printf 'CONSISTENCY — %s\n' "$ROOT"

# 1. Shell syntax for every script
for s in "$ROOT"/scripts/*.sh "$ROOT"/tests/*.sh; do
  [ -f "$s" ] || continue
  if sh -n "$s" 2>/dev/null; then ok "syntax: ${s#"$ROOT"/}"; else bad "syntax: ${s#"$ROOT"/}"; fi
done

# 2. Every reference is linked from SKILL.md
for f in "$ROOT"/references/*.md; do
  [ -f "$f" ] || continue
  rel="references/$(basename "$f")"
  if grep -q "$rel" "$ROOT/SKILL.md"; then ok "linked: $rel"; else bad "not linked from SKILL.md: $rel"; fi
done

# 3. Every reference is listed in README
for f in "$ROOT"/references/*.md; do
  [ -f "$f" ] || continue
  rel="$(basename "$f")"
  if grep -q "$rel" "$ROOT/README.md"; then :; else bad "not listed in README: references/$rel"; fi
done
ok "README reference index checked"

# 4. Version consistency: SKILL metadata == latest CHANGELOG heading
SKILL_V="$(grep -A1 '^metadata:' "$ROOT/SKILL.md" | grep 'version:' | sed 's/.*"\(.*\)".*/\1/')"
CHANGELOG_V="$(grep -m1 '^## ' "$ROOT/CHANGELOG.md" | sed 's/^## //')"
if [ -n "$SKILL_V" ] && [ "$SKILL_V" = "$CHANGELOG_V" ]; then
  ok "version in sync: $SKILL_V"
else
  bad "version mismatch: SKILL.md=$SKILL_V CHANGELOG.md=$CHANGELOG_V"
fi

# 5. No local absolute paths or machine-specific references in docs
if grep -rnE "/Volumes/|/Users/[a-z]" "$ROOT"/*.md "$ROOT"/references/*.md 2>/dev/null | grep -v "example\|<PATH" >/dev/null; then
  bad "machine-specific path found in docs"
else
  ok "no machine-specific paths in docs"
fi

# 6. Templates keep their placeholders (no accidental substitution)
for t in "__APP_NAME__" "__APP_TITLE__" "__FEATURE_CLASS__" "__ENTITY_CLASS__"; do
  if grep -rq "$t" "$ROOT/templates"; then ok "template placeholder present: $t"; else bad "template placeholder missing: $t"; fi
done

# 7. Scripts are executable
for s in "$ROOT"/scripts/*.sh; do
  [ -x "$s" ] && ok "executable: ${s#"$ROOT"/}" || bad "not executable: ${s#"$ROOT"/}"
done

# 8. Size budgets: SKILL.md stays scannable, references stay single-topic
SKILL_WORDS="$(wc -w < "$ROOT/SKILL.md" | tr -d ' ')"
if [ "$SKILL_WORDS" -le 1900 ]; then
  ok "SKILL.md budget: $SKILL_WORDS words (max 1900)"
else
  bad "SKILL.md over budget: $SKILL_WORDS words (max 1900) — push detail to references"
fi

OVER=""
for f in "$ROOT"/references/*.md; do
  LINES="$(wc -l < "$f" | tr -d ' ')"
  [ "$LINES" -gt 240 ] && OVER="$OVER $(basename "$f")($LINES)"
done
if [ -z "$OVER" ]; then ok "reference size budget: all under 240 lines"; else bad "references over 240 lines:$OVER"; fi

# 9. fdev command sync (when the CLI is installed)
if command -v fdev >/dev/null 2>&1; then
  HELP="$(fdev --help 2>/dev/null || true)"
  MISSING=""
  for cmd in $(grep -oE '`fdev [a-z][a-z-]*' "$ROOT/references/fdev.md" | sed 's/`fdev //' | sort -u); do
    case "$HELP" in *"$cmd"*) : ;; *) MISSING="$MISSING $cmd" ;; esac
  done
  if [ -z "$MISSING" ]; then ok "fdev commands documented exist in --help"; else bad "fdev commands not in --help:$MISSING"; fi
else
  ok "fdev not installed — command sync skipped"
fi

printf '\n'
if [ "$FAIL" -eq 0 ]; then
  printf '\033[32mCONSISTENCY PASS\033[0m\n'
else
  printf '\033[31mCONSISTENCY FAIL\033[0m\n'
fi
exit "$FAIL"
