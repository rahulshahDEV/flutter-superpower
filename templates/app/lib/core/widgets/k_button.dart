import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:__APP_NAME__/core/extensions/size_extensions.dart';
import 'package:__APP_NAME__/core/theme/app_colors.dart';
import 'package:__APP_NAME__/core/theme/app_text_styles.dart';

enum KButtonVariant { primary, secondary, outlined }

class KButton extends StatelessWidget {
  const KButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.variant = KButtonVariant.primary,
    this.leadingIcon,
    this.height,
    super.key,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final KButtonVariant variant;
  final IconData? leadingIcon;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: (height ?? 52).clamp(48, double.infinity),
      ),
      child: FilledButton(
        onPressed: isEnabled ? onPressed : null,
        style: _style().copyWith(
          minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 48)),
          padding: WidgetStatePropertyAll(EdgeInsets.all(AppSizes.md)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Visibility(
              visible: !isLoading,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: 20.r),
                    HorizontalSpace(AppSizes.sm),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: AppTextStyles.label,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              Semantics(
                label: text,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _style() {
    return switch (variant) {
      KButtonVariant.primary => FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
      ),
      KButtonVariant.secondary => FilledButton.styleFrom(
        backgroundColor: AppColors.textPrimary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
      ),
      KButtonVariant.outlined => FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
      ),
    };
  }
}
