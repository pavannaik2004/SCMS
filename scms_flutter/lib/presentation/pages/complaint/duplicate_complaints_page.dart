import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/duplicate_check_model.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart' as scms;
import '../../widgets/common/gradient_app_bar.dart';
import '../../widgets/complaint/status_badge.dart';

/// Shows the list of complaints that are similar to the one the user just
/// submitted (or is about to submit), fetched from the AI duplicate-check API.
///
/// Route arg: [complaintId] — the ID of the submitted complaint whose
/// neighbours we want to display.
class DuplicateComplaintsPage extends StatefulWidget {
  final String complaintId;
  const DuplicateComplaintsPage({super.key, required this.complaintId});

  @override
  State<DuplicateComplaintsPage> createState() =>
      _DuplicateComplaintsPageState();
}

class _DuplicateComplaintsPageState extends State<DuplicateComplaintsPage> {
  late Future<DuplicateCheckModel> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = context.read<ComplaintRepository>();
    // Re-run duplicate check using the complaint's stored description.
    // The repository internally calls the AI service.
    setState(() {
      _future = repo.getDuplicatesForComplaint(widget.complaintId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: GradientAppBar(
        title: 'Similar Complaints',
        glass: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
      ),
      body: FutureBuilder<DuplicateCheckModel>(
        future: _future,
        builder: (context, snapshot) {
          // ── Loading ──────────────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Error ────────────────────────────────────────────────────────
          if (snapshot.hasError) {
            return scms.ScmsErrorWidget(
              message: 'Could not load similar complaints.',
              onRetry: _load,
            );
          }

          final model = snapshot.data!;

          // ── Empty — no duplicates ─────────────────────────────────────────
          if (!model.isDuplicate || model.allMatches.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.check_circle_outline_rounded,
              title: 'No Similar Complaints',
              subtitle:
                  'Your complaint appears to be unique. No similar open tickets were found.',
            );
          }

          // ── Results ──────────────────────────────────────────────────────
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryBanner(count: model.similarCount),
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: model.allMatches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _DuplicateCard(match: model.allMatches[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Summary Banner ───────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  final int count;
  const _SummaryBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.severityMedium.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.severityMedium.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppColors.severityMedium, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count similar complaint${count == 1 ? '' : 's'} found. '
              'Consider upvoting an existing ticket instead of submitting a new one.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Duplicate Match Card ─────────────────────────────────────────────────────

class _DuplicateCard extends StatelessWidget {
  final DuplicateMatch match;
  const _DuplicateCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final similarity = (match.score * 100).toStringAsFixed(0);

    return GestureDetector(
      onTap: () => context.push('/complaint/${match.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _similarityColor(match.score).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$similarity% match',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: _similarityColor(match.score),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  match.complaintNumber,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                StatusBadge(status: match.status),
              ],
            ),
            const SizedBox(height: 10),

            // ── Title ──────────────────────────────────────────────────────
            Text(
              match.title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // ── View button ────────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'View details →',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _similarityColor(double score) {
    if (score >= 0.85) return AppColors.severityHigh;
    if (score >= 0.70) return AppColors.severityMedium;
    return AppColors.primary;
  }
}
