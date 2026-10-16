# Adaptive Layout

Adapt to the space the app has, not a guessed device identity. `ScreenUtil` and `AppSizes`
remain the house tools for design sizing; they do not decide whether content should become a
two-pane layout, navigation rail, or grid.

## Choose structure from constraints

- Use `LayoutBuilder` when a component's local constraints determine its structure. Use
  `MediaQuery.sizeOf(context)` when the whole app window determines the shell layout.
- Define breakpoints once for the app and use them consistently. Choose them from the
  content's minimum usable width and test near each boundary; do not copy breakpoint numbers
  without checking the project's design.
- Let narrow layouts stack or navigate between list and detail. Use a split view only when
  both panes remain readable at the available width. Never ship a stretched phone UI on a
  tablet — wide windows earn master-detail, rail, or grid structure.
- Cap long-form content with a maximum width. Use `Expanded`, `Flexible`, and grids for
  flexible regions instead of fixed screen widths.
- Keep row and control heights content-driven so accessibility text scaling can expand them.
- Respect safe-area and keyboard insets. Prefer the narrow `MediaQuery` accessors needed by
  the widget so unrelated media changes do not trigger broad rebuilds.

## House sizing and responsive behavior

- Continue to use `AppSizes` and `.w/.h/.r/.sp` where the established design system uses
  `flutter_screenutil`. Use constraints to select structure and tokens to size that
  structure.
- Do not add platform checks such as `Platform.isIOS` to choose a layout. Do not make a
  separate tablet screen unless the product explicitly calls for a different workflow.
- Keep orientation behavior consistent with the app's existing platform policy. Test every
  orientation the app supports rather than changing a global orientation setting to fix one
  page.
- For navigation shells, select bottom navigation, rail, or drawer by available width in one
  shared place; keep route and selection behavior in `routing.md`.

## Verification

Exercise the smallest supported width, a wide window, a breakpoint boundary, keyboard-open
state, and the largest supported text scale. Include landscape, split-screen, or foldable
postures when the app supports them. Add widget tests for meaningful breakpoint behavior;
use screenshots for stable visual states, not as a substitute for overflow assertions.

Never claim tablet support from a single simulator screenshot. Check the actual content,
focus order, scrolling, and reachable actions in each layout.
