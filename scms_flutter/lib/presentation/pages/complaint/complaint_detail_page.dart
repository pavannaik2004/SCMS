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
import '../../widgets/common/media_image.dart';
import '../../widgets/common/scms_button.dart';
import '../../widgets/complaint/sla_timer_widget.dart';
import '../../widgets/complaint/status_badge.dart';

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
          final isAdmin = role == 'ROLE_ADMIN' || role == 'ROLE_DEPT_HEAD';
          final canAssign = isAdmin;
          // Admin verifies the staff's proof once the ticket is RESOLVED.
          final canVerify = isAdmin && c.status == 'RESOLVED';
          // The submitter can edit/delete their own complaint.
          final isOwner = authState is AuthAuthenticated &&
              authState.user.id == c.submittedById;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text('#${c.complaintNumber}'),
                actions: [
                  if (canAssign)
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      tooltip: c.assignedToName == null
                          ? 'Assign to staff'
                          : 'Reassign',
                      onPressed: () => _showAssignSheet(context, c),
                    ),
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit complaint',
                      onPressed: () => _showEditSheet(context, c),
                    ),
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'Delete complaint',
                      onPressed: () => _confirmDelete(context, c),
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.subject,
                        style: AppTextStyles.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      StatusBadge(status: c.status, fontSize: 13),
                      const SizedBox(height: 16),
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
                      if (c.photoUrls.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _Section(
                          title: 'Attachments',
                          child: _buildPhotoGallery(c.photoUrls),
                        ),
                      ],
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
                      if (c.proofUrls.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _Section(
                          title: 'Resolution Proof',
                          child: _buildPhotoGallery(c.proofUrls),
                        ),
                      ],
                      if (canVerify) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ScmsButton(
                                label: 'Approve',
                                icon: Icons.check_circle_outline_rounded,
                                onPressed: () => _approveResolution(c),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ScmsButton(
                                label: 'Send back',
                                icon: Icons.replay_rounded,
                                variant: ScmsButtonVariant.secondary,
                                onPressed: () => _sendBackForRework(c),
                              ),
                            ),
                          ],
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

  void _showEditSheet(BuildContext pageContext, ComplaintModel c) async {
    final updated = await showModalBottomSheet<bool>(
      context: pageContext,
      isScrollControlled: true,
      backgroundColor: Theme.of(pageContext).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _EditComplaintSheet(complaint: c),
    );
    if (updated == true && mounted) {
      context
          .read<ComplaintBloc>()
          .add(LoadComplaintDetail(complaintId: c.id));
    }
  }

  void _confirmDelete(BuildContext pageContext, ComplaintModel c) async {
    final confirmed = await showDialog<bool>(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete complaint?'),
        content: Text(
          'This will permanently delete "${c.subject}". This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.severityHigh),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteComplaint(c.id);
    }
  }

  Future<void> _deleteComplaint(String id) async {
    final repository = context.read<ComplaintRepository>();
    try {
      await repository.deleteComplaint(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint deleted.')),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete complaint.')),
      );
    }
  }

  /// Horizontal gallery of complaint media (submission photos or resolution
  /// proof). URLs may be server-relative (/Storage/..) — [MediaImage] resolves
  /// them against the effective backend base URL. Tapping opens a full-screen,
  /// zoomable viewer.
  Widget _buildPhotoGallery(List<String> urls) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => _openPhotoViewer(urls[i]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MediaImage(url: urls[i], width: 120, height: 120),
            ),
          );
        },
      ),
    );
  }

  void _openPhotoViewer(String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: MediaImage(
                url: url,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _approveResolution(ComplaintModel c) async {
    final repository = context.read<ComplaintRepository>();
    final bloc = context.read<ComplaintBloc>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repository.verifyResolution(c.id, decision: 'APPROVE');
      messenger.showSnackBar(
        const SnackBar(content: Text('Complaint marked as completed.')),
      );
      bloc.add(LoadComplaintDetail(complaintId: c.id));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to approve: $e')),
      );
    }
  }

  Future<void> _sendBackForRework(ComplaintModel c) async {
    final repository = context.read<ComplaintRepository>();
    final bloc = context.read<ComplaintBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send back for rework'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('The task returns to the same staff member as In Progress.'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason / instructions',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send back'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      notesController.dispose();
      return;
    }

    try {
      await repository.verifyResolution(
        c.id,
        decision: 'REDO',
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Sent back to staff for rework.')),
      );
      bloc.add(LoadComplaintDetail(complaintId: c.id));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to send back: $e')),
      );
    } finally {
      notesController.dispose();
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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

/// Bottom-sheet form for the submitter to edit their own complaint.
/// Edits title/description/location/severity; performs the update itself and
/// pops `true` on success so the detail page can reload.
class _EditComplaintSheet extends StatefulWidget {
  final ComplaintModel complaint;
  const _EditComplaintSheet({required this.complaint});

  @override
  State<_EditComplaintSheet> createState() => _EditComplaintSheetState();
}

class _EditComplaintSheetState extends State<_EditComplaintSheet> {
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _locationCtrl;
  late String _severity;
  bool _saving = false;

  static const _severities = ['LOW', 'MEDIUM', 'HIGH'];

  @override
  void initState() {
    super.initState();
    _subjectCtrl = TextEditingController(text: widget.complaint.subject);
    _descriptionCtrl =
        TextEditingController(text: widget.complaint.description);
    _locationCtrl = TextEditingController(text: widget.complaint.location);
    _severity = _severities.contains(widget.complaint.severity)
        ? widget.complaint.severity
        : 'MEDIUM';
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final subject = _subjectCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    if (subject.isEmpty || description.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title, description and location are required.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<ComplaintRepository>().updateComplaint(
            widget.complaint.id,
            subject: subject,
            description: description,
            location: location,
            severity: _severity,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update complaint.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit complaint', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _severity,
              decoration: const InputDecoration(
                labelText: 'Severity',
                border: OutlineInputBorder(),
              ),
              items: _severities
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.capitalize()),
                      ))
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _severity = v ?? _severity),
            ),
            const SizedBox(height: 20),
            ScmsButton(
              label: 'Save Changes',
              icon: Icons.check_rounded,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 8),
          ],
        ),
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
