import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// A single headline stat shown inside [DashboardHero].
class HeroStat {
  final String label;
  final String value;
  final IconData icon;

  const HeroStat({required this.label, required this.value, required this.icon});
}

/// iOS large-title dashboard header: greeting + name + avatar on the grouped
/// background, with a row of light stat tiles below. Sits at the top of role
/// dashboards inside a scroll view.
class DashboardHero extends StatelessWidget {
  final String greeting;
  final String name;
  final String? roleBadge;
  final String? avatarUrl;
  final List<HeroStat> stats;

  const DashboardHero({
    super.key,
    required this.greeting,
    required this.name,
    this.roleBadge,
    this.avatarUrl,
    this.stats = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style:
                            AppTextStyles.bodyMedium.copyWith(color: secondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style:
                            AppTextStyles.displayLarge.copyWith(color: primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (roleBadge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      roleBadge!,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                CircleAvatar(
                  radius: 24,
                  backgroundColor: accent.withValues(alpha: 0.14),
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? Icon(Icons.person, color: accent, size: 24)
                      : null,
                ),
              ],
            ),
            if (stats.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: _StatTile(stat: stats[i])),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final HeroStat stat;
  const _StatTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stat.icon, color: accent, size: 20),
          const SizedBox(height: 8),
          Text(
            stat.value,
            style: AppTextStyles.headlineMedium.copyWith(color: primary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            stat.label,
            style: AppTextStyles.labelSmall.copyWith(color: secondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
