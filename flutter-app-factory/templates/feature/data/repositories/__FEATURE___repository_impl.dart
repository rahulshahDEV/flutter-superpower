// `show` keeps names like `Order` from colliding with injectable's annotations.
import 'package:injectable/injectable.dart' show LazySingleton;

import 'package:__APP_NAME__/core/error/api_exception_handler.dart';
import 'package:__APP_NAME__/core/error/either_extensions.dart';
import 'package:__APP_NAME__/features/__FEATURE__/data/datasources/__FEATURE___remote_data_source.dart';
import 'package:__APP_NAME__/features/__FEATURE__/domain/entities/__ENTITY__.dart';
import 'package:__APP_NAME__/features/__FEATURE__/domain/repositories/__FEATURE___repository.dart';

@LazySingleton(as: __FEATURE_CLASS__Repository)
class __FEATURE_CLASS__RepositoryImpl
    with ApiExceptionHandler
    implements __FEATURE_CLASS__Repository {
  __FEATURE_CLASS__RepositoryImpl(this._remoteDataSource);

  final __FEATURE_CLASS__RemoteDataSource _remoteDataSource;

  @override
  FutureEither<List<__ENTITY_CLASS__>> get__FEATURE_CLASS__() {
    return safeApiCall(() async {
      final models = await _remoteDataSource.get__FEATURE_CLASS__();
      return models.cast<__ENTITY_CLASS__>();
    });
  }
}
