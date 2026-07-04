import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// iOS segmented control: a rounded track with a sliding selected chip.
class CupertinoSegmentedTabs extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const CupertinoSegmentedTabs({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final selectedFill = isDark ? AppColors.surfaceDark : Colors.white;
    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(9),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final segW = c.maxWidth / segments.length;
        return Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: segW * selectedIndex,
            top: 0,
            bottom: 0,
            width: segW,
            child: Container(
              decoration: BoxDecoration(
                color: selectedFill,
                borderRadius: BorderRadius.circular(7),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1)),
                ],
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < segments.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: Center(
                      child: Text(
                        segments[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: (i == selectedIndex
                                ? AppTextStyles.titleSmall
                                : AppTextStyles.bodyMedium)
                            .copyWith(
                                color: i == selectedIndex ? primary : secondary),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ]);
      }),
    );
  }
}
