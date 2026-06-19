import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/complaint_model.dart';
import '../common/glass_card.dart';

/// A 7-day line chart of how many complaints were created per day, derived from
/// the passed list. Used on staff/admin dashboards to show recent inflow.
class TrendSparkline extends StatelessWidget {
  final List<ComplaintModel> complaints;
  final String title;
  final int days;

  const TrendSparkline({
    super.key,
    required this.complaints,
    this.title = 'Last 7 days',
    this.days = 7,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    // Bucket counts per day for the trailing [days] window.
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final buckets = List<int>.filled(days, 0);
    final labels = <String>[];
    for (var i = 0; i < days; i++) {
      final day = startOfToday.subtract(Duration(days: days - 1 - i));
      labels.add(_weekday(day.weekday));
    }
    for (final c in complaints) {
      final created =
          DateTime(c.createdAt.year, c.createdAt.month, c.createdAt.day);
      final diff = startOfToday.difference(created).inDays;
      final idx = days - 1 - diff;
      if (idx >= 0 && idx < days) buckets[idx]++;
    }

    final maxY = buckets.fold<int>(0, (p, c) => c > p ? c : p).toDouble();
    final total = buckets.fold<int>(0, (p, c) => p + c);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppTextStyles.titleMedium),
              const Spacer(),
              Text(
                '$total total',
                style: AppTextStyles.labelMedium.copyWith(color: secondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY == 0 ? 4 : maxY + 1,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[i],
                            style: AppTextStyles.labelSmall
                                .copyWith(color: secondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < buckets.length; i++)
                        FlSpot(i.toDouble(), buckets[i].toDouble()),
                    ],
                    isCurved: true,
                    barWidth: 3,
                    color: AppColors.primary,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _weekday(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(weekday - 1) % 7];
  }
}
