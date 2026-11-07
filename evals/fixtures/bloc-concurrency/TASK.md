Fix search results reverting after a refresh, and prevent duplicate saves without losing
submitted writes. Preserve the supplied event Bloc API and repository boundary.

SearchChanged and SearchRefreshed both replace the visible read. The latest intent across
both event types owns loading/content/error; keep the selected query on refresh. A stale
success or failure cannot overwrite a newer outcome. Failed reads retain useful content.

SaveRequested carries a globally unique operation ID and immutable payload. Distinct save
intents execute in FIFO order, including while reads overlap. Repeated delivery of a pending
or already-successful operation ID must not call the repository again. Failed saves may be
retried with that same ID/payload. Reusing an ID with a different payload must fail safely
without another external call. One failed save must not drop the next queued distinct save.
Saving and read feedback are independent; never restart a server write to cancel a UI read.

Use controlled futures and count repository calls/effects. Protect the fix with meaningful
red/green regression checks; verify cross-event overlap, repeated submit, failure/retry,
queue order and closing with work in flight. The repository has no transport cancellation
API, so do not claim that rejecting stale state cancels server work. No UI/backend requested.
