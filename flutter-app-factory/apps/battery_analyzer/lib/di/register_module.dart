import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:battery_analyzer/core/network/dio_client.dart';
import 'package:battery_analyzer/core/storage/local_storage_service.dart';

@module
abstract class RegisterModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @lazySingleton
  LocalStorageService localStorageService(SharedPreferences prefs) =>
      LocalStorageService(prefs);

  @lazySingleton
  DioClient dioClient(LocalStorageService storage) => DioClient(storage);
}
