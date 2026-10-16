import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:battery_analyzer/core/theme/app_theme.dart';
import 'package:battery_analyzer/core/widgets/error_state_widget.dart';

void main() {
  testWidgets('error state offers retry under large text', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Example error',
              onRetry: () {
                retried = true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    expect(retried, isTrue);
    expect(tester.takeException(), isNull);
  });
}
