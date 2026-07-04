import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/complaint_model.dart';
import 'status_badge.dart';
import 'sla_timer_widget.dart';

/// iOS-clean complaint card: a surface card with a leading category tile,
/// title + description, a compact meta row, and a trailing status pill.
class ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ComplaintCard({
    super.key,
    required this.complaint,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final severityColor = complaint.severity.toSeverityColor();
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        CategoryIcons.forCategory(complaint.categoryName),
                        size: 22,
                        color: severityColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint.subject,
                            style: AppTextStyles.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '#${complaint.complaintNumber}',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: secondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: complaint.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  complaint.description,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: secondary, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: severityColor),
                    const SizedBox(width: 6),
                    Text(
                      complaint.severity.capitalize(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: severityColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (complaint.categoryName.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          complaint.categoryName,
                          style:
                              AppTextStyles.labelSmall.copyWith(color: secondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      complaint.createdAt.timeAgoString,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                if (complaint.isSlaActive) ...[
                  const SizedBox(height: 12),
                  SlaTimerWidget(
                    createdAt: complaint.createdAt,
                    deadline: complaint.slaDeadline!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
