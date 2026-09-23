#!/bin/sh
# Generate a full house-style feature inside an existing Flutter app.
#
#   ./scripts/new_feature.sh orders                 # app = current directory
#   ./scripts/new_feature.sh orders --app ~/apps/my_app
#   ./scripts/new_feature.sh news --entity article  # override singular
#
# Creates data/domain/presentation layers, runs codegen, and prints the GoRoute
# snippet to paste into the router. Refuses to overwrite an existing feature.

set -eu

usage() {
  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

FEATURE=""
APP_DIR=""
ENTITY=""

while [ $# -gt 0 ]; do
  case "$1" in
    --app) shift; [ $# -gt 0 ] || { echo "error: --app needs a value" >&2; exit 1; }; APP_DIR="$1" ;;
    --entity) shift; [ $# -gt 0 ] || { echo "error: --entity needs a value" >&2; exit 1; }; ENTITY="$1" ;;
    -h|--help) usage ;;
    -*) echo "error: unknown option: $1" >&2; usage ;;
    *) FEATURE="$1" ;;
  esac
  shift
done

[ -n "$FEATURE" ] || { usage; exit 1; }
APP_DIR="${APP_DIR:-$(pwd)}"
[ -f "$APP_DIR/pubspec.yaml" ] || {
  echo "error: no pubspec.yaml in $APP_DIR (pass --app /path/to/app)" >&2
  exit 1
}

pascal() {
  printf '%s' "$1" | awk -F_ '{ for (i = 1; i <= NF; i++) if ($i != "") printf toupper(substr($i, 1, 1)) substr($i, 2) }'
}

APP_NAME="$(awk '/^name:/{ print $2; exit }' "$APP_DIR/pubspec.yaml")"
FEATURE_CLASS="$(pascal "$FEATURE")"
ENTITY="${ENTITY:-$(printf '%s' "$FEATURE" | sed 's/s$//')}"
[ -n "$ENTITY" ] || ENTITY="$FEATURE"
ENTITY_CLASS="$(pascal "$ENTITY")"

DEST="$APP_DIR/lib/features/$FEATURE"
[ -e "$DEST" ] && { echo "error: $DEST already exists" >&2; exit 1; }

SRC="$(cd "$(dirname "$0")/.." && pwd)"
TPL="$SRC/templates/feature"

find "$TPL" -type f | while IFS= read -r file; do
  rel="${file#"$TPL"/}"
  out="$(printf '%s' "$rel" | sed -e "s/__FEATURE__/$FEATURE/g" -e "s/__ENTITY__/$ENTITY/g")"
  dest="$DEST/$out"
  mkdir -p "$(dirname "$dest")"
  sed \
    -e "s/__APP_NAME__/$APP_NAME/g" \
    -e "s/__FEATURE_CLASS__/$FEATURE_CLASS/g" \
    -e "s/__FEATURE__/$FEATURE/g" \
    -e "s/__ENTITY_CLASS__/$ENTITY_CLASS/g" \
    -e "s/__ENTITY__/$ENTITY/g" \
    "$file" > "$dest"
done

API="$APP_DIR/lib/core/constants/api_constants.dart"
if [ -f "$API" ] && grep -q "static const String $FEATURE =" "$API"; then
  : # endpoint already declared
elif [ -f "$API" ] && grep -q "__FEATURE_ENDPOINTS__" "$API"; then
  awk -v line="  static const String $FEATURE = '/$FEATURE';" \
    '{ if ($0 ~ /__FEATURE_ENDPOINTS__/) print line; print }' "$API" > "$API.tmp"
  mv "$API.tmp" "$API"
else
  echo "note: add the '$FEATURE' endpoint to ApiConstants manually"
fi

cd "$APP_DIR"
echo "Running code generation..."
# --force-jit: Dart 3.10+ refuses to AOT-compile the build script when the package
# graph contains native build hooks (objective_c via shared_preferences_foundation).
if command -v fdev >/dev/null 2>&1; then
  fdev gen -- --force-jit >/dev/null
else
  dart run build_runner build --delete-conflicting-outputs --force-jit >/dev/null
fi
dart format lib >/dev/null

echo
echo "Created feature '$FEATURE' in $DEST"
echo "Add to lib/core/router/app_router.dart:"
echo
cat <<EOF
      GoRoute(
        path: ${FEATURE_CLASS}Screen.path,
        name: ${FEATURE_CLASS}Screen.routeName,
        builder: (context, state) => const ${FEATURE_CLASS}Screen(),
      ),
EOF
