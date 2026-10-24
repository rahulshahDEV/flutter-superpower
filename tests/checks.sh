#!/bin/sh
# Contract tests for audit/release exit codes and source-preserving tool checks.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/fsp-checks.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
APP="$WORK/app"
mkdir -p "$APP/lib/core/utils" "$APP/lib/features/orders" "$APP/test" "$APP/android/app" "$WORK/bin"
cat > "$APP/pubspec.yaml" <<'YAML'
name: app2
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
YAML
for entry in main_dev main_prod; do printf 'void main() {}\n' > "$APP/lib/$entry.dart"; done
printf 'final isDev = true;\n' > "$APP/lib/core/utils/app_logger.dart"
printf 'BASE_URL=https://api.example.com\n' > "$APP/.env.prod"
printf 'android { productFlavors {} }\n' > "$APP/android/app/build.gradle"
printf '#!/bin/sh\nexit 0\n' > "$WORK/bin/dart"
cat > "$WORK/bin/flutter" <<'SH'
#!/bin/sh
[ "${2:-}" = --no-pub ] || exit 90
if [ "$1" = analyze ]; then
  printf 'No issues found!\n'
  exit "${ANALYZE_EXIT:-0}"
fi
if [ "$1" = test ]; then
  printf 'All tests passed!\n'
  exit "${TEST_EXIT:-0}"
fi
exit 91
SH
chmod +x "$WORK/bin/dart" "$WORK/bin/flutter"
expect_fail() {
  if "$@" > "$WORK/output" 2>&1; then
    echo "expected nonzero exit: $*" >&2
    cat "$WORK/output" >&2
    exit 1
  fi
}
sh "$ROOT/scripts/audit.sh" "$APP" --static > "$WORK/output"
sh "$ROOT/scripts/release-check.sh" "$APP" > "$WORK/output"
printf 'void badLog() { print("diagnostic"); }\n' > "$APP/lib/bad.dart"
expect_fail sh "$ROOT/scripts/audit.sh" "$APP" --static
expect_fail sh "$ROOT/scripts/release-check.sh" "$APP"
rm "$APP/lib/bad.dart"
printf 'import "../../features/orders/item.dart";\n' > "$APP/lib/core/utils/leak.dart"
sh "$ROOT/scripts/audit.sh" "$APP" --static > "$WORK/output"
grep -q 'review: core/ imports features/' "$WORK/output"
printf 'import "package:app2/features/orders/item.dart";\n' > "$APP/lib/core/utils/leak.dart"
sh "$ROOT/scripts/audit.sh" "$APP" --static > "$WORK/output"
grep -q 'review: core/ imports features/' "$WORK/output"
rm "$APP/lib/core/utils/leak.dart"
expect_fail env PATH="$WORK/bin:$PATH" ANALYZE_EXIT=7 sh "$ROOT/scripts/audit.sh" "$APP"
expect_fail env PATH="$WORK/bin:$PATH" TEST_EXIT=9 sh "$ROOT/scripts/audit.sh" "$APP" --tests
env PATH="$WORK/bin:$PATH" sh "$ROOT/scripts/audit.sh" "$APP" --tests > "$WORK/output"
# Output language changes must not override successful command status.
printf '#!/bin/sh\n[ "${2:-}" = --no-pub ] || exit 90\nprintf "validation completed\\n"\nexit 0\n' > "$WORK/bin/flutter"
env PATH="$WORK/bin:$PATH" sh "$ROOT/scripts/audit.sh" "$APP" --tests > "$WORK/output"
rm "$APP/lib/main_prod.dart"
expect_fail sh "$ROOT/scripts/release-check.sh" "$APP"
expect_fail sh "$ROOT/scripts/audit.sh" "$APP" --unknown
expect_fail sh "$ROOT/scripts/release-check.sh" "$APP" --unknown
sh "$ROOT/evals/prepare_permission.sh" "$WORK/eval-inputs" > "$WORK/output"
cmp "$WORK/eval-inputs/baseline/TASK.md" "$WORK/eval-inputs/with_skill/TASK.md"
cmp "$WORK/eval-inputs/baseline/lib/location_gateway.dart" "$WORK/eval-inputs/with_skill/lib/location_gateway.dart"
expect_fail sh "$ROOT/evals/prepare_permission.sh" "$WORK/eval-inputs"
printf 'CHECK SCRIPT CONTRACTS PASS\n'
