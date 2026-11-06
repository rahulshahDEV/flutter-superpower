# Feature Contracts and Shared Business Modules

Use when one feature needs another capability or several apps share business behavior.
Keep the existing project organization; a small app does not need packages or an event bus
just to look modular. Layers describe responsibilities, not a required number of folders.

## Choose the narrowest useful boundary

| Need | Boundary |
|---|---|
| Open another feature's screen | Route ID/typed input through application navigation composition |
| Checkout needs current cart/pricing policy | Cart's public domain contract, injected into checkout orchestration |
| Several features share identity/authorization rules | Explicit shared domain capability/module with one owner |
| Reusable transport, clock or storage adapter | Feature-independent infrastructure in `core/` |
| Several applications share a stable capability | A package with explicit exports and independently runnable checks |

Keep business concepts with their owning capability rather than relocating them into core
merely because a second feature uses them. `core/` must not become an unowned collection of
cart, order and identity policies. Shared UI tokens/widgets and domain rules have different
owners and dependency needs.

## Dependency direction and public surface

A feature may consume another capability's deliberately public domain API. It must not
import the other feature's private data sources, repository implementation, controller or
widgets to reach its state. Expose only the contract/value types needed by consumers; keep
state-management, transport and plugin types behind that boundary. Application composition
chooses implementations and wires them into constructors.

For a multi-capability flow, place orchestration with the capability responsible for the
outcome or in an application flow module. For example, checkout can consume cart snapshots
and an order-placement contract without either cart or orders importing checkout. Assign
ownership of cross-step validation, compensation and partial failure explicitly; don't put
that sequence in every screen or hide it in a generic utility.

Document a small dependency graph before adding a cross-feature edge. If A needs B and B
already needs A, do not fix the cycle with a barrel, service locator or global event bus.
Move the shared stable contract to a lower module, invert a dependency with an injected
interface, or move orchestration above both. Use direct typed calls for request/result;
notifications/events are for real asynchronous facts with defined delivery/lifetime rules.

A small public export file is allowed when it deliberately defines a capability's supported
API. It is different from a barrel exporting every internal file. Consumers import that API;
repository-local lint/import checks or package boundaries can enforce the agreement when
worth their maintenance cost. No mandatory monorepo tool or package split.

## Use cases earn their seam

A use case is appropriate for shared orchestration, business validation, transaction policy
or a useful independent testing boundary. A simple read may call a repository contract from
its state owner directly if that is the chosen project convention. The Cubit scaffold keeps
its use-case example; don't add forwarding classes solely because an operation is async.
Keep business invariants in a reusable domain/application boundary, not only a UI callback.

## Changing a public contract

1. Find all callers, DI/provider/binding registrations, fakes and serialized representations.
2. Define the behavior and compatibility window: units, error outcomes, ownership, ordering,
   cancellation and session scope are contract details too.
3. Prefer an additive change or an explicit adapter when consumers cannot migrate together.
   Remove the old surface only after all known consumers have moved.
4. Test the contract at its owning module and test important consuming outcomes. Do not
   bypass the real orchestration with mocks at every intermediate method.
5. Check the final dependency graph for cycles and accidental internal imports. If multiple
   packages/apps are affected, analyze/test each affected consumer, not just the edited one.

Do not claim architectural isolation from folders alone. A contract test demonstrates
behavior; an import/dependency check demonstrates allowed edges. Neither proves the other.

Related: `architecture.md`, `boundary-design.md`, `task-planning.md`.
The optional domain/use-case split also aligns with
[Flutter's architecture guide](https://docs.flutter.dev/app-architecture/guide); follow the
application's actual needs rather than applying every layer to every feature.
