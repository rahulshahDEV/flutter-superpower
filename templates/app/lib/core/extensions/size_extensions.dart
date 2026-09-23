import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSizes {
  AppSizes._();

  static const Size designSize = Size(390, 844);

  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 16.w;
  static double get lg => 24.w;
  static double get xl => 32.w;
  static double get xxl => 48.w;

  static double get radiusSm => 4.r;
  static double get radiusMd => 8.r;
  static double get radiusLg => 12.r;
  static double get radiusXl => 16.r;
  static double get radius2Xl => 24.r;
  static double get radiusFull => 999.r;
}

class VerticalSpace extends StatelessWidget {
  const VerticalSpace(this.height, {super.key});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(height: height.h);
}

class HorizontalSpace extends StatelessWidget {
  const HorizontalSpace(this.width, {super.key});

  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(width: width.w);
}
