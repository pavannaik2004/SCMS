import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// A solid iOS-style surface card (formerly a frosted-glass container). Keeps
/// the original API for compatibility, but now renders an opaque [surface] fill
/// with a soft low shadow — the app's content chrome is solid, not glass.
/// ([blurSigma]/[borderColor] are accepted for API stability and largely
/// ignored; blur is reserved for nav/tab bars.)
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final VoidCallback? onTap;
  final Color? fill;
  final Color? borderColor;
  final bool showShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 14,
    this.blurSigma = AppColors.glassBlurSigma,
    this.onTap,
    this.fill,
    this.borderColor,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);
    final resolvedFill =
        fill ?? (isDark ? AppColors.surfaceDark : AppColors.surface);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedFill,
        borderRadius: radius,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }
    return content;
  }
}
