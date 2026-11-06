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

# Fail before creating files or changing API constants. This generator requires the
# Cubit house scaffold; other stacks follow references/state-selection.md manually.
preflight_error() {
  echo "error: $*" >&2
  echo "No files changed. Use the manual feature workflow in references/state-selection.md." >&2
  exit 1
}
valid_identifier() {
  # Reject Dart keywords/built-in identifiers conservatively for filenames, generated
  # declarations and endpoint members (including the derived singular entity name).
  case "$1" in
    abstract|as|assert|async|await|augment|base|break|case|catch|class|const|continue|covariant|default|deferred|do|dynamic|else|enum|export|extends|extension|external|factory|false|final|finally|for|Function|get|hide|if|implements|import|in|interface|is|late|library|mixin|native|new|null|of|on|operator|part|required|rethrow|return|sealed|set|show|static|super|switch|sync|this|throw|true|try|type|typedef|var|void|when|while|with|yield) return 1 ;;
  esac
  printf '%s\n' "$1" | LC_ALL=C grep -Eq '^[a-z][a-z0-9]*(_[a-z0-9]+)*$'
}
valid_identifier "$FEATURE" || preflight_error "feature must be a lower_snake_case identifier"
if [ -n "$ENTITY" ]; then
  valid_identifier "$ENTITY" || preflight_error "entity must be a lower_snake_case identifier"
fi
# Conservative parser for block-style dependency maps used by the house pubspec.
# Exotic YAML/aliases are rejected safely rather than guessed or rewritten.
has_package() {
  awk -v package="$1" -v expected="${2:-dependencies}" '
    /^[^[:space:]#]/ { section = ($0 ~ ("^" expected ":[[:space:]]*(#.*)?$")) }
    section && $0 ~ "^  " package ":([[:space:]]|$)" { found=1 }
    END { exit !found }
  ' "$APP_DIR/pubspec.yaml"
}
if ! awk '
  /^[^[:space:]#]/ && $0 !~ /^[a-z][a-z0-9_]*:([[:space:]]|$)/ { exit 1 }
  /^(dependencies|dev_dependencies):/ && $0 !~ /^(dependencies|dev_dependencies):[[:space:]]*(#.*)?$/ { exit 1 }
  /^[^[:space:]#]/ { section = ($0 ~ /^(dependencies|dev_dependencies):[[:space:]]*(#.*)?$/) }
  section && /^  [^[:space:]#]/ && $0 !~ /^  [a-z][a-z0-9_]*:([[:space:]]|$)/ { exit 1 }
' "$APP_DIR/pubspec.yaml"; then
  preflight_error "unsupported dependency declaration (plain block-style package keys required)"
fi
for alternate in flutter_riverpod riverpod hooks_riverpod provider get; do
  if has_package "$alternate" || has_package "$alternate" dev_dependencies; then
    preflight_error "alternative or mixed stack ($alternate); Cubit generator is not applicable"
  fi
done
for package in flutter flutter_bloc get_it injectable go_router dartz equatable dio json_annotation \
  flutter_screenutil; do
  has_package "$package" || preflight_error "missing house dependency: $package (block-style pubspec required)"
done
for package in build_runner injectable_generator json_serializable; do
  has_package "$package" dev_dependencies || preflight_error "missing house dev dependency: $package"
done
for required in \
  core/cubit/safe_cubit.dart core/error/api_exception_handler.dart \
  core/error/api_response_handler.dart core/error/either_extensions.dart \
  core/error/exceptions.dart core/error/failures.dart core/usecases/usecase.dart \
  core/constants/api_constants.dart core/constants/error_constants.dart \
  core/constants/string_constants.dart core/network/dio_client.dart \
  core/extensions/size_extensions.dart core/theme/app_colors.dart \
  core/theme/app_text_styles.dart core/widgets/app_snack_bar.dart \
  core/widgets/empty_state_widget.dart core/widgets/error_state_widget.dart \
  core/widgets/loading_widget.dart di/injection.dart; do
  [ -f "$APP_DIR/lib/$required" ] || preflight_error "missing house contract: lib/$required"
done

pascal() {
  printf '%s' "$1" | awk -F_ '{ for (i = 1; i <= NF; i++) if ($i != "") printf toupper(substr($i, 1, 1)) substr($i, 2) }'
}

APP_NAME="$(awk '/^name:/{ print $2; exit }' "$APP_DIR/pubspec.yaml")"
valid_identifier "$APP_NAME" || preflight_error "unsupported pubspec package name"
FEATURE_CLASS="$(pascal "$FEATURE")"
ENTITY="${ENTITY:-$(printf '%s' "$FEATURE" | sed 's/s$//')}"
[ -n "$ENTITY" ] || ENTITY="$FEATURE"
valid_identifier "$ENTITY" || preflight_error "derived entity is a reserved or invalid Dart identifier; pass --entity"
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
