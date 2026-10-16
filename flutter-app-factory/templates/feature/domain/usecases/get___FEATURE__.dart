// `show` keeps names like `Order` from colliding with injectable's annotations.
import 'package:injectable/injectable.dart' show lazySingleton;

import 'package:__APP_NAME__/core/error/either_extensions.dart';
import 'package:__APP_NAME__/core/usecases/usecase.dart';
import 'package:__APP_NAME__/features/__FEATURE__/domain/entities/__ENTITY__.dart';
import 'package:__APP_NAME__/features/__FEATURE__/domain/repositories/__FEATURE___repository.dart';

@lazySingleton
class Get__FEATURE_CLASS__ implements UseCase<List<__ENTITY_CLASS__>, NoParams> {
  Get__FEATURE_CLASS__(this._repository);

  final __FEATURE_CLASS__Repository _repository;

  @override
  FutureEither<List<__ENTITY_CLASS__>> call(NoParams params) =>
      _repository.get__FEATURE_CLASS__();
}
