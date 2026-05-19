import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/extensions.dart';
import '../../bloc/complaint/complaint_bloc.dart';
import '../../bloc/complaint/complaint_event.dart';
import '../../bloc/complaint/complaint_state.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/scms_button.dart';
import '../../widgets/complaint/status_badge.dart';
import '../../widgets/complaint/sla_timer_widget.dart';

class ComplaintDetailPage extends StatefulWidget {
  final String complaintId;
  const ComplaintDetailPage({super.key, required this.complaintId});

  @override
  State<ComplaintDetailPage> createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<ComplaintBloc>().add(LoadComplaintDetail(complaintId: widget.complaintId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Detail')),
      body: BlocBuilder<ComplaintBloc, ComplaintState>(
        builder: (context, state) {
          if (state is ComplaintLoading) return const Center(child: CircularProgressIndicator());
          if (state is ComplaintError) return ScmsErrorWidget(message: state.message, onRetry: () => context.read<ComplaintBloc>().add(LoadComplaintDetail(complaintId: widget.complaintId)));
          if (state is! ComplaintDetailLoaded) return const SizedBox.shrink();

          final c = state.complaint;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${c.complaintNumber}', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
                  StatusBadge(status: c.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(c.subject, style: AppTextStyles.headlineMedium),
              const SizedBox(height: 4),
              Text('Submitted ${DateFormatter.formatFull(c.createdAt)}', style: AppTextStyles.caption),
              const Divider(height: 24),

              // Description
              Text(c.description, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 16),

              // Meta info
              _infoRow(Icons.location_on_outlined, 'Location', c.location),
              _infoRow(Icons.category_outlined, 'Category', c.categoryName),
              _infoRow(Icons.business_rounded, 'Department', c.departmentName),
              _infoRow(Icons.warning_amber_rounded, 'Severity', c.severity),
              if (c.assignedToName != null)
                _infoRow(Icons.person_outline, 'Assigned To', c.assignedToName!),

              // SLA
              if (c.isSlaActive) ...[
                const SizedBox(height: 16),
                SlaTimerWidget(createdAt: c.createdAt, deadline: c.slaDeadline!),
              ],

              // Timeline
              if (c.updates.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Timeline', style: AppTextStyles.titleLarge),
                const SizedBox(height: 12),
                ...c.updates.map((u) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.timelineIcon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${u.updatedByName} • ${u.newStatus.toStatusLabel()}', style: AppTextStyles.titleSmall),
                            if (u.notes != null) Text(u.notes!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                            Text(DateFormatter.formatRelative(u.timestamp), style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],

              // Rate button
              if (c.canRate) ...[
                const SizedBox(height: 24),
                ScmsButton(
                  label: 'Rate Resolution',
                  icon: Icons.star_rounded,
                  onPressed: () => context.push('/complaint/${c.id}/rate'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text('$label: ', style: AppTextStyles.labelMedium),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
