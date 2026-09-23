# Ponytail — Scope Discipline (built into this skill)

Structure is non-negotiable; **scope is lazy**. Apply this to every task in this skill.
Lazy = efficient, not careless. The best widget tree is the one never built.

## The Flutter ladder

Stop at the first rung that holds:

1. **Does this need to exist?** Speculative screen/flag/config = skip it, say so in one line.
2. **Already in this codebase?** `core/widgets/` (`KButton`, `KTextField`, `ImageRenderer`, empty/error/loading, shimmer, snackbars), `core/utils/`, `core/extensions/` — reuse first. Search before writing. Re-implementing what exists a few files over is the #1 Flutter slop.
3. **Flutter/Material SDK does it?** `showDatePicker` over a date package, `AnimatedSwitcher`/`AnimatedContainer` over an animation package, `Hero`, `Dismissible`, `RefreshIndicator`, `SliverAppBar`, `SwitchListTile`, `showModalBottomSheet`, `Form`+`TextFormField` validators. Search the SDK before pub.dev.
4. **Platform feature covers it?** Native keyboard input type, `MediaQuery`, `SafeArea`, system share sheet.
5. **Already-installed dependency?** Use it — never add a new package for what a few lines can do.
6. **Can it be one widget or one line?** One line. `const Text(...)`, a getter, a `switch` expression.
7. **Only then:** the minimum working widget.

The ladder runs after understanding the screen, not instead of it. Read the existing
screen + its cubit first, trace the data flow, then climb.

## Flutter rules

- **Local state before global state.** `setState`/`ValueNotifier` for toggles, controllers, expansion, scroll — a cubit is for async/shared/navigation-surviving state only (see `state-and-di.md § Local UI state`).
- **No wrapper widgets that just forward params.** If `MyCard` only passes props to `Card`, delete it. Extract when it adds layout, defaults, or logic.
- **No abstraction with one implementation.** The house-style seam (repo/use case) is required structure; a *new* interface/factory/generic over one concrete class is not.
- **No speculative features:** pagination, caching, offline mode, analytics events, feature flags, settings screens — only when asked or when the API forces it.
- **Fewest files.** A private `_buildSection()` method beats a new widget file. A widget file beats a folder.
- **`const` everywhere it compiles; `ListView.builder`/`SliverList` for lists; `RepaintBoundary` only with evidence.**
- **No new package if the SDK covers it.** If a package is genuinely needed, the smallest maintained one, and say why in one line.
- **No `!`, no `dynamic`, no `late` as a state-management tool.**
- **One check per non-trivial logic path** (parser, validator, state machine): a small `test/..._test.dart`. Trivial layout needs no test.
- Mark deliberate corners with a `// ponytail:` comment naming the ceiling and upgrade path (e.g. `// ponytail: client-side filter, server-side when list > 1k`).

## House-style interaction

- Requested structure is not over-engineering — if the user asks for the house style, build the layers, no re-arguing.
- Within a feature, still apply the ladder: no extra cubits, endpoints, packages, or widgets the feature doesn't use.
- Never simplify away: input validation, error handling on network calls, accessibility (`Semantics`, tap target ≥ 48dp), security, or anything explicitly requested.

## Anti-patterns (instant rollback)

| Smell | Lazy fix |
|---|---|
| Cubit for a counter/checkbox/tab | `setState` / `ValueNotifier` |
| New package for pull-to-refresh, date pick, share, fade | SDK: `RefreshIndicator`, `showDatePicker`, `Share.share`, `AnimatedOpacity` |
| `MyCustomButton` wrapping `KButton` to change one padding | pass the param, or add it to `KButton` |
| Repository + use case + service for one GET | repository only; use case when logic/params exist |
| Global provider for screen-only state | create in route builder |
| Custom JSON parsing package for 3 fields | `jsonDecode` + `as`/patterns |
| 5 files for a static info screen | 1 file |
| `BlocListener` + `BlocBuilder` + `BlocConsumer` all on one page | one `BlocConsumer` |
| Animated splash choreography nobody asked for | static logo + route |

## Output

Code first. Then at most three short lines: what was skipped, when to add it.
`[code] → skipped: [X], add when [Y].` No design essays.

## Intensity

| Level | Change |
|---|---|
| **lite** | Build what's asked; name the lazier alternative in one line. |
| **full** | Ladder enforced. SDK and reuse first. Shortest diff. Default. |
| **ultra** | YAGNI extremist. Deletion before addition. Ship the one-liner and challenge the requirement. |

Example: "Add a custom animated loading button."
- lite: "Done. FYI: `KButton(isLoading: true)` already animates this."
- full: "`KButton(isLoading: isLoading)` — skipped custom widget, add when the design diverges."
- ultra: "No new button. `KButton(isLoading:)` exists; a custom one is a maintenance tax with a spinner."
