# Reviewing Changes (two axes)

Review the diff between `HEAD` and a fixed point (commit, branch, tag, merge-base) on two
independent axes:

- **Standards** — does the code follow the profiled project conventions and applicable defaults?
- **Spec** — does the code do what was actually asked?

When the editor provides sub-agents, run the two axes concurrently as separate reviewers so
neither pollutes the other. If it does not, run them as separate passes and keep their
findings independent. Never merge or rerank findings across axes: code can pass one and fail
the other. See `agent-delegation.md` for task sizing, evidence, and integration rules.

## Process

1. **Pin the fixed point.** `git rev-parse <ref>` first; capture
   `git diff <ref>...HEAD` and `git log <ref>..HEAD --oneline`. Resolve an empty diff or bad
   ref before dispatching reviewers.
2. **Find the spec.** Issue references in commits → a path the user passed → a spec file
   under `docs/`, `specs/`, `.scratch/`. If none, the Spec reviewer reports "no spec available".
3. **Review both axes independently.** Dispatch one Standards reviewer and one Spec reviewer
   in parallel when sub-agents are available. Give each only the material that axis needs.
4. **Aggregate** under `## Standards` and `## Spec`, then a one-line summary: findings per
   axis, worst issue per axis. The lead reviewer checks cited hunks before reporting; no
   cross-axis winner.

## Standards axis — house-style checklist

Give this checklist to the Standards reviewer, without the Spec reviewer's conclusions:

Profile the existing app first, including consistent conventions not written in repository
rules. The following defaults apply to greenfield work or explicitly adopted house style;
existing Riverpod/Provider/navigation conventions are not migration findings by themselves.
Correctness, lifecycle safety and the user's scope still apply in every project.

**Violations of the applicable conventions**:
- Layer breach: `core/` importing `features/` outside route assembly; widget calling a data source/Dio directly.
- State: `Provider`/Riverpod/GetX; raw `emit` instead of `safeEmit`; cubit holding
  `BuildContext`/navigation/controllers; business logic in a widget.
- DI: `getIt` inside `build`; unregistered type; hand-edited `injection.config.dart`.
- Routing: hardcoded route strings; `Navigator.push`/raw `context.go`; `extra as X`.
- Constants: inline user-visible string, hex color, route path, or raw pixel size.
- Generated files (`.g.dart`, `.freezed.dart`, `injection.config.dart`) modified by hand.
- `!` non-null assertions, `dynamic`, `late` as a crutch; `print()` instead of `AppLogger`.
- No test for a new non-trivial logic path.

**Judgement calls** (name it, quote the hunk):
- **Mysterious name** — doesn't reveal what it holds/does → rename or redesign.
- **Duplicated code** — same logic shape in more than one hunk → extract once.
- **Feature envy** — a method reaching into another object's data more than its own → move it.
- **Data clumps** — the same fields/params travel together → bundle into a type.
- **Primitive obsession** — a primitive standing in for a domain concept → small type.
- **Repeated switches** — the same switch on the same type recurs → one shared mapping.
- **Shotgun surgery** — one logical change scatters edits across files → gather them.
- **Divergent change** — one file edited for unrelated reasons → split by reason.
- **Speculative generality** — hooks/params for needs nobody has → delete, inline back.
- **Message chains** — long `a.b().c().d()` navigation → hide behind one method.
- **Middle man** — a class/function that only delegates → cut it.
- **Refused bequest** — a subclass ignoring most of what it inherits → composition instead.

Project conventions override conflicting defaults. Read relevant analyzer/test output and
avoid duplicate findings; a tooling check is evidence only when it actually ran.

## Spec axis

Paste the diff + spec, then ask for:
- (a) requirements asked for that are missing or partial;
- (b) behaviour in the diff that wasn't asked for (scope creep);
- (c) requirements that look implemented but wrong.

Quote the spec line for every finding. Under 400 words per axis.

## Flutter review extras

- Loading/empty/error/success all handled for every async screen.
- Failure feedback matches context (inline content recovery or transient action message); no duplicate announcements.
- Skeleton/shimmer mirrors real layout; no double loaders.
- Keyboard: scroll + `viewInsets` handled; CTA reachable.
- Lists use `ListView.builder`/slivers with `const` items.
- New package: is the SDK enough? Is it justified in the PR description?
- Screens stay args-free (router/provider passes args); cubit fetches.
- Route wired last and reachable; deep-link fallback present when parameterized.
