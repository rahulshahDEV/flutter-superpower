# App Optimization — level-wise, decide before you do

Tiered optimization playbook. Each item states what it is, what it buys, and when to skip it —
so you can hand the user a plan and let them decide what to implement.

## Ground rules

1. **Measure first.** Profile/release mode only (`flutter run --profile`), DevTools timeline,
   `flutter build appbundle --analyze-size`. No measurement → no claimed speed improvement.
   Fix confirmed correctness/resource-lifetime defects without waiting for a benchmark.
2. **One level at a time**, re-measure after each; stop when the goal is met.
3. **Never trade correctness, accessibility, or security for speed.**
4. **Adopt test:** implement if (measured problem) + (effort ≤ impact) + (no behavior change) +
   (reversible). Otherwise write it into the plan, not the code.
5. If the number doesn't move after a change, revert it — no cargo cult.

Agree budgets for target devices and journeys. A 60 Hz display allows about 16.7 ms per
frame; 120 Hz about 8.3 ms. Define startup percentile/measurement points and size limits
for the actual product instead of treating a universal two-second launch as acceptance.

## Level 0 — Reproducible baseline

- `flutter run --profile` for anything you intend to judge; debug timings lie.
- Capture the baseline: frame timings, startup trace (`flutter run --trace-startup`), build size.
- Name slow screens/actions, device/OS/refresh rate, build mode, dataset and warm/cold state.
- Compare repeated runs under equivalent conditions; retain traces, frame percentiles,
  memory snapshots or size reports. Emulator/debug results are not release-device evidence.
- Gate before and after: `dart format` · `flutter analyze` · `flutter test`.

## Level 1 — Small changes selected by evidence

These are candidates, not a mandatory batch. Resource disposal and correctness defects must
be fixed regardless of timing; the remaining changes need a relevant cost or clear repeated
work. Use the selected stack's subscription APIs rather than introducing Bloc to optimize it.

| Technique | Adopt when | Keep/skip when |
|---|---|---|
| `const` widgets | Values are compile-time constants and a stable subtree can be reused | Don't distort state/data ownership merely to make a constructor const |
| Narrow subscriptions | Profiling shows unrelated rebuild work | A small screen's build is cheap; selectors add no useful boundary |
| Builder/sliver lists | Items are numerous, expensive or unbounded | A short bounded list is clearer with explicit children |
| Bounded layout/slivers | Nested shrink-wrap causes costly repeated layout | Short bounded nested content legitimately needs shrink-wrap |
| Dispose owned resources | Creator's lifetime ends | Borrowed resources must remain with their original owner |
| Decode near display size | Large source images dominate decoded memory | Preserve zoom/full-screen resolution; account for pixel ratio |
| Debounce input | Remote search creates replaceable requests | Immediate local feedback or a committed command must not be delayed |
| Narrow MediaQuery access | A subtree only depends on one supported property | Existing broad access is intentional and inexpensive |
| Asset/build size cleanup | Report identifies unused/oversized assets or unsupported packaging | Verify dynamic asset use, platform/signing and plugin shrinker requirements |

Re-measure each selected change; stop when acceptance is met. Removing a selector, shrinking
an image cache or enabling native shrinking can introduce regressions and needs verification.

## Level 2 — Focused changes for a measured bottleneck

| Technique | Gain | Skip when |
|---|---|---|
| Pagination | bounded work per scroll | API returns everything / list is short |
| Image caching + bounded precache | fewer repeated loads/decodes on measured paths | decoded-memory/network costs outweigh benefit; CDN cache is not decoded-image cache |
| Extract heavy subtree into `const` widget | smaller rebuild scope | extraction hurts readability |
| `RepaintBoundary` | isolates raster work | no raster evidence (ListView already adds per-child boundaries) |
| `compute()`/isolate for parsing | moves measured CPU work off the UI isolate on supported targets | transfer/startup overhead dominates; check web behavior |
| Adjust expensive clipping/opacity/filter use | lower measured raster/layer cost | effect is required or trace shows no relevant cost; not every clip causes saveLayer |
| `itemExtent`/`prototypeItem` | faster scroll metrics | rows wrap text / text scaling must stay intact |
| Defer non-critical init | faster first frame | work is required to render the first screen |
| WebP/AVIF via CDN | smaller downloads | already optimized |

## Level 3 — Project-level (days; adopt with a stated goal and owner)

- **Startup**: audit everything before first frame; lazy DI (`@lazySingleton`), defer syncs after
  first frame where safe, startup budget, `flutter run --trace-startup` before/after.
- **Size**: `flutter build appbundle --analyze-size` → biggest contributors; font subsetting;
  asset audit; `--split-debug-info` + `--obfuscate`; remove duplicate/oversized assets.
- **Network**: batch/parallel independent calls (`Future.wait`), request only needed fields,
  honor cache headers, gzip; bounded retry based on request outcomes and idempotency.
- **Storage/caching**: choose freshness/retention from the data contract; change image-cache
  limits only after measuring working set, churn and memory pressure.
- **Rendering**: verify Impeller on target devices; pool video controllers; avoid rebuild-heavy
  animations (`AnimatedBuilder` with `child:`).
- **Memory**: compare retained instances/retaining paths after repeated journeys and GC;
  distinguish intentional cache growth from leaked owners.

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
SKIP       speculative · no relevant gain · violates UX/a11y/security · cannot be measured
EVALUATE   justified dependency or behavior trade-off; follow dependencies.md and task scope
```

## Plan template (hand this to the user)

```
OPTIMIZATION PLAN — <app / screen>
Goal:        <60fps on Orders list | cold start < 2s | size < 30MB>
Baseline:    <numbers + how measured>
Level 1 (selected small changes):      [ ] …  [ ] …
Level 2 (only if goal not met): [ ] …
Level 3 (planned — owner/date): [ ] …
Not doing (and why):            <list>
Re-measure:  <exact command> → <before> → <after>
```

## Reporting

State the measurement, the change, and the re-measurement. If the goal was met by Level 1,
say so and stop — shipping Levels 2–3 anyway is scope creep with extra risk.

Sources: [Flutter performance practices](https://docs.flutter.dev/perf/best-practices),
[device profiling](https://docs.flutter.dev/perf/ui-performance).
