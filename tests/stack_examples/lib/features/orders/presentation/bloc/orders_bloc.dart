import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:state_stack_examples/features/orders/domain/orders_repository.dart';
import 'package:state_stack_examples/features/orders/presentation/orders_state.dart';
import 'package:state_stack_examples/features/orders/presentation/bloc/orders_event.dart';

final class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc(this._repository, this.accountId) : super(OrdersState()) {
    on<OrdersRequested>(_load, transformer: concurrent());
  }
  final OrdersRepository _repository;
  final String accountId;
  int _generation = 0;

  Future<void> _load(OrdersRequested event, Emitter<OrdersState> emit) async {
    final generation = ++_generation;
    emit(state.loading());
    final result = await _repository.fetch(accountId);
    if (emit.isDone || generation != _generation) return;
    emit(state.complete(result));
  }
}
