import 'package:factory_core/factory_core.dart';
import 'package:flutter_test/flutter_test.dart';

class CounterCubit extends SafeCubit<int> {
  CounterCubit() : super(0);
  void increment() => safeEmit(state + 1);
}

void main() {
  test('closed cubit ignores asynchronous emissions', () async {
    final cubit = CounterCubit();
    await cubit.close();
    expect(cubit.increment, returnsNormally);
    expect(cubit.state, 0);
  });
}
