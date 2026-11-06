#!/bin/sh
# Failed feature preflight must leave incompatible app trees byte-for-byte unchanged.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d "${TMPDIR:-/tmp}/fsp-preflight.XXXXXX")
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
APP="$WORK/app"
mkdir -p "$APP/lib/core/constants" "$WORK/bin"
printf 'sentinel endpoint\n' > "$APP/lib/core/constants/api_constants.dart"
for tool in dart flutter fdev; do
  cat > "$WORK/bin/$tool" <<'SH'
#!/bin/sh
printf 'unexpected codegen/tool invocation\n' >&2
exit 99
SH
  chmod +x "$WORK/bin/$tool"
done
snapshot() {
  (cd "$APP" && find . -type f -exec cksum {} \; | LC_ALL=C sort)
  (cd "$APP" && find . -type d | LC_ALL=C sort)
}
reject_unchanged() {
  snapshot > "$WORK/before"
  if PATH="$WORK/bin:$PATH" sh "$ROOT/scripts/new_feature.sh" "$@" --app "$APP" > "$WORK/log" 2>&1; then
    echo 'incompatible feature generation accepted' >&2; exit 1
  fi
  grep -q 'No files changed' "$WORK/log"
  if grep -q 'unexpected codegen/tool' "$WORK/log"; then cat "$WORK/log"; exit 1; fi
  snapshot > "$WORK/after"
  cmp "$WORK/before" "$WORK/after"
}
for stack in flutter_riverpod hooks_riverpod provider get; do
  printf 'name: app\ndependencies:\n  flutter:\n    sdk: flutter\n  %s: any\n' "$stack" > "$APP/pubspec.yaml"
  reject_unchanged orders
  grep -q 'alternative or mixed stack' "$WORK/log"
done
# Quoted YAML keys/merge aliases must not hide an alternative stack from preflight.
for declaration in '"provider": ^6.1.5' "'get': ^4.7.3" '<<: *shared'; do
  cp "$ROOT/templates/app/pubspec.yaml" "$APP/pubspec.yaml"
  # Insert a direct dependency declaration while preserving all house packages.
  awk -v declaration="$declaration" '{ print; if ($0 == "dependencies:") print "  " declaration }' \
    "$APP/pubspec.yaml" > "$WORK/pubspec"
  cp "$WORK/pubspec" "$APP/pubspec.yaml"
  reject_unchanged orders
  grep -q 'unsupported dependency declaration' "$WORK/log"
done
# A flow/quoted dependency section must not hide packages behind a valid second section.
for header in 'dependencies: {provider: ^6.1.5}' '"dependencies": {provider: ^6.1.5}'; do
  awk -v header="$header" '
    $0 == "dependencies:" { print header; print "dev_dependencies:"; next }
    $0 == "dev_dependencies:" { next }
    { print }
  ' "$ROOT/templates/app/pubspec.yaml" > "$APP/pubspec.yaml"
  reject_unchanged orders
  grep -q 'unsupported dependency declaration' "$WORK/log"
done
# A bare Flutter app, incomplete house core, invalid names and traversal all fail early.
printf 'name: app\ndependencies:\n  flutter:\n    sdk: flutter\n' > "$APP/pubspec.yaml"
reject_unchanged orders
grep -q 'missing house dependency' "$WORK/log"
cp "$ROOT/templates/app/pubspec.yaml" "$APP/pubspec.yaml"
reject_unchanged orders
grep -q 'missing house contract' "$WORK/log"
reject_unchanged class
reject_unchanged orders --entity switch
reject_unchanged '../escaped'
reject_unchanged orders --entity '../escaped'
test ! -e "$WORK/escaped"
echo 'GENERATOR PREFLIGHT PASS: incompatible stacks, dependencies, contracts, identifiers; no mutation'
