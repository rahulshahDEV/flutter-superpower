#!/bin/sh
# Prepare identical isolated inputs for case 38; implementations are authored by agents.
set -eu
[ "$#" -eq 1 ] || { echo "usage: evals/prepare_permission.sh <new-work-dir>" >&2; exit 1; }
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$1"
[ ! -e "$WORK" ] || { echo "error: destination already exists" >&2; exit 1; }
for lane in baseline with_skill; do
  mkdir -p "$WORK/$lane/lib"
  cp "$ROOT/evals/fixtures/location_gateway.dart" "$WORK/$lane/lib/location_gateway.dart"
  cp "$ROOT/evals/fixtures/permission-coordinator-task.md" "$WORK/$lane/TASK.md"
  cat > "$WORK/$lane/pubspec.yaml" <<'YAML'
name: permission_eval
publish_to: none
environment:
  sdk: ^3.9.0
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
YAML
  printf 'include: package:flutter_lints/flutter.yaml\n' > "$WORK/$lane/analysis_options.yaml"
done
printf 'Prepared baseline/with_skill inputs. Resolve dependencies, run separate agents, then apply evaluator checks.\n'
