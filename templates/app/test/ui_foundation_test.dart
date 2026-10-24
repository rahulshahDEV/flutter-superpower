import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:__APP_NAME__/app.dart';
import 'package:__APP_NAME__/core/config/app_config.dart';
import 'package:__APP_NAME__/core/config/app_platform.dart';
import 'package:__APP_NAME__/core/constants/string_constants.dart';
import 'package:__APP_NAME__/core/extensions/size_extensions.dart';
import 'package:__APP_NAME__/core/theme/app_colors.dart';
import 'package:__APP_NAME__/core/theme/app_theme.dart';
import 'package:__APP_NAME__/core/widgets/k_button.dart';
import 'package:__APP_NAME__/core/widgets/k_text_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpControl(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(320, 640),
    double textScale = 2,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: AppSizes.designSize,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      ),
    );
  }

  testWidgets('long button label grows at large text without overflow', (
    tester,
  ) async {
    var calls = 0;
    await pumpControl(
      tester,
      KButton(
        text: 'Continue and review all selected items',
        leadingIcon: Icons.check,
        onPressed: () => calls++,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(FilledButton)).height, greaterThan(52));
    await tester.tap(find.byType(FilledButton));
    expect(calls, 1);
  });

  testWidgets('busy button preserves its name and prevents duplicate action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var calls = 0;
      await pumpControl(
        tester,
        KButton(
          text: 'Save changes',
          isLoading: true,
          onPressed: () => calls++,
        ),
      );
      expect(find.bySemanticsLabel('Save changes'), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      expect(calls, 0);
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(48),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('resolved gap tokens are not scaled a second time', (
    tester,
  ) async {
    await pumpControl(
      tester,
      Builder(
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [VerticalSpace(AppSizes.md), HorizontalSpace(AppSizes.sm)],
        ),
      ),
      size: const Size(780, 844),
    );
    expect(tester.getSize(find.byType(VerticalSpace)).height, AppSizes.md);
    expect(tester.getSize(find.byType(HorizontalSpace)).width, AppSizes.sm);
    expect(AppSizes.md, lessThanOrEqualTo(16 * 1.15));
  });

  testWidgets('startup failure is readable without DI or config', (
    tester,
  ) async {
    await tester.pumpWidget(const StartupFailureApp());
    expect(find.text(StringConstants.startupFailed), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared input participates in form validation and keeps input', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final formKey = GlobalKey<FormState>();
    await pumpControl(
      tester,
      Form(
        key: formKey,
        child: KTextField(
          controller: controller,
          focusNode: focusNode,
          labelText: 'Name',
          validator: (value) =>
              value == null || value.isEmpty ? 'Enter a name' : null,
        ),
      ),
    );
    expect(formKey.currentState?.validate(), isFalse);
    await tester.pump();
    expect(find.text('Enter a name'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Example');
    expect(formKey.currentState?.validate(), isTrue);
    expect(controller.text, 'Example');
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    focusNode.dispose();
  });

  test('invalid config fails before it reaches the network client', () {
    dotenv.loadFromString(envString: 'BASE_URL=not-a-url');
    expect(
      () => AppConfig.initialize(flavor: Flavor.dev, appName: 'Test'),
      throwsStateError,
    );
    dotenv.loadFromString(envString: 'BASE_URL=https://api.example.com');
    AppConfig.initialize(flavor: Flavor.dev, appName: 'Test');
    expect(AppConfig.instance.baseUrl, 'https://api.example.com');
  });

  test(
    'mobile platform policy requests OS orientation and edge-to-edge',
    () async {
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await AppPlatform.configure();
      expect(calls.map((call) => call.method), [
        'SystemChrome.setPreferredOrientations',
        'SystemChrome.setEnabledSystemUIMode',
      ]);
      expect(calls.first.arguments, isEmpty);
      expect(calls.last.arguments, 'SystemUiMode.edgeToEdge');
    },
  );

  testWidgets('loading preserves the multiline button footprint', (
    tester,
  ) async {
    const label = 'Continue and review all selected items';
    await pumpControl(tester, KButton(text: label, onPressed: () {}));
    final size = tester.getSize(find.byType(FilledButton));
    await pumpControl(
      tester,
      KButton(text: label, onPressed: () {}, isLoading: true),
    );
    expect(tester.getSize(find.byType(FilledButton)), size);
    expect(tester.takeException(), isNull);
  });

  test('light edge-to-edge surfaces request dark icons for both bars', () {
    expect(
      AppTheme.systemUiOverlayStyle.statusBarIconBrightness,
      Brightness.dark,
    );
    expect(
      AppTheme.systemUiOverlayStyle.systemNavigationBarIconBrightness,
      Brightness.dark,
    );
  });

  test('primary button foreground meets normal-text contrast', () {
    final contrast =
        (AppColors.white.computeLuminance() + 0.05) /
        (AppColors.primary.computeLuminance() + 0.05);
    expect(contrast, greaterThanOrEqualTo(4.5));
  });
}
