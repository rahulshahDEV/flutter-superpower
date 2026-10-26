# Testing by Failure Boundary

Use flutter_test, plain expectations and hand-written fakes. Keep the existing app's testing
conventions; don't add mocktail/mockito as a new house default. Paths mirror lib/.
Device-level flows use the SDK integration_test package when appropriate; see integration-testing.md.

## Choose evidence from the risk

| Behavior at risk | Useful check |
|---|---|
| Business invariant, validator, parsing, failure mapping | Unit test with explicit input/output |
| Request order, duplicate writes, refresh/cancellation | Cubit/repository test with controlled completion |
| Visible state, input, semantics, callback or route effect | Widget test with real interaction |
| Breakpoint, keyboard, long label, accessibility overflow | Widget test at the failing constraints/scale |
| Stable component appearance | Deterministic golden when visual comparison adds value |
| Bootstrap, plugin registration or multi-screen device flow | Integration test and affected native device |

Don't test trivial getters or duplicate generated serialization internals. Test your schema
contract and malformed inputs. Layout isn't automatically exempt: a hidden submit action or
an unusable large-text control is a behavior regression. Match effort to consequence.

## One observable behavior at a time

Identify the public operation and acceptance result before choosing fixtures. Use the
highest boundary that exposes the failure with reliable diagnosis; add lower-level checks
when they protect a distinct parsing, invariant or lifecycle contract. Follow the project's
existing test seams; routine test choices don't require a separate user approval round.
See boundary-design.md when the public contract itself needs design work.

For a bug or test-first feature slice: write one meaningful failing check, confirm that it
fails for the intended missing behavior, implement the smallest complete path, then rerun.
An import/setup failure is not the regression's red result. Repeat for the next behavior;
don't write a bulk suite against an imagined implementation before exercising any slice.
Refactor with the relevant checks green; preserve the same public behavior.

Derive expected results independently from the specification, a worked example or a fixed
fixture. For a total of 12 and 8, assert 20; don't compute the expected total with the same
loop/helper as production. Reject assertions that merely confirm the implementation's wiring.
Assert returned data, emitted state, visible recovery or an externally meaningful effect.
Call counts/order are useful for an explicit duplicate-write or serialization invariant;
checking every internal collaborator call makes harmless refactors break tests.

## Fixtures and state tests

Use minimal fakes implementing the actual contract, with explicit success/failure fixtures.
Use Completer-controlled results for out-of-order requests; don't rely on sleep timing.
Test immutable snapshots by modifying the original input and attempting consumer mutation.
Close factory Cubits/subscriptions after each test. Restore DI overrides and platform handlers.
Don't test private methods when a public operation exposes the behavior.

The runnable examples are maintained with the scaffold rather than duplicated here:

- templates/app/test/network_error_test.dart: typed mapping and safe copy.
- templates/app/test/ui_foundation_test.dart: large text, busy semantics/geometry, input,
  resolved spacing, startup failure surface and platform requests.
- tests/fixtures/feature_regression_test.dart: generated feature parsing and state ownership
  (the regression runner installs it into its temporary demo app after feature generation).

These tests supply their own fixtures/fakes and use actual generated contracts. When writing
an app test, import that app's types; don't copy a stale example with different entity fields.

## Widget test loop

Build with required theme/localization/directionality and ScreenUtil when the component uses
it. Provide fake repositories or a provider-free view rather than contacting live services.
Choose exactly one Cubit owner: wrapping a screen that already creates the same Cubit creates
a shadow instance. Assert the initial state, act, pump, then assert the changed user outcome.

Prefer stable keys or scoped finders where text/type appears multiple times. Scroll lazy
content into view before interacting; its absence before mounting isn't proof of a bug.
For text entry, focus and keyboard submission, check the actual values/errors and preserved
input, not only that a TextField exists. Check busy/disabled controls cannot submit twice.

Use pump for a frame and bounded pumping for known transitions. pumpAndSettle is appropriate
only when frames can settle; an indefinite progress indicator, timer or recurring animation
can keep it waiting. Use controlled futures and explicit end states instead of arbitrary
Future.delayed calls. Don't make a test pass by increasing every timeout.

Check tester.takeException after risky layouts and test the actual parent constraints, not
just the full window. Test below/at/above a breakpoint where behavior changes. Include long
copy, large text, keyboard insets, supported RTL/themes, and focus where relevant. Restore
test-view size/devicePixelRatio and dispose semantics handles/controllers even on failure.

## Services, plugins and globals

Use SharedPreferences.setMockInitialValues before storage resolution when testing that
legacy API. Plugin transport mocks test adapter behavior, not real native registration.
Initialize/fake Firebase at the appropriate test boundary or build a smaller view; never add
production empty catches or Firebase.apps guards merely to hide missing test setup.
Keep binding selection before any app binding initialization; a test runner's binding and a
runtime automation binding aren't interchangeable. See device-tooling.md.

## Golden and preview boundaries

A golden needs fixed viewport, text scale, locale, theme, fonts and deterministic data.
Bundle/load the real face when comparing brand typography; no runtime HTTP. Review baseline
changes visually rather than accepting updates to clear failures. A screenshot cannot prove
an action, route, accessible name or native permission works. Combine only the checks useful
to the change. Previews are iteration surfaces; see component-previews.md.

## Commands and completion

Run format → codegen if needed → analyze → test. Prefer fdev gen for generation; fallback:
`dart run build_runner build --delete-conflicting-outputs`.

```bash
flutter test test/core
flutter test --coverage
```

Use the actual test path and device target; integration commands live in integration-testing.md.
For a regression, demonstrate the new check fails for the original cause when practical,
then passes with the fix. Don't report a widget test as a device pass or inflate confidence
from coverage percentage alone. Record exact commands, outcomes and untested boundaries.

Sources: [Flutter widget testing](https://docs.flutter.dev/cookbook/testing/widget/introduction),
[official widget-test workflow](https://github.com/flutter/agent-plugins/tree/main/skills/flutter-add-widget-test).
