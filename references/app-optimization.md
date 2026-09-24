# App Optimization — level-wise, decide before you do

Tiered optimization playbook. Each item states what it is, what it buys, and when to skip it —
so you can hand the user a plan and let them decide what to implement.

## Ground rules

1. **Measure first.** Profile/release mode only (`flutter run --profile`), DevTools timeline,
   `flutter build appbundle --analyze-size`. No measurement → no optimization.
2. **One level at a time**, re-measure after each; stop when the goal is met.
3. **Never trade correctness, accessibility, or security for speed.**
4. **Adopt test:** implement if (measured problem) + (effort ≤ impact) + (no behavior change) +
   (reversible). Otherwise write it into the plan, not the code.
5. If the number doesn't move after a change, revert it — no cargo cult.

Budgets to aim at: 16 ms/frame (60 fps) · cold start < 2 s · app size per store limits.

## Level 0 — Baseline (always, zero risk)

- `flutter run --profile` for anything you intend to judge; debug timings lie.
- Capture the baseline: frame timings, startup trace (`flutter run --trace-startup`), build size.
- Know which screens/actions are slow — name them, with numbers.
- Gate before and after: `dart format` · `flutter analyze` · `flutter test`.

## Level 1 — Free wins (default; minutes each, no behavior change)

| Technique | How | Skip when |
|---|---|---|
| `const` constructors | everywhere it compiles; const subtrees stop rebuilds | never |
| Scope rebuilds | smallest `BlocBuilder`, add `buildWhen`/`context.select` | never |
| Builder lists | `ListView.builder`/`separated`, slivers | never for dynamic data |
| Remove `shrinkWrap: true` | use bounded height / slivers | never |
| Dispose resources | controllers, focus nodes, subscriptions, timers, sockets | never |
| Decode at display size | `cacheWidth`/`cacheHeight` for thumbnails/avatars | full-screen images |
| Debounce input | ~300 ms on search/typing | instant local filters |
| `MediaQuery.sizeOf` etc. | instead of `MediaQuery.of` (fewer rebuilds) | never |
| Size hygiene | tree-shake icons, split ABI / ship AAB, R8/minify on, delete unused assets/deps | never |

Do all of Level 1 — it is the default state of the codebase, not an optimization project.

## Level 2 — Cheap wins (hours; only for a screen that is measurably slow)

| Technique | Gain | Skip when |
|---|---|---|
| Pagination | bounded work per scroll | API returns everything / list is short |
| Image caching + precache | no re-decode on scroll | images already cached by CDN layer |
| Extract heavy subtree into `const` widget | smaller rebuild scope | extraction hurts readability |
| `RepaintBoundary` | isolates raster work | no raster evidence (ListView already adds per-child boundaries) |
| `compute()`/isolate for parsing | keeps UI thread free (>~10 ms work) | payloads are tiny |
| Avoid `ClipRRect`/`Opacity`/`BackdropFilter` in list rows | no `saveLayer` per frame | needed for the design |
| `itemExtent`/`prototypeItem` | faster scroll metrics | rows wrap text / text scaling must stay intact |
| Defer non-critical init | faster first frame | work is required to render the first screen |
| WebP/AVIF via CDN | smaller downloads | already optimized |

## Level 3 — Project-level (days; adopt with a stated goal and owner)

- **Startup**: audit everything before first frame; lazy DI (`@lazySingleton`), defer syncs after
  first frame, splash budget, `flutter run --trace-startup` before/after.
- **Size**: `flutter build appbundle --analyze-size` → biggest contributors; font subsetting;
  asset audit; `--split-debug-info` + `--obfuscate`; remove duplicate/oversized assets.
- **Network**: batch/parallel independent calls (`Future.wait`), request only needed fields,
  honor cache headers, gzip; connectivity-aware retry.
- **Storage/caching**: TTL cache layer for read-mostly data; cap `imageCache.maximumSizeBytes`.
- **Rendering**: verify Impeller on target devices; pool video controllers; avoid rebuild-heavy
  animations (`AnimatedBuilder` with `child:`).
- **Memory**: DevTools memory leak tracking; dispose pools; watch the sawtooth that never returns.

## Level 4 — Advanced (only with profiling data + a named owner)

- Isolate pools / FFI for heavy compute.
- Android deferred components or route-level lazy loading.
- Custom render objects/shaders — only with a proven bottleneck.
- OTA patches for Dart-only fixes (`shorebird.md`).
- Engine/plugin-level changes; CDN transform services.

## Decide: implement, plan, or skip

```
IMPLEMENT  measured problem + cheap (L1–L2) + no behavior change + reversible
PLAN       real but not urgent, or needs a goal/owner/date (L3+)
SKIP       speculative · micro-gain only · changes UX/a11y/security · adds a dependency ·
           cannot be measured
```

## Plan template (hand this to the user)

```
OPTIMIZATION PLAN — <app / screen>
Goal:        <60fps on Orders list | cold start < 2s | size < 30MB>
Baseline:    <numbers + how measured>
Level 1 (do now, no risk):      [ ] …  [ ] …
Level 2 (only if goal not met): [ ] …
Level 3 (planned — owner/date): [ ] …
Not doing (and why):            <list>
Re-measure:  <exact command> → <before> → <after>
```

## Reporting

State the measurement, the change, and the re-measurement. If the goal was met by Level 1,
say so and stop — shipping Levels 2–3 anyway is scope creep with extra risk.
