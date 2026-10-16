---
name: flutter-ui-builder
description: Build or extend Flutter screens using existing Material 3 design tokens, responsive layouts, themes and accessibility, with meaningful widget tests.
---

# flutter-ui-builder

Work from the factory root. Inspect `AGENTS.md`, the app's `app.yaml`, registry,
existing implementation and working tree first. Reuse existing settings; make the
smallest changes and never replace important configuration without reviewing its
diff. Ask only for essential missing identity or account information. Run relevant
checks, report failures with redacted evidence, and distinguish completed, blocked,
and unverified work. Never fabricate build or publishing success.

Read [shared operating rules](../../../docs/skills.md) and run
`python3 automation/scripts/factory.py --help` before using unfamiliar options.

Inspect the closest screen, routing, widgets, themes and tests before editing.
Read [architecture](../../../docs/architecture.md). Reuse `packages/ui_kit` and
existing app components; do not rewrite screens beyond the request.

- Follow the app's established house style: feature-first layers, SafeCubit for
  async/state-machine flows, separate sealed Initial/Loading/Success/Failure
  states, GetIt/Injectable, and existing GoRouter typed route-data helpers.
  Mirror an existing freezed app's initial/loading/loaded/failed variants.
- Keep controllers/focus/navigation in UI; use constructor injection for business
  logic. Use `@injectable` Cubits and `@LazySingleton(as: RepositoryInterface)`
  implementations when adding those layers.
- Use centralized strings, semantic colors, typography and ScreenUtil spacing
  tokens. Support light/dark themes, available-width layouts, keyboard insets,
  text scaling, semantics, focus order and accessible touch targets.
- Refuse the standard tells: nested cards, shadow-plus-border on one surface,
  gray text on colored fills, pure black/gray neutrals, emoji-as-icon,
  gradient text, gratuitous blur, color-only status, transplanted Cupertino
  controls. One accent on action/selection/status only; motion 100-500ms with
  decelerating easings, never bounce/elastic, honoring reduced motion.
- Cover requested loading/error/empty/success behavior; do not add speculative
  abstractions. Preserve platform back navigation and familiar controls.
- Add widget tests for meaningful behavior, responsive overflow or accessibility
  regressions, using hand-written fakes rather than implementation-mirroring tests.

Run formatting, conditional codegen (`fdev gen`, raw fallback
`dart run build_runner build --delete-conflicting-outputs`), analysis and tests,
in that order. `python3 automation/scripts/factory.py test battery_analyzer`
runs the factory's app verification. Inspect the dev screen on a device when
available and explicitly report visual checks not performed.

