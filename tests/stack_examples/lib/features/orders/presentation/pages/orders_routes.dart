import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:state_stack_examples/features/orders/domain/orders_repository.dart';
import 'package:state_stack_examples/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:state_stack_examples/features/orders/presentation/bloc/orders_event.dart';
import 'package:state_stack_examples/features/orders/presentation/controllers/orders_controller.dart';
import 'package:state_stack_examples/features/orders/presentation/notifiers/orders_notifier.dart';
import 'package:state_stack_examples/features/orders/presentation/orders_state.dart';
import 'package:state_stack_examples/features/orders/presentation/viewmodels/orders_view_model.dart';

abstract final class OrdersText {
  static const loading = 'Loading';
  static const empty = 'No orders';
  static const retry = 'Retry';
}

class OrdersView extends StatelessWidget {
  const OrdersView({required this.state, required this.onRetry, super.key});
  final OrdersState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (state.status == OrdersStatus.loading || state.refreshing)
        const Text(OrdersText.loading),
      if (state.status == OrdersStatus.loaded && state.items.isEmpty)
        const Text(OrdersText.empty),
      for (final order in state.items) Text(order.id),
      if (state.error case final error?) Text(error),
      TextButton(onPressed: onRetry, child: const Text(OrdersText.retry)),
    ],
  );
}

class RiverpodOrdersRoute extends StatelessWidget {
  const RiverpodOrdersRoute({
    required this.repository,
    required this.accountId,
    super.key,
  });
  final OrdersRepository repository;
  final String accountId;

  @override
  Widget build(BuildContext context) => rp.ProviderScope(
    key: ValueKey((repository, accountId)),
    overrides: [
      ordersRepositoryProvider.overrideWithValue(repository),
      accountIdProvider.overrideWithValue(accountId),
      ordersProvider.overrideWith(OrdersNotifier.new),
    ],
    child: rp.Consumer(
      builder: (context, ref, child) => OrdersView(
        state: ref.watch(ordersProvider),
        onRetry: () => ref.read(ordersProvider.notifier).load(),
      ),
    ),
  );
}

class ProviderOrdersRoute extends StatelessWidget {
  const ProviderOrdersRoute({
    required this.repository,
    required this.accountId,
    super.key,
  });
  final OrdersRepository repository;
  final String accountId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    key: ValueKey((repository, accountId)),
    create: (_) => OrdersViewModel(repository, accountId)..load(),
    child: Consumer<OrdersViewModel>(
      builder: (context, model, child) =>
          OrdersView(state: model.state, onRetry: model.load),
    ),
  );
}

class BlocOrdersRoute extends StatelessWidget {
  const BlocOrdersRoute({
    required this.repository,
    required this.accountId,
    super.key,
  });
  final OrdersRepository repository;
  final String accountId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey((repository, accountId)),
    create: (_) =>
        OrdersBloc(repository, accountId)..add(const OrdersRequested()),
    child: BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) => OrdersView(
        state: state,
        onRetry: () => context.read<OrdersBloc>().add(const OrdersRequested()),
      ),
    ),
  );
}

class GetOrdersRoute extends StatefulWidget {
  const GetOrdersRoute({
    required this.repository,
    required this.accountId,
    required this.tag,
    super.key,
  });
  final OrdersRepository repository;
  final String accountId;
  final String tag;

  @override
  State<GetOrdersRoute> createState() => _GetOrdersRouteState();
}

class _GetOrdersRouteState extends State<GetOrdersRoute> {
  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void didUpdateWidget(covariant GetOrdersRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountId != widget.accountId ||
        !identical(oldWidget.repository, widget.repository) ||
        oldWidget.tag != widget.tag) {
      Get.delete<OrdersController>(tag: oldWidget.tag);
      _register();
    }
  }

  void _register() {
    if (Get.isRegistered<OrdersController>(tag: widget.tag)) {
      throw StateError(
        'Every simultaneously mounted route needs a distinct tag',
      );
    }
    Get.put(
      OrdersController(widget.repository, widget.accountId),
      tag: widget.tag,
    );
  }

  @override
  void dispose() {
    Get.delete<OrdersController>(tag: widget.tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrdersController>(tag: widget.tag);
    return Obx(
      () => OrdersView(state: controller.state, onRetry: controller.load),
    );
  }
}
