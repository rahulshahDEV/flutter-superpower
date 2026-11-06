final class Order {
  const Order(this.id);
  final String id;
}

sealed class OrdersResult {
  const OrdersResult();
}

final class OrdersSuccess extends OrdersResult {
  OrdersSuccess(List<Order> items) : items = List.unmodifiable(items);
  final List<Order> items;
}

final class OrdersFailure extends OrdersResult {
  const OrdersFailure(this.message);
  final String message;
}

abstract interface class OrdersRepository {
  Future<OrdersResult> fetch(String accountId);
}
