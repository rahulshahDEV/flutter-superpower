#!/bin/sh
# Prepare an eval app: base orders feature + the case's defect (reproducible setups).
#
#   scripts/new_app.sh eval_app --dir /tmp/eval04 --title "Eval App"
#   evals/setup.sh 04 /tmp/eval04
#
# Cases without a defect (07, 15) just get the base feature.

set -eu

CASE="${1:-}"
APP="${2:-}"
[ -n "$CASE" ] && [ -n "$APP" ] || { echo "usage: evals/setup.sh <case> <app-dir>" >&2; exit 1; }
[ -d "$APP" ] || { echo "error: app dir not found: $APP" >&2; exit 1; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

sh "$ROOT/scripts/new_feature.sh" orders --app "$APP" >/dev/null

CU="$APP/lib/features/orders/presentation/cubit/orders/orders_cubit.dart"
SC="$APP/lib/features/orders/presentation/pages/orders_screen.dart"

python3 - "$CASE" "$CU" "$SC" <<'PY'
import sys

case, cubit_path, screen_path = sys.argv[1], sys.argv[2], sys.argv[3]

if case == "04":  # stale-response bug: request-id guard removed
    src = open(cubit_path).read()
    src = src.replace("  int _latestRequestId = 0;\n\n", "")
    src = src.replace("    final requestId = ++_latestRequestId;\n", "")
    src = src.replace("    if (isClosed || requestId != _latestRequestId) return;\n", "")
    open(cubit_path, "w").write(src)

elif case == "08":  # failure swallowed: spinner forever on API failure
    src = open(cubit_path).read()
    src = src.replace(
        "(failure) => safeEmit(OrdersFailure(failure)),",
        "(failure) => safeEmit(const OrdersLoading()),",
    )
    open(cubit_path, "w").write(src)

elif case == "17":  # perf smells: shrinkWrap list + raw Image.network in the row
    src = open(screen_path).read()
    src = src.replace(
        "OrdersSuccess(:final items) => ListView.separated(\n",
        "OrdersSuccess(:final items) => ListView.separated(\n                shrinkWrap: true,\n",
    )
    # indentation-agnostic: dart format normalizes the inserted block
    src = src.replace(
        "child: Text(item.name, style: AppTextStyles.body),",
        "child: Row(children: [\n"
        "                        Image.network('https://picsum.photos/80', width: 80, height: 80),\n"
        "                        SizedBox(width: AppSizes.sm),\n"
        "                        Expanded(child: Text(item.name, style: AppTextStyles.body)),\n"
        "                      ]),",
    )
    open(screen_path, "w").write(src)
PY

if command -v fdev >/dev/null 2>&1; then
  (cd "$APP" && fdev gen -- --force-jit >/dev/null)
else
  (cd "$APP" && dart run build_runner build --delete-conflicting-outputs --force-jit >/dev/null)
fi
(cd "$APP" && dart format lib >/dev/null)

echo "prepared case $CASE in $APP"
