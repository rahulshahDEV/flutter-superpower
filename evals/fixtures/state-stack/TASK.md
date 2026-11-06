Add order history with loading, empty, failure and retry. Keep our chosen state stack and
feature-first conventions, and verify it. Use the supplied OrdersRepository contract.

Expose OrdersRoute(repository: ..., accountId: ..., key: ...) in
lib/features/orders/presentation/pages/orders_route.dart. Render these observable labels:
Loading while fetching, No orders for a successful empty result, the returned safe failure
message and a Retry button. Show order IDs as content. Retry also refreshes existing content;
retain that content if refresh fails. Repository is borrowed, not closed by a screen.

Initialize once per mounted owner. Only the latest replacement request may publish results.
Leaving/reopening the route and changing accountId/repository on the same widget key must
not leak prior data or late completions. Two routes may be mounted simultaneously.

Choose files, ownership and dependency composition for the declared stack. Don't add another
state-management/DI stack. No backend, native integration or application release is requested.
