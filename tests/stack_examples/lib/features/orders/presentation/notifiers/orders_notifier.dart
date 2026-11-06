import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:state_stack_examples/features/orders/domain/orders_repository.dart';
import 'package:state_stack_examples/features/orders/presentation/orders_state.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => throw StateError('Supply a repository at composition'),
);
final accountIdProvider = Provider<String>((ref) => 'example-account');
final ordersProvider = NotifierProvider<OrdersNotifier, OrdersState>(
  OrdersNotifier.new,
  isAutoDispose: true,
);

final class OrdersNotifier extends Notifier<OrdersState> {
  int _generation = 0;

  @override
  OrdersState build() {
    final repository = ref.watch(ordersRepositoryProvider);
    final accountId = ref.watch(accountIdProvider);
    final generation = ++_generation;
    ref.onDispose(() => _generation++);
    unawaited(_fetch(repository, accountId, generation));
    return OrdersState(status: OrdersStatus.loading);
  }

  Future<void> load() {
    state = state.loading();
    return _fetch(
      ref.read(ordersRepositoryProvider),
      ref.read(accountIdProvider),
      ++_generation,
    );
  }

  Future<void> _fetch(
    OrdersRepository repository,
    String accountId,
    int generation,
  ) async {
    final result = await repository.fetch(accountId);
    if (!ref.mounted || generation != _generation) return;
    state = state.complete(result);
  }
}
