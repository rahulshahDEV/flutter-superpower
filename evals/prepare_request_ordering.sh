#!/bin/sh
# Matched case-04 inputs. Requires Flutter and Python 3; no agent is run by this script.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEST=${1:?usage: evals/prepare_request_ordering.sh NEW_DIRECTORY}
[ ! -e "$DEST" ] || { echo 'error: destination exists' >&2; exit 1; }
mkdir -p "$DEST"
sh "$ROOT/scripts/new_app.sh" eval_app --dir "$DEST/base" --title 'Eval App'
sh "$ROOT/evals/setup.sh" 04 "$DEST/base"
for lane in baseline with_skill; do
  mkdir -p "$DEST/$lane"
  for entry in pubspec.yaml pubspec.lock analysis_options.yaml lib test assets .env.dev .env.prod; do
    [ ! -e "$DEST/base/$entry" ] || cp -R "$DEST/base/$entry" "$DEST/$lane/"
  done
  cp "$ROOT/evals/fixtures/request-ordering/TASK.md" "$DEST/$lane/TASK.md"
  cp "$DEST/$lane/lib/features/orders/presentation/cubit/orders/orders_cubit.dart" \
    "$DEST/$lane/ORIGINAL_CUBIT.dart.txt"
done
printf 'Matched case 04 inputs prepared; withhold acceptance checks during agent runs.\n'
