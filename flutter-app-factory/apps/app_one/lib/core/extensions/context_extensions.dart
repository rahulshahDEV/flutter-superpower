import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  void goTo(String path, {Object? extra}) => go(path, extra: extra);
  void goReplace(String path, {Object? extra}) => replace(path, extra: extra);
  Future<T?> pushRoute<T>(String path, {Object? extra}) =>
      push<T>(path, extra: extra);
  void popRoute<T extends Object?>([T? result]) => pop(result);
  bool get canPop => GoRouter.of(this).canPop();
}
