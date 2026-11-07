# Feature Suggestions and Integration Advice

Use for explicit requests to suggest, recommend or compare a package, integration approach,
or migration plan: “I need this feature; what is the easiest maintainable way?”
If implementation is also requested, make the selection and continue into the normal workflow.
A request only for advice ends with a concrete recommendation and plan: no dependency
installation, generated files, application edits, builds or migration execution. Read-only
project inspection and source research are appropriate. Do not turn an implementation
request into a mandatory proposal-approval stage.

## Establish the decision

Inspect the accessible project's pubspec/lockfile, Flutter/Dart versions, target platforms,
minimum OS/build requirements, closest capability, state/DI and existing adapters. Reuse
what already works. Without a project, state assumptions; do not manufacture its SDK or
claim compatibility. Ask only when an unresolved constraint would materially change the
choice; otherwise give useful conditional advice without blocking.

Define the actual capability and non-negotiables: supported platforms, online/offline,
privacy/data location, backend contract, latency/data volume, permissions, native UI,
background survival, licensing and implementation/maintenance budget. “Camera support” can
mean picking a photo, capturing video, scanning text or streaming frames; these need
separate capability checks. A package's platform badge does not establish every feature.

## Research and compare

Apply the ladder in `dependencies.md`: existing code → SDK → installed dependency →
maintained package → owned integration. A package is not compulsory. Compare the strongest
fit with one credible fallback; add another option only for a real trade-off.

Browse current primary sources: package page, official repository, changelog, migration
notes and relevant platform documentation. Record date and versions checked. Assess:

- Required API/platform coverage and behavior, not just downloads, likes or a recent release.
- Flutter/Dart constraints, native toolchain/minimum OS, transitive SDKs and generator versions.
- Setup effort: registration, permissions/entitlements, signing, assets and backend work.
- Failure/cancel/dispose semantics, test seams, offline behavior and release-mode limitations.
- License/vendor dependency, maintenance signals and breaking-change/migration history.

Distinguish the installed version, newest compatible version and newest published version.
Do not recommend an incompatible upgrade or replace a working dependency solely for recency.
If sources are unavailable, mark the recommendation provisional and name the unverified
criteria; never invent maintenance, compatibility or benchmark evidence.

## Choose the integration path

| Need | Candidate path | Maintenance decision |
|---|---|---|
| SDK/existing dependency already covers the behavior | Reuse it | Smallest new dependency surface; still verify capability |
| Standard capability with a suitable maintained plugin | Plugin behind the existing app boundary | Usually easiest; inspect per-platform APIs and native setup |
| Owned typed API across host platforms | Pigeon-generated contract | Check installed generator/SDK, backends and each target |
| Existing small raw bridge or low-level messages/streams | MethodChannel/BasicMessageChannel/EventChannel | Keep when appropriate; own schema, errors and subscriptions |
| Existing C-compatible library or measured native compute need | `dart:ffi` with FFIgen where useful | Own binary delivery, ABI, memory, threads and callbacks |
| Existing Java/Kotlin library or JAR/AAR | JNIgen where supported, or a typed host wrapper | Android-specific API shape/lifecycle needs an app-facing boundary |
| Objective-C / compatible Swift API | FFIgen or a Pigeon/native wrapper | Check exported header/API support; pure Swift features may need a wrapper |
| Browser/JavaScript capability | `dart:js_interop`, `package:web` or a maintained web implementation | Verify browser and build-target support; native FFI is not a web fallback |
| Embedded host-native UI | Platform views / an existing UI plugin | Assess gestures, accessibility, composition and disposal |
| Work must survive app termination | OS-supported scheduling/backend job | FFI, channels, `async` and isolates alone do not make it durable |

Pigeon is a contract generator, not a synonym for platform channels. Current Flutter docs
also describe a native FFI/JNI backend in preview. Verify its actual status, SDK, generator
and target support before choosing it; retain a supported stable path when production
constraints require one. New documentation can describe a newer SDK than the app uses.
No blanket claim that FFI is faster, easier or more portable: measure the relevant path
and include the ownership/build cost. Details: `platform-channels.md`.

## Recommend one path and a small first slice

State the preferred option early and tie it to the supplied constraints. Name the fallback
and the condition that would make it preferable. Compare ease and long-term ownership
separately; neither lowest setup effort nor fewest dependencies always wins.

Give the smallest implementation sequence that exercises the capability:

1. Reuse the current feature/repository boundary and selected state/DI. Add a narrow adapter
   only when it earns a lifecycle, portability, business-policy or testing seam.
2. List actual package/config/native setup and any required generator. Name unsupported
   platforms/fallback behavior instead of pretending one native implementation covers all.
3. Implement one success plus one important failure/recovery path; define permissions,
   loading/cancel states, owner/disposal and safe errors appropriate to this capability.
4. Verify adapter behavior with fakes, then build/run each affected native/web target. A
   package resolution or generated binding does not prove registration or hardware works.

For an advice-only request these are proposed steps, not executed checks. Use existing
project generation commands. `fdev gen` (fallback: `dart run build_runner build
--delete-conflicting-outputs`) covers configured builders, not every native generator;
Pigeon/FFIgen/JNIgen may have their own pinned project scripts/configuration.

## Upgrade and exit path

Keep this proportionate to the integration's risk; do not add speculative abstraction layers.

- Keep plugin/vendor/generated types out of domain/public feature contracts where a useful
  boundary exists. Identify the owner of initialization, lifetime and error translation.
- Pin compatible dependencies/toolchains and commit the app lockfile. Retain generator
  configuration and regenerate matched Dart/host bindings together; never hand-edit output.
- Identify persisted schemas, queued payloads, server contracts, permissions and user data
  affected by replacement. Use `persistence-migrations.md` for data/rollback compatibility.
- For a replacement, preserve the app-facing contract, implement a second adapter only for
  the migration, and validate the same behaviors on both. Switch composition in runnable
  stages; remove obsolete dependencies, native registration/config and temporary adapters.
- State upgrade triggers: missing capability, confirmed abandonment/incompatibility, measured
  bottleneck or supported-platform change. Name rollback/cleanup and verification costs.
  A code rollback does not undo a database migration, server write or OS permission decision.

Do not promise permanent API stability. Separate a practical upgrade path from a speculative
future rewrite; explicitly requested migration implementation uses `senior-mode.md`.

## Response shape

Lead with the recommendation. Default to a short decision brief; expand native/version
details only when they affect the choice or the user requests them:

1. Goal, project constraints and assumptions.
2. Recommendation plus a compact options table: fit, setup effort, platform limits,
   maintenance/upgrade cost, evidence. Avoid invented time estimates or numerical scores.
3. Easiest implementation slice and its architecture/lifetime owner.
4. Upgrade/exit plan and the condition for choosing the fallback.
5. Source links/date/version checked; separate verified facts, inference and untested areas.

Finish advice when the decision is reviewable. Report “not implemented/device-tested” when
applicable; do not run the implementation evidence gate or claim it passed for advice.

Sources for integration mechanisms (checked 2026-11-07):
[Flutter native interop](https://docs.flutter.dev/interop),
[Pigeon](https://docs.flutter.dev/interop/pigeon),
[FFIgen](https://docs.flutter.dev/interop/ffigen),
[JNIgen](https://docs.flutter.dev/interop/jnigen),
[Dart JavaScript interop](https://dart.dev/interop/js-interop).
