# Android Automation with Optional ARTEMIS

Use when a real Android UI journey, OS dialog or native boundary needs observation. Keep
unit/widget tests for logic and layout; runtime exploration is not their prerequisite.
ARTEMIS is an external Android automation agent, not a Flutter package or iOS runner.

## Select the environment and capabilities

Discover connected tools and their live schemas before using the names below. If ARTEMIS
is unavailable, use existing Flutter/native tooling or a documented manual journey. Do not
install it or alter global MCP rules merely because this guide is linked.

- Identify the app commit/artifact, application ID, dev/test flavor, account/fixture and
  exact device serial. `adb devices -l` lists devices; `adb -s DEVICE_SERIAL ...` targets one.
  Reuse an already selected target. Ask only if several targets remain genuinely ambiguous.
- Check that the target is authorized/online and the correct app is installed. Do not clear
  its data or reinstall over a personal session to make an exploratory run convenient.
- ARTEMIS currently exposes `mobile_diagnose` for readiness, `mobile_get_device_state` for
  observations, `mobile_run_task` for background work, `mobile_manage_task` for lifecycle,
  and `mobile_inspect_trace` for evidence. Names/arguments may vary by installed version.
- For startup/tool errors, inspect readiness, recent errors and the failed trace before
  retrying. Distinguish required blockers from optional recording/OCR warnings. Inspect the
  effects of diagnostic repair options before using them; diagnosis need not reset ADB,
  regenerate keys, stop other work or change credentials. Keep credentials out of chat.

If deliberately setting ARTEMIS up, follow its versioned upstream README and inspect the
configuration diff. Its MCP installer can modify global client configuration and rules;
review those changes within the authorized scope. Verify readiness after reloading the
server. This skill does not require a particular model provider or stored credential.

## Give the device task an observable contract

Describe starting state, intended actions, explicit assertions, permitted side effects,
time/attempt budget and termination condition. Limit it to the requested app/test data;
permission recovery may legitimately leave the package for a named OS Settings screen.
Do not assume an app lock permits that excursion; check the tool's actual behavior first.

Example brief (replace the selected device/app context):

> On the selected test device, open nearby search in the dev app with location denied.
> Tap its location action once. Assert that denial produces the recovery view and preserves
> the search draft. If Settings recovery is available, exercise it and return; assert a
> passive access recheck without a second automatic permission prompt. Capture each outcome.
> Stop after this journey or after two minutes; report blocked steps. Do not reset app data.

At the reviewed version, Flash suits a known direct path; Pro supports exploration,
diagnostics and checkpoint verification. Pro's `verification_level` accepts `off`, `final`,
`checkpoints`, `strict`; these settings are ignored for Flash. Choose checkpoints/strict
when independent intermediate assertions matter; inspect failed/inconclusive/unchecked
results even if the overall task completes. Do not treat a model choice as proof of safety
or correctness, or transfer an upstream benchmark success rate to this app.

## Own the asynchronous lifecycle

1. Use `mobile_run_task` with the exact `device_serial` and a bounded `task_desc`; retain
   the returned `trace_id`, assigned serial and log paths. A returned trace means submission,
   not a passed test. Inspect rejection/error fields before waiting.
2. Check `mobile_manage_task(action="status", trace_id=...)` periodically, at least once
   per minute in the reviewed version. Keep user progress updates; do useful independent
   work between checks. Avoid competing interaction tasks on the same device.
3. On completion, inspect `test_summary` where present, relevant stderr, and
   `mobile_inspect_trace(action="view_summary", trace_id=...)`. Read the screenshots/details
   for assertions that matter. Completed execution may contain failed or unchecked checks.
4. If stalled, inspect the current screen and failure first. Retry only after a concrete
   correction, within the declared budget. Stop this task with the lifecycle tool when its
   budget is exhausted or actions leave scope. Record partial results and the blocker.
5. A deliberately continuous Pro task uses its documented loop lifecycle; at the reviewed
   version graceful termination uses `inject_instruction` with `release_loop=true`.
   Do not leave background interaction running after reporting a bounded task complete.

## Turn exploration into repeatable evidence

Prefer inspected semantics/resource IDs/keys and explicit state waits. Flutter keys are
available to Flutter finders; they are not automatically Android resource IDs. An absent
UIAutomator node is not proof the widget is absent: compare the screenshot and Flutter tree.
Native dialogs may need native automation beyond WidgetTester.

Use coordinates only when grounded in the current screen, orientation and viewport, then
assert the result. Do not silently catch every locator failure and tap a cached position:
the locator may have exposed a real regression. Fail or re-inspect before proceeding.
For timing requirements, measure elapsed time/state with bounded waits; never subtract an
estimated model inference delay from a required duration or encode exploratory sleeps in CI.

Minimize the confirmed flow into a deterministic widget/integration/native regression at
the appropriate boundary; see integration-testing.md. A video or checker report alone cannot
establish a backend write, hardware accuracy, iOS behavior or OS process-death recovery.
Record commit/artifact, device/OS, flavor, initial fixture, actions, asserted outcomes,
trace/log/screenshot paths and unverified steps. Redact private device/account/location data.

Sources inspected at commit `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`:
[ARTEMIS MCP overview](https://github.com/google/artemis/blob/351ca8422f7b5b54e80a9c1ce03a222e02415b6b/mcp_server/README.md),
[task submission](https://github.com/google/artemis/blob/351ca8422f7b5b54e80a9c1ce03a222e02415b6b/mcp_server/tools/task_runner.py),
[lifecycle](https://github.com/google/artemis/blob/351ca8422f7b5b54e80a9c1ce03a222e02415b6b/mcp_server/tools/task_manager.py).
