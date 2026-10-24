import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:__APP_NAME__/core/extensions/size_extensions.dart';
import 'package:__APP_NAME__/core/theme/app_colors.dart';
import 'package:__APP_NAME__/core/theme/app_text_styles.dart';

class KTextField extends StatelessWidget {
  const KTextField({
    required this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.onSubmitted,
    this.onChanged,
    this.validator,
    this.focusNode,
    this.autofillHints,
    this.autovalidateMode,
    this.enabled = true,
    this.readOnly = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    super.key,
  });

  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final AutovalidateMode? autovalidateMode;
  final bool enabled;
  final bool readOnly;
  final bool autocorrect;
  final bool enableSuggestions;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      validator: validator,
      focusNode: focusNode,
      autofillHints: autofillHints,
      autovalidateMode: autovalidateMode,
      enabled: enabled,
      readOnly: readOnly,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.white,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: 14.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}
