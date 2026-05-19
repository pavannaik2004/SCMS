import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: complaint number + status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${complaint.complaintNumber}',
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  StatusBadge(status: complaint.status),
                ],
              ),
              const SizedBox(height: 8),

              // Subject
              Text(
                complaint.subject,
                style: AppTextStyles.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Description preview
              Text(
                complaint.description,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Bottom row: category, severity, time
              Row(
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      complaint.categoryName,
                      style: AppTextStyles.labelSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Severity dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: complaint.severity.toSeverityColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    complaint.severity,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: complaint.severity.toSeverityColor(),
                    ),
                  ),
                  const Spacer(),
                  // Time ago
                  Text(
                    complaint.createdAt.timeAgoString,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),

              // SLA timer if active
              if (complaint.isSlaActive) ...[
                const SizedBox(height: 8),
                SlaTimerWidget(
                  createdAt: complaint.createdAt,
                  deadline: complaint.slaDeadline!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
