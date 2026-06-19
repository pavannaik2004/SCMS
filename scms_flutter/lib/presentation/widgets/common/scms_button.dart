import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

enum ScmsButtonVariant { primary, secondary, destructive, text }

class ScmsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ScmsButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? height;

  const ScmsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ScmsButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? 54.0;

    Widget contentFor(Color fg) => isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppTextStyles.button.copyWith(color: fg)),
            ],
          );

    switch (variant) {
      case ScmsButtonVariant.primary:
        // Solid indigo pill for a premium primary action (no gradient).
        final enabled = !isLoading && onPressed != null;
        return Opacity(
          opacity: enabled ? 1 : 0.6,
          child: SizedBox(
            width: isFullWidth ? double.infinity : null,
            height: buttonHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: enabled ? onPressed : null,
                  child: Center(child: contentFor(Colors.white)),
                ),
              ),
            ),
          ),
        );
      case ScmsButtonVariant.secondary:
        return SizedBox(
          width: isFullWidth ? double.infinity : null,
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            child: contentFor(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      case ScmsButtonVariant.destructive:
        return SizedBox(
          width: isFullWidth ? double.infinity : null,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.severityHigh,
              foregroundColor: Colors.white,
            ),
            child: contentFor(Colors.white),
          ),
        );
      case ScmsButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: contentFor(Theme.of(context).colorScheme.primary),
        );
    }
  }
}
