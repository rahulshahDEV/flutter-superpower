import 'package:flutter/foundation.dart';

import 'package:state_stack_examples/features/orders/domain/orders_repository.dart';
import 'package:state_stack_examples/features/orders/presentation/orders_state.dart';

final class OrdersViewModel extends ChangeNotifier {
  OrdersViewModel(this._repository, this.accountId);
  final OrdersRepository _repository;
  final String accountId;
  OrdersState _state = OrdersState();
  OrdersState get state => _state;
  bool _disposed = false;
  int _generation = 0;

  Future<void> load() async {
    if (_disposed) return;
    final generation = ++_generation;
    _state = _state.loading();
    notifyListeners();
    final result = await _repository.fetch(accountId);
    if (_disposed || generation != _generation) return;
    _state = _state.complete(result);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
