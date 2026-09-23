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

printf '\n'
if [ "$FAIL" -eq 0 ]; then
  printf '\033[32mCONSISTENCY PASS\033[0m\n'
else
  printf '\033[31mCONSISTENCY FAIL\033[0m\n'
fi
exit "$FAIL"
