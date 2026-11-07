# Suggestion mode and reliability evidence — 2026-11-07

Skill under test: working v2.13.0. Independent agent tasks used inherited session models;
exact model IDs were not exposed. Raw inputs and parent-held checks are in `evals/fixtures/`.
This batch records implementation checks separately from advice quality and native proof.

## Suggestion mode

| Case | Request | Observed recommendation | Scope check |
|---|---|---|---|
| 52 | Existing app needs PDF/message sharing | Reuse installed share_plus; platform/browser fallback, setup and upgrade path | Entire app input tree unchanged |
| 53 | Vendor host SDK plus C DSP; future browser | Typed Pigeon channel boundary for host configuration/events; FFIgen/Dart FFI for C DSP, separate future web adapter | Entire app input tree unchanged |

Both responses inspected project constraints, preserved Riverpod, compared credible paths,
linked current primary sources, distinguished installed/published/compatible candidates,
and proposed an implementation slice plus proportionate migration/exit plan. They did not
install, edit, generate or build in the input apps. Responses were saved outside the apps.
`summary.json` records before-run input hashes; the parent recomputed the same complete trees
after both runs. Package source/platform claims were reviewed against the cited upstream docs.

The native recommendation distinguishes Pigeon as a schema generator from its backends,
recognizes preview/newer-SDK limits, and avoids treating native FFI as browser support.
Its DSP plan names ABI, memory, buffers, thread/callback ownership, binary distribution and
verification requirements. These are recommendations, not tested vendor SDK integration.
Live package metadata may change: reruns should research current sources rather than expect
the same latest-version number. Dated responses preserve what was actually recommended.

## Case 45: Bloc ordering and save delivery

| Lane | Own tests | Parent checks | Observed result |
|---|---:|---:|---|
| Baseline without skill | 11 | 8 | 17 passing, 2 raw-exception-message safety failures |
| With skill | 8 | 8 | 16 passing |

Both implementations fixed the task's core cross-event ordering, FIFO, deduplication,
retry and disposal behavior. The baseline also rendered raw read/write exception strings
into feedback; the parent safety checks detected those strings. Error redaction was not an
explicit standalone Must in case 45, so do not mislabel the core baseline concurrency fix
as failed or claim a general causal advantage. This run demonstrates an observed safety
quality difference under broader application standards, with the exact failures retained.
The baseline source is preserved without repairing away the initial observation.

Checks use actual Bloc with controlled futures and external-call/effect counters. No sleeps
are used to hide races; queue turns let scheduled stream work drain. Save deduplication is
within Bloc lifetime; backend idempotency and durable operation identity remain separate.
Own regressions recorded meaningful red before fixes; parent checks were withheld until
implementations finished. Analyze passes in both lanes; the baseline test command is
intentionally nonzero because of the two safety assertions.

## Case 46: offline coordinator recovery

The with-skill implementation passes 13 own tests plus 10 parent-held checks (23 total),
with a clean analyzer. Checks cover atomic local/queue commits, offline reconstruction,
lost acknowledgements with stable IDs/one simulated server effect, conflicts/newer input,
account switches while an older sync remains pending, overlapping sync, acknowledgement
commit failure and completion after close. The parent tests do not prescribe whether a
sync commit failure is surfaced or retained as feedback: they verify pending state/replay.

MemoryStore is a transactional fake retained across coordinator reconstruction; the server
is a versioned idempotency fake. This establishes coordinator policy, not disk durability,
real server deduplication, multi-process leases, scheduling or OS process-death behavior.
Application composition supplies one active coordinator per account as stated in the task.

## Reproduce

- Run `evals/prepare_reliability.sh <new-dir>`, apply `case45-<lane>.patch` in the corresponding
  concurrency app and `case46-offline.patch` in its offline app using `git apply <patch>`.
- Copy the matching `.lock` to each app's `pubspec.lock`; run
  `flutter pub get --enforce-lockfile`, then copy that fixture's acceptance test into `test/`.
- Run `dart format .`, `flutter analyze`, `flutter test --reporter expanded`. No codegen.
  Baseline case 45 should reproduce its two safety failures; with-skill checks should pass.
- Advice: run `evals/prepare_feature_advice.sh <new-dir>`. Restore `case52-input.lock` to the
  share app before resolving its existing dependencies. Capture hashes, give an independent
  agent only TASK.md/app inputs plus skill/references, save advice outside the app, and
  compare hashes/research the source claims. Do not give it this parent scoring document.

Archived patches include agent-authored tests and omit parent checks, which live in fixtures.
Paths in reports/logs use placeholders. Dependency locks/checksums preserve the tested graph;
use the recorded Flutter 3.38.9 / Dart 3.10.8 for exact replay. Source review also corrected
ambiguous “final entities” wording to “entities with final fields,” retaining the taught model
inheritance option. Parent harness lint/contract corrections were not scored as app bugs.
