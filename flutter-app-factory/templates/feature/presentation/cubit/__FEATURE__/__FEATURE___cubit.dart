import 'package:injectable/injectable.dart';

import 'package:__APP_NAME__/core/cubit/safe_cubit.dart';
import 'package:__APP_NAME__/core/usecases/usecase.dart';
import 'package:__APP_NAME__/features/__FEATURE__/domain/usecases/get___FEATURE__.dart';
import 'package:__APP_NAME__/features/__FEATURE__/presentation/cubit/__FEATURE__/__FEATURE___state.dart';

@injectable
class __FEATURE_CLASS__Cubit extends SafeCubit<__FEATURE_CLASS__State> {
  __FEATURE_CLASS__Cubit(this._get__FEATURE_CLASS__)
      : super(const __FEATURE_CLASS__Initial());

  final Get__FEATURE_CLASS__ _get__FEATURE_CLASS__;
  int _latestRequestId = 0;

  Future<void> load() async {
    final requestId = ++_latestRequestId;
    safeEmit(const __FEATURE_CLASS__Loading());

    final result = await _get__FEATURE_CLASS__(const NoParams());
    if (isClosed || requestId != _latestRequestId) return;

    result.fold(
      (failure) => safeEmit(__FEATURE_CLASS__Failure(failure)),
      (items) => safeEmit(__FEATURE_CLASS__Success(items)),
    );
  }
}
