# Component Previews

Use previews to iterate on a reusable component or a view that accepts explicit state.
Prefer existing project tooling; a small UI fix doesn't require a new preview system.
Tests and visual review remain governed by testing.md and design-review.md.

## Check SDK support first

Check flutter --version and flutter widget-preview --help before adding annotations. Current
Flutter documentation describes a stable previewer from 3.47; earlier SDKs may have an
experimental surface or different IDE support. Don't upgrade the app merely to add previews.
Use a small widget-test harness or the existing component gallery when support is unavailable.

On a supported SDK, flutter widget-preview start launches the preview environment. SDK APIs
come from package:flutter/widget_previews.dart. Use a top-level/static factory or eligible
public widget constructor without required arguments. Verify annotation parameters against
the selected SDK rather than copying new APIs into an older app.

## Preview the meaningful state matrix

Choose the states that distinguish this component: content, empty/error, disabled/busy,
long labels, narrow/wide constraints, supported theme/locale/RTL and large text. Keep fixtures
small, deterministic and owned beside the feature/component. A preview name should identify
the state, not claim that the component passed an automated test.

Wrap with the actual theme, localization, directionality and sizing environment the component
requires. A ScreenUtil-based component needs the established initialization; don't invent a
second scale. Inputs/callbacks stay explicit. Inject fake data above the view rather than
resolving live DI/network services from a preview factory.

Preview callbacks must meet the SDK's visibility/constant requirements. Start with ordinary
annotations; extract shared wrappers or custom multi-preview annotations only when repetition
justifies them. Check type and API compatibility before using newer builder/transform APIs.

## Runtime limitations

The previewer renders in a web environment. Native plugins, dart:io/ffi execution and platform
registration aren't established by a successful component render. Isolate the pure view and
fake the necessary boundary; don't weaken production behavior with broad preview catches.
Loading assets through lower-level APIs can require package-qualified paths; verify asset
resolution in the actual preview runtime. Fonts follow fonts.md with no live HTTP dependency.

Keep preview build caches out of version control. Reset the local preview state when a
component fixture changes; restart the preview process/global state when static initialization
changes. Diagnose the first error rather than repeatedly clearing every app cache.

## Inspect and preserve evidence

Inspect wrapping, action reachability, layout transitions, focus/hover where supported,
contrast and semantics. Then add a focused widget/golden check for regressions worth retaining.
Don't assert native correctness or production performance from browser previews. Report SDK,
preview configuration and inspected states; record unsupported device checks separately.

Sources: [Flutter Widget Previewer](https://docs.flutter.dev/tools/widget-previewer),
[official preview workflow](https://github.com/flutter/agent-plugins/tree/main/skills/flutter-add-widget-preview).
