#!/bin/sh
# Prepare isolated, minimal inputs for case 43; acceptance checks are run separately.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEST=${1:?usage: evals/prepare_state_stack.sh NEW_DIRECTORY [--matrix]}
MODE=${2:-}
case "$MODE" in ''|--matrix) ;; *) echo 'error: unknown mode' >&2; exit 1 ;; esac
STACKS='riverpod provider getx'
[ "$MODE" != --matrix ] || STACKS='riverpod provider getx cubit bloc new_riverpod new_provider new_getx new_default'
[ ! -e "$DEST" ] || { echo 'error: destination exists' >&2; exit 1; }
mkdir -p "$DEST"
for stack in $STACKS; do
  APP="$DEST/$stack"
  mkdir -p "$APP/lib/features/orders/domain" "$APP/test"
  cp "$ROOT/evals/fixtures/state-stack/orders_repository.dart" "$APP/lib/features/orders/domain/orders_repository.dart"
  cp "$ROOT/evals/fixtures/state-stack/TASK.md" "$APP/TASK.md"
  case "$stack" in
    riverpod) PACKAGE='flutter_riverpod: ^3.0.0' ;;
    provider) PACKAGE='provider: ^6.1.5' ;;
    getx) PACKAGE='get: ^4.7.3' ;;
    cubit|bloc) PACKAGE='flutter_bloc: ^9.1.1' ;;
    new_*) PACKAGE='' ;;
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
  case "$stack" in
    cubit|bloc)
      mkdir -p "$APP/lib/precedent"
      cp "$ROOT/evals/fixtures/state-stack/precedent_$stack.dart" "$APP/lib/precedent/counter.dart"
      printf '\nExisting project precedent: retain the %s style in lib/precedent/counter.dart.\n' "$stack" >> "$APP/TASK.md"
      ;;
    new_riverpod) printf '\nThis is a new app. Use Riverpod as explicitly requested.\n' >> "$APP/TASK.md" ;;
    new_provider) printf '\nThis is a new app. Use Provider as explicitly requested.\n' >> "$APP/TASK.md" ;;
    new_getx) printf '\nThis is a new app. Use GetX as explicitly requested.\n' >> "$APP/TASK.md" ;;
    new_default) printf '\nThis is a new app with no state-stack preference. Select the skill default.\n' >> "$APP/TASK.md" ;;
  esac
done
printf 'Prepared case 43 inputs: %s\n' "$STACKS"
