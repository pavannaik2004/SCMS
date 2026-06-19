import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// A branded app bar used across the role dashboards for a cohesive look.
///
/// Two modes:
/// * default (`glass: false`) — a bold indigo→violet gradient hero bar.
/// * `glass: true` — a frosted, translucent bar that lets the page backdrop
///   show through (pairs with [AppScaffold]).
///
/// Optionally shows a role badge on the right.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? roleBadge;
  final List<Widget>? actions;
  final bool glass;
  final Widget? leading;

  const GradientAppBar({
    super.key,
    required this.title,
    this.roleBadge,
    this.actions,
    this.glass = false,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = glass
        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
        : Colors.white;

    final bar = AppBar(
      title: Text(title, style: AppTextStyles.titleLarge.copyWith(color: fg)),
      backgroundColor: Colors.transparent,
      foregroundColor: fg,
      elevation: 0,
      leading: leading,
      iconTheme: IconThemeData(color: fg),
      flexibleSpace: glass
          ? _GlassBarBackground(isDark: isDark)
          : const DecoratedBox(
              decoration: BoxDecoration(color: AppColors.primary),
            ),
      actions: [
        ...?actions,
        if (roleBadge != null)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: glass
                  ? AppColors.primary.withOpacity(0.12)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              roleBadge!,
              style: AppTextStyles.labelSmall.copyWith(
                color: glass ? AppColors.primary : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );

    return bar;
  }
}

class _GlassBarBackground extends StatelessWidget {
  final bool isDark;
  const _GlassBarBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withOpacity(0.5)
                : Colors.white.withOpacity(0.55),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AppColors.glassBorderDark
                    : AppColors.glassBorderLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
