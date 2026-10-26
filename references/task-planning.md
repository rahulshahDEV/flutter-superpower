# Plan from Observable Outcomes

Use for a feature spanning several boundaries, an ambiguous behavior change, or a migration.
A small known fix needs only a brief acceptance statement and a regression check. Keep the
plan in the conversation unless its size or a requested handoff justifies a local document.

## Before choosing files

Read the repository instructions, relevant ADRs/glossary if present, and the closest working
feature. Follow the app's vocabulary and architecture. Inspect available contracts rather
than asking the user to explain code that is already accessible.

Write down:

- **Outcome:** what the user can do after the change and what currently prevents it.
- **Acceptance:** observable input/action/result, including the important failure/recovery.
- **Scope:** affected callers, fixtures, routes, DI, native configuration and persisted data;
  distinguish necessary supporting work from additional product features.
- **Decisions:** existing public interfaces, state/lifetime owner, backend/platform contract,
  and any assumption that could change the solution.
- **Checks:** the boundary each assertion exercises and the limits of that evidence.

Resolve routine choices from project conventions. Ask only about an unresolved product or
contract decision that materially changes behavior; make useful progress while it is pending.
Do not add issue-tracker setup, publish tickets, or require approval of each test boundary
merely to implement an already authorized feature.

## Build a runnable slice

Group work by a user outcome that can be exercised through the app's layers. Within that
slice, follow architecture.md's dependency/build order; do not bypass the repository/use-case
seam to get an early screenshot. One slice may need several files.

Example for requested paginated order history:

| Slice | Observable acceptance | Boundary/check |
|---|---|---|
| First page | Opening history shows returned orders; no orders shows the empty view | Repository parsing, Cubit result, widget state |
| Recovery | A failed load exposes retry; retry displays orders | Controlled failure/success through the same public operation |
| Next page | Repeated scroll triggers do not duplicate a request or discard existing orders | Controlled pending response and visible list/footer |

Implement one important assertion and its minimal complete behavior, run the focused check,
then take the next slice. Avoid generating all imagined tests before validating any path.
When changing existing behavior, preserve unrelated public contracts and input/state.

## Dependencies and checkpoints

For substantial work, mark which slices depend on a contract/configuration decision and which
are independently runnable. Establish shared contracts before consumers; integrate and verify
each completed slice before building on it. Parallel work follows agent-delegation.md only
when the session permits it and ownership can be separated safely.

Use a short checkpoint with: completed outcome, changed contract, evidence, unresolved
decision and next executable step. Resume by checking the actual worktree/artifacts against
that checkpoint. A checked plan item or an implementer's report is not verification.

## Close the plan

Map each acceptance item to its test or observed runtime result. Record unavailable device,
backend or native checks explicitly. Remove speculative scaffolding left by discarded ideas.
Review the integrated diff, then run the normal format → conditional codegen → analyze → test
gate. Prefer `fdev gen`; raw fallback:
`dart run build_runner build --delete-conflicting-outputs`.

Source ideas adapted for Flutter from
[Matt Pocock's engineering skills](https://github.com/mattpocock/skills/tree/5beb35b040e3de97e54fa9e386d7e42d15c295c2/skills/engineering),
especially to-spec, implement-spec and tdd. Their publishing and approval workflows are not
prerequisites for this guide.
