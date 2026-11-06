import 'package:state_stack_examples/features/orders/domain/orders_repository.dart';

enum OrdersStatus { initial, loading, loaded, failed }

final class OrdersState {
  OrdersState({
    this.status = OrdersStatus.initial,
    List<Order> items = const [],
    this.error,
    this.refreshing = false,
  }) : items = List.unmodifiable(items);

  final OrdersStatus status;
  final List<Order> items;
  final String? error;
  final bool refreshing;

  OrdersState loading() => OrdersState(
    status: status == OrdersStatus.loaded ? status : OrdersStatus.loading,
    items: items,
    refreshing: status == OrdersStatus.loaded,
  );

  OrdersState complete(OrdersResult result) => switch (result) {
    OrdersSuccess(:final items) => OrdersState(
      status: OrdersStatus.loaded,
      items: items,
    ),
    OrdersFailure(:final message) => OrdersState(
      status: status == OrdersStatus.loaded ? status : OrdersStatus.failed,
      items: items,
      error: message,
    ),
  };
}
