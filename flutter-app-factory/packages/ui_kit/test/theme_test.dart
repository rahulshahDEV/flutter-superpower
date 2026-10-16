import 'package:factory_ui_kit/factory_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('both themes use Material 3 and honor brightness', () {
    for (final brightness in Brightness.values) {
      final theme = FactoryTheme.theme(brightness);
      expect(theme.useMaterial3, true);
      expect(theme.brightness, brightness);
    }
  });
  testWidgets('responsive content respects available width', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ResponsiveContent(child: SizedBox.expand())),
    );
    expect(
      tester.getSize(find.byType(ResponsiveContent)).width,
      lessThanOrEqualTo(840),
    );
  });
}
