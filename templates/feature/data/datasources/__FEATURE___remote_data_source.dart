import 'package:injectable/injectable.dart';

import 'package:__APP_NAME__/core/constants/api_constants.dart';
import 'package:__APP_NAME__/core/constants/error_constants.dart';
import 'package:__APP_NAME__/core/error/exceptions.dart';
import 'package:__APP_NAME__/core/network/dio_client.dart';
import 'package:__APP_NAME__/features/__FEATURE__/data/models/__ENTITY___model.dart';

abstract class __FEATURE_CLASS__RemoteDataSource {
  Future<List<__ENTITY_CLASS__Model>> get__FEATURE_CLASS__();
}

@LazySingleton(as: __FEATURE_CLASS__RemoteDataSource)
class __FEATURE_CLASS__RemoteDataSourceImpl
    implements __FEATURE_CLASS__RemoteDataSource {
  __FEATURE_CLASS__RemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<List<__ENTITY_CLASS__Model>> get__FEATURE_CLASS__() async {
    final response = await _dioClient.get<Object?>(ApiConstants.__FEATURE__);
    final raw = response.data;
    final list = raw is Map<String, dynamic> ? raw['data'] : raw;
    if (list is! List) {
      throw const ServerException(ErrorConstants.serverError);
    }
    return list
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ServerException(ErrorConstants.serverError);
          }
          return __ENTITY_CLASS__Model.fromJson(item);
        })
        .toList(growable: false);
  }
}
