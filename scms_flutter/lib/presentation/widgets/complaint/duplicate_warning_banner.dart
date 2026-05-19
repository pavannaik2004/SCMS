import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/duplicate_check_model.dart';

class DuplicateWarningBanner extends StatelessWidget {
  final DuplicateCheckModel duplicateResult;
  final VoidCallback onViewDuplicates;
  final VoidCallback onSubmitAnyway;

  const DuplicateWarningBanner({
    super.key,
    required this.duplicateResult,
    required this.onViewDuplicates,
    required this.onSubmitAnyway,
  });

  @override
  Widget build(BuildContext context) {
    if (!duplicateResult.isDuplicate) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.severityMedium.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.severityMedium.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.severityMedium),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Possible duplicate found (${duplicateResult.similarCount} similar)',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.severityMedium),
                ),
              ),
            ],
          ),
          if (duplicateResult.topMatch != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${duplicateResult.topMatch!.complaintNumber}',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    duplicateResult.topMatch!.title,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${duplicateResult.topMatch!.similarityPercent} similar • ${duplicateResult.topMatch!.status}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onViewDuplicates,
                child: const Text('View Duplicates'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onSubmitAnyway,
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36)),
                child: const Text('Submit Anyway'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
