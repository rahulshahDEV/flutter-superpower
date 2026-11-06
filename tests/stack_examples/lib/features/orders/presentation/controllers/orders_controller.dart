import 'dart:async';

import 'package:get/get.dart';

import 'package:state_stack_examples/features/orders/domain/orders_repository.dart';
import 'package:state_stack_examples/features/orders/presentation/orders_state.dart';

final class OrdersController extends GetxController {
  OrdersController(this._repository, this.accountId);
  final OrdersRepository _repository;
  final String accountId;
  final _state = OrdersState().obs;
  OrdersState get state => _state.value;
  int _generation = 0;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    if (isClosed) return;
    final generation = ++_generation;
    _state.value = state.loading();
    final result = await _repository.fetch(accountId);
    if (isClosed || generation != _generation) return;
    _state.value = state.complete(result);
  }

  @override
  void onClose() {
    _generation++;
    super.onClose();
  }
}
