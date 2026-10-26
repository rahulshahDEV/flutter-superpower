# Useful Interfaces and Safe Simplification

Use when a feature leaks policy across callers, a shared contract changes, or a refactor
claims to remove unnecessary layers. Keep architecture.md and the app's conventions.

## Judge what the caller must know

An interface includes more than method signatures: required ordering, failure cases,
configuration, ownership, cancellation and data invariants are also part of its contract.
Prefer a small public operation that hides coherent policy over callers coordinating many
low-level operations. Hiding complexity means owning and testing it, not swallowing errors.

For example, an upload operation can own size validation, presigned URL acquisition, upload
and confirmation. UI should express upload intent and render its result; it should not
reimplement that sequence in every screen. Keep transport in data and business policy in
the domain/use-case seam according to the existing feature, with typed failures crossing out.

## Decide whether a seam earns its place

| Boundary | Reason to preserve or add it | Evidence to seek |
|---|---|---|
| Repository/use case | Domain contract, shared policy, failure mapping, app convention | Callers depend on stable domain behavior |
| Plugin/HTTP/storage adapter | External lifetime, transport, nondeterminism or platform variation | Real implementation plus a controlled test substitute |
| Stateful coordinator | Serialization, cancellation, cache consistency or resource ownership | One owner enforces an invariant across calls |
| Private pure helper | A calculation or parsing rule has a clear input/output | Known worked examples, malformed inputs |
| Forwarding wrapper | Consistent styling, ownership or intentional compatibility | Actual responsibility beyond renamed parameters |

A single production implementation can justify an interface. Do not require a second
production backend, nor invent one. Conversely, a hypothetical test double doesn't justify
an interface around every helper. Inject dependencies at real I/O/lifetime boundaries and
keep pure computation directly testable. Avoid GetIt calls hidden inside domain operations.

Apply a deletion thought experiment: if removing a wrapper eliminates only forwarding, it
may be redundant; if callers inherit validation, retry ordering or cleanup, it owns useful
complexity. Respect intentional compatibility and house use-case boundaries even when small.

## Refactor without weakening the contract

1. Read definitions, callers, implementations, overrides, tests, DI and stored/wire formats.
   Search the contract name across the relevant app, not only the changed directory.
2. State the invariant and current failure/lifetime behavior before moving code. Define the
   public observation that would reveal a broken refactor.
3. Keep domain entities and `FutureEither<T>` contracts where the app uses them. Don't move
   Dio responses, plugin handles or BuildContext into the domain to reduce file count.
4. Consolidate duplicated policy under its owner; update every affected caller/fixture and
   registration. Preserve cancellation, validation, error mapping and immutable snapshots.
5. Keep checks that establish distinct contracts. Retire a redundant internal test only
   after public-boundary checks demonstrably cover its useful failure mode.

For a shared mutation, trace double submission, partial failure and navigation/disposal in
addition to the happy path. Tests may assert a write/request count when uniqueness is itself
the required observable contract; counting every internal method call couples tests to wiring.
For example, assert that two taps produce one external write and one visible confirmation.

## Compare alternatives only when the choice matters

For a costly boundary decision, sketch the current approach and one plausible alternative.
Compare what callers must know, where changes concentrate, state/lifetime ownership, failure
handling and how to test it. Choose the smallest complete change consistent with the project.
Routine leaf fixes do not need an architecture proposal or a migration.

Source ideas:
[Matt Pocock's codebase-design](https://github.com/mattpocock/skills/tree/5beb35b040e3de97e54fa9e386d7e42d15c295c2/skills/engineering/codebase-design)
and [Ponytail](https://github.com/DietrichGebert/ponytail/tree/09c434ab73ca43761c5d8b0c5d341926c2fba710/skills/ponytail).
These are decision criteria adapted to the existing Flutter layers, not a replacement stack.
