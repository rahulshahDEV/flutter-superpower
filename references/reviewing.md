# Reviewing Changes (two axes)

Review the diff between `HEAD` and a fixed point (commit, branch, tag, merge-base) on two
independent axes:

- **Standards** — does the code follow this skill's house style?
- **Spec** — does the code do what was actually asked?

Run the two axes as parallel sub-agents so neither pollutes the other, then report both
side by side. Never merge or rerank findings across axes: code can pass one and fail the
other, and the separation is what stops one masking the other.

## Process

1. **Pin the fixed point.** `git rev-parse <ref>` first; capture
   `git diff <ref>...HEAD` and `git log <ref>..HEAD --oneline`. Empty diff or bad ref fails
   here, not inside two sub-agents.
2. **Find the spec.** Issue references in commits → a path the user passed → a spec file
   under `docs/`, `specs/`, `.scratch/`. If none, the Spec agent reports "no spec available".
3. **Spawn both sub-agents in parallel.**
4. **Aggregate** under `## Standards` and `## Spec`, then a one-line summary: findings per
   axis, worst issue per axis. No cross-axis winner.

## Standards axis — house-style checklist

Paste this checklist into the Standards sub-agent (it has no other access):

**Hard violations** (documented rules):
- Layer breach: `core/` importing `features/`; widget calling a data source/Dio directly.
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

Repo docs override this checklist; tooling-enforced rules are skipped (the analyzer already
covers them).

## Spec axis

Paste the diff + spec, then ask for:
- (a) requirements asked for that are missing or partial;
- (b) behaviour in the diff that wasn't asked for (scope creep);
- (c) requirements that look implemented but wrong.

Quote the spec line for every finding. Under 400 words per axis.

## Flutter review extras

- Loading/empty/error/success all handled for every async screen.
- Failure surfaces via snackbar; retry where sensible.
- Skeleton/shimmer mirrors real layout; no double loaders.
- Keyboard: scroll + `viewInsets` handled; CTA reachable.
- Lists use `ListView.builder`/slivers with `const` items.
- New package: is the SDK enough? Is it justified in the PR description?
- Screens stay args-free (router/provider passes args); cubit fetches.
- Route wired last and reachable; deep-link fallback present when parameterized.
