import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/complaint_model.dart';
import '../common/glass_card.dart';

/// A donut chart summarizing a set of complaints by status, with the total in
/// the center and a compact legend. Derived entirely from the passed list — no
/// extra network calls.
class StatusBreakdownRing extends StatelessWidget {
  final List<ComplaintModel> complaints;
  final String title;

  const StatusBreakdownRing({
    super.key,
    required this.complaints,
    this.title = 'Status breakdown',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    // Aggregate counts per status, preserving a sensible display order.
    const order = [
      'PENDING_SR_REVIEW',
      'OPEN',
      'ASSIGNED',
      'IN_PROGRESS',
      'RESOLVED',
      'CLOSED',
      'REJECTED',
    ];
    final counts = <String, int>{};
    for (final c in complaints) {
      counts[c.status] = (counts[c.status] ?? 0) + 1;
    }
    final entries = order
        .where((s) => (counts[s] ?? 0) > 0)
        .map((s) => MapEntry(s, counts[s]!))
        .toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nothing to show yet',
                  style: AppTextStyles.bodySmall.copyWith(color: secondary),
                ),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          centerSpaceRadius: 42,
                          sectionsSpace: 2,
                          startDegreeOffset: -90,
                          sections: entries.map((e) {
                            final color = AppColors.statusColor(e.key);
                            return PieChartSectionData(
                              color: color,
                              value: e.value.toDouble(),
                              radius: 18,
                              showTitle: false,
                            );
                          }).toList(),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${complaints.length}',
                            style: AppTextStyles.headlineMedium,
                          ),
                          Text(
                            'total',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: secondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entries
                        .map((e) => _LegendRow(
                              color: AppColors.statusColor(e.key),
                              label: e.key.toStatusLabel(),
                              count: e.value,
                              secondary: secondary,
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final Color secondary;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$count',
            style: AppTextStyles.titleSmall.copyWith(color: secondary),
          ),
        ],
      ),
    );
  }
}
