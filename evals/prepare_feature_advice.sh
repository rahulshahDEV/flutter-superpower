#!/bin/sh
# Read-only advice-mode inputs; callers may resolve share package before taking snapshots.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEST=${1:?usage: evals/prepare_feature_advice.sh NEW_DIRECTORY}
[ ! -e "$DEST" ] || { echo 'error: destination exists' >&2; exit 1; }
for scenario in share interop; do
  APP="$DEST/$scenario"
  mkdir -p "$APP/lib/features/reports/domain" "$APP/native/include"
  cat > "$APP/pubspec.yaml" <<'YAML'
name: advice_eval
publish_to: none
environment:
  sdk: '>=3.10.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^3.0.0
YAML
  cat > "$APP/ENVIRONMENT.md" <<'MD'
Existing app: Flutter 3.38.9 / Dart 3.10.8, feature-first Riverpod. Targets Android, iOS;
sharing must also work in web. Android min SDK 24, iOS deployment target 13.0.
Retain existing state/DI/router conventions. No native SDK sources/binaries are installed
in this minimal fixture; recommendation/source evidence cannot prove native integration.
MD
done
printf '  share_plus: 12.0.1\n' >> "$DEST/share/pubspec.yaml"
cp "$ROOT/evals/fixtures/feature-advice/SHARE_TASK.md" "$DEST/share/TASK.md"
cp "$ROOT/evals/fixtures/feature-advice/INTEROP_TASK.md" "$DEST/interop/TASK.md"
cat > "$DEST/share/lib/features/reports/domain/report_share.dart" <<'DART'
import 'dart:typed_data';

abstract interface class ReportShare {
  Future<void> sharePdf(Uint8List bytes, String fileName, String message);
}
DART
cat > "$DEST/interop/native/include/dsp.h" <<'C'
#include <stddef.h>
typedef struct DspContext DspContext;
DspContext* dsp_create(int sample_rate);
int dsp_process(DspContext* context, const float* input, size_t length, float* output);
void dsp_destroy(DspContext* context);
C
cat > "$DEST/interop/native/VENDOR_CONTRACT.md" <<'MD'
The Android SDK is distributed as AAR/JAR Java/Kotlin classes; the Apple SDK is Swift.
Both expose configuration and event callbacks. Whether Swift APIs have Objective-C-visible
headers is unconfirmed. DSP ships a C header and native binaries; supported ABIs, release
symbols, licensing and distribution must be checked before implementation. No web build
or browser API is currently supplied. These are task constraints, not verified SDK binaries.
MD
printf 'Prepared package and native-interop advice inputs\n'
