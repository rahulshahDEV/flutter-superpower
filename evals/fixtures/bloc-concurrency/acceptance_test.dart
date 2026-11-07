import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:concurrency_eval/search_bloc.dart';

final class ReadCall {
  ReadCall(this.query);
  final String query;
  final result = Completer<List<String>>();
}

final class SaveCall {
  SaveCall(this.id, this.payload);
  final String id;
  final String payload;
  final result = Completer<void>();
}

final class ControlledRepository implements SearchRepository {
  final reads = <ReadCall>[];
  final saves = <SaveCall>[];
  final effects = <String>[];
  @override
  Future<List<String>> search(String query) {
    final call = ReadCall(query);
    reads.add(call);
    return call.result.future;
  }

  @override
  Future<void> save(String operationId, String payload) {
    final call = SaveCall(operationId, payload);
    saves.add(call);
    return call.result.future.then((_) {
      effects.add(operationId);
    });
  }
}

// A queue turn drains Bloc's scheduled stream/microtask work; no elapsed-time sleep.
Future<void> drain() => Future<void>(() {});

void main() {
  late ControlledRepository repository;
  late SearchBloc bloc;
  setUp(() {
    repository = ControlledRepository();
    bloc = SearchBloc(repository);
  });
  tearDown(() async {
    // Release controlled work even when an earlier assertion fails.
    for (var turn = 0; turn < 8; turn++) {
      for (final call in repository.reads) {
        if (!call.result.isCompleted) call.result.complete([]);
      }
      for (final call in repository.saves) {
        if (!call.result.isCompleted) call.result.complete();
      }
      await drain();
    }
    if (!bloc.isClosed) await bloc.close().timeout(const Duration(seconds: 2));
  });

  test('refresh and query reads share latest-intent ownership', () async {
    bloc.add(const SearchChanged('a'));
    await drain();
    bloc.add(const SearchRefreshed());
    await drain();
    expect(repository.reads.map((call) => call.query), ['a', 'a']);
    repository.reads[1].result.complete(['fresh']);
    await drain();
    repository.reads[0].result.complete(['stale']);
    await drain();
    expect(bloc.state.items, ['fresh']);
    expect(bloc.state.query, 'a');
    expect(bloc.state.loading, isFalse);
  });

  test('query after refresh rejects stale cross-type failure', () async {
    bloc.add(const SearchChanged('a'));
    await drain();
    repository.reads[0].result.complete(['kept']);
    await drain();
    bloc.add(const SearchRefreshed());
    await drain();
    bloc.add(const SearchChanged('b'));
    await drain();
    repository.reads[2].result.complete(['b-result']);
    await drain();
    repository.reads[1].result.completeError(
      StateError('Internal stale error'),
    );
    await drain();
    expect(bloc.state.items, ['b-result']);
    expect(bloc.state.query, 'b');
    expect(bloc.state.readError, isNull);
  });

  test('latest failure and retained content survive stale success', () async {
    bloc.add(const SearchChanged('q'));
    await drain();
    repository.reads[0].result.complete(['kept']);
    await drain();
    bloc.add(const SearchChanged('new'));
    await drain();
    bloc.add(const SearchRefreshed());
    await drain();
    repository.reads[2].result.completeError(StateError('secret backend text'));
    await drain();
    final failure = bloc.state.readError;
    expect(failure, isNotNull);
    expect(failure, isNot(contains('secret backend text')));
    repository.reads[1].result.complete(['stale']);
    await drain();
    expect(bloc.state.items, ['kept']);
    expect(bloc.state.readError, failure);
    expect(bloc.state.loading, isFalse);
  });

  test(
    'distinct writes are FIFO; duplicates do not drop queued intents or reads',
    () async {
      bloc.add(const SaveRequested('one', 'A'));
      bloc.add(const SaveRequested('one', 'A'));
      bloc.add(const SaveRequested('two', 'B'));
      await drain();
      expect(repository.saves.map((call) => call.id), ['one']);
      bloc.add(const SearchChanged('q'));
      await drain();
      repository.reads.single.result.complete(['read-result']);
      await drain();
      repository.saves[0].result.complete();
      await drain();
      expect(repository.saves.map((call) => call.id), ['one', 'two']);
      repository.saves[1].result.complete();
      await drain();
      bloc.add(const SaveRequested('one', 'A'));
      await drain();
      expect(repository.saves, hasLength(2));
      expect(repository.effects, ['one', 'two']);
      expect(bloc.state.savedIds, unorderedEquals(['one', 'two']));
      expect(bloc.state.items, ['read-result']);
    },
  );

  test(
    'failed write can retry without dropping the next distinct write',
    () async {
      bloc.add(const SaveRequested('one', 'A'));
      bloc.add(const SaveRequested('two', 'B'));
      await drain();
      repository.saves[0].result.completeError(
        StateError('private server details'),
      );
      await drain();
      expect(bloc.state.savedIds, isNot(contains('one')));
      expect(bloc.state.saveError, isNot(contains('private server details')));
      expect(repository.saves.map((call) => call.id), ['one', 'two']);
      bloc.add(const SaveRequested('one', 'A'));
      await drain();
      expect(repository.saves, hasLength(2));
      repository.saves[1].result.complete();
      await drain();
      expect(repository.saves.map((call) => call.id), ['one', 'two', 'one']);
      repository.saves[2].result.complete();
      await drain();
      expect(repository.effects, ['two', 'one']);
      expect(bloc.state.savedIds, unorderedEquals(['two', 'one']));
    },
  );

  test(
    'reusing an operation ID for different payload never writes it',
    () async {
      bloc.add(const SaveRequested('one', 'original'));
      await drain();
      repository.saves.single.result.complete();
      await drain();
      bloc.add(const SaveRequested('one', 'different'));
      await drain();
      expect(repository.saves, hasLength(1));
      expect(bloc.state.saveError, isNotNull);
      expect(bloc.state.savedIds, ['one']);
    },
  );

  test(
    'state snapshots cannot be mutated by repository callers or consumers',
    () async {
      bloc.add(const SearchChanged('q'));
      await drain();
      final input = ['kept'];
      repository.reads.single.result.complete(input);
      await drain();
      input.clear();
      expect(bloc.state.items, ['kept']);
      expect(() => bloc.state.items.clear(), throwsUnsupportedError);
    },
  );

  test(
    'closing with read and write in flight does not cancel the server effect',
    () async {
      bloc.add(const SearchChanged('q'));
      bloc.add(const SaveRequested('one', 'A'));
      await drain();
      final closing = bloc.close();
      repository.reads.single.result.complete(['late']);
      repository.saves.single.result.complete();
      await closing.timeout(const Duration(seconds: 2));
      await drain();
      expect(bloc.isClosed, isTrue);
      expect(repository.effects, ['one']);
    },
  );
}
