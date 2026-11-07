import 'package:flutter_bloc/flutter_bloc.dart';

sealed class CounterEvent {
  const CounterEvent();
}

final class CounterIncremented extends CounterEvent {
  const CounterIncremented();
}

// Existing feature establishes event-based Bloc ownership.
final class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<CounterIncremented>((event, emit) => emit(state + 1));
  }
}
