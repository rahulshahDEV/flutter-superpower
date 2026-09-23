#!/bin/sh
# End-to-end regression for the skill: installer, scaffold, generator, audit.
# Requires Flutter on PATH. Takes a few minutes.
#
#   tests/run.sh
#
# Exits non-zero on any failure. Uses a temp workspace; touches nothing real.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${TMPDIR:-/tmp}/flutter-superpower-tests.$$"
FAIL=0

ok() { printf '  \033[32m✅\033[0m %s\n' "$1"; }
bad() { printf '  \033[31m❌\033[0m %s\n' "$1"; FAIL=1; }
section() { printf '\n%s\n' "$1"; }

cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

mkdir -p "$WORK"
printf 'REGRESSION — workspace %s\n' "$WORK"

section "Installer (copy mode, fake HOME)"
FAKE_HOME="$WORK/home"
mkdir -p "$FAKE_HOME"
if HOME="$FAKE_HOME" sh "$ROOT/scripts/install.sh" --all --copy >/dev/null 2>&1; then
  ok "install.sh --all --copy ran"
else
  bad "install.sh failed"
fi
for p in .claude .agents .config/opencode .gemini .copilot .codex .cursor; do
  if [ -f "$FAKE_HOME/$p/skills/flutter-superpower/SKILL.md" ]; then
    ok "installed: $p"
  else
    bad "missing install: $p"
  fi
done

section "Project install (--project)"
PROJ="$WORK/proj"
mkdir -p "$PROJ"
sh "$ROOT/scripts/install.sh" --project "$PROJ" >/dev/null 2>&1
[ -f "$PROJ/.claude/skills/flutter-superpower/SKILL.md" ] && ok "project-level link" || bad "project-level link missing"

section "Scaffold (new_app.sh)"
APP="$WORK/demo_app"
if sh "$ROOT/scripts/new_app.sh" demo_app --dir "$APP" --title "Demo App" >/dev/null 2>&1; then
  ok "new_app.sh completed"
else
  bad "new_app.sh failed"
fi

if [ -d "$APP" ]; then
  (cd "$APP" && dart format --output=none --set-exit-if-changed lib test >/dev/null 2>&1) && ok "format clean" || bad "format not clean"
  (cd "$APP" && flutter analyze >/dev/null 2>&1) && ok "analyze clean" || bad "analyze failed"
  (cd "$APP" && flutter test >/dev/null 2>&1) && ok "tests pass" || bad "tests failed"
  [ -f "$APP/lib/di/injection.config.dart" ] && ok "codegen produced injection.config.dart" || bad "missing injection.config.dart"
  [ -f "$APP/lib/core/cubit/safe_cubit.dart" ] && ok "core skeleton present" || bad "core skeleton missing"

  section "Feature generator (new_feature.sh)"
  sh "$ROOT/scripts/new_feature.sh" orders --app "$APP" >/dev/null 2>&1 && ok "new_feature.sh completed" || bad "new_feature.sh failed"
  for f in \
    lib/features/orders/domain/entities/order.dart \
    lib/features/orders/domain/repositories/orders_repository.dart \
    lib/features/orders/domain/usecases/get_orders.dart \
    lib/features/orders/data/models/order_model.dart \
    lib/features/orders/data/models/order_model.g.dart \
    lib/features/orders/data/datasources/orders_remote_data_source.dart \
    lib/features/orders/data/repositories/orders_repository_impl.dart \
    lib/features/orders/presentation/cubit/orders/orders_state.dart \
    lib/features/orders/presentation/cubit/orders/orders_cubit.dart \
    lib/features/orders/presentation/pages/orders_screen.dart; do
    [ -f "$APP/$f" ] && ok "generated: ${f#lib/features/orders/}" || bad "missing: $f"
  done
  grep -q "static const String orders = '/orders';" "$APP/lib/core/constants/api_constants.dart" && ok "endpoint inserted into ApiConstants" || bad "endpoint not inserted"
  (cd "$APP" && flutter analyze >/dev/null 2>&1) && ok "analyze clean with feature" || bad "analyze failed with feature"
  (cd "$APP" && flutter test >/dev/null 2>&1) && ok "tests pass with feature" || bad "tests failed with feature"

  section "Forbidden patterns in generated code"
  PRINTS="$(grep -rE --include='*.dart' '(^|[^a-zA-Z])print\(' "$APP/lib" | wc -l | tr -d ' ')"
  [ "$PRINTS" = "0" ] && ok "no print()" || bad "$PRINTS print() in generated app"
  TODOS="$(grep -rE --include='*.dart' 'TODO|FIXME' "$APP/lib" | wc -l | tr -d ' ')"
  [ "$TODOS" = "0" ] && ok "no TODO/FIXME" || bad "$TODOS TODO/FIXME in generated app"
  NAV="$(grep -rE --include='*.dart' 'Navigator\.push\(' "$APP/lib" | wc -l | tr -d ' ')"
  [ "$NAV" = "0" ] && ok "no raw Navigator.push" || bad "$NAV raw Navigator.push"

  section "Audit + release-check run"
  sh "$ROOT/scripts/audit.sh" "$APP" --static >/dev/null 2>&1 && ok "audit.sh --static ran" || bad "audit.sh failed"
  sh "$ROOT/scripts/audit.sh" "$APP" --static --perf >/dev/null 2>&1 && ok "audit.sh --perf ran" || bad "audit.sh --perf failed"
  sh "$ROOT/scripts/release-check.sh" "$APP" >/dev/null 2>&1 && ok "release-check.sh ran" || bad "release-check.sh failed"
else
  bad "app directory missing — skipping scaffold checks"
fi

printf '\n'
if [ "$FAIL" -eq 0 ]; then
  printf '\033[32mREGRESSION PASS\033[0m\n'
else
  printf '\033[31mREGRESSION FAIL\033[0m\n'
fi
exit "$FAIL"
