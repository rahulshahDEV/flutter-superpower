import 'package:equatable/equatable.dart';

import 'package:factory_core/core/error/either_extensions.dart';

abstract class UseCase<T, Params> {
  FutureEither<T> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => const [];
}
