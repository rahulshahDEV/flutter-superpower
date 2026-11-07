import 'package:flutter_bloc/flutter_bloc.dart';

// Existing feature establishes Cubit ownership; it is unrelated to order history.
final class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
}
