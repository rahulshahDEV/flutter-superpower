# Eval Results

Protocol: `README.md`. Cases: `cases.md`. Verdicts were checked independently of the agent's
own report (analyze/test re-run, Must/Must-not inspected in the diff).

## Coverage

| Status | Cases |
|---|---|
| ✅ Recorded PASS with skill (mixed skill versions; independently verified) | 01, 04, 07, 08, 15, 17, 18, 38 (8/42) |
| ⬜ Not run | 02, 03, 05, 06, 09, 10, 11, 12, 13, 14, 16, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 39, 40, 41, 42 (34/42) |
| 🔬 Baseline (no skill) run | 38 — PASS; with skill also PASS, no demonstrated advantage |

Case 38 adds the first matched baseline. Both lanes passed, so the recorded results still
do not establish a causal skill advantage. Expand comparisons on harder, less prescriptive
tasks; retain passing baselines rather than selecting only favorable results.

## 2026-10-26 — v2.10.0 upstream-adoption validation

Compared pinned source snapshots of mattpocock/skills, google/artemis and Ponytail;
IMPROVEMENT_PLAN.md records the files inspected, adoption decisions and rejected assumptions.
Added cases 39–42 for outcome planning, independent test expectations, safe shared-operation
simplification and Android automation lifecycle/verdicts. All four remain **NOT RUN** as
independent agent evaluations; no baseline comparison was performed for this batch.

Implementation validation on the local macOS Flutter toolchain:

- `tests/consistency.sh`: PASS, including all new reference links/README entries, version
  2.10.0 sync, shell syntax and the entrypoint budget (1,892 words, limit 1,900).
- `tests/run.sh`: PASS, including failure/installer contracts, copy/project installs, fresh
  app codegen/format/analyze/tests, orders generation/analyze/tests and audit/release checks.
- Skill-creator `quick_validate.py`: PASS (`Skill is valid!`).
- `git diff --check`: PASS. Read the full changed guidance and new references for ownership,
  project precedence, sealed/freezed naming, DI, route arguments and verification order.

One redirected consistency invocation failed its fdev command-name check after receiving
empty help text. A direct `fdev --help` returned the documented commands and a direct
consistency rerun passed. No CLI or gate changes were made to hide that failure.

This pass changes guidance and eval definitions, not templates/scripts or app dependencies.
It does not establish live ARTEMIS readiness, device interaction, native permission behavior,
iOS support or a measured behavioral advantage. No ARTEMIS installer or device task ran.

## 2026-09-24 — skill v2.2.0 (batch 2)

Environment: macOS · Flutter 3.38.9 · Dart 3.10.8 · fdev 0.1.6
Setups: `evals/setup.sh <case> <app>` (reproducible defects; base app from `new_app.sh`).
All verdicts re-verified independently (`flutter analyze` + `flutter test` re-run, Must/Must-not
inspected in the diff).

| Case | Verdict | Notes |
|---|---|---|
| 04 — cubit stale-response bug | **PASS** | root cause in cubit; race test fails without the guard |
| 07 — pagination | **PASS** | state fields + duplicate-load guard + footer + mid-failure preserves items |
| 08 — API failure handling | **PASS** | one-line fold fix; error state + retry covered by tests |
| 15 — shared repository change | **PASS** | impact analysis listed 8 dependents; all updated; tests added |
| 17 — performance | **PASS** | `shrinkWrap` removed, decode sized, `const` tile; behavior unchanged |

### Case 04 — stale-response bug

Setup removed the request-id guard from `OrdersCubit`. Agent restored the canonical guard
(both success and failure paths), added two race tests, and proved them by temporarily
reverting the fix (tests fail exactly as reported, then pass). Independently verified:
analyze clean; 5 tests pass; `_latestRequestId` present in the cubit.

### Case 07 — pagination

Agent added `page`/`hasReachedMax`/`isLoadingMore`/`loadMoreFailure` + `canLoadMore`, a
`loadMore()` with duplicate-load guard, near-end prefetch, footer loader + retry, and
failure-mid-pagination that preserves loaded items. Independently verified: analyze clean;
10 tests pass; `loadMore`/`canLoadMore` present in cubit + state.

### Case 08 — failure handling

Setup replaced the failure emit with a re-emit of `OrdersLoading` (spinner forever). Agent
found the one-line root cause, added cubit + widget tests (error state, retry recovers).
Independently verified: analyze clean; 5 tests pass; fold now emits `OrdersFailure`.

### Case 15 — shared repository change

Agent swept every dependent (`RepositoryImpl`, `GetOrders`, `OrdersCubit`, `OrdersSuccess`,
screen, data source, DI, tests), changed the contract to a paginated entity, updated all
callers, and reported the affected list. Independently verified: analyze clean; 6 tests pass;
repository signature returns the paginated type.

### Case 17 — performance

Setup injected `shrinkWrap: true` + a raw `Image.network` in the row. Agent removed the
shrink-wrap viewport, sized the image decode (`cacheWidth`/`cacheHeight`), extracted a `const`
row widget, moved the URL/title into constants, and deliberately skipped `itemExtent`
(text wrapping) and `RepaintBoundary` (no raster evidence). Independently verified: analyze
clean; tests pass; 0 `shrinkWrap`, 2 decode-size references, `_OrderTile` present.

**Honest limits:** no device/profiler timeline available (headless) — the perf verdict rests
on framework layout semantics plus widget-level behavior, not captured frame timings. The
first run of case 17 had a setup bug (the image defect was not injected); `evals/setup.sh`
was fixed and the case re-run — the result above is from the corrected setup.

**Follow-ups:** cases 05, 06, 09, 10, 11, 12, 13, 14, 16, 19, 20 remain unrun; run 05/11/19
next (routing, architecture violation, localization).

## 2026-09-24 — skill v2.1.0

Environment: macOS · Flutter 3.38.9 · Dart 3.10.8 · fdev 0.1.6
Agent under test: opencode subagent (session model), skill read from `SKILL.md` + references.
Base app: `scripts/new_app.sh eval_app` (analyze/test clean before each case).

| Case | Verdict | Notes |
|---|---|---|
| 01 — New feature end to end | **PASS** | 12/12 tests, analyze clean |
| 18 — Reject unnecessary dependency | **PASS** | package nonexistent + already covered by `intl`; pubspec unchanged |

### Case 01 — order history feature

**Must:** all present. `features/orders/{data,domain,presentation}`; `Order`/`OrderStatus`
entities (enum with `apiValue` + `fromApiValue`); `OrderModel` extends entity with
`@JsonSerializable`; data source throws typed exceptions; repo uses `safeApiCall`; sealed
`Initial/Loading/Success/Failure`; stale-request guard; `OrdersScreen` with
`static path/routeName`; route registered in `AppRouter`; endpoint in `ApiConstants`;
empty/error/retry/success widget tests; cubit success/failure tests.

**Must-not:** none found — no `Dio`/`DioClient` in presentation (0 hits), no inline
`Color(0x…)`/`TextStyle(fontSize:)` in the feature (0 hits), no new package.

**Independently verified:** `flutter analyze` → No issues; `flutter test` → 12 passed.

**Observations for the skill:**
- The agent hit the Dart 3.10 build-hook error and used the documented
  `fdev gen -- --force-jit` fallback — the reference worked as written.
- It bumped `json_annotation` `^4.11.0 → ^4.12.0` in pubspec (no lock change) to clear a
  constraint warning. Reasonable, but `dependencies.md` does not explicitly cover
  constraint-only bumps; consider one line there.
- Added a navigation helper + a Home entry button (additive) so the route is reachable —
  matches "own the obvious work".
- Used locale-aware `NumberFormat.simpleCurrency()` rather than a hardcoded currency.

### Case 18 — unnecessary dependency

**Must:** no package added — `date_format_plus` does not exist on pub.dev and `intl` is
already a direct dependency; a `DateTimeExtensions.formatOrderDate` built on
`DateFormat.yMMMd` was added instead; one test for the formatting path.

**Must-not:** `date_format_plus` absent from `pubspec.yaml` and `pubspec.lock` (0 hits);
no second date library.

**Independently verified:** `flutter analyze` → No issues; `flutter test` → 2 passed;
`pubspec.yaml` unchanged.

**Observations for the skill:**
- The agent rejected the package on two independent grounds and explained both — the
  dependency ladder in `dependencies.md` was followed.
- It added a formatter with no call site (no orders feature existed). Acceptable given the
  task, but the report correctly flagged it under Notes.

### Follow-ups (from this run)

- [ ] Add one line to `dependencies.md`: constraint-only bumps (no lock change) are allowed
      to resolve analyzer/pub warnings; still report them.
- [ ] Re-run cases 04, 07, 08, 17 (bug fix, pagination, failure handling, performance) on the
      next pass — the highest-value behavior cases not yet exercised.

## 2026-10-24 — v2.9.0 implementation validation

Cases 27–34 added for startup/platform, font/UI delivery, package selection, boundary
integrity, CI/CD, OTA, native diagnostics, and runtime tooling. These cases have not yet been run as independent agent/baseline comparisons;
scaffold regression tests are separate implementation evidence, not behavioral eval passes.

Implementation environment: Flutter 3.38.9, Dart 3.10.8, macOS; fdev 0.1.6.

Implementation checks completed:

- tests/consistency.sh: PASS (all reference indexes, version sync, budgets, shell syntax,
  placeholders and documented fdev command names).
- tests/run.sh: PASS (installer copy/project modes; new_app scaffold and orders feature;
  codegen; format; analyze; tests; forbidden-pattern checks; audit/release-check execution).
- Fresh-app tests cover adaptive/busy controls, form validation, single-pass spacing,
  bootstrap failure surface, configuration validation, platform calls and safe error mapping.
- Generated-feature fixtures cover immutable state, strict malformed-record rejection,
  successful parsing and network-failure classification across the data boundary.
- Skill quick validation, local reference targets, changed workflow YAML parsing, fastlane
  Ruby syntax and git diff whitespace checks: PASS.
- fdev 0.1.6 command help checked (upgrade excluded from read-only probing after its help
  unexpectedly reactivated the same version); Shorebird 1.6.123 relevant command help checked.

Not verified: real device orientation/system bars, clean-install bundled Google Font delivery,
native hardware/lifecycle behavior, credentialed hosted signing/store upload, or live OTA
activation/promotion/rollback. New behavior cases 27–34 and baseline comparisons remain unrun;
implementation regression success does not count as their PASS verdict.

### Reference comparison follow-up

Reviewed Flutter agent-plugins' widget-test/responsive/preview workflows and the flutter_skill
package documentation. Updated case 34 and added case 35; neither was run as an agent/baseline
eval. Added dedicated integration/preview references and corrected stale testing rules.
Documentation-only follow-up: consistency, skill metadata and local-link validation pass;
the earlier scaffold regression remains applicable because templates/scripts were unchanged.
No new preview session, device integration run, or flutter_skill installation was performed.

### Permission and location follow-up

Read an existing app's location utility, provider selection, location Cubit, permission UI,
camera helper, lifecycle coordination and native permission declarations without modifying
that app. Retained separate GPS/access outcomes, bounded acquisition and centralized refresh;
strengthened denied/restricted/limited handling, Settings return, cancellation and fix quality.
Checked permission_handler/geolocator/location and Android/Apple primary guidance; documented
the current Android federated-plugin passive-status/request-result distinction explicitly.
Added cases 36–37 (not run as agent/baseline evals). Documentation checks passed; templates,
scripts and package dependencies are unchanged. No native permission/device flow was executed.

## 2026-10-24 — independent quality and acceptance pass

Independent audit found and corrected unsafe installer replacement/copy behavior, silent
success exit codes, string-based tool-result detection, stale preference-token guidance,
and scope/evidence contradictions. Negative script contracts and isolated installer tests
pass. Full regression passes after these changes. PowerShell edits were source-reviewed;
no PowerShell runtime was available.

### Case 38 — matched permission coordinator

Two independent agents received identical public task/gateway inputs in isolated directories.
Only the with-skill lane could read SKILL.md/references; neither implementer saw the held-out
checks before implementation completed. The parent then ran the same 14 acceptance checks,
read outcomes, and independently reran analyzer and all tests.

| Lane | Authored tests | Held-out acceptance checks | Combined test result | Analyze |
|---|---:|---:|---:|---|
| Baseline, no skill | 27 | 14/14 | 41 passed | 0 issues |
| With skill | 34 | 14/14 | 48 passed | 0 issues |

Verdict: PASS for both lanes on this pure-Dart contract. This demonstrates correct behavior
under the tested races and failure paths, not a measured advantage from the skill. Test
counts alone do not establish superior quality. Future comparisons should use harder,
less prescriptive tasks. Neither lane exercised native prompts or GPS hardware.

Reproducible inputs/acceptance: fixtures/permission-coordinator-task.md,
fixtures/location_gateway.dart, fixtures/permission-coordinator-checks.dart and
prepare_permission.sh. Frozen source, authored tests, source hashes and per-check results:
[case 38 artifacts](artifacts/2026-10-24-case38/summary.json).

### Android scaffold smoke

A separate fresh scaffold was generated, analyzed (0 issues), unit/widget tested (18 passed),
built as a debug APK, installed and launched on an Android 17/API 37 ARM64 emulator.
Home was confirmed by UIAutomator text and inspected screenshots in portrait/landscape;
the same process remained alive, and app-scoped logs had no fatal/overflow/startup-failure
markers. Original free-rotation policy was restored. No emulator wipe/reset was requested.
One emulator launch retry was required; Android cold-booted after a renderer snapshot mismatch.

am start reported Status ok and TotalTime 2397ms. This isn't a Flutter first-frame benchmark.
The starter has no primary interactive flow; this smoke proves the observed startup/rotation
scope only. Native permissions/GPS, iOS, release signing/store processing and OTA remain untested.
[Device evidence](artifacts/2026-10-24-device-smoke/summary.json) includes screenshots and APK hash.
