# Eval Results

Protocol: `README.md`. Cases: `cases.md`. Verdicts were checked independently of the agent's
own report (analyze/test re-run, Must/Must-not inspected in the diff).

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
