import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../domain/usecases/update_complaint_status_usecase.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/complaint/complaint_bloc.dart';
import '../../bloc/complaint/complaint_event.dart';
import '../../bloc/complaint/complaint_state.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/scms_button.dart';
import '../../widgets/common/scms_chip.dart';
import '../../widgets/complaint/complaint_card.dart';
import '../../widgets/dashboard/attention_card.dart';
import '../../widgets/dashboard/dashboard_hero.dart';
import '../../widgets/dashboard/status_breakdown_ring.dart';
import '../../widgets/dashboard/trend_sparkline.dart';

class StaffDashboardPage extends StatefulWidget {
	const StaffDashboardPage({super.key});

	@override
	State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> {
	final _filters = const ['All', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED_TODAY'];
	String _activeFilter = 'All';
	late final UpdateComplaintStatusUseCase _updateStatusUseCase;

	bool _selectionMode = false;
	final Set<String> _selected = {};

	@override
	void initState() {
		super.initState();
		_updateStatusUseCase = UpdateComplaintStatusUseCase(
			repository: context.read<ComplaintRepository>(),
		);
		context.read<ComplaintBloc>().add(LoadMyComplaints());
	}

	@override
	Widget build(BuildContext context) {
		return AppScaffold(
			bottomNavigationBar: _selectionMode ? _buildBulkBar() : null,
			body: Column(
				children: [
					_buildHero(context),
					const SizedBox(height: 12),
					SizedBox(
						height: 48,
						child: ListView.separated(
							scrollDirection: Axis.horizontal,
							padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
							itemCount: _filters.length,
							separatorBuilder: (_, __) => const SizedBox(width: 8),
							itemBuilder: (_, i) {
								final filter = _filters[i];
								final label = filter == 'RESOLVED_TODAY'
										? 'Resolved Today'
										: filter == 'All'
												? 'All'
												: filter.replaceAll('_', ' ');
								return ScmsChip(
									label: label,
									isSelected: filter == _activeFilter,
									onTap: () {
										setState(() => _activeFilter = filter);
										final statusFilter = _activeFilter == 'All'
												? null
												: _activeFilter == 'RESOLVED_TODAY'
														? 'RESOLVED'
														: _activeFilter;
										context.read<ComplaintBloc>().add(
													LoadMyComplaints(statusFilter: statusFilter),
												);
									},
								);
							},
						),
					),
					Expanded(
						child: BlocBuilder<ComplaintBloc, ComplaintState>(
							builder: (context, state) {
								if (state is ComplaintLoading) {
									return const Center(child: CircularProgressIndicator());
								}
								if (state is ComplaintError) {
									return ScmsErrorWidget(
										message: state.message,
										onRetry: () => context.read<ComplaintBloc>().add(RefreshComplaints()),
									);
								}
								if (state is MyComplaintsLoaded) {
									final filtered = _filterComplaints(state.complaints);
									if (filtered.isEmpty) {
										return const EmptyStateWidget(
											title: 'No tasks found',
											subtitle: 'You are all caught up for now.',
											icon: Icons.task_alt_rounded,
										);
									}

									return RefreshIndicator(
										onRefresh: () async =>
												context.read<ComplaintBloc>().add(RefreshComplaints()),
										child: ListView(
											padding: const EdgeInsets.only(top: 12, bottom: 24),
											children: [
												Padding(
													padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
													child: AttentionCard(
														complaints: state.complaints,
														onTapComplaint: (c) =>
																context.push('/staff/complaint/${c.id}'),
													),
												),
												Padding(
													padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
													child: TrendSparkline(
														complaints: state.complaints,
														title: 'Incoming · last 7 days',
													),
												),
												Padding(
													padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
													child: StatusBreakdownRing(
														complaints: state.complaints,
														title: 'My workload',
													),
												),
												...filtered.map(_buildStaffCard),
											],
										),
									);
								}
								return const SizedBox.shrink();
							},
						),
					),
				],
			),
		);
	}

	List<ComplaintModel> _filterComplaints(List<ComplaintModel> complaints) {
		if (_activeFilter == 'All') return complaints;
		if (_activeFilter == 'RESOLVED_TODAY') {
			return complaints
					.where((c) => c.status == 'RESOLVED' && c.updatedAt.isToday)
					.toList();
		}
		return complaints.where((c) => c.status == _activeFilter).toList();
	}

	Widget _buildStaffCard(ComplaintModel complaint) {
		final selected = _selected.contains(complaint.id);
		return Column(
			children: [
				Stack(
					children: [
						ComplaintCard(
							complaint: complaint,
							onTap: () {
								if (_selectionMode) {
									_toggleSelect(complaint.id);
								} else {
									context.push('/staff/complaint/${complaint.id}');
								}
							},
							onLongPress: () {
								setState(() {
									_selectionMode = true;
									_selected.add(complaint.id);
								});
							},
						),
						if (_selectionMode)
							Positioned(
								right: 26,
								top: 16,
								child: Icon(
									selected
											? Icons.check_circle_rounded
											: Icons.radio_button_unchecked_rounded,
									color: selected ? AppColors.primary : AppColors.textSecondary,
								),
							),
					],
				),
				if (!_selectionMode && complaint.status == 'ASSIGNED')
					Padding(
						padding: const EdgeInsets.symmetric(horizontal: 16),
						child: ScmsButton(
							label: 'Start Working',
							variant: ScmsButtonVariant.secondary,
							isFullWidth: true,
							onPressed: () => _startWorking(complaint),
						),
					),
				const SizedBox(height: 16),
			],
		);
	}

	void _toggleSelect(String id) {
		setState(() {
			if (_selected.contains(id)) {
				_selected.remove(id);
				if (_selected.isEmpty) _selectionMode = false;
			} else {
				_selected.add(id);
			}
		});
	}

	Widget _buildBulkBar() {
		return Material(
			elevation: 8,
			color: Theme.of(context).cardColor,
			child: SafeArea(
				top: false,
				child: Padding(
					padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
					child: Row(
						children: [
							Text('${_selected.length} selected',
									style: AppTextStyles.titleSmall),
							const Spacer(),
							TextButton(
								onPressed: () => setState(() {
									_selectionMode = false;
									_selected.clear();
								}),
								child: const Text('Cancel'),
							),
							const SizedBox(width: 4),
							OutlinedButton(
								onPressed:
										_selected.isEmpty ? null : () => _bulkUpdate('IN_PROGRESS'),
								child: const Text('In Progress'),
							),
							const SizedBox(width: 8),
							FilledButton(
								onPressed:
										_selected.isEmpty ? null : _bulkResolveInfo,
								child: const Text('Resolve…'),
							),
						],
					),
				),
			),
		);
	}

	Future<void> _bulkUpdate(String newStatus) async {
		final ids = _selected.toList();
		setState(() {
			_selectionMode = false;
			_selected.clear();
		});
		var ok = 0;
		for (final id in ids) {
			try {
				await _updateStatusUseCase(
					complaintId: id,
					newStatus: newStatus,
					notes: 'Bulk update',
				);
				ok++;
			} catch (_) {
				// Skip failures (e.g. invalid transition); report the tally below.
			}
		}
		if (!mounted) return;
		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(content: Text('Updated $ok of ${ids.length} task(s).')),
		);
		context.read<ComplaintBloc>().add(RefreshComplaints());
	}

	/// Resolving requires photo proof, which is captured per-task on the detail
	/// screen — so the bulk action just points the user there.
	void _bulkResolveInfo() {
		setState(() {
			_selectionMode = false;
			_selected.clear();
		});
		ScaffoldMessenger.of(context).showSnackBar(
			const SnackBar(
				content: Text('Open a task to submit its resolution with photo proof.'),
			),
		);
	}

	_StaffStats _buildStats(List<ComplaintModel> complaints) {
		final assigned = complaints.where((c) => c.status == 'ASSIGNED').length;
		final inProgress = complaints.where((c) => c.status == 'IN_PROGRESS').length;
		final resolvedToday = complaints
				.where((c) => c.status == 'RESOLVED' && c.updatedAt.isToday)
				.length;
		return _StaffStats(assigned, inProgress, resolvedToday);
	}

	Widget _buildHero(BuildContext context) {
		return BlocBuilder<AuthBloc, AuthState>(
			builder: (context, authState) {
				final user = authState is AuthAuthenticated ? authState.user : null;
				final name = user?.name.split(' ').first ?? 'there';
				return BlocBuilder<ComplaintBloc, ComplaintState>(
					builder: (context, state) {
						final complaints =
								state is MyComplaintsLoaded ? state.complaints : <ComplaintModel>[];
						final stats = _buildStats(complaints);
						return DashboardHero(
							greeting: DateFormatter.greeting(),
							name: name,
							roleBadge: 'STAFF',
							avatarUrl: user?.picture,
							stats: [
								HeroStat(
									label: 'Assigned',
									value: '${stats.assigned}',
									icon: Icons.assignment_ind_outlined,
								),
								HeroStat(
									label: 'In Progress',
									value: '${stats.inProgress}',
									icon: Icons.pending_actions_rounded,
								),
								HeroStat(
									label: 'Done Today',
									value: '${stats.resolvedToday}',
									icon: Icons.check_circle_outline_rounded,
								),
							],
						);
					},
				);
			},
		);
	}

	Future<void> _startWorking(ComplaintModel complaint) async {
		try {
			await _updateStatusUseCase(
				complaintId: complaint.id,
				newStatus: 'IN_PROGRESS',
				notes: 'Started work',
			);
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Marked as In Progress.')),
			);
			context.read<ComplaintBloc>().add(RefreshComplaints());
		} catch (_) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Failed to update status.')),
			);
		}
	}
}

class _StaffStats {
	final int assigned;
	final int inProgress;
	final int resolvedToday;

	_StaffStats(this.assigned, this.inProgress, this.resolvedToday);
}
