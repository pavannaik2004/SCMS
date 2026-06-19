import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/complaint_model.dart';
import 'status_badge.dart';
import 'sla_timer_widget.dart';

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
    final statusColor = complaint.status.toStatusColor();
    final severityColor = complaint.severity.toSeverityColor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border.withOpacity(0.7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : AppColors.primary.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status accent stripe (solid)
                Container(
                  width: 5,
                  color: statusColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Category icon tile
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: severityColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
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
                                    style: AppTextStyles.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '#${complaint.complaintNumber}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
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
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _Pill(
                              icon: Icons.circle,
                              iconSize: 8,
                              label: complaint.severity.capitalize(),
                              color: severityColor,
                            ),
                            const SizedBox(width: 8),
                            if (complaint.categoryName.isNotEmpty)
                              Flexible(
                                child: _Pill(
                                  icon: Icons.folder_outlined,
                                  label: complaint.categoryName,
                                  color: AppColors.textSecondary,
                                  muted: true,
                                ),
                              ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String label;
  final Color color;
  final bool muted;

  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
    this.iconSize = 12,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(muted ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: muted ? AppColors.textSecondary : color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
