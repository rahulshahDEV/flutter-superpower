# Runtime Inspection and Agent Tooling

Use when a running app will resolve a UI, state, navigation, or integration question. Keep
existing tools first; adding an automation package isn't a prerequisite for a small fix.

## Choose the smallest useful tool

| Question | Evidence/tool |
|---|---|
| Type/build failure | Analyzer, compiler/task output, `native.md` |
| Wrong widget/layout/state | Flutter Inspector, debugger, or available Dart/Flutter MCP |
| Reproduce a user flow | Available runtime interaction tools plus explicit state assertions |
| Native dialogs, hardware or process death | Device/native tooling; `native-diagnostics.md` |
| Protect a confirmed fix | Widget/unit test or integration_test using the appropriate boundary |

Discover the tools actually connected to the session and their schemas; don't invent MCP
names or assume a tool is installed. Add the relevant project root if the server requires
it, select the exact app/device/flavor, and attach using the URI the current runner reports.
Keep service/debug URIs private. State what each tool observes: widget trees, semantics,
screenshots, logs and native OS UI are different views with different blind spots.

The official [Flutter agent plugins](https://github.com/flutter/agent-plugins) provide focused
workflows for layout, previews, testing and other Flutter tasks. Use their diagnostic ideas
within the app's architecture; don't switch from Dio/Cubits merely because a sample uses a
different stack. Check the installed SDK and live docs before copying tool or preview APIs.
Official MCP setup: [Dart and Flutter MCP](https://docs.flutter.dev/ai/mcp-server).

## Inspect → act → assert

1. Reproduce the failing build/viewport/state. Inspect the first exception and owning subtree.
2. For layout, trace incoming constraints, child size and parent positioning. Expanded helps
   only inside a bounded Flex axis; it cannot repair an infinitely tall scrolling ancestor.
   Avoid treating shrinkWrap, fixed heights, or smaller text as universal fixes.
3. Prefer stable semantic labels/keys over coordinates. Inspect lazy content after scrolling
   it into view; distinguish unmounted content from a missing feature.
4. Perform one meaningful action and wait for an observable state with a bounded timeout.
   Infinite loaders/animations make unconditional pumpAndSettle unreliable.
5. Assert the expected result, capture the relevant screenshot/log, and check the return/back
   path. An error-free tool response doesn't establish a correct user outcome.
6. Convert the confirmed causal flow into a permanent regression test. IntegrationTest's
   binding does not require enabling a legacy Flutter Driver extension in production.
   Preserve the app's bootstrap/DI setup and use isolated deterministic data.

Widget previews are useful for pure components with narrow/wide/large-text/error states.
They don't prove plugin registration, native permissions or cold launch. Verify the SDK's
preview feature and command availability rather than making previews a universal gate.

## Select the inspection route

| Situation | Preferred starting point |
|---|---|
| Existing official Dart/Flutter MCP or Inspector available | Use it with the selected running app |
| Reusable pure UI iteration | component-previews.md or a widget-test harness |
| Missing runtime interaction capability with a concrete need | Evaluate flutter_skill before adding it |
| OS dialog, hardware or native crash | Native tools/device automation; bridge visibility may be insufficient |
| Android UI journey with ARTEMIS already selected/available | android-automation.md: readiness, trace lifecycle and outcome checks |

A tool's existence doesn't require installation. Verify versions and capabilities on this
project; keep the reference project's state/HTTP samples subordinate to house architecture.
For permanent device regressions, follow integration-testing.md.
For optional ARTEMIS discovery, Android device targeting and asynchronous trace ownership,
follow android-automation.md. A submitted or completed automation job is not a test verdict.

## Optional flutter_skill integration

The [flutter_skill package](https://pub.dev/packages/flutter_skill) offers runtime automation
and its own MCP/CLI. Treat its advertised platform/test coverage as publisher claims until
verified on the project's actual device and version. It is distinct from this repository's
Flutter Superpower skill and from Flutter's official agent plugins.

If this tool is selected, follow `dependencies.md`: inspect version, license, transitive
cost, SDK/platform requirements, transport and release behavior before installation. Match
CLI and app SDK versions. Configure the MCP server using the client's supported config,
then enumerate live tools and connect to the intended debug app; don't hardcode a marketing
list of available tools in project instructions.

The package documents `FlutterSkillBinding.ensureInitialized()` in debug mode. A custom
binding must be selected before a normal WidgetsFlutterBinding has been created. In this
scaffold, bootstrap creates that binding, so a debug-only automation entrypoint would select
the custom binding BEFORE delegating to bootstrap. Don't paste it later into App.build or
replace the production binding. Check the installed package's exact API before wiring it.

Distinguish the app SDK dependency from the separately installed CLI/MCP process. If code
under lib imports the package, making it a dev_dependency alone does not make that import a
valid production-library dependency. Select the project's supported debug harness/delivery
strategy, inspect the resolved dependency graph and verify release behavior; don't claim
kDebugMode alone proves every package component was removed.

Use a dedicated dev/test entrypoint and non-production data. Verify the bridge is absent or
inactive in the distributed release and that no debug service is exposed remotely. Review
`flutter-skill init` changes before adopting them; a reference link isn't a request to modify
an application's configuration. Keep native OS/hardware checks where the bridge cannot see.

## Evidence

Record tool/package version, app commit, device/OS, flavor/mode, viewport/text scale,
starting state, actions and assertions, and artifact paths. If tools are unavailable, use
widget tests plus the native CLI/IDE route and disclose remaining runtime checks. Don't
claim visual, accessibility, or platform coverage from a widget tree alone.
