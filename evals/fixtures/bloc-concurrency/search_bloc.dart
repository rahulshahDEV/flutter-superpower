import 'package:flutter_bloc/flutter_bloc.dart';

abstract interface class SearchRepository {
  Future<List<String>> search(String query);
  Future<void> save(String operationId, String payload);
}

sealed class SearchEvent {
  const SearchEvent();
}

final class SearchChanged extends SearchEvent {
  const SearchChanged(this.query);
  final String query;
}

final class SearchRefreshed extends SearchEvent {
  const SearchRefreshed();
}

final class SaveRequested extends SearchEvent {
  const SaveRequested(this.operationId, this.payload);
  final String operationId;
  final String payload;
}

final class SearchState {
  SearchState({
    this.query = '',
    List<String> items = const [],
    this.loading = false,
    this.readError,
    List<String> savedIds = const [],
    this.saveError,
  }) : items = List.unmodifiable(items),
       savedIds = List.unmodifiable(savedIds);
  final String query;
  final List<String> items;
  final bool loading;
  final String? readError;
  final List<String> savedIds;
  final String? saveError;
}

final class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this.repository) : super(SearchState()) {
    on<SearchChanged>((event, emit) => _read(event.query, emit));
    on<SearchRefreshed>((event, emit) => _read(state.query, emit));
    on<SaveRequested>((event, emit) async {
      await repository.save(event.operationId, event.payload);
      emit(
        SearchState(
          query: state.query,
          items: state.items,
          loading: state.loading,
          readError: state.readError,
          savedIds: [...state.savedIds, event.operationId],
        ),
      );
    });
  }
  final SearchRepository repository;
  Future<void> _read(String query, Emitter<SearchState> emit) async {
    emit(
      SearchState(
        query: query,
        items: state.items,
        loading: true,
        savedIds: state.savedIds,
      ),
    );
    final items = await repository.search(query);
    emit(SearchState(query: query, items: items, savedIds: state.savedIds));
  }
}
