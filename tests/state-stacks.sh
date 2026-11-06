#!/bin/sh
# Verify the isolated runnable state-stack examples (requires Flutter/network or cache).
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/flutter-state-stacks.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
for entry in pubspec.yaml analysis_options.yaml README.md lib test; do
  cp -R "$ROOT/tests/stack_examples/$entry" "$WORK/"
done
cd "$WORK"
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --reporter expanded
