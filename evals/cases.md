# Eval Cases

Base app: `scripts/new_app.sh eval_app --dir /tmp/eval_app --title "Eval App"`.
`Verify` commands run in `/tmp/eval_app`. See `README.md` for the protocol.

---

## 01 — New feature end to end

**Task:** "Add an order history feature: list orders from `GET /orders`, reachable at `/orders`."
**Must:** full `features/orders/{data,domain,presentation}` layers; `OrdersScreen` with
`static path/routeName`; route registered in `AppRouter`; cubit + sealed states; endpoint in
`ApiConstants`; loading/empty/error/success handled; a cubit test exists.
**Must-not:** direct Dio/API calls in widgets; inline strings/colors; new package.
**Verify:** `flutter analyze` · `flutter test`.

## 02 — Add an API endpoint

**Task:** "Orders API now returns `{data: [...], meta: {total}}` — wire it up."
**Must:** parsing in the data source/model, not the cubit; `meta.total` surfaced in state;
malformed payload yields `ServerFailure` (not a crash); no raw `Map` leaking into UI.
**Must-not:** `!` on API fields; parsing in `build()`.
**Verify:** `flutter analyze` · `flutter test` (parser test present).

## 03 — Google sign-in flow

**Task:** "Add Sign in with Google to the app."
**Must:** native sign-in in a data source; backend exchange in repository; cubit
loading/success/failure (cancel silent); session persisted; tokens never logged; platform
setup documented/configured (serverClientId from env; SHA note).
**Must-not:** Firebase Auth added unrequested; raw SDK calls in the widget.
**Verify:** `flutter analyze` · `flutter test` (cubit success/failure/cancel tests).

## 04 — Fix a cubit bug

**Setup:** introduce a stale-response bug (remove the request-id guard) in the orders cubit.
**Task:** "Rapidly switching filters sometimes shows the wrong list. Fix it."
**Must:** root cause fixed in the cubit (stale guard restored); regression test that fails
before the fix; no unrelated refactor.
**Must-not:** fix in the widget; `Future.delayed` hack.
**Verify:** `flutter test` (new test fails on the pre-fix code).

## 05 — Fix a routing bug

**Setup:** change `OrdersScreen.path` registration to a typo'd literal in the router.
**Task:** "Tapping 'Orders' opens the not-found page."
**Must:** root cause found (path constant mismatch); route uses `OrdersScreen.path`; deep-link
fallback intact.
**Must-not:** hardcoded route strings; Navigator workaround.
**Verify:** `flutter analyze` · `flutter test` · manual: route opens.

## 06 — Refactor a giant screen

**Setup:** generate a feature, then inline three sections and 200 lines into the screen file.
**Task:** "This screen is 600 lines and hard to review. Clean it up."
**Must:** extracted widgets with meaningful names; behavior identical; no new packages;
screen file back under ~200 lines.
**Must-not:** splitting into 20 trivial files; changing UX/state shape.
**Verify:** `flutter analyze` · `flutter test` (unchanged behavior).

## 07 — Add pagination

**Task:** "Order history should load more when the user scrolls to the end."
**Must:** page/canLoadMore/hasReachedMax in state; guard against duplicate loads; footer
loader; failure mid-pagination handled without losing loaded items; test for the guard.
**Must-not:** loading all pages up front; `shrinkWrap: true` list.
**Verify:** `flutter analyze` · `flutter test`.

## 08 — Handle an API failure

**Setup:** make the fake/repo return `Left(ServerFailure(...))`.
**Task:** "The orders screen shows a spinner forever when the API fails."
**Must:** failure state rendered (`ErrorStateWidget` + retry); snackbar for transient failure;
retry re-invokes the cubit.
**Must-not:** catching-and-swallowing; raw exception text shown to users.
**Verify:** `flutter test` (failure-state test present).

## 09 — Loading/empty/error states

**Task:** "Orders screen only handles the happy path. Complete it."
**Must:** four states rendered distinctly; empty uses `EmptyStateWidget`; loading uses
`LoadingWidget`/shimmer; error offers retry; no double loaders.
**Must-not:** one generic "no data" for empty + error.
**Verify:** `flutter analyze` · `flutter test`.

## 10 — Add a reusable widget

**Task:** "Order rows appear in three places with slight variations — consolidate."
**Must:** one widget with parameters for the variations; used in all three sites; placed in the
feature (or `core/widgets` only if a second feature needs it); const constructor.
**Must-not:** duplicating the widget per screen; speculative parameters nobody uses.
**Verify:** `flutter analyze` · `flutter test`.

## 11 — Fix an architecture violation

**Setup:** move an API call into a screen's `initState` (raw `DioClient` in presentation).
**Task:** "Code review flagged this screen. Fix the violation."
**Must:** call moved to data source → repository → cubit; screen consumes state only;
behavior unchanged.
**Must-not:** keeping the call and wrapping it in a helper in presentation.
**Verify:** `flutter analyze` · `flutter test`.

## 12 — Debug an Android build issue

**Setup:** break `android/app/build.gradle(.kts)` (e.g. remove the Kotlin plugin id).
**Task:** "Android build fails after a merge. Fix it."
**Must:** native file corrected; root cause named; Dart untouched.
**Must-not:** editing Dart to work around a gradle error; deleting the failing config.
**Verify:** `flutter analyze` · `flutter build apk --debug` (or `fdev apk dev --debug`).

## 13 — Debug an iOS build issue

**Setup:** break `ios/Podfile` platform line or a plugin's pod requirement.
**Task:** "iOS build fails after adding a plugin. Fix it."
**Must:** pod config fixed; `pod install` re-run; report names the native cause.
**Must-not:** removing the plugin to silence the error without saying so.
**Verify:** `flutter analyze` · `cd ios && pod install` (or `fdev pod update`).

## 14 — Firebase notification flow

**Task:** "Add push notifications: FCM token registration after login, tap opens the orders screen."
**Must:** `firebase_core`/`messaging` wired in `main`; background handler with
`@pragma('vm:entry-point')`; token stored + registered post-login; tap → route mapping;
unknown payload ignored safely.
**Must-not:** token in logs; notification handling inside widgets.
**Verify:** `flutter analyze` · `flutter test` (route-mapping test).

## 15 — Modify a shared repository

**Task:** "Change `OrdersRepository.getOrders` to return a paginated result."
**Must:** impact analysis performed (callers grepped, listed); every caller updated; tests
updated; report lists affected cubits/screens.
**Must-not:** leaving a stale overload silently; breaking other features without mention.
**Verify:** `flutter analyze` · `flutter test` (all callers covered).

## 16 — Add missing tests

**Task:** "The orders cubit has no tests. Add them."
**Must:** success + failure + (loading) transitions; hand-written fake repo (no mockito);
`addTearDown(cubit.close)`; test mirrors `lib/` path.
**Must-not:** testing private methods; asserting implementation details; new test packages.
**Verify:** `flutter test` · `flutter test --coverage` (cubit covered).

## 17 — Optimize a slow screen

**Setup:** generate a list screen that rebuilds the whole tree on scroll state and uses raw
`Image.network`.
**Task:** "Scrolling the orders list drops frames. Improve it."
**Must:** evidence-based fix (const, scoped rebuild, builder list, cached image); measurement
or profiler reasoning stated; no behavior change.
**Must-not:** adding a caching package; speculative rewrites of unrelated code.
**Verify:** `flutter analyze` · `flutter test`.

## 18 — Reject an unnecessary dependency

**Task:** "Add `date_format_plus` to format order dates."
**Must:** the agent checks `intl` (already present) and formats with `DateFormat`; explains why
no package was added; if it does add something, it justifies against the ladder.
**Must-not:** adding the package silently; adding a second date library.
**Verify:** `pubspec.yaml` unchanged (or justified); `flutter analyze` · `flutter test`.

## 19 — Implement localization

**Setup:** add ARB files (`lib/l10n/app_en.arb`, `app_ne.arb`) + `flutter_localizations`.
**Task:** "Localize the orders screen; add the empty-state string."
**Must:** new key added to every locale; `AppLocalizations` used; no hardcoded user strings;
date formatted with `intl` locale-aware.
**Must-not:** string concatenation; English-only key left in the second locale.
**Verify:** `flutter analyze` · `flutter test` · `fdev gen` (l10n codegen) clean.

## 20 — Tablet/responsive layout

**Task:** "The orders screen is unusable on tablets — fix the layout."
**Must:** responsive layout via constraints (`LayoutBuilder`/`Flexible`/grid) using existing
`AppSizes`/ScreenUtil tokens; no overflow at 320pt and tablet width; text scaling 2.0× intact.
**Must-not:** hardcoded device checks (`Platform.isIOS`); separate screen for tablets.
**Verify:** `flutter analyze` · `flutter test` · manual: resize/rotate.
