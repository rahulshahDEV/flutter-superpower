#!/bin/sh
# Matched case-45 and independent case-46 inputs; parent checks are withheld.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEST=${1:?usage: evals/prepare_reliability.sh NEW_DIRECTORY}
[ ! -e "$DEST" ] || { echo 'error: destination exists' >&2; exit 1; }
for lane in baseline with_skill; do
  APP="$DEST/concurrency/$lane"
  mkdir -p "$APP/lib" "$APP/test"
  cp "$ROOT/evals/fixtures/bloc-concurrency/pubspec.yaml" "$APP/pubspec.yaml"
  cp "$ROOT/evals/fixtures/bloc-concurrency/TASK.md" "$APP/TASK.md"
  cp "$ROOT/evals/fixtures/bloc-concurrency/search_bloc.dart" "$APP/lib/search_bloc.dart"
  printf 'include: package:flutter_lints/flutter.yaml\n' > "$APP/analysis_options.yaml"
done
APP="$DEST/offline"
mkdir -p "$APP/lib" "$APP/test"
cp "$ROOT/evals/fixtures/offline-writes/pubspec.yaml" "$APP/pubspec.yaml"
cp "$ROOT/evals/fixtures/offline-writes/TASK.md" "$APP/TASK.md"
cp "$ROOT/evals/fixtures/offline-writes/note_sync.dart" "$APP/lib/note_sync.dart"
printf 'include: package:flutter_lints/flutter.yaml\n' > "$APP/analysis_options.yaml"
printf 'Prepared reliability inputs\n'
