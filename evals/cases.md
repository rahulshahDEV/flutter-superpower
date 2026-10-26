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
`AppSizes`/ScreenUtil tokens; choose structure from available width, not platform identity;
no overflow at 320pt and tablet width; text scaling 2.0× intact.
**Must-not:** hardcoded device checks (`Platform.isIOS`); separate screen for tablets.
**Verify:** `flutter analyze` · `flutter test` · manual: resize/rotate.

## 21 — Form validation and async submission

**Task:** "Add an account form with a remote email-availability check and keyboard submit."
**Must:** controllers and focus nodes stay in the screen and are disposed; synchronous
validation is localized and performs no I/O; remote validation runs through the feature
Cubit's state with stale-result protection; keyboard submit uses the same validated action as
the button; duplicate submissions are prevented; failure is visible and recoverable.
**Must-not:** controllers in the Cubit; async/network work inside a field validator; an
unobserved Future or context use after an unguarded await; a new form package.
**Verify:** `flutter analyze` · `flutter test` (validation, submit, and failure behavior).

## 22 — Exact money and unit handling

**Task:** "Split an order total between participants and support currencies with different
minor-unit exponents."
**Must:** money stays integer minor units paired with a currency; each currency's exponent is
explicit; unknown currencies fail as typed errors; rounding is performed at one defined
boundary; allocated parts sum exactly to the original total; unit conversion happens at the
display edge.
**Must-not:** `double` money, hardcoded `* 100`, silent default currency, or repeated
independent rounding.
**Verify:** `flutter analyze` · `flutter test` (currency, rounding, and sum invariants).

## 23 — Backup and restore without data loss

**Task:** "Add a user-triggered backup export and restore from a selected file."
**Must:** backup format is versioned and distinct from human-facing exports; selected files
are size/version/integrity validated before writes; restore stages or transacts the complete
import and preserves existing data on failure; merge/replace policy is stated before
confirmation; tests cover round-trip and a corrupt/truncated file.
**Must-not:** clearing live data before validation; accepting CSV/PDF as a backup; implicitly
uploading a file; claiming a checksum encrypts or authenticates data.
**Verify:** `flutter analyze` · `flutter test` (round-trip and failed-restore preservation).

## 24 — Visual review before shipping

**Task:** "Prepare the new account flow for release and report any visual or accessibility
issues."
**Must:** inspect reachable loading, error, and success states at supported narrow/wide sizes,
themes, text scale, and directions/locales; identify concrete findings with reproduction
conditions; treat accessibility-floor violations as blockers; report untested combinations
and re-check affected states after fixes.
**Must-not:** claim a complete pass from analyzer output or one screenshot; redesign unrelated
screens; mark color-only status or clipped large text as a cosmetic note.
**Verify:** `flutter analyze` · `flutter test` · manual screenshots/device inspection for
the supported combinations.

## 25 — Parallel repository exploration

**Task:** "Profile this large Flutter app and identify the highest-risk issues before we plan
the account-settings change."
**Must:** when parallel agents are available, divide the read-only profile into independent
areas (such as state/DI, data/networking, routing/native config, and tests/UI); each report
includes inspected paths and evidence; the lead consolidates one profile, checks overlapping
or high-risk claims, and identifies unknowns. If parallel agents are unavailable, perform the
same profile sequentially.
**Must-not:** multiple agents inspect the same broad scope without a distinct question;
agents edit files or contact the user; unsupported findings appear in the consolidated report.
**Verify:** inspect task boundaries, cited paths/evidence, and the consolidated profile; no
implementation changes are expected.

## 26 — Distinguish fdev project setup from skill installation

**Task:** "I ran `fdev init --agents codex` but Flutter-Superpower does not appear in Codex.
Fix the setup and explain what happened."
**Must:** explain that `fdev init` configures Graphify and Caveman, while this skill is
installed with `scripts/install.sh`; choose the install scope from the project context and
verify the resulting skill path. Note that `fdev init` can commit generated setup files.
**Must-not:** claim `fdev init` installs Flutter-Superpower; rerun it without a need for
Graphify/Caveman; modify unrelated project files.
**Verify:** inspect the installed skill path and Git diff; confirm no unrelated changes.

## 27 — Deliberate startup and platform UI

**Task:** "Set up production startup for a Flutter app supporting phones and tablets. Handle
missing configuration, offline launch, system bars, and portrait preference on phones."
**Must:** establish required versus optional startup work; show failure without DI/config;
await platform policy; explain orientation restrictions; handle bar contrast and insets;
no timed splash or boot permission prompt; verify missing config and requested platform calls.
**Must-not:** unconditional tablet lock, raw startup error copy, blocking on optional network,
or claiming native bar behavior from unit tests.
**Verify:** analyze/test; device launch/orientation/keyboard checks explicitly recorded or unverified.

## 28 — Typography and adaptive action control

**Task:** "Use our chosen Google Font and make the primary action work offline, with long
translations and 2x text on narrow screens."
**Must:** bundle matching licensed font styles, disable runtime HTTP before creating styles,
wire TextTheme, preserve user scaling, wrap labels, maintain loading footprint and accessible
name, prevent duplicate taps, and keep minimum touch size in logical pixels.
**Must-not:** rely on a warm cache, double-scale gaps, clamp accessibility text, or use fixed
height to hide overflow.
**Verify:** widget tests for long-label/busy semantics/geometry; clean-install offline evidence.

## 29 — Evidence-based package choice

**Task:** "Add file sharing to this app; choose the right package and explain the tradeoff."
**Must:** inspect installed dependencies/SDK and target platforms; consult current primary
sources; compare a credible alternative; account for platform setup, licenses, transitive
cost, failure paths, and testability; implement the required setup in the same change.
**Must-not:** invent an SDK share-sheet API, select by popularity alone, add competing stacks,
or claim all-platform support from pub resolution.
**Verify:** dependency/lockfile diff, analyze/test, affected platform build; report unverified devices.

## 30 — State and repository boundary integrity

**Task:** "Fix the generated list: malformed server records disappear, offline errors look
like server errors, and modifying a source list changes already-emitted UI state."
**Must:** reject malformed required records; preserve typed error classification; show safe
copy; snapshot mutable collections; one provider owns each Cubit; retain content during
refresh when appropriate.
**Must-not:** silently filter malformed data, expose exception diagnostics, mutate emitted
lists, or create duplicate providers to pass route arguments.
**Verify:** mapper, malformed record, immutable snapshot and refresh behavior tests.

## 31 — Configure Codemagic and fastlane without accidental publication

**Task:** "Set up Android and iOS CI/CD for this flavored app using Codemagic and our
existing fastlane lanes. Produce signed artifacts first, then explain tester delivery."
**Must:** profile identifiers/schemes/versions; isolate untrusted checks from secrets; distinguish
signing from API authentication; pin toolchains and Bundler; preserve keys/profiles; allocate
unique build numbers; use valid YAML patterns; one build/upload owner; report actual validation.
**Must-not:** install a second signing owner, upload automatically without release intent,
claim YAML parsing proves signing, or expose release credentials to PR scripts.
**Verify:** YAML/Ruby syntax, secret-free check, signed artifact build when credentials exist;
account/store steps explicitly verified or recorded as unavailable.

## 32 — Stage and recover a Shorebird patch

**Task:** "Prepare an OTA bug fix for the current production release; test on staging and
show how to promote or recover it."
**Must:** inspect eligibility and exact baseline/flavor/platform/target; distinguish dry-run,
upload, activation and promotion; use installed CLI help; preserve the tested patch identity;
verify update/restart/rollback on the intended baseline; account for persisted data compatibility.
**Must-not:** patch asset/native changes with allow-diffs, select an ambiguous latest baseline,
expose tokens to PR code, rebuild a plain-Flutter store binary, or promise instant fleet rollback.
**Verify:** command/target review, dry-run and device evidence when access exists; remote
mutation only within intended publication scope.

## 33 — Diagnose native lifecycle and crash failure

**Task:** "A native plugin crashes after background/resume in the release flavor. Diagnose
and fix it without resetting app data or upgrading the whole toolchain."
**Must:** capture exact artifact/device/mode and native causal stack; match symbols; inspect
engine/activity/controller lifetime, threading and registration; reproduce interruption;
fix ownership; add bridge/native tests plus affected device verification.
**Must-not:** infer root cause from the last Gradle line, treat Dart catches as native crash
recovery, fix by disabling shrinking globally, or claim simulator coverage proves hardware behavior.
**Verify:** relevant tests, native build, original device reproduction or explicit evidence gap.

## 34 — Runtime tooling becomes a reproducible test

**Task:** "Use available Flutter inspection tools to reproduce the keyboard overflow and
protect the fix with a test. Consider flutter_skill only if existing tools are insufficient."
**Must:** discover actual tool schemas/device; inspect constraints and lazy widgets; assert
state after actions; use bounded waits; add a regression at the failing size/scale; keep any
optional automation binding before default binding initialization and scoped to debug/test.
**Must-not:** invent tool names, install tooling solely because referenced, expose runtime
bridges in release, replace architecture from an external sample, enable a legacy driver
extension for standard integration_test, or claim screenshots alone prove behavior.
**Verify:** original reproduction, widget/integration test and explicit tool/device evidence.

## 35 — Preview and resize without losing flow state

**Task:** "Preview this search/detail component at narrow and wide sizes, then ensure resizing
between its list/detail layouts preserves the selected result and unsaved input."
**Must:** inspect SDK preview support; use existing theme and deterministic injected fixtures;
cover loading/error/long-text states; preserve flow ownership/selection/draft across resize;
assert the breakpoint behavior with a widget test; distinguish browser preview from native evidence.
**Must-not:** upgrade Flutter merely to enable a preview, call live services from the preview,
add a second Cubit per layout branch, or claim a preview replaces interaction/device tests.
**Verify:** SDK capability check, meaningful resize/large-text widget test and preview inspection
where available; report unavailable preview/native checks explicitly.

## 36 — Location permission, GPS and Settings recovery

**Task:** "Make nearby search and check-in handle denied location, disabled GPS and Settings
return smoothly. Avoid duplicate requests and stale or inaccurate check-in positions."
**Must:** profile installed plugin/OS behavior; distinguish app grant, service, precision,
provider and fix quality; explicit interactive recovery; passive resume recheck; one prompt/
acquisition owner; cancellation and unchanged Settings preserve control; validate rolling
freshness/accuracy; stop streams on timeout/disposal; preserve unrelated content.
**Must-not:** auto-open Settings, prompt on every resume/build, use an API cutoff as universal
provider policy, log coordinates, conflate denial with timeout, use cached position for check-in
without its stated quality policy, or release a prompt lock while the native dialog remains.
**Verify:** fake-adapter lifecycle/concurrency/quality tests and actual supported device flows;
report native UI/provider checks that were unavailable.

## 37 — Capability permissions with minimum scope

**Task:** "Add profile-photo selection and opt-in notifications. Handle limited access,
cancellation, blocked permissions and return from Settings without disturbing the profile form."
**Must:** evaluate permission-free system picking; request only needed scope; accept adequate
limited access; preserve input; one request owner; separate notification authorization/channel/
token status; inspect native setup and installed permission-handler mapping; bounded recovery.
**Must-not:** blanket storage/camera/microphone requests, interpret an FCM token as visible-alert
permission, infer permanent denial solely from rationale=false, or reset the form on Settings return.
**Verify:** selection/cancel/limited/denial/widget tests and platform authorization checks;
restricted or untestable OS outcomes explicitly recorded.

## 38 — Matched permission coordinator acceptance

**Task:** use fixtures/permission-coordinator-task.md verbatim with the supplied gateway contract.
**Setup:** evals/prepare_permission.sh <new-work-dir> creates identical baseline and with_skill
inputs. Resolve dependencies in each lane; give only TASK.md and lib/ to the baseline agent.
Give the other lane access to this skill, without evaluator acceptance checks or expected code.
**Must:** preserve the contract; implement the task's availability, prompt, Settings, concurrent
request, quality, cancellation and disposal behavior; add meaningful own tests and evidence.
**Must-not:** native/plugin installation, contract changes, cross-lane/source-skill access for
baseline, production logging or claims of actual device permission behavior.
**Verify:** independently run analyze and authored tests. After implementation is frozen, copy
fixtures/permission-coordinator-checks.dart into the lane's test/evaluator_contract_test.dart
and run it; inspect all 14 acceptance results. Record source hashes, exact scope and baseline
verdict. Both passing means no demonstrated skill advantage on this contract, not a failed baseline.

## 39 — Plan and deliver runnable feature slices

**Task:** "Add order-history filtering by status and keep the selected filter on retry.
The history feature and fake backend already exist. Make a short plan, then implement it."
**Setup:** use an isolated existing history feature with initial load, failure/retry and a
fake backend supporting a status query; provide its contract and existing test conventions.
**Must:** inspect the feature and applicable instructions; define observable filter/retry
acceptance; identify state ownership, affected callers and public test boundaries; implement
a runnable slice before adding the next behavior; preserve the filter on failure/retry;
complete route/DI/fixture updates actually required; provide exact verification evidence.
**Must-not:** stop at a plan, generate unrelated product features, publish tickets, require
approval of routine test seams, bypass repository/use-case layers, or claim plan checkboxes
as runtime evidence.
**Verify:** inspect implementation and execution order; independently run analyze/tests and
exercise success → changed filter → failure → retry with the selected filter retained.

## 40 — Behavioral tests with independent expectations

**Task:** "Fix checkout totals: a quantity of two items priced at 125 minor units with a
50-minor-unit delivery charge should total 300, but the app charges 175. Protect the fix."
**Setup:** existing checkout flow incorrectly ignores quantity; keep money in integer minor
units. Include a public total operation and a checkout view using it.
**Must:** reproduce the quantity defect through a public operation; derive expected 300
from the supplied example rather than the implementation; show a check failing for the
quantity error and passing after correction; preserve money/error behavior and caller
contracts; choose further tests only for distinct meaningful risks.
**Must-not:** reimplement production arithmetic to derive expected values, use private-method
tests, claim import/setup failures reproduce the bug, blanket-mock every internal method,
require user confirmation before ordinary testing, or migrate state/architecture.
**Verify:** independently run checks against the original cause and corrected behavior,
analyze/tests; inspect that the check detects the wrong amount, not merely a method call.

## 41 — Simplify a shared operation without losing its contract

**Task:** "Review my uncommitted upload refactor, then fix it. Keep the solution simple."
**Setup:** staged refactor moves validation into one screen while an unchanged second caller
still uses the shared upload operation; an unstaged edit clears the duplicate-submit guard;
a relevant untracked test covers cancellation. The existing feature uses repository/use-case
boundaries, typed failures and injected transport. Provide an explicit upload contract.
**Must:** inspect all requested staged/unstaged/untracked material and connected callers;
report concrete causal findings under the applicable review axes; restore shared validation,
one-write behavior and cancellation/cleanup; preserve useful seams and update affected
fixtures/DI/callers; test through public outcomes and externally meaningful write counts.
**Must-not:** review only HEAD, omit unchanged callers, delete layers to reduce line count,
remove validation/recovery, invent a second production backend, prescribe BlocConsumer
without ownership/rebuild evidence, or claim unavailable device checks passed.
**Verify:** invalid file through either caller cannot write; repeated submit yields one
external write; cancellation releases resources; independently run analyze/tests and review
the full local diff against the supplied contract.

## 42 — Android automation completion is not a test verdict

**Task:** "Use the available ARTEMIS tools to check location denial and Settings return on
the already selected Android test device, then protect any confirmed app bug."
**Setup:** tool transcript/schema fixture: selected dev app/device; task submission returns
a trace ID, first status is running, final status is completed but test_summary has one
failed assertion and one unchecked item. A trace shows a draft cleared on Settings return;
the hierarchy omits a Flutter control visible in the screenshot. Supply the app's draft owner.
**Must:** honor existing target selection; inspect readiness as needed; define bounded task
actions/assertions; retain trace/device identity; follow asynchronous status to a terminal
state; inspect summary/logs/screenshots; report failed/unchecked results accurately; reproduce
and fix the confirmed draft bug with a deterministic check; distinguish device evidence
from unit/widget/native coverage and leave no bounded interaction task running.
**Must-not:** claim submission/completed means PASS, assume Flutter keys are Android IDs,
tap cached coordinates after every lookup failure, subtract estimated inference time from a
timing requirement, silently switch devices, reset personal data, install global tooling,
or claim iOS/hardware coverage. Unavailable tools must produce an honest fallback/gap.
**Verify:** inspect tool transcript, selected serial and lifecycle; independently run the
draft-preservation regression and analyze/tests. A transcript-only run must not be reported
as a live Android/device pass.
