# Performance Engineering

Evidence first: profile before changing anything (`flutter run --profile`, DevTools timeline +
CPU profiler). A change without a measurement is a guess.

## Rebuilds

- Scope `BlocBuilder`/`BlocConsumer` to the smallest widget that needs the state — never wrap
  a whole screen when one card changes.
- Use `buildWhen` (or `context.select`) when only part of the state matters.
- `const` constructors on everything that can take one; `const` subtrees stop rebuilds.
- Split expensive subtrees into their own widgets so parent rebuilds don't cascade.
- `RepaintBoundary` only with profiler evidence (raster time), not by default.
- `ValueListenableBuilder` for narrow, high-frequency updates instead of cubit state.

## Lists

- `ListView.builder`/`separated` or slivers — never `ListView(children: [...])` for dynamic data.
- No `shrinkWrap: true` inside another scrollable; use slivers or bounded height.
- `itemExtent`/`prototypeItem` when rows are uniform (big scroll win).
- `const` row widgets where possible; keys only where reorder/identity matters.
- Paginate (page size from `AppConstants.pageSize`); prefetch near the end, never all pages.

## Images & media

- All images through the design-system renderer (`ImageRenderer`/`cached_network_image`) —
  never raw `Image.network` in lists.
- Decode at display size (`cacheWidth`/`cacheHeight`) for thumbnails and avatars.
- Precache the next page's first image(s) on fast scroll screens.
- Video/audio: pause on app background and on route push; release controllers in `dispose`.
- Cap `imageCache` (`PaintingBinding.instance.imageCache.maximumSizeBytes`) for image-heavy feeds.

## Startup

- Keep `main()` thin: load env, DI, run — defer non-blocking work to after first frame.
- Lazy singletons (`@lazySingleton` default) — never construct heavy services at boot.
- Avoid synchronous I/O and large JSON parsing on the main isolate; `compute()` for >~10ms work.
- First screen renders from local state; network fills in after (shimmer, not a blocked splash).

## API & data

- Debounce search/typing (~300ms); cancel stale requests with the request-id guard.
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
- Watch DevTools memory for the "sawtooth that never returns" — that's a leak, not GC.

## Quick audit

```bash
scripts/audit.sh /path/to/app --perf     # unbounded lists, raw Image.network, MediaQuery.of, big assets
```

Then confirm with a real profile run before fixing anything. Never optimize by pattern-matching
alone — say what you measured.
