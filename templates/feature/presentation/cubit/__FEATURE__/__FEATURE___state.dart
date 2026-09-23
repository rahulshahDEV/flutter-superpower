import 'package:equatable/equatable.dart';

import 'package:__APP_NAME__/core/error/failures.dart';
import 'package:__APP_NAME__/features/__FEATURE__/domain/entities/__ENTITY__.dart';

sealed class __FEATURE_CLASS__State extends Equatable {
  const __FEATURE_CLASS__State();

  @override
  List<Object?> get props => const [];
}

final class __FEATURE_CLASS__Initial extends __FEATURE_CLASS__State {
  const __FEATURE_CLASS__Initial();
}

final class __FEATURE_CLASS__Loading extends __FEATURE_CLASS__State {
  const __FEATURE_CLASS__Loading();
}

final class __FEATURE_CLASS__Success extends __FEATURE_CLASS__State {
  const __FEATURE_CLASS__Success(this.items);

  final List<__ENTITY_CLASS__> items;

  @override
  List<Object?> get props => [items];
}

final class __FEATURE_CLASS__Failure extends __FEATURE_CLASS__State {
  const __FEATURE_CLASS__Failure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
