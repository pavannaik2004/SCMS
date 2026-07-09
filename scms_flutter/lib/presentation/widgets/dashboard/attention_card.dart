import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/complaint_model.dart';
import '../common/glass_container.dart';

/// Highlights complaints that need attention: already SLA-breached, or with an
/// active SLA deadline falling within [riskWindow]. Hidden when there's nothing
/// urgent. Tapping a row invokes [onTapComplaint].
class AttentionCard extends StatelessWidget {
  final List<ComplaintModel> complaints;
  final void Function(ComplaintModel) onTapComplaint;
  final Duration riskWindow;
  final int maxItems;

  const AttentionCard({
    super.key,
    required this.complaints,
    required this.onTapComplaint,
    this.riskWindow = const Duration(hours: 12),
    this.maxItems = 3,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final atRisk = complaints.where((c) {
      if (c.isSlaBreached &&
          !['RESOLVED', 'COMPLETED', 'CLOSED', 'REJECTED'].contains(c.status)) {
        return true;
      }
      if (c.isSlaActive && c.slaDeadline != null) {
        final remaining = c.slaDeadline!.difference(now);
        return !remaining.isNegative && remaining <= riskWindow;
      }
      return false;
    }).toList()
      ..sort((a, b) =>
          (a.slaDeadline ?? now).compareTo(b.slaDeadline ?? now));

    if (atRisk.isEmpty) return const SizedBox.shrink();

    final shown = atRisk.take(maxItems).toList();
    const accent = AppColors.severityHigh;

    return GlassContainer(
      borderColor: accent.withOpacity(0.30),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: accent, size: 20),
              const SizedBox(width: 8),
              Text('Needs attention', style: AppTextStyles.titleMedium),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${atRisk.length}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final c in shown)
            _AttentionRow(
              complaint: c,
              now: now,
              onTap: () => onTapComplaint(c),
            ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  final ComplaintModel complaint;
  final DateTime now;
  final VoidCallback onTap;

  const _AttentionRow({
    required this.complaint,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final breached = complaint.isSlaBreached;
    final remaining = complaint.slaDeadline?.difference(now);
    final label = breached
        ? 'SLA breached'
        : remaining == null
            ? ''
            : remaining.inHours >= 1
                ? '${remaining.inHours}h left'
                : '${remaining.inMinutes}m left';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                complaint.subject,
                style: AppTextStyles.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.severityHigh,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
