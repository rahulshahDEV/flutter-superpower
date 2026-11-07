# State-selection and migration validation — 2026-11-07

These are independent agent executions, followed by parent-held checks and source review.
The exact model identifier was not exposed; agents inherited the session model without
an override. `summary.json` records counts and outcomes. No production account was used.

## Case 43: complete supplied state-selection matrix

| Input | Own tests | Parent checks | Final outcome |
|---|---:|---:|---|
| Existing Riverpod | 7 | 8 | PASS |
| Existing Provider | 7 | 8 | PASS |
| Existing GetX | 7 | 8 | PASS |
| Existing Cubit | 7 | 8 | PASS |
| Existing event Bloc | 7 | 8 | PASS |
| Greenfield Riverpod requested | 8 | 8 | PASS |
| Greenfield Provider requested | 8 | 8 | PASS |
| Greenfield GetX requested | 8 | 8 | PASS |
| Greenfield no preference | 8 | 8 | Initial standards FAIL; corrected PASS |

All nine final variants passed formatting, analyzer and the tests (139 tests total).
Parent review checked selected packages/owners, absolute imports, unchanged domain and
counter precedent, ownership, DI and generated-source policy. Existing styles are preserved;
the blank default selects Cubit/GetIt/Injectable. There is no common custom state manager.

The default implementation initially skipped Injectable in favor of manual GetIt factories,
contrary to the skill default. Its initial source/report are preserved separately. After
review, the agent used real Injectable factory-parameter registration and code generation.
UI and the original eight agent tests were retained. The default was not an initial pass.
State-selection now explicitly distinguishes actual composition from package declarations.

The first parent simultaneous-route harness placed full-screen routes directly inside an
unbounded Column. That imposed an unstated layout requirement and failed their Expanded
content. Corrected the harness to bound both routes before scoring; the other eight apps
needed no implementation correction. This harness failure is not an app regression.

Parent checks cover retry, refresh retention, reversed completion, same-key account and
repository changes, route teardown/reopen and simultaneous routes. They establish widget
lifetime behavior, not native router registration, real push/pop, OS process death or backend
transport cancellation. Different package majors, data adapters and production bootstrap
are not covered. Case 43 now has all of its supplied state-choice variants exercised, not
proof of every possible Flutter app integration.

## Case 47: matched real SQLite schema migration

Baseline and with-skill agents received identical schema-1 adapters and tasks. Their task
histories were independent; the baseline was instructed not to read skill/reference files.
Neither lane received parent acceptance checks before implementation.

| Lane | Own tests | Parent checks | Total | Outcome |
|---|---:|---:|---:|---|
| Baseline without skill | 10 | 9 | 19 | PASS |
| With skill | 13 | 9 | 22 | PASS |

Both analyzers were clean. The parent tests create actual on-disk schema-1/schema-2 files,
open them through the adapter, preserve values through reopen, inject upgrade failures,
compare complete schema/data/version snapshots, verify index columns/defaults, preserve
future/corrupt file bytes, and execute the stated previous-v2 SQL against schema 3.
Review strengthened the held-out checks to protect timestamps and schema definitions on
rollback and verify the actual index target rather than just its name. Both lanes passed
these stronger checks without implementation repair. Both lanes pass, so this comparison
does not demonstrate a causal skill advantage.

The host used Flutter 3.38.9 / Dart 3.10.8 and sqlite3 2.9.4 with the host SQLite library.
No mobile SQLite build, old executable, power-loss/process-kill durability, low-disk or
cross-process contention test was run. Synchronous injected rollback is not process death.

## Reproduce

1. Run `evals/prepare_state_stack.sh <new-dir> --matrix`. Apply each `case43-<variant>.patch`
   using `git apply <patch>` from that app. Copy
   `evals/fixtures/state-stack/acceptance_test.dart` into its `test/`.
2. Run `evals/prepare_migrations.sh <new-dir>`. Apply each `case47-<lane>.patch` from that
   app. Copy `evals/fixtures/migrations/acceptance_test.dart` into its `test/`.
3. Copy the matching `case43-<variant>.lock` or `case47-<lane>.lock` to that app's
   `pubspec.lock`, then run `flutter pub get --enforce-lockfile` to retain tested package
   versions/checksums. Lockfile SHA-256 values are recorded in `summary.json`. With the
   recorded Flutter/Dart SDK, run `dart format .`, applicable codegen, `flutter analyze`, then
   `flutter test --reporter expanded`. Only the final no-preference default needs codegen:
   `fdev gen` (fallback: `dart run build_runner build --delete-conflicting-outputs`).
4. Generated outputs are omitted from source patches; recreate them. The initial default
   patch represents the observed deviation, not the final supported implementation.

Archived lockfiles preserve the tested resolution; a replay with a different SDK is a
compatibility run, not an exact reproduction.

Every final patch was replayed against fresh input trees and compared with tested source.
The default's generation/analyzer/tests and the with-skill migration suite were additionally
run from clean replayed inputs. Logs replace app/skill paths with placeholders and trim
trailing whitespace. Reports are agent evidence; parent logs and source review supply the
independent check. Raw legacy formatting and code in inputs represent existing-project
precedent, not new universal house defaults.
