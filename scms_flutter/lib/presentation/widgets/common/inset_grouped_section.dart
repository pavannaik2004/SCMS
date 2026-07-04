import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// iOS "inset grouped" list section: optional header caption, a rounded card
/// containing [children] separated by leading-inset hairline dividers.
class InsetGroupedSection extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;

  const InsetGroupedSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final sep = isDark ? AppColors.separatorDark : AppColors.separator;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Divider(height: 0.5, thickness: 0.5, color: sep),
        ));
      }
      rows.add(children[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(header!.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(color: secondary)),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: surface,
            child: Column(children: rows),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(footer!,
                style: AppTextStyles.caption.copyWith(color: secondary)),
          ),
      ],
    );
  }
}
