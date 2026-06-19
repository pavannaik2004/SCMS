import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/analytics_model.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../bloc/all_complaints/all_complaints_cubit.dart';
import '../../bloc/all_complaints/all_complaints_state.dart';
import '../../bloc/analytics/analytics_cubit.dart';
import '../../bloc/analytics/analytics_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/analytics/complaints_chart.dart';
import '../../widgets/analytics/stats_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_app_bar.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/complaint/complaint_card.dart';
import '../../widgets/dashboard/trend_sparkline.dart';

/// Shared statistics & analytics screen available to every role (read-only).
///
/// KPIs, the by-department / by-category charts and recent SLA breaches all come
/// from the accurate server-side aggregate (`/analytics/summary` via
/// [AnalyticsCubit]). A page-scoped [AllComplaintsCubit] supplies a recent slice
/// of the global feed purely to draw the 7-day inflow sparkline.
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AllComplaintsCubit>(
      create: (ctx) =>
          AllComplaintsCubit(repository: ctx.read<ComplaintRepository>())
            ..setQuery(const AllComplaintsQuery()),
      child: const _StatsView(),
    );
  }
}

class _StatsView extends StatefulWidget {
  const _StatsView();

  @override
  State<_StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<_StatsView> {
  @override
  void initState() {
    super.initState();
    // The AnalyticsCubit is shared app-wide; only kick a load if it's idle so we
    // don't double-fetch when the admin dashboard already populated it.
    final cubit = context.read<AnalyticsCubit>();
    if (cubit.state is AnalyticsInitial) {
      cubit.loadSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final role = authState is AuthAuthenticated ? authState.user.role : null;

    return AppScaffold(
      appBar: GradientAppBar(
        title: 'Statistics',
        glass: true,
        roleBadge: _roleBadge(role),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Copy as CSV',
            onPressed: _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<AnalyticsCubit>().loadSummary();
              context.read<AllComplaintsCubit>().refresh();
            },
          ),
        ],
      ),
      body: BlocBuilder<AnalyticsCubit, AnalyticsState>(
        builder: (context, state) {
          if (state is AnalyticsLoading || state is AnalyticsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AnalyticsError) {
            return ScmsErrorWidget(
              message: state.message,
              onRetry: () => context.read<AnalyticsCubit>().loadSummary(),
            );
          }
          if (state is AnalyticsEmpty) {
            return const EmptyStateWidget(
              title: 'No analytics yet',
              subtitle: 'Charts appear once complaints start flowing in.',
              icon: Icons.insights_rounded,
            );
          }
          if (state is! AnalyticsLoaded) return const SizedBox.shrink();

          final a = state.analytics;
          return RefreshIndicator(
            onRefresh: () async {
              context.read<AnalyticsCubit>().loadSummary();
              await context.read<AllComplaintsCubit>().refresh();
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                const SizedBox(height: 12),
                _buildKpiRow(a),
                const SizedBox(height: 8),
                _buildTrend(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: ComplaintsChart(
                    departments: a.byDepartment,
                    categories: a.byCategory,
                  ),
                ),
                if (a.byCategory.isNotEmpty) ...[
                  const SectionHeader(title: 'Browse by category'),
                  _CategoryDrilldown(categories: a.byCategory),
                ],
                const SectionHeader(title: 'Recent SLA breaches'),
                if (a.recentSlaBreaches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'No breaches in the last 7 days.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...a.recentSlaBreaches.map(
                    (c) => ComplaintCard(
                      complaint: c,
                      onTap: () => context.push('/complaint/${c.id}'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _exportCsv() {
    final state = context.read<AnalyticsCubit>().state;
    if (state is! AnalyticsLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analytics not loaded yet.')),
      );
      return;
    }
    final a = state.analytics;
    final buffer = StringBuffer()
      ..writeln('Metric,Value')
      ..writeln('Total Active,${a.totalActiveComplaints}')
      ..writeln('SLA Breaches,${a.slaBreachesLast7Days}')
      ..writeln('Avg Resolution (hrs),${a.avgResolutionTimeHours}')
      ..writeln(
          'Resolution Rate (%),${a.resolutionRatePercent.toStringAsFixed(1)}')
      ..writeln()
      ..writeln('Department,Count');
    for (final d in a.byDepartment) {
      buffer.writeln('"${d.departmentName}",${d.totalCount}');
    }
    buffer
      ..writeln()
      ..writeln('Category,Count');
    for (final c in a.byCategory) {
      buffer.writeln('"${c.categoryName}",${c.count}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analytics copied to clipboard as CSV.')),
    );
  }

  Widget _buildKpiRow(AnalyticsModel a) {
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          StatsCard(
            title: 'Total Active',
            value: '${a.totalActiveComplaints}',
            subtitle: 'Open + In Progress',
            icon: Icons.inbox_rounded,
            accentColor: AppColors.primary,
          ),
          StatsCard(
            title: 'SLA Breaches',
            value: '${a.slaBreachesLast7Days}',
            subtitle: 'Needs attention',
            icon: Icons.warning_amber_rounded,
            accentColor: AppColors.severityHigh,
          ),
          StatsCard(
            title: 'Avg Resolution',
            value: a.avgResolutionTimeHours.toHoursDuration(),
            subtitle: 'Across all depts',
            icon: Icons.timer_rounded,
            accentColor: AppColors.severityMedium,
          ),
          StatsCard(
            title: 'Resolution Rate',
            value: a.resolutionRatePercent.toPercentString(),
            subtitle: 'Resolved / total',
            icon: Icons.trending_up_rounded,
            accentColor: AppColors.statusResolved,
          ),
        ],
      ),
    );
  }

  Widget _buildTrend() {
    return BlocBuilder<AllComplaintsCubit, AllComplaintsState>(
      builder: (context, state) {
        if (state is! AllComplaintsLoaded || state.items.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TrendSparkline(
            complaints: state.items,
            title: 'Incoming · last 7 days',
          ),
        );
      },
    );
  }

  String? _roleBadge(String? role) {
    switch (role) {
      case 'ROLE_ADMIN':
        return 'ADMIN';
      case 'ROLE_DEPT_HEAD':
        return 'DEPT HEAD';
      case 'ROLE_STAFF':
        return 'STAFF';
      case 'ROLE_SR':
        return 'SR';
      case 'ROLE_USER':
        return 'STUDENT';
      default:
        return null;
    }
  }
}

/// Tappable category rows that drill down into the [AllComplaintsPage] feed
/// pre-filtered to the chosen category.
class _CategoryDrilldown extends StatelessWidget {
  final List<CategoryStat> categories;

  const _CategoryDrilldown({required this.categories});

  @override
  Widget build(BuildContext context) {
    final maxCount = categories
        .map((c) => c.count)
        .fold<int>(1, (p, c) => c > p ? c : p);
    final sorted = [...categories]..sort((a, b) => b.count.compareTo(a.count));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        child: Column(
          children: [
            for (final stat in sorted.take(8))
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => context.push(
                  Uri(
                    path: '/complaints/all',
                    queryParameters: {'categoryName': stat.categoryName},
                  ).toString(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          stat.categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: stat.count / maxCount,
                            minHeight: 8,
                            backgroundColor:
                                AppColors.primary.withOpacity(0.10),
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${stat.count}', style: AppTextStyles.titleSmall),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
