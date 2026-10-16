import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SafeCubit<State> extends Cubit<State> {
  SafeCubit(super.initialState);

  void safeEmit(State state) {
    if (!isClosed) emit(state);
  }
}
