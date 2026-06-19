import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/complaint_update_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/complaint/complaint_bloc.dart';
import '../../bloc/complaint/complaint_event.dart';
import '../../bloc/complaint/complaint_state.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/scms_button.dart';
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
      body: BlocBuilder<ComplaintBloc, ComplaintState>(
        builder: (context, state) {
          if (state is ComplaintLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ComplaintError) {
            return SafeArea(
              child: ScmsErrorWidget(
                message: state.message,
                onRetry: () => context
                    .read<ComplaintBloc>()
                    .add(LoadComplaintDetail(complaintId: widget.complaintId)),
              ),
            );
          }
          if (state is! ComplaintDetailLoaded) return const SizedBox.shrink();

          final c = state.complaint;
          final authState = context.watch<AuthBloc>().state;
          final role =
              authState is AuthAuthenticated ? authState.user.role : null;
          final canAssign =
              role == 'ROLE_ADMIN' || role == 'ROLE_DEPT_HEAD';
          return CustomScrollView(
            slivers: [
              _buildHeader(context, c, canAssign: canAssign),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (c.isSlaActive) ...[
                        _Section(
                          child: SlaTimerWidget(
                            createdAt: c.createdAt,
                            deadline: c.slaDeadline!,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _Section(
                        title: 'Description',
                        child: Text(
                          c.description,
                          style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Section(
                        title: 'Details',
                        child: Column(
                          children: [
                            _infoRow(Icons.location_on_outlined, 'Location', c.location),
                            _infoRow(Icons.folder_outlined, 'Category', c.categoryName),
                            _infoRow(Icons.business_rounded, 'Department', c.departmentName),
                            _infoRow(
                              Icons.flag_outlined,
                              'Severity',
                              c.severity.capitalize(),
                              valueColor: c.severity.toSeverityColor(),
                            ),
                            if (c.assignedToName != null)
                              _infoRow(Icons.engineering_outlined, 'Assigned To', c.assignedToName!),
                            _infoRow(
                              Icons.schedule_rounded,
                              'Submitted',
                              DateFormatter.formatFull(c.createdAt),
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      if (c.tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _Section(
                          title: 'Tags',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: c.tags
                                .map((t) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '#$t',
                                        style: AppTextStyles.labelMedium
                                            .copyWith(color: AppColors.primary),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                      if (c.rating != null) ...[
                        const SizedBox(height: 12),
                        _buildRatingCard(c),
                      ],
                      if (c.updates.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _Section(
                          title: 'Timeline',
                          child: _Timeline(updates: c.updates),
                        ),
                      ],
                      if (c.canRate) ...[
                        const SizedBox(height: 20),
                        ScmsButton(
                          label: 'Rate Resolution',
                          icon: Icons.star_rounded,
                          onPressed: () => context.push('/complaint/${c.id}/rate'),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ComplaintModel c,
      {bool canAssign = false}) {
    final statusColor = c.status.toStatusColor();
    return SliverAppBar(
      pinned: true,
      expandedHeight: 180,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        if (canAssign)
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: c.assignedToName == null ? 'Assign to staff' : 'Reassign',
            onPressed: () => _showAssignSheet(context, c),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(color: AppColors.primary),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${c.complaintNumber}',
                          style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          c.status.toStatusLabel(),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    c.subject,
                    style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAssignSheet(BuildContext pageContext, ComplaintModel c) {
    final repository = pageContext.read<ComplaintRepository>();
    showModalBottomSheet<void>(
      context: pageContext,
      isScrollControlled: true,
      backgroundColor: Theme.of(pageContext).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (sheetContext, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assign to staff', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Assigning sets the status to ASSIGNED and notifies the staff member.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder<List<UserModel>>(
                      future: repository.getStaff(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Failed to load staff list.',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.severityHigh),
                            ),
                          );
                        }
                        final staff = snapshot.data ?? const [];
                        if (staff.isEmpty) {
                          return Center(
                            child: Text(
                              'No staff members available.',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: staff.length,
                          itemBuilder: (context, i) {
                            final s = staff[i];
                            final isCurrent = s.id == c.assignedToId;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.12),
                                backgroundImage: s.picture != null
                                    ? NetworkImage(s.picture!)
                                    : null,
                                child: s.picture == null
                                    ? Text(
                                        s.name.isNotEmpty
                                            ? s.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            color: AppColors.primary),
                                      )
                                    : null,
                              ),
                              title: Text(s.name),
                              subtitle: Text(
                                s.departmentName ?? s.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: isCurrent
                                  ? const Icon(Icons.check_circle_rounded,
                                      color: AppColors.statusResolved)
                                  : const Icon(Icons.chevron_right_rounded),
                              onTap: isCurrent
                                  ? null
                                  : () => _assignTo(sheetContext, repository,
                                      c.id, s),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _assignTo(BuildContext sheetContext,
      ComplaintRepository repository, String complaintId, UserModel staff) async {
    Navigator.pop(sheetContext);
    try {
      await repository.assignComplaint(complaintId, staff.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assigned to ${staff.name}.')),
      );
      context
          .read<ComplaintBloc>()
          .add(LoadComplaintDetail(complaintId: complaintId));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to assign complaint.')),
      );
    }
  }

  Widget _buildRatingCard(ComplaintModel c) {
    return _Section(
      title: 'Your Rating',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < c.rating!.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                color: AppColors.severityLow,
                size: 28,
              ),
            ),
          ),
          if (c.ratingComment != null && c.ratingComment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"${c.ratingComment!}"',
              style: AppTextStyles.bodyMedium.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String? title;
  final Widget child;
  const _Section({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<ComplaintUpdateModel> updates;
  const _Timeline({required this.updates});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(updates.length, (i) {
        final u = updates[i];
        final isLast = i == updates.length - 1;
        final color = u.newStatus.toStatusColor();
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Center(
                      child: Text(u.timelineIcon, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 2, color: AppColors.border),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.newStatus.toStatusLabel(), style: AppTextStyles.titleSmall),
                      if (u.notes != null && u.notes!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          u.notes!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${u.updatedByName} • ${DateFormatter.formatRelative(u.timestamp)}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
