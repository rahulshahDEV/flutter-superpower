# State Stack Selection

Choose before adding packages, scaffolding or planning files:

1. Honor an explicit user choice, including in a new app.
2. Otherwise inspect pubspec/lockfile, bootstrap, nearest feature, route ownership and tests.
   Preserve the working stack, including existing Bloc events or older Riverpod APIs.
3. With no preference or precedent, use the tested Cubit/GetIt default.
4. An explicit migration needs runnable stages; never mix competing owners for one state.

| Stack | Presentation structure per feature | Composition and lifetime | Read next |
|---|---|---|---|
| Bloc/Cubit | `cubit/<flow>/<flow>_cubit.dart`, `<flow>_state.dart` | GetIt/Injectable creates; BlocProvider closes | `state-and-di.md` |
| Riverpod | `providers/<feature>_providers.dart`, `notifiers/<flow>_notifier.dart`, optional `state/<flow>_state.dart` | ProviderScope and provider graph; explicit disposal/cache policy | `riverpod.md` |
| Provider | `viewmodels/<flow>_view_model.dart`, `state/<flow>_state.dart`, optional `providers/<feature>_providers.dart` | Provider tree creates/disposes; constructor dependencies | `provider.md` |
| GetX | `controllers/<flow>_controller.dart`, `state/<flow>_state.dart`, `bindings/<feature>_binding.dart` | Route binding creates; route owner deletes | `getx.md` |

Each keeps `features/<feature>/{data,domain,presentation}` plus presentation `pages/`
and `widgets/`. Omit layers with no useful responsibility. `core/` holds shared infrastructure;
feature composition stays feature-local and the app root assembles dependencies/routes.
Domain has no Flutter, Ref, ChangeNotifier, Get or BuildContext dependency. Data sources
throw typed exceptions; repositories translate them into the app's result/failure contract.
State owners consume that contract; UI renders state and handles navigation/feedback.
Use cases are useful for reused orchestration, not compulsory forwarding wrappers.

## Common contract

- One immutable snapshot or coherent async value per flow: initial, loading, empty,
  success, failure, with independent refresh/pagination/action status when needed.
- Keep useful content on refresh/action failure. Copy collections at state boundaries.
- Keep UI controllers/focus and ephemeral toggles in the widget unless sharing is required.
- Define request identity, latest-result policy, cancellation and post-disposal behavior.
  A mounted check alone does not stop an older request replacing a newer result.
- Close subscriptions/timers/clients at their owner. Clear user-scoped state on logout or
  account switch. Avoid duplicate clients or parallel DI registrations for the same service.
- Scope rebuild subscriptions narrowly; navigation and snackbars are one-shot UI effects,
  never repeated during build. Route IDs/queries and typed-extra fallback rules still apply.
- Verify public behavior with fake repositories, controlled async completion and widget tests:
  loading → content/empty/failure, retry, refresh failure, reverse-order requests, leaving the
  route during a request, reopening, and account changes where applicable.

## Scaffolding and verification

`scripts/new_app.sh`, `scripts/new_feature.sh` and `templates/` generate Cubit/GetIt only.
Do not run them into a Riverpod/Provider/GetX app and then retrofit a second stack.
For an alternative new app, use `flutter create --org com.example <name>`, then follow the
selected guide; for a feature, create its needed files manually following its nearest peer.
Shared theme, constants, error and platform patterns can be reused without Cubit/DI code.
`playbooks.md`'s numbered bootstrap and route examples are Cubit-specific; substitute the
selected provider tree/binding graph and state files rather than installing their packages.

No alternative generator flags are advertised. Report which stack/manual path was used.
Verify in order: `dart format .` → `fdev gen` only for changed generated annotations
(fallback: `dart run build_runner build --delete-conflicting-outputs`) → `flutter analyze`
→ `flutter test`. Build/run affected platforms when necessary. Check APIs against the
installed major version; don't copy incompatible generated/manual provider syntax.
