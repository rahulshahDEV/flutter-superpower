# Reviewing Changes (two axes)

Review the requested working tree, staged changes, commit or branch range on two independent
axes. Pin committed endpoints; preserve staged/unstaged distinctions for local work.

- **Standards** — does the code follow the profiled project conventions and applicable defaults?
- **Spec** — does the code do what was actually asked?

When the session permits sub-agents, run the two axes concurrently as separate reviewers so
neither pollutes the other. Otherwise, run them as separate passes and keep their
findings independent. Never merge or rerank findings across axes: code can pass one and fail
the other. See `agent-delegation.md` for task sizing, evidence, and integration rules.

## Process

1. **Select the actual change.** Use the target the user named. With no target, inspect
   `git status --short`: review local changes if present, otherwise the last commit.
   Staged: `git diff --cached`; unstaged: `git diff`; combined tracked changes:
   `git diff HEAD`. Inspect relevant untracked source files separately; diff omits them.
   For a branch, resolve the base and head with `git rev-parse`, then inspect
   `git diff <base>...<head>` and `git log <base>..<head> --oneline`. For a single commit,
   use `git show <commit>` (choose the intended parent for a merge). Resolve bad refs or
   an unexpectedly empty diff before review. Don't silently omit uncommitted work.
2. **Find the spec.** Start with the user's request and supplied acceptance/contract; follow
   their linked issue or file, then relevant repository specs under `docs/` or `specs/`.
   Issue references in commits may add context. If none exists, the Spec reviewer reports
   "no spec available" instead of inventing requirements.
3. **Read the connected flow.** Inspect changed definitions, their callers/callees, contracts,
   DI, fixtures and tests. Trace input → policy → effect → user result. Search all callers
   when a signature or behavior changes, including unchanged files; use boundary-design.md
   for shared contracts. Judge concurrency and growth against the app's actual expected use.
4. **Review both axes independently.** Dispatch one Standards reviewer and one Spec reviewer
   in parallel when permitted. Give each only the material that axis needs.
5. **Aggregate** under `## Standards` and `## Spec`, then a one-line summary: findings per
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

## Make findings actionable

Prioritize correctness, data/security/lifecycle risk and missing acceptance before style or
diff size. Cite a precise location, triggering input/state, resulting failure, and a feasible
correction. Separate observed defects from hypotheses needing a check. Name missing runtime
evidence without asserting the app fails. A smell is a prompt to investigate, not a finding
until it has a concrete cost or violates an applicable convention. Avoid speculative scale
requirements, preference-only rewrites, duplicate reports and invented spec requirements.

## Flutter review extras

- Loading/empty/error/success all handled for every async screen.
- Failure feedback matches context (inline content recovery or transient action message); no duplicate announcements.
- Skeleton/shimmer mirrors real layout; no double loaders.
- Keyboard: scroll + `viewInsets` handled; CTA reachable.
- Lists use `ListView.builder`/slivers with `const` items.
- New package: is the SDK enough? Is it justified in the PR description?
- Screens stay args-free (router/provider passes args); cubit fetches.
- Route wired last and reachable; deep-link fallback present when parameterized.
