import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'pressable_scale.dart';

enum ScmsButtonVariant { primary, secondary, destructive, text }

/// iOS-style action button.
/// - primary: solid accent fill (flat)
/// - secondary: tinted accent (accent @15% bg, accent text)
/// - destructive: solid system red
/// - text: plain accent text
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final buttonHeight = height ?? 50.0;
    final enabled = !isLoading && onPressed != null;

    Widget contentFor(Color fg) => isLoading
        ? SizedBox(
            width: 20,
            height: 20,
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

    Color bg;
    Color fg;
    switch (variant) {
      case ScmsButtonVariant.primary:
        bg = accent;
        fg = Colors.white;
        break;
      case ScmsButtonVariant.secondary:
        bg = AppColors.fillTinted(accent);
        fg = accent;
        break;
      case ScmsButtonVariant.destructive:
        bg = AppColors.systemRed;
        fg = Colors.white;
        break;
      case ScmsButtonVariant.text:
        return TextButton(
          onPressed: enabled ? onPressed : null,
          child: contentFor(accent),
        );
    }

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: PressableScale(
        onTap: enabled ? onPressed : null,
        child: Container(
          width: isFullWidth ? double.infinity : null,
          height: buttonHeight,
          alignment: Alignment.center,
          padding: isFullWidth
              ? null
              : const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: contentFor(fg),
        ),
      ),
    );
  }
}
