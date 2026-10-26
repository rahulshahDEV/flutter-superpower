# Ponytail — Scope Discipline (built into this skill)

Project conventions and explicit requirements govern structure; **scope is deliberate**. Apply this to every task in this skill.
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

The smallest complete change includes affected callers, fixtures, exports, DI, configuration
and tests. Trace those before minimizing the diff. Prefer a readable few lines over a dense
one-liner, and retain error/validation/lifecycle behavior when moving or merging code.
Use boundary-design.md before deleting an interface that may own useful policy.

## Flutter rules

- **Local state before global state.** `setState`/`ValueNotifier` for toggles, controllers, expansion, scroll — a cubit is for async/shared/navigation-surviving state only (see `state-and-di.md § Local UI state`).
- **No wrapper widgets that just forward params.** If `MyCard` only passes props to `Card`, delete it. Extract when it adds layout, defaults, or logic.
- **Add a seam for a reason.** A single-implementation interface can provide a useful plugin, repository, test or lifecycle boundary. Skip interfaces that only duplicate a concrete API without that benefit.
- **No speculative features:** pagination, caching, offline mode, analytics events, feature flags, settings screens — only when asked or when the API forces it.
- **Fewest files.** Use a private widget for a meaningful layout/rebuild responsibility; a tiny pure helper need not become a new file. A widget file beats a folder.
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
| New package for an already-covered effect/action | SDK for refresh/date/fade; existing sharing plugin/native bridge for sharing |
| `MyCustomButton` wrapping `KButton` to change one padding | pass the param, or add it to `KButton` |
| Extra service/interface for a simple GET | keep the app's repository/use-case seam; add no unused layer |
| Global provider for screen-only state | create in route builder |
| Custom JSON parsing package for 3 fields | `jsonDecode` + `as`/patterns |
| 5 files for a static info screen | 1 file |
| Duplicate listeners/rebuilds for the same state effect | choose `BlocConsumer` when both concerns belong together; separate scoped listeners/builders when ownership or rebuild filtering differs |
| Animated splash choreography nobody asked for | static logo + route |

## Output

Keep scope notes brief. Preserve the Implemented / Files changed / Verification / Not verified
evidence required by senior-mode.md; brevity never removes test results or limitations.

## Intensity

| Level | Change |
|---|---|
| **lite** | Build what's asked; name the lazier alternative in one line. |
| **full** | Ladder enforced. Project components, then SDK/reuse. Smallest complete, readable change. Default. |
| **ultra** | YAGNI extremist. Deletion before addition. Ship the one-liner and challenge the requirement. |

Example: "Add a custom animated loading button."
- lite: reuse KButton loading behavior; report the actual checks and remaining gaps.
- full: "`KButton(isLoading: isLoading)` — skipped custom widget, add when the design diverges."
- ultra: "No new button. `KButton(isLoading:)` exists; a custom one is a maintenance tax with a spinner."
