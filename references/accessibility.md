# Accessibility

Accessibility is part of the definition of done for any user-facing change, not polish.
Integrate it into the existing design system — never build a parallel "accessible" widget set.

## Semantics

- Icon-only controls need a label: `IconButton(tooltip: ...)` or `Semantics(label: 'Close')`.
- Wrap compound rows so screen readers read them as one unit (`MergeSemantics`).
- Mark purely decorative images `excludeFromSemantics: true` (and prefer `ImageRenderer`'s
  existing behavior).
- Buttons expose their role: use real buttons (`KButton`, `FilledButton`), not `GestureDetector`
  on a `Container`.
- Async results (form errors, saved toast) should be announced: use the app's snackbar
  (already announced) or `Semantics(liveRegion: true)` for inline updates.
- Don't duplicate labels — if the visible text says it, the semantics shouldn't repeat it.

## Touch targets & interaction

- Minimum 48×48dp (Material) / 44×44pt (iOS). `KButton` is 52 high — keep new controls in that range.
- Space adjacent tappable items ≥8dp apart.
- Long-press/slide-only actions need a visible alternative.

## Text scaling

- Test at 1.3×, 1.5×, and 2.0× text scale.
- No fixed-height containers around text (`SizedBox(height:)` around multi-line text overflows).
- Prefer `maxLines` + `overflow: TextOverflow.ellipsis` over clipping.
- Avoid `TextScaler.noScaling` unless the layout genuinely cannot scale (and document why).

## Contrast

- Body text ≥ 4.5:1 against its background; large text (≥18pt bold / 24pt) ≥ 3:1.
- Check semantic pairs (`AppColors.textSecondary` on `background`, white on `primary`) —
  a token that looks fine on one surface can fail on another.
- Never encode meaning by color alone (error red + message, not just red border).

## Focus & keyboard

- Logical focus order (`FocusTraversalOrder`/widget order) on forms.
- `textInputAction: TextInputAction.next` chains fields; `done` submits the last one.
- Desktop/web: visible focus ring (don't `FocusNode(canRequestFocus: false)` to hide it).
- Escape/back closes dialogs and sheets.

## Motion

- Respect `MediaQuery.disableAnimations`; skip or shorten non-essential animations.
- No flashing content; avoid parallax-only affordances.

## Per-screen check

```
[ ] Every icon-only control has a label
[ ] Tap targets ≥48dp
[ ] Screen reader pass: order + meaning make sense (TalkBack / VoiceOver)
[ ] Layout survives 2.0× text scale (no overflow stripes)
[ ] Contrast passes for text and state colors
[ ] Keyboard: fields chain, last field submits, focus visible
[ ] Errors are announced and tied to their field
```

Audit mechanical signals (missing labels on `IconButton`s, small tap targets) are a starting
point — the screen-reader pass is the real test.
