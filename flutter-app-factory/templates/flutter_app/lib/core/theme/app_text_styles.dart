import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get h1 => _base(32, FontWeight.w700, height: 1.25);
  static TextStyle get h2 => _base(28, FontWeight.w600, height: 1.3);
  static TextStyle get h3 => _base(22, FontWeight.w600, height: 1.3);
  static TextStyle get bodyLarge => _base(17, FontWeight.w400, height: 1.5);
  static TextStyle get body => _base(15, FontWeight.w400, height: 1.5);
  static TextStyle get bodySmall => _base(13, FontWeight.w400, height: 1.4);
  static TextStyle get caption => _base(12, FontWeight.w400, height: 1.3);
  static TextStyle get label => _base(14, FontWeight.w500, height: 1.4);

  static TextStyle _base(
    double fontSize,
    FontWeight fontWeight, {
    required double height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize.sp,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: 0,
    );
  }
}
