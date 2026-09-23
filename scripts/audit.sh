#!/bin/sh
# Read-only audit of a Flutter project against the flutter-superpower architecture.
#
#   scripts/audit.sh /path/to/app             # static checks + format + flutter analyze
#   scripts/audit.sh /path/to/app --tests     # also runs flutter test
#   scripts/audit.sh /path/to/app --static    # no toolchain: greps + file sizes only
#
# Prints a mechanical report. Architecture/state judgment is the agent's review pass
# (references/auditing.md). This script never modifies the project.

set -u

usage() {
  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

APP_DIR=""
RUN_TESTS=0
STATIC_ONLY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --tests) RUN_TESTS=1 ;;
    --static) STATIC_ONLY=1 ;;
    -h|--help) usage ;;
    -*) echo "error: unknown option: $1" >&2; usage ;;
    *) APP_DIR="$1" ;;
  esac
  shift
done

APP_DIR="${APP_DIR:-$(pwd)}"
[ -f "$APP_DIR/pubspec.yaml" ] || { echo "error: no pubspec.yaml in $APP_DIR" >&2; exit 1; }
LIB="$APP_DIR/lib"
[ -d "$LIB" ] || { echo "error: no lib/ in $APP_DIR" >&2; exit 1; }

has_dep() { grep -q "^  $1:" "$APP_DIR/pubspec.yaml"; }
# Generated files are excluded everywhere: they are not maintained by hand.
GEN_EXCLUDES="--exclude=*.g.dart --exclude=*.freezed.dart --exclude=*.config.dart"
count() { grep -rEl --include='*.dart' $GEN_EXCLUDES "$1" "$LIB" 2>/dev/null | wc -l | tr -d ' '; }
count_all() { grep -rE --include='*.dart' $GEN_EXCLUDES "$1" "$LIB" 2>/dev/null | wc -l | tr -d ' '; }
examples() { grep -rEl --include='*.dart' $GEN_EXCLUDES "$1" "$LIB" 2>/dev/null | sed "s|$APP_DIR/||" | head -3; }

ok() { printf '  \033[32m✅\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m⚠\033[0m  %s\n' "$1"; }
bad() { printf '  \033[31m❌\033[0m %s\n' "$1"; }
section() { printf '\n%s\n' "$1"; }

STATE="unknown"
if has_dep flutter_bloc; then STATE="Bloc/Cubit"
elif has_dep flutter_riverpod || has_dep riverpod; then STATE="Riverpod"
elif has_dep provider; then STATE="Provider"
elif has_dep get; then STATE="GetX"
fi

ROUTER="unknown"
if has_dep go_router; then ROUTER="GoRouter"
elif has_dep auto_route; then ROUTER="AutoRoute"
elif has_dep flutter; then ROUTER="Navigator (or project custom)"
fi

DI="manual"
if has_dep get_it; then DI="get_it"; fi
if has_dep injectable; then DI="get_it + injectable"; fi

NET="unknown"
if has_dep dio; then NET="Dio"
elif has_dep http; then NET="http"
elif has_dep graphql_flutter; then NET="GraphQL"
fi

MODELS="manual JSON"
if has_dep freezed_annotation; then MODELS="Freezed"
elif has_dep json_annotation; then MODELS="json_serializable"; fi

TESTS="flutter_test"
if has_dep mocktail; then TESTS="$TESTS + mocktail"; fi
if has_dep mockito; then TESTS="$TESTS + mockito"; fi

printf 'FLUTTER SUPERPOWER AUDIT — %s\n' "$(basename "$APP_DIR")"
printf 'Profile: state=%s · router=%s · di=%s · net=%s · models=%s · tests=%s\n' \
  "$STATE" "$ROUTER" "$DI" "$NET" "$MODELS" "$TESTS"

section "Architecture"
if [ -d "$LIB/core" ]; then
  CORE_LEAK_FILES="$(grep -rEl --include='*.dart' $GEN_EXCLUDES "package:[a-z_]+/features/" "$LIB/core" 2>/dev/null | grep -v '/core/router/' || true)"
  if [ -z "$CORE_LEAK_FILES" ]; then
    ok "core/ does not import features/ (router excluded)"
  else
    warn "review: core/ imports features/ in $(printf '%s\n' "$CORE_LEAK_FILES" | wc -l | tr -d ' ') file(s) (router excluded)"
    printf '%s\n' "$CORE_LEAK_FILES" | sed "s|$APP_DIR/||" | head -3 | sed 's/^/     /'
  fi
else
  warn "no lib/core/ directory (project may use a different layout — follow the project)"
fi

BIG="$(find "$LIB" -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' ! -name '*.config.dart' -exec wc -l {} + 2>/dev/null | sort -rn | awk '$2 != "total" && $1 > 500 {print $2 " (" $1 " lines)"}' | sed "s|$APP_DIR/||" | head -5)"
if [ -z "$BIG" ]; then ok "no Dart file over 500 lines"; else warn "large files (check for multiple responsibilities):"; printf '%s\n' "$BIG" | sed 's/^/     /'; fi

section "Code quality"
PRINTS="$(count_all '(^|[^a-zA-Z])print\(|debugPrint\(' || true)"
if [ "$PRINTS" = "0" ]; then ok "no print/debugPrint in lib/"; else bad "$PRINTS print/debugPrint call(s) in lib/"; examples '(^|[^a-zA-Z])print\(|debugPrint\(' | sed 's/^/     /'; fi

IGNORES="$(count_all '// ignore:' || true)"
if [ "$IGNORES" = "0" ]; then ok "no // ignore: suppressions"; else warn "$IGNORES // ignore: suppression(s) — each needs a reason"; fi

TODOS="$(count_all 'TODO|FIXME' || true)"
if [ "$TODOS" = "0" ]; then ok "no TODO/FIXME markers"; else warn "$TODOS TODO/FIXME marker(s)"; fi

DEPRECATED="$(count_all 'withOpacity\(' || true)"
if [ "$DEPRECATED" = "0" ]; then ok "no deprecated withOpacity"; else warn "$DEPRECATED withOpacity call(s) — use withValues(alpha:)"; fi

section "Design system discipline"
COLORS="$(grep -rE --include='*.dart' $GEN_EXCLUDES 'Color\(0x' "$LIB" 2>/dev/null | grep -vE '/(app_colors|colours)\.dart:' | wc -l | tr -d ' ')"
if [ "$COLORS" = "0" ]; then ok "no inline hex colors (palette files excluded)"; else warn "$COLORS inline Color(0x...) — move to AppColors/Colours"; fi

TEXTSTYLES="$(count_all 'TextStyle\(fontSize' || true)"
if [ "$TEXTSTYLES" = "0" ]; then ok "no ad-hoc TextStyle(fontSize:)"; else warn "$TEXTSTYLES ad-hoc TextStyle(fontSize:) — use AppTextStyles"; fi

section "Security"
# firebase_options.dart is generated and its API keys are public by design — excluded.
SECRET_PATTERN="(api[_-]?key|secret|access[_-]?token|password)[\"']?[[:space:]]*[:=][[:space:]]*[\"'][A-Za-z0-9_/+=.-]{16,}[\"']"
SECRETS="$(grep -rEni --include='*.dart' $GEN_EXCLUDES "$SECRET_PATTERN" "$LIB" 2>/dev/null | grep -v 'firebase_options.dart:' | wc -l | tr -d ' ')"
if [ "$SECRETS" = "0" ]; then ok "no hardcoded secrets detected"; else bad "$SECRETS possible hardcoded secret(s)"; fi

HTTP_PATTERN="['\"]http://"
HTTP="$(count_all "$HTTP_PATTERN" || true)"
if [ "$HTTP" = "0" ]; then ok "no plain http:// URLs in lib/"; else warn "$HTTP plain http:// URL(s)"; fi

section "Performance"
LISTS="$(count_all 'ListView\(' || true)"
if [ "$LISTS" = "0" ]; then ok "no unbounded ListView( — builders/slivers used"; else warn "$LISTS ListView( (non-builder) — confirm the list is short or switch to ListView.builder"; fi

section "Testing"
if [ -d "$APP_DIR/test" ]; then
  TEST_FILES="$(find "$APP_DIR/test" -name '*_test.dart' 2>/dev/null | wc -l | tr -d ' ')"
  FEATURES="$(find "$LIB/features" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$FEATURES" -gt 0 ]; then
    printf '  ℹ  %s test file(s) for %s feature(s)\n' "$TEST_FILES" "$FEATURES"
  else
    printf '  ℹ  %s test file(s)\n' "$TEST_FILES"
  fi
else
  warn "no test/ directory"
fi

if [ "$STATIC_ONLY" -eq 0 ]; then
  section "Toolchain"
  if command -v dart >/dev/null 2>&1; then
    if (cd "$APP_DIR" && dart format --output=none --set-exit-if-changed lib test >/dev/null 2>&1); then
      ok "dart format clean"
    else
      warn "dart format would change files — run: dart format ."
    fi
  else
    warn "dart not on PATH — skipped format check"
  fi

  if command -v flutter >/dev/null 2>&1; then
    ANALYZE_OUT="$(cd "$APP_DIR" && flutter analyze 2>&1 | tail -1)"
    case "$ANALYZE_OUT" in
      *"No issues found"*) ok "flutter analyze clean" ;;
      *) bad "flutter analyze: $ANALYZE_OUT" ;;
    esac

    if [ "$RUN_TESTS" -eq 1 ]; then
      TEST_OUT="$(cd "$APP_DIR" && flutter test 2>&1 | tail -1)"
      case "$TEST_OUT" in
        *"All tests passed"*) ok "flutter test green" ;;
        *) bad "flutter test: $TEST_OUT" ;;
      esac
    else
      printf '  ℹ  tests not run (pass --tests)\n'
    fi
  else
    warn "flutter not on PATH — skipped analyze/test"
  fi
fi

printf '\nReport is mechanical. Architecture/state judgment: references/auditing.md.\n'
