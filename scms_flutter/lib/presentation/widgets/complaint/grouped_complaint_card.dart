import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/complaint_model.dart';
import 'status_badge.dart';

class GroupedComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final double? similarityScore;
  final VoidCallback? onTap;

  const GroupedComplaintCard({
    super.key,
    required this.complaint,
    this.similarityScore,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(complaint.subject, style: AppTextStyles.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('#${complaint.complaintNumber}', style: AppTextStyles.caption),
            if (similarityScore != null) ...[
              const SizedBox(height: 4),
              Text('${(similarityScore! * 100).toStringAsFixed(0)}% similar',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.severityMedium)),
            ],
          ],
        ),
        trailing: StatusBadge(status: complaint.status),
      ),
    );
  }
}
