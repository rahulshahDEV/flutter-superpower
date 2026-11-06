# Current-version hardening evidence — 2026-11-06

Skill under test: working v2.12.0. These runs use independent agents with inherited task
history disabled. The case-04 baseline was explicitly denied skill/reference access; the
with-skill lane received the skill and identical raw app/task inputs. Case-43 agent received
only the three minimal app inputs plus skill/references, not the framework regression suite
or parent-held acceptance tests. No device, backend or production account was used.

| Run | Agent checks | Parent verification | Verdict and limits |
|---|---|---|---|
| Case 04 baseline | Meaningful red then 6 regression tests; 24 total | Analyzer clean, 28 total including 4 parent checks; parent checks fail on original | PASS |
| Case 04 with skill | Meaningful red then 14 regression tests; 32 total | Analyzer clean, 36 total including 4 parent checks; parent checks fail on original | PASS; baseline also passes, no demonstrated advantage |
| Case 43 existing Riverpod | Analyzer clean, 8 widget tests | Analyzer clean, 16 tests including 8 parent checks | Behavior PASS for this supplied variant |
| Case 43 existing Provider | Analyzer clean, 8 widget tests | Analyzer clean, 16 tests including 8 parent checks | Behavior PASS for this supplied variant |
| Case 43 existing GetX | Analyzer clean, 8 widget tests | Analyzer clean, 16 tests including 8 parent checks | Behavior PASS for this supplied variant |

Full case 43 remains PARTIAL: greenfield/default-selection variants and existing Bloc/Cubit
variants were not independently run here. The framework fixture regression is separate.
The three independent implementations use relative imports despite the shared architecture
style; their behavior pass is not a full standards pass. State-selection guidance now
explicitly routes agents to shared import/naming rules. Preserve that initial result rather
than silently rewriting the evaluation artifacts to look compliant.

The first parent state-stack harness used an unsupported named pumpAndSettle argument.
Corrected the harness before scoring behavioral results; that compilation error is not
counted as an app regression. No implementation repair was needed for the parent checks.

## Reproduce and inspect

- Case 04: `evals/prepare_request_ordering.sh <new-dir>`, then apply the lane's patch with
  `git apply <patch>` from its app directory. Copy
  `evals/fixtures/request-ordering/acceptance_test.dart` into that app's `test/`.
- Case 43: `evals/prepare_state_stack.sh <new-dir>`, apply the stack patch in its app, then
  copy `evals/fixtures/state-stack/acceptance_test.dart` into its `test/`.
- Run `flutter pub get`, `dart format .`, `flutter analyze`, `flutter test --reporter expanded`.
  Case 04 requires generated files from preparation; codegen is not changed by the patches.
- Logs replace app-directory paths with `<APP>`; patches retain relative source paths and
  include agent-authored regression tests. Parent checks live in the shared fixture folders.

These are recorded executions, not a statistical benchmark. Reports are agent evidence;
parent logs and source/test inspection supply independent verification. Other historical
cases are not claimed current-version passes.
