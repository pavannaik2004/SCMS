import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/complaint/complaint_bloc.dart';
import '../../bloc/complaint/complaint_event.dart';
import '../../bloc/complaint/complaint_state.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/complaint/complaint_card.dart';
import '../../widgets/dashboard/attention_card.dart';
import '../../widgets/dashboard/dashboard_hero.dart';
import '../../widgets/dashboard/quick_actions_row.dart';
import '../../widgets/dashboard/status_breakdown_ring.dart';

/// The student (ROLE_USER) dashboard — tab 1 of the role shell.
///
/// Premium solid-brand hero + quick actions + attention card + status ring +
/// recent activity. Navigation uses routes (My Complaints / All Complaints) so
/// it composes inside [MainShell] without needing to control the tab index.
class StudentDashboardView extends StatefulWidget {
  const StudentDashboardView({super.key});

  @override
  State<StudentDashboardView> createState() => _StudentDashboardViewState();
}

class _StudentDashboardViewState extends State<StudentDashboardView> {
  @override
  void initState() {
    super.initState();
    final state = context.read<ComplaintBloc>().state;
    if (state is! MyComplaintsLoaded) {
      context.read<ComplaintBloc>().add(LoadMyComplaints());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.submitComplaint),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Complaint'),
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            context.read<ComplaintBloc>().add(RefreshComplaints()),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: QuickActionsRow(
                  actions: [
                    QuickAction(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'New',
                      color: AppColors.primary,
                      onTap: () => context.push(Routes.submitComplaint),
                    ),
                    QuickAction(
                      icon: Icons.list_alt_rounded,
                      label: 'My Complaints',
                      color: AppColors.accent,
                      onTap: () => context.push(Routes.myComplaints),
                    ),
                    QuickAction(
                      icon: Icons.public,
                      label: 'Browse All',
                      color: AppColors.statusAssigned,
                      onTap: () => context.push(Routes.allComplaints),
                    ),
                  ],
                ),
              ),
            ),
            BlocBuilder<ComplaintBloc, ComplaintState>(
              builder: (context, state) {
                if (state is ComplaintLoading) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state is MyComplaintsLoaded && state.complaints.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      title: 'No complaints yet',
                      subtitle: 'Tap "New Complaint" to report your first issue',
                      icon: Icons.inbox_rounded,
                    ),
                  );
                }
                if (state is MyComplaintsLoaded) {
                  final complaints = state.complaints;
                  final recent = complaints.take(5).toList();
                  return SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: AttentionCard(
                          complaints: complaints,
                          onTapComplaint: (c) =>
                              context.push('/complaint/${c.id}'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: StatusBreakdownRing(complaints: complaints),
                      ),
                      SectionHeader(
                        title: 'Recent Activity',
                        actionLabel: 'See all',
                        onAction: () => context.push(Routes.myComplaints),
                      ),
                      ...recent.map(
                        (c) => ComplaintCard(
                          complaint: c,
                          onTap: () => context.push('/complaint/${c.id}'),
                        ),
                      ),
                    ]),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;
        final name = user?.name.split(' ').first ?? 'there';
        return BlocBuilder<ComplaintBloc, ComplaintState>(
          builder: (context, state) {
            final complaints =
                state is MyComplaintsLoaded ? state.complaints : const [];
            final active = complaints
                .where((c) =>
                    !['RESOLVED', 'COMPLETED', 'CLOSED', 'REJECTED'].contains(c.status))
                .length;
            final resolved = complaints
                .where((c) => ['RESOLVED', 'COMPLETED', 'CLOSED'].contains(c.status))
                .length;
            return DashboardHero(
              greeting: DateFormatter.greeting(),
              name: name,
              avatarUrl: user?.picture,
              stats: [
                HeroStat(
                  label: 'Total',
                  value: '${complaints.length}',
                  icon: Icons.assignment_outlined,
                ),
                HeroStat(
                  label: 'Active',
                  value: '$active',
                  icon: Icons.pending_actions_rounded,
                ),
                HeroStat(
                  label: 'Resolved',
                  value: '$resolved',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
