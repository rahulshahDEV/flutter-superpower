# Visual Design Review

Use this guide for a meaningful UI change or a pre-release visual pass. Keep review effort
proportional to the change: a shared theme or navigation shell deserves a wider sweep than a
single label adjustment.

## Review coverage

For each changed screen or shared component, inspect the states the user can reach: loading,
empty, failure, partial data, and success where they apply. Cover the app's supported light
and dark themes, locales and text directions, narrow and wide layouts, and large text. Check
reduced-motion behavior for screens with animation. Use the actual supported combinations;
do not invent a locale or theme the app does not claim to support.

Verify that:

- layout and content follow the project's existing design tokens and component system;
- no important text clips, overlaps, or becomes unreachable when width or text scale changes;
- actions remain visible and keyboard/focus behavior still works;
- direction-sensitive elements and mixed-direction text render correctly in supported RTL
  locales;
- status is not conveyed by color alone, and motion can be reduced without losing meaning;
- loading, empty, and error states feel consistent with the successful state.

Read `accessibility.md`, `localization.md`, and `adaptive-layout.md` for the specific floors.
Automated widget/golden tests complement this inspection; they do not prove behavior on a
device or prove every supported combination is correct.

## Findings and follow-through

Record each concrete issue with the screen/state, reproduction conditions, and a screenshot
or test when useful. Separate release blockers from improvements that can be tracked later.
Fix issues introduced by the change, then re-run relevant tests and inspect the affected
states again. Do not silently broaden a visual review into a redesign.

For release work, include the reviewed build/flavor, supported combinations inspected,
unresolved findings, and anything that could not be checked in the evidence report. Do not
claim a complete visual pass from a successful analyzer run or a single screenshot.
