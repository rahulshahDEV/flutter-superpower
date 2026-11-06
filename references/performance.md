# Performance Engineering

Evidence first: profile before changing anything (`flutter run --profile`, DevTools timeline +
CPU profiler). A claimed optimization without measurement is unproven. Correctness fixes
such as disposing an owned subscription do not require a timing experiment. Record device,
build mode, dataset, warm/cold state and repeated before/after observations. See
`app-optimization.md` for contextual decisions and display-refresh budgets.

## Rebuilds

- Scope subscriptions to state consumers when unrelated rebuilds have a measurable cost.
  Cubit uses BlocBuilder/BlocSelector, Riverpod select/Consumer, Provider Selector/Consumer,
  GetX narrow Obx/GetBuilder. A cheap screen-wide builder can be adequate.
- Use selectors/buildWhen when they express a correct stable dependency; preserve state
  equality and avoid suppressing required updates to hide rebuild counts.
- Use const for immutable configuration where possible; it allows stable widget reuse,
  but inherited dependencies and descendant local state can still cause rebuilds.
- Split expensive subtrees into their own widgets so parent rebuilds don't cascade.
- `RepaintBoundary` only with profiler evidence (raster time), not by default.
- `ValueListenableBuilder` for narrow, high-frequency updates instead of cubit state.

## Lists

- Use lazy builders/slivers for large or unbounded data; explicit children can be clearer
  for a short bounded list, including one assembled from dynamic data.
- Investigate nested shrink-wrap in costly layout traces; prefer slivers/bounds for long
  content, but keep valid short nested layouts when no meaningful cost is demonstrated.
- `itemExtent`/`prototypeItem` when rows are uniform (big scroll win).
- `const` row widgets where possible; keys only where reorder/identity matters.
- Follow the API/product pagination contract when needed; cap prefetch/concurrency.
  Do not add pagination to a small complete dataset without a requirement.

## Images & media

- Reuse the app's image renderer; introduce caching only for measured or required behavior.
  An HTTP/CDN cache is distinct from decoded-image memory.
- Decode at display size (`cacheWidth`/`cacheHeight`) for thumbnails and avatars.
- Precache likely next images only with a bounded memory/network budget and evidence.
- Video/audio: apply the product's background/route playback policy; dispose owned
  controllers when their actual owner ends. Background audio may intentionally continue.
- Tune image-cache limits only with working-set/churn measurements; a smaller cache may
  increase repeated decodes and downloads.

## Startup

- Keep `main()` thin: load env, DI, run — defer non-blocking work to after first frame.
- Defer expensive optional initialization; required storage/session dependencies must be
  ready before consumers. Lazy registration alone does not make initialization asynchronous.
- Move measured expensive parsing/I/O off the UI isolate where supported; account for
  transfer/startup overhead and platform differences instead of a universal duration cutoff.
- Render useful local/startup state promptly; unresolved authorization must still guard
  protected content. No artificial splash delay or unbounded network gate.

## API & data

- Debounce replaceable remote search when appropriate; tune latency to the product.
  A request-ID guard rejects stale results; it does not cancel the underlying transport.
- Cache read-mostly data (TTL via the app's cache layer); don't refetch on every rebuild.
- Batch/parallelize independent calls with `Future.wait` instead of serial awaits.
- Reuse parsed entities; don't re-map on every build.

## Animations

- Implicit animations (`AnimatedSwitcher`, `AnimatedOpacity`) unless a custom controller is needed.
- `AnimatedBuilder` with the `child:` parameter so the static subtree isn't rebuilt.
- Keep controllers in `State`, dispose them, and avoid rebuilding on every tick where possible.
- Respect reduced-motion (`MediaQuery.disableAnimations`) — see `accessibility.md`.

## Memory

- Dispose controllers, focus nodes, stream subscriptions, timers, and sockets.
- Close cubits you create; don't hold screens in memory via retained callbacks.
- Compare retained instances and retaining paths across repeated journeys/GC. A rising
  graph alone cannot distinguish a leak, intentional cache growth or delayed collection.

## Quick audit

```bash
scripts/audit.sh /path/to/app --perf     # unbounded lists, raw Image.network, MediaQuery.of, big assets
```

Then confirm with a real profile run before fixing anything. Never optimize by pattern-matching
alone — say what you measured.

Sources: [Flutter performance practices](https://docs.flutter.dev/perf/best-practices),
[profile on target devices](https://docs.flutter.dev/perf/ui-performance).
