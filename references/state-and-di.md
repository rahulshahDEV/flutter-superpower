# State Ownership and Dependency Injection

Use the runnable feature templates as the default implementation: separate Cubit/state files,
constructor injection, safe emission, explicit Either folding, and stale-result protection.
Existing apps retain their state style and provider conventions.

## Basic fetch states

| Lifecycle | Sealed/Equatable (new-app default) | Freezed (existing/field-heavy apps) |
|---|---|---|
| Before first request | Initial | initial |
| First request | Loading | loading |
| Usable content | Success | loaded |
| No usable content after failure | Failure | failed |

These are basic fetch variants, not an exhaustive state machine for every flow. Add explicit
refresh/pagination/mutation status while retaining useful content. Model mutually exclusive
statuses with a variant/enum rather than contradictory booleans. Keep failure/retry metadata
with the affected operation. A failed row update should not replace an entire loaded page.

Keep state and Cubit in separate files under presentation/cubit/<flow>/. Colocate sealed
variants in the state file. Freezed uses its generated part; never edit generated output.
Use Equatable fields that fully describe state, including operation status/error where needed.
Snapshot collections at state boundaries; final prevents reassignment, not list mutation.
The scaffold's Success constructor uses List.unmodifiable to isolate input and consumers.

## Cubit contract

Every Cubit extends SafeCubit and emits through safeEmit. SafeCubit prevents emission after
close; it does not cancel work, prevent duplicates, or reject out-of-order results by itself.

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SafeCubit<State> extends Cubit<State> {
  SafeCubit(super.initialState);

  void safeEmit(State next) {
    if (!isClosed) emit(next);
  }
}
```

- Inject use cases/repository contracts through constructors; no hidden getIt lookups.
- Keep BuildContext, navigation, snackbars, and editing/focus controllers in presentation UI.
- Fold Either into state at the owner. Keep failures typed and user copy safe.
- Validate before issuing a write; prevent duplicate submissions and define idempotency.
- For replaceable reads (search/filter), increment a request ID and ignore stale results on
  BOTH success and failure paths. Cancel underlying requests where useful, but still guard
  completion. Writes may need serialization instead; don't discard their result blindly.
- Define retry/cancel semantics. A timeout does not necessarily cancel the server operation.
- Close owned subscriptions/timers and stop accepting new operations after disposal.
- Keep one flow per Cubit; split unrelated responsibilities rather than growing a global
  screen controller. Don't split solely to satisfy an arbitrary line count.

Use the templates for the full data → repository → use case → Cubit contract. Domain logic
and transport parsing never move into build methods to avoid adding a state field.

## Provider ownership: choose exactly one arrangement

**Screen-owned:** a route creates the screen; its BlocProvider(create:) resolves a fresh
factory Cubit and calls load(), then builds a provider-free private view.

**Route/wrapper-owned:** the router parses IDs/typed extras and builds a provider wrapper.
That wrapper resolves a fresh factory Cubit, calls init(parsedArgs), and builds a provider-free
screen/view. In this arrangement the child MUST NOT create another provider for that Cubit.
An inner provider would shadow the initialized outer instance and fetch twice.

Use load() when no arguments are required and init(args) when arguments are required; don't
call both for the same initialization. Pass a few fields directly, or a typed route-data
object when it carries a meaningful group. Parse routing input once in the router.

BlocProvider(create:) owns and closes the instance it creates. BlocProvider.value borrows
an existing instance; its original owner must close it. Do not return an app singleton from
a route-owned create: callback that will dispose it when that route leaves.
If route arguments can change without destroying the provider, explicitly update the existing
flow or key/recreate its owner; don't assume create: reruns whenever a field changes.

## Rendering and effects

Builders render state; listeners perform navigation/toasts/dialogs. Avoid side effects in
build(), listeners registered repeatedly, or navigation from Cubits/repositories.
Use listenWhen or an explicit operation/result identity for one-time outcomes; repeated
unrelated rebuilds must not repeat a saved toast or navigation. Keep no-content failures
inline with retry; use a snackbar when an action fails while usable content remains. Don't
announce the same error twice. Prefer BlocSelector/buildWhen for measured broad rebuilds,
not as a workaround for incorrect state equality.

Only truly app-wide state belongs at the root: session/theme/cart when required. Route-local
state belongs under its provider so it has a clear lifetime and can be tested in isolation.

## Local UI state

Controllers, focus, animation, obscure-password, expansion and local selection belong in
StatefulWidget/setState or ValueNotifier. Dispose them in their creator. A static/purely
local screen needs no Cubit, repository, use case, or empty data/domain directories.
Use a Cubit for asynchronous state shared by the flow or a meaningful state machine, not
for every boolean. Prefer explicit input props/callbacks for leaf components.

## DI registration

| Responsibility | Annotation/owner |
|---|---|
| Per-screen factory Cubit | @injectable; BlocProvider owns disposal |
| App-wide Cubit | @Singleton(); app/DI owns disposal |
| Repository implementation | @LazySingleton(as: RepositoryContract) |
| Data-source implementation | @LazySingleton(as: DataSourceContract) |
| Use case | @lazySingleton |
| Stateful infrastructure | @lazySingleton with explicit disposal |
| Router composition | @singleton |
| Plugins/preferences | @module, @preResolve only when startup must await |

An implementation with no interface may use @lazySingleton. Never register the same client
using both a class annotation and a module factory. Constructor dependencies must be
resolvable before consumers. Prefer required initialization over swallowed GetIt errors.

Keep getIt resolution at composition boundaries: bootstrap, route/provider creation, and
app-wide providers. Business logic and leaf widget build methods don't locate services.
Await configureDependencies before resolving anything. See app-bootstrap.md for required
versus optional startup work and opt-in Firebase sequencing.

Use @disposeMethod for DI-owned service cleanup where supported, and test reset/teardown.
Don't reset a live container under active screens. Retry/bootstrap or tests must dispose
partial registrations and subscriptions before creating replacements.

Regenerate with `fdev gen` (fallback
`dart run build_runner build --delete-conflicting-outputs`) after registration/state annotations
change; never hand-edit injection.config.dart or generated Freezed files.

## Verification

Test success/failure folding, stale result order, duplicate writes, refresh failure preserving
content, immutable snapshots, and disposal according to the flow's risks. A provider test
should establish one instance/one initial fetch and the intended close behavior. UI effects
need a listener-level check when incorrect repetition or navigation is possible. Follow
`testing.md`; test observable behavior rather than matching private implementation names.
