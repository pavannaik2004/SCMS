import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/complaint_update_model.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../domain/usecases/update_complaint_status_usecase.dart';
import '../../bloc/complaint/complaint_bloc.dart';
import '../../bloc/complaint/complaint_event.dart';
import '../../bloc/complaint/complaint_state.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/scms_button.dart';
import '../../widgets/common/scms_text_field.dart';
import '../../widgets/complaint/status_badge.dart';
import '../../widgets/complaint/sla_timer_widget.dart';

class StaffComplaintDetailPage extends StatefulWidget {
	final String complaintId;
	const StaffComplaintDetailPage({super.key, required this.complaintId});

	@override
	State<StaffComplaintDetailPage> createState() => _StaffComplaintDetailPageState();
}

class _StaffComplaintDetailPageState extends State<StaffComplaintDetailPage> {
	late final UpdateComplaintStatusUseCase _updateStatusUseCase;
	final TextEditingController _notesController = TextEditingController();
	String? _selectedStatus;
	bool _isSaving = false;

	@override
	void initState() {
		super.initState();
		_updateStatusUseCase = UpdateComplaintStatusUseCase(
			repository: context.read<ComplaintRepository>(),
		);
		context.read<ComplaintBloc>().add(
					LoadComplaintDetail(complaintId: widget.complaintId),
				);
	}

	@override
	void dispose() {
		_notesController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return AppScaffold(
			appBar: AppBar(title: const Text('Task Detail')),
			body: BlocBuilder<ComplaintBloc, ComplaintState>(
				builder: (context, state) {
					if (state is ComplaintLoading) {
						return const Center(child: CircularProgressIndicator());
					}
					if (state is ComplaintError) {
						return ScmsErrorWidget(
							message: state.message,
							onRetry: () => context.read<ComplaintBloc>().add(
										LoadComplaintDetail(complaintId: widget.complaintId),
									),
						);
					}
					if (state is! ComplaintDetailLoaded) return const SizedBox.shrink();

					final c = state.complaint;
					_selectedStatus ??= c.status;

					final options = _statusOptions(c.status);
					final canUpdate = options.isNotEmpty;

					return LoadingOverlay(
						isLoading: _isSaving,
						message: 'Updating status...',
						child: ListView(
							padding: const EdgeInsets.all(16),
							children: [
								Row(
									mainAxisAlignment: MainAxisAlignment.spaceBetween,
									children: [
										Text(
											'#${c.complaintNumber}',
											style: AppTextStyles.labelMedium.copyWith(
												color: AppColors.textSecondary,
											),
										),
										StatusBadge(status: c.status),
									],
								),
								const SizedBox(height: 8),
								Text(c.subject, style: AppTextStyles.headlineMedium),
								const SizedBox(height: 4),
								Text(
									'Submitted ${DateFormatter.formatFull(c.createdAt)}',
									style: AppTextStyles.caption,
								),
								const Divider(height: 24),
								Text(c.description, style: AppTextStyles.bodyMedium),
								const SizedBox(height: 16),
								_infoRow(Icons.location_on_outlined, 'Location', c.location),
								_infoRow(Icons.category_outlined, 'Category', c.categoryName),
								_infoRow(Icons.business_rounded, 'Department', c.departmentName),
								_infoRow(Icons.warning_amber_rounded, 'Severity', c.severity),
								if (c.isSlaActive) ...[
									const SizedBox(height: 16),
									SlaTimerWidget(createdAt: c.createdAt, deadline: c.slaDeadline!),
								],
								const SizedBox(height: 24),
								Text('Update Status', style: AppTextStyles.titleLarge),
								const SizedBox(height: 12),
								DropdownButtonFormField<String>(
									value: options.contains(_selectedStatus) ? _selectedStatus : options.first,
									decoration: const InputDecoration(labelText: 'Status'),
									items: options
											.map(
												(status) => DropdownMenuItem(
													value: status,
													child: Text(status.toStatusLabel()),
												),
											)
											.toList(),
									onChanged: canUpdate
											? (value) => setState(() => _selectedStatus = value)
											: null,
								),
								const SizedBox(height: 12),
								ScmsTextField(
									label: 'Work Notes',
									hint: 'Add update details for the timeline',
									controller: _notesController,
									maxLines: 3,
								),
								const SizedBox(height: 16),
								ScmsButton(
									label: 'Save Update',
									onPressed: canUpdate ? () => _saveUpdate(c) : null,
								),
								if (c.updates.isNotEmpty) ...[
									const SizedBox(height: 28),
									Text('Activity Timeline', style: AppTextStyles.titleLarge),
									const SizedBox(height: 12),
									...c.updates.map(_timelineTile),
								],
							],
						),
					);
				},
			),
		);
	}

	List<String> _statusOptions(String currentStatus) {
		switch (currentStatus) {
			case 'ASSIGNED':
				return const ['IN_PROGRESS', 'RESOLVED'];
			case 'IN_PROGRESS':
				return const ['RESOLVED'];
			default:
				return const [];
		}
	}

	Future<void> _saveUpdate(ComplaintModel complaint) async {
		final newStatus = _selectedStatus;
		if (newStatus == null) return;

		setState(() => _isSaving = true);
		try {
			await _updateStatusUseCase(
				complaintId: complaint.id,
				newStatus: newStatus,
				notes: _notesController.text.trim().isEmpty
						? null
						: _notesController.text.trim(),
			);
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Status updated successfully.')),
			);
			context.read<ComplaintBloc>().add(
						LoadComplaintDetail(complaintId: complaint.id),
					);
		} catch (_) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Failed to update status.')),
			);
		} finally {
			if (mounted) setState(() => _isSaving = false);
		}
	}

	Widget _timelineTile(ComplaintUpdateModel u) {
		return Container(
			margin: const EdgeInsets.only(bottom: 10),
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: AppColors.surfaceVariant.withOpacity(0.5),
				borderRadius: BorderRadius.circular(12),
			),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(u.timelineIcon, style: const TextStyle(fontSize: 18)),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Row(
									children: [
										Expanded(
											child: Text(
												'${u.previousStatus.toStatusLabel()} → ${u.newStatus.toStatusLabel()}',
												style: AppTextStyles.titleSmall,
											),
										),
										Text(u.timestamp.timeAgoString, style: AppTextStyles.caption),
									],
								),
								if (u.notes != null && u.notes!.isNotEmpty) ...[
									const SizedBox(height: 4),
									Text(
										u.notes!,
										style: AppTextStyles.bodySmall
												.copyWith(color: AppColors.textSecondary),
									),
								],
								const SizedBox(height: 4),
								Text(
									u.updatedByName,
									style: AppTextStyles.labelSmall
											.copyWith(color: AppColors.textSecondary),
								),
							],
						),
					),
				],
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
