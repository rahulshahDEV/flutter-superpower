import 'package:equatable/equatable.dart';

import 'package:__APP_NAME__/core/constants/error_constants.dart';

abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = ErrorConstants.serverError]);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = ErrorConstants.noInternetConnection]);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = ErrorConstants.unauthorized]);
}

final class ValidationFailure extends Failure {
  const ValidationFailure([super.message = ErrorConstants.validationFailed]);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = ErrorConstants.notFound]);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = ErrorConstants.cacheError]);
}
