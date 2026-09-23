import 'package:dartz/dartz.dart';

import 'package:__APP_NAME__/core/error/failures.dart';

typedef FutureEither<T> = Future<Either<Failure, T>>;
typedef ResultEither<T> = Either<Failure, T>;

extension EitherX<L, R> on Either<L, R> {
  R? get valueOrNull => fold((_) => null, (right) => right);
  L? get errorOrNull => fold((left) => left, (_) => null);
  bool get isSuccess => isRight();
  bool get isFailure => isLeft();
}

extension FutureEitherX<T> on FutureEither<T> {
  Future<void> handle({
    required void Function(T value) onSuccess,
    required void Function(Failure failure) onFailure,
  }) async {
    final result = await this;
    result.fold(onFailure, onSuccess);
  }
}
