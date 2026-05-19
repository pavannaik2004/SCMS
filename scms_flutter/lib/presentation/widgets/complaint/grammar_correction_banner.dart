import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/grammar_correction_model.dart';

class GrammarCorrectionBanner extends StatelessWidget {
  final GrammarCorrectionModel correction;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const GrammarCorrectionBanner({
    super.key,
    required this.correction,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (!correction.hasCorrections) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_fix_high_rounded, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('AI Grammar Suggestion', style: AppTextStyles.labelLarge.copyWith(color: AppColors.accent)),
              const Spacer(),
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Show diffs with color coding
          RichText(
            text: TextSpan(
              children: correction.diffs.map((diff) {
                if (diff.isDelete) {
                  return TextSpan(
                    text: diff.text,
                    style: const TextStyle(
                      color: AppColors.severityHigh,
                      decoration: TextDecoration.lineThrough,
                      fontSize: 13,
                    ),
                  );
                }
                if (diff.isInsert) {
                  return TextSpan(
                    text: diff.text,
                    style: const TextStyle(
                      color: AppColors.confidenceHigh,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  );
                }
                return TextSpan(
                  text: diff.text,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onDismiss, child: const Text('Ignore')),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Apply'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
