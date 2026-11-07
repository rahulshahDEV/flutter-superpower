#!/bin/sh
# Matched schema-evolution inputs; withhold parent acceptance checks from the agents.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEST=${1:?usage: evals/prepare_migrations.sh NEW_DIRECTORY}
[ ! -e "$DEST" ] || { echo 'error: destination exists' >&2; exit 1; }
for lane in baseline with_skill; do
  APP="$DEST/$lane"
  mkdir -p "$APP/lib" "$APP/test"
  cp "$ROOT/evals/fixtures/migrations/pubspec.yaml" "$APP/pubspec.yaml"
  cp "$ROOT/evals/fixtures/migrations/draft_database.dart" "$APP/lib/draft_database.dart"
  cp "$ROOT/evals/fixtures/migrations/TASK.md" "$APP/TASK.md"
  printf 'include: package:flutter_lints/flutter.yaml\n' > "$APP/analysis_options.yaml"
done
printf 'Prepared identical baseline/with-skill migration inputs\n'
