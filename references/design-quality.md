# Design Quality

Visual taste rules for Flutter/Material 3 work. Distilled from Impeccable's
detector vocabulary and UI-UX-Pro-Max's mobile checklist, adapted to the house
style (K-widgets, `AppColors`, `AppTextStyles`, ScreenUtil). These are default taste
preferences, not universal bans: supplied designs, brand requirements, platform conventions,
and content needs win. Accessibility and readable controls remain requirements. Read with
`design-review.md` before a visual pass.

## Default visual direction

- Never `Card` inside `Card`. Flatten with `Divider`, padding, or M3 tonal
  surface levels (`surfaceContainer*`).
- One elevation language: `Card.elevated` (shadow) XOR `Card.outlined`
  (1px border) — never shadow plus border on one surface.
- No `BoxShadow` with zero blur (halos, hard offset blocks). Shadows need
  offset + blur; depth only clarifies state or hierarchy.
- No gray text on colored surfaces. Use `onPrimary` / `onSurfaceVariant`, or
  the foreground color at reduced alpha.
- No pure black (`0xFF000000`) or pure gray neutrals. Tint neutrals warm or
  cool; compose dark theme explicitly with tonal elevation, never a mechanical
  invert.
- One accent, spent at ≤10% on primary action, selection, and status only.
  Never decoration, never scattered dots.
- Cards use 12–16dp radii. `StadiumBorder` is for chips and small controls,
  not cards or sheets.
- No overline kicker above every heading; no decorative `01/02/03` section
  numbers (real step indicators excepted). Let type hierarchy speak.
- No `ShaderMask` gradient text — emphasize with weight and size.
- No gratuitous `BackdropFilter` blur; blur only scrims over real media.
- Status is icon plus label in an M3 semantic role (`errorContainer`, etc.).
  Never a colored side-stripe `Container`, never color alone.
- Icons come from one family (`Icons` / Material Symbols, one weight). Never
  emoji-as-icon `Text`, never monospace-for-vibe (mono is for code/data).
- Prefer M3 controls verbatim (button, chip, switch, dialog, snackbar) over
  reinvented affordances. Inactive states are muted, never full-saturation.
- Android gets M3 navigation (bar/rail), system Back, M3 dialogs and sheets.
  Never transplant Cupertino switches, iOS tabs, or back chevrons.
- The scaffold uses system fonts offline. Choose a branded family for a product reason;
  use shared text roles and the delivery checks in `fonts.md`.

## Motion tokens

- 100–150ms immediate feedback (ripple, switch, checkbox); 150–300ms routine
  state change; 300–500ms route or overlay transition; 500–800ms only for one
  authored focal entrance per screen.
- Arrivals decelerate (`Curves.easeOut` / `fastOutSlowIn`); exits run faster
  than entrances. Never `bounce*` or `elastic*` except a genuinely playful
  brand moment.
- One authored moment per screen, not one fade-rise on every section. Stagger
  only when a list appears as a list, and cap total delay.
- Respect `MediaQuery.disableAnimations`: shorten or cut non-essential motion
  while preserving state feedback. Never remove meaning with the animation.
- Loops are for loaders only. Carousels and auto-advance need pause controls
  and stop offscreen.

## Resilient text and compact UI

- Text reflows at narrow widths, large text scale, and long locales. No
  fixed-height containers around text; containers expand, `maxLines` plus
  ellipsis only where designed.
- Never ellipsis headings, actions, errors, or safety-critical names. Wrap,
  stack, or disclose with an accessible full-value path.
- Long tokens (URLs, IDs) wrap safely (`overflow-wrap` equivalent); never
  `nowrap` a value the user must read in full.
- Chip/tag collections wrap or collapse into an operable `+n` disclosure —
  never a clipped single row. Interactive chips are real controls with visible
  focus and keyboard support; badges carry static state, never action.
- Async counts announce atomically (`3 items in cart` in one live region),
  not a bare number. Cancelled interactions still land on the correct final
  state, focus, and content.
- Forms: visible labels, per-field inline errors, keyboard type matching the
  input, Next/Done chaining, password show/hide, paste and manager friendly.

## Critique checklist (condensed)

Score a screen against these before calling it done:

1. Status visible — loading, progress, confirmation, inline validation.
2. Plain language, logical order, recognizable metaphors.
3. Undo, cancel, back, and escape from every flow.
4. Same words, same results; M3 patterns; coherent type, color, spacing.
5. Destructive actions confirmed; inputs constrained; sensible defaults.
6. Options visible, icons labeled; no icon-only navigation.
7. One primary action plus two to three secondary per screen at most.
8. Errors name the problem and the fix, sit near the source, keep input.
9. Help is findable, contextual, and task-focused.

Walk the primary action as a first-timer (clear in 5 seconds), a power user
(under 60 seconds, batch path), a screen-reader user (order, labels, no
color-only meaning), and a stressed user (empty data, huge data, long text,
RTL, interruption mid-flow, no silent loss).

## Shape before build

For a new surface, confirm a short brief before writing code: job plus
audience, outcome plus proof, direction, scope and anti-goals, states and
ranges, interaction and layout intent, constraints. Never ask aesthetic-lane
questions the brief should decide; assert the likely reading and proceed.
