# Async Safety

An asynchronous operation has an owner, an error path, and a lifetime. Keep all three
visible. A `Future` passed through a void callback may have its result and error discarded,
even when the callback looks like a simple one-line call.

## Event callbacks and Cubits

- Before wiring an async Cubit method to `onPressed`, `onTap`, or another `VoidCallback`,
  check that the Cubit handles expected failures as typed state and that unexpected errors
  reach the app's existing error/reporting path.
- Do not assume that a callback's return type means Flutter will await it. Avoid empty
  `catch` blocks, bare `unawaited(future)`, and detached work with no terminal error path.
- Keep expected request failures in the existing `Either<Failure, T>` flow. Log unexpected
  errors with their stack and surface a useful failure state; do not leak raw exceptions to
  users.
- For work that truly continues in the background, explain why it may outlive the screen and
  handle its failure where it is started. Do not add a second error framework.

## `BuildContext` and awaits

- A `BuildContext` is only valid while its element remains mounted. After every `await`,
  check `mounted` immediately before using the context or `State`-owned resources.
- A guard before an `await` does not cover the resumed code. With multiple awaits, check
  again after the last await before the next context use.
- Prefer emitting state and letting a `BlocListener` handle navigation or snackbars. This
  keeps Cubits free of `BuildContext` and avoids context use after an async gap.
- Do not retain a context in a Cubit, repository, callback, timer, or service.

## Owned asynchronous resources

- Cancel every `StreamSubscription` and `Timer` in the lifecycle owner that created it.
- Close owned `StreamController`s and sinks. Dispose `TextEditingController` and
  `FocusNode` in the owning `State`; see `forms-and-input.md`.
- A timer or stream callback that calls `setState` must first confirm the `State` is still
  mounted. Canceling in `dispose` is still required; the guard covers callbacks already
  queued when disposal begins.
- In Cubits, retain the request-id or cancellation guard when a newer request can supersede
  an older one. Check `isClosed` before emitting after an await; `SafeCubit` remains the
  normal emission path.

## Error handling

- Catch only errors the current layer can handle. Convert expected failures at the repository
  boundary; log unexpected errors with the original stack and preserve the failure signal.
- Use `rethrow` when an error must continue upward. `throw error` replaces useful stack
  information.
- Never use `assert` to validate runtime plugin or platform results. Assertions disappear in
  release builds.
- Keep startup ordering and global error handlers in `app-bootstrap.md`; do not add
  `runZonedGuarded` or a competing error handler here.

## Review checklist

For every async path, identify who starts it, who observes its failure, and what happens if
its owner is disposed or a newer request begins. Verify the failure path and lifecycle edge
with a focused test when either can change user-visible behavior.
