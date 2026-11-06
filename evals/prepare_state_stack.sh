#!/bin/sh
# Prepare isolated, minimal inputs for case 43; acceptance checks are run separately.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEST=${1:?usage: evals/prepare_state_stack.sh NEW_DIRECTORY}
[ ! -e "$DEST" ] || { echo 'error: destination exists' >&2; exit 1; }
mkdir -p "$DEST"
for stack in riverpod provider getx; do
  APP="$DEST/$stack"
  mkdir -p "$APP/lib/features/orders/domain" "$APP/test"
  cp "$ROOT/evals/fixtures/state-stack/orders_repository.dart" "$APP/lib/features/orders/domain/orders_repository.dart"
  cp "$ROOT/evals/fixtures/state-stack/TASK.md" "$APP/TASK.md"
  case "$stack" in
    riverpod) PACKAGE='flutter_riverpod: ^3.0.0' ;;
    provider) PACKAGE='provider: ^6.1.5' ;;
    getx) PACKAGE='get: ^4.7.3' ;;
  esac
  cat > "$APP/pubspec.yaml" <<YAML
name: stack_eval
publish_to: none
environment:
  sdk: '>=3.10.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  $PACKAGE
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
YAML
  printf 'include: package:flutter_lints/flutter.yaml\n' > "$APP/analysis_options.yaml"
done
printf 'Prepared case 43 inputs for Riverpod, Provider and GetX\n'
