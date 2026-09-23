import 'package:flutter_test/flutter_test.dart';

import 'package:__APP_NAME__/core/usecases/usecase.dart';

void main() {
  group('NoParams', () {
    test('is equal to another NoParams', () {
      expect(const NoParams(), const NoParams());
    });
  });
}
