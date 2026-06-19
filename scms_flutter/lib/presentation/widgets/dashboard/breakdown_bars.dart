import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../common/glass_card.dart';

/// A compact horizontal-bar breakdown (label · proportional bar · count),
/// useful for distributions like "pending by category" or "by severity".
/// Sorted descending by count; shows the top [maxRows] entries.
class BreakdownBars extends StatelessWidget {
  final String title;
  final Map<String, int> data;
  final Color Function(String label)? colorFor;
  final int maxRows;

  const BreakdownBars({
    super.key,
    required this.title,
    required this.data,
    this.colorFor,
    this.maxRows = 5,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final entries = data.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(maxRows).toList();
    final maxVal =
        top.fold<int>(0, (p, e) => e.value > p ? e.value : p).toDouble();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: 14),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No data yet',
                  style: AppTextStyles.bodySmall.copyWith(color: secondary),
                ),
              ),
            )
          else
            for (final e in top)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        e.key.isEmpty ? 'Other' : e.key,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: maxVal == 0 ? 0 : e.value / maxVal,
                          minHeight: 8,
                          backgroundColor: secondary.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorFor?.call(e.key) ?? AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${e.value}', style: AppTextStyles.titleSmall),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
