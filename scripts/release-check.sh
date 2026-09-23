#!/bin/sh
# Read-only release-readiness check for a Flutter app.
#
#   scripts/release-check.sh /path/to/app
#
# Verifies what a script can verify (files, config, obvious leaks) and explicitly lists
# what it cannot (store submissions, signing validity, device installs). Never modifies
# the project. Full checklist: references/release.md.

set -u

usage() {
  sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

APP_DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage ;;
    -*) echo "error: unknown option: $1" >&2; usage ;;
    *) APP_DIR="$1" ;;
  esac
  shift
done
APP_DIR="${APP_DIR:-$(pwd)}"
[ -f "$APP_DIR/pubspec.yaml" ] || { echo "error: no pubspec.yaml in $APP_DIR" >&2; exit 1; }

ok() { printf '  \033[32m✅\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m⚠\033[0m  %s\n' "$1"; }
bad() { printf '  \033[31m❌\033[0m %s\n' "$1"; }
info() { printf '  ℹ  %s\n' "$1"; }
section() { printf '\n%s\n' "$1"; }

printf 'FLUTTER SUPERPOWER RELEASE CHECK — %s\n' "$(basename "$APP_DIR")"

section "Version & identity"
VERSION="$(awk '/^version:/{ print $2; exit }' "$APP_DIR/pubspec.yaml")"
if [ -n "${VERSION:-}" ]; then ok "pubspec version: $VERSION"; else bad "no version in pubspec.yaml"; fi

section "Entrypoints & environments"
for f in lib/main_dev.dart lib/main_prod.dart; do
  if [ -f "$APP_DIR/$f" ]; then ok "$f"; else bad "missing $f"; fi
done
for f in .env.dev .env.prod .env.sample; do
  if [ -f "$APP_DIR/$f" ]; then ok "$f present"; else warn "missing $f"; fi
done
if [ -f "$APP_DIR/.env.prod" ]; then
  if grep -qiE "dev|stage|staging|localhost|127\.0\.0\.1" "$APP_DIR/.env.prod"; then
    bad ".env.prod looks like a non-production URL — verify BASE_URL"
  else
    ok ".env.prod has no dev/staging markers"
  fi
fi
if [ -f "$APP_DIR/.env.dev" ] && grep -qiE "prod" "$APP_DIR/.env.dev"; then
  warn ".env.dev may point at production — verify"
fi

section "Android"
GRADLE=""
for c in android/app/build.gradle.kts android/app/build.gradle; do
  [ -f "$APP_DIR/$c" ] && GRADLE="$APP_DIR/$c"
done
if [ -n "$GRADLE" ]; then
  ok "gradle config present"
  grep -q "productFlavors\|productFlavors {" "$GRADLE" && ok "productFlavors configured" || warn "no productFlavors found"
  grep -q "minifyEnabled true\|isMinifyEnabled = true" "$GRADLE" && ok "R8/minify enabled" || warn "minifyEnabled not set for release"
  if [ -f "$APP_DIR/android/key.properties" ]; then ok "android/key.properties present"; else warn "android/key.properties missing — release signing may fall back to debug"; fi
else
  bad "no android/app/build.gradle(.kts)"
fi
[ -f "$APP_DIR/android/app/google-services.json" ] && ok "google-services.json present" || info "no google-services.json (skip if Firebase unused)"

section "iOS"
[ -d "$APP_DIR/ios/Runner.xcodeproj" ] && ok "Xcode project present" || warn "ios/Runner.xcodeproj missing"
[ -f "$APP_DIR/ios/Podfile" ] && ok "Podfile present" || warn "ios/Podfile missing"
[ -f "$APP_DIR/ios/Runner/GoogleService-Info.plist" ] && ok "GoogleService-Info.plist present" || info "no GoogleService-Info.plist (skip if Firebase unused)"
[ -f "$APP_DIR/lib/firebase_options.dart" ] && ok "firebase_options.dart present" || info "no firebase_options.dart (skip if Firebase unused)"

section "Logging & debug"
LIB="$APP_DIR/lib"
if [ -d "$LIB" ]; then
  PRINTS="$(grep -rE --include='*.dart' --exclude='*.g.dart' --exclude='*.freezed.dart' --exclude='*.config.dart' '(^|[^a-zA-Z])print\(|debugPrint\(' "$LIB" 2>/dev/null | wc -l | tr -d ' ')"
  [ "$PRINTS" = "0" ] && ok "no print/debugPrint" || bad "$PRINTS print/debugPrint call(s) in lib/"
  grep -rq --include='*.dart' "debugShowCheckedModeBanner" "$LIB" && ok "debug banner explicitly configured" || warn "debugShowCheckedModeBanner not found — confirm banner is off in release"
  if [ -f "$LIB/core/utils/app_logger.dart" ] && grep -q "isDev" "$LIB/core/utils/app_logger.dart"; then
    ok "AppLogger is flavor-gated"
  else
    warn "AppLogger gating not detected — verify logging is silent in release"
  fi
fi

section "Push & deep links"
if grep -qE "firebase_messaging" "$APP_DIR/pubspec.yaml" 2>/dev/null; then
  [ -f "$LIB/core/services/fcm_background_handler.dart" ] || grep -rq "vm:entry-point" "$LIB" 2>/dev/null \
    && ok "FCM background handler present" || warn "firebase_messaging present but no background entrypoint found"
fi
if grep -qE "app_links|uni_links" "$APP_DIR/pubspec.yaml" 2>/dev/null; then
  info "deep-link package present — verify schemes/associated domains manually"
fi

section "Cannot verify here (check manually)"
info "Signing validity (keystore/profile) — fdev sha, Xcode, Play Console"
info "Store metadata, screenshots, privacy declarations"
info "Real device install + smoke test of the store build"
info "Push delivery end-to-end on a physical device"

printf '\nChecklist: references/release.md. Nothing was modified.\n'
