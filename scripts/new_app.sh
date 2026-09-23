#!/bin/sh
# Create a new Flutter app in the flutter-superpower house style.
#
#   ./scripts/new_app.sh my_app
#   ./scripts/new_app.sh my_app --org com.acme --title "My App" --dir ~/apps/my_app
#
# After it finishes: flutter run  (or flutter run --flavor dev -t lib/main_dev.dart
# once you wire the native flavors — see references/app-bootstrap.md).

set -eu

usage() {
  sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

APP_NAME=""
ORG="com.example"
DIR=""
TITLE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --org) shift; [ $# -gt 0 ] || { echo "error: --org needs a value" >&2; exit 1; }; ORG="$1" ;;
    --dir) shift; [ $# -gt 0 ] || { echo "error: --dir needs a value" >&2; exit 1; }; DIR="$1" ;;
    --title) shift; [ $# -gt 0 ] || { echo "error: --title needs a value" >&2; exit 1; }; TITLE="$1" ;;
    -h|--help) usage ;;
    -*) echo "error: unknown option: $1" >&2; usage ;;
    *) APP_NAME="$1" ;;
  esac
  shift
done

[ -n "$APP_NAME" ] || { usage; exit 1; }

pascal() {
  printf '%s' "$1" | awk -F_ '{ for (i = 1; i <= NF; i++) if ($i != "") printf toupper(substr($i, 1, 1)) substr($i, 2) }'
}

APP_CLASS="$(pascal "$APP_NAME")"
DIR="${DIR:-$APP_NAME}"
TITLE="${TITLE:-$APP_CLASS}"

SRC="$(cd "$(dirname "$0")/.." && pwd)"
TPL="$SRC/templates/app"

command -v flutter >/dev/null 2>&1 || { echo "error: flutter is not on PATH" >&2; exit 1; }
[ -e "$DIR" ] && { echo "error: $DIR already exists" >&2; exit 1; }

echo "Creating Flutter project: $DIR (org $ORG, package $APP_NAME)"
flutter create --org "$ORG" --project-name "$APP_NAME" --platforms ios,android "$DIR" >/dev/null

mkdir -p "$DIR/assets/images"

find "$TPL" -type f | while IFS= read -r file; do
  rel="${file#"$TPL"/}"
  dest="$DIR/$rel"
  mkdir -p "$(dirname "$dest")"
  sed \
    -e "s/__APP_NAME__/$APP_NAME/g" \
    -e "s/__APP_CLASS__/$APP_CLASS/g" \
    -e "s/__APP_TITLE__/$TITLE/g" \
    "$file" > "$dest"
done

printf '\n.env.dev\n.env.prod\n' >> "$DIR/.gitignore"

cd "$DIR"
echo "Fetching packages..."
flutter pub get >/dev/null
echo "Running code generation..."
# --force-jit: Dart 3.10+ refuses to AOT-compile the build script when the package
# graph contains native build hooks (objective_c via shared_preferences_foundation).
if command -v fdev >/dev/null 2>&1; then
  fdev gen -- --force-jit >/dev/null
else
  dart run build_runner build --delete-conflicting-outputs --force-jit >/dev/null
fi
dart format lib test >/dev/null

echo
echo "Done: $DIR"
echo "Next:"
echo "  cd $DIR && flutter run                 # runs lib/main.dart (dev config)"
echo "  $SRC/scripts/new_feature.sh orders --app $DIR"
echo "  Wire native flavors before shipping: references/app-bootstrap.md"
