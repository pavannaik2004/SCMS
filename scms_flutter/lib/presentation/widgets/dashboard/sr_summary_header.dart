import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/complaint_model.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import 'breakdown_bars.dart';
import 'dashboard_hero.dart';

/// SR dashboard header: a gradient hero (greeting + SR badge + queue stats:
/// pending / high-severity / oldest-waiting) followed by a "pending by
/// category" breakdown. All derived from the passed pending list.
class SrSummaryHeader extends StatelessWidget {
  final List<ComplaintModel> complaints;
  const SrSummaryHeader({super.key, required this.complaints});

  @override
  Widget build(BuildContext context) {
    final highCount =
        complaints.where((c) => c.severity.toUpperCase() == 'HIGH').length;
    ComplaintModel? oldest;
    for (final c in complaints) {
      if (oldest == null || c.createdAt.isBefore(oldest.createdAt)) {
        oldest = c;
      }
    }
    final oldestLabel = oldest == null ? '—' : oldest.createdAt.timeAgoString;

    final byCategory = <String, int>{};
    for (final c in complaints) {
      byCategory[c.categoryName] = (byCategory[c.categoryName] ?? 0) + 1;
    }

    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final name = user?.name.split(' ').first ?? 'there';

    return Column(
      children: [
        DashboardHero(
          greeting: DateFormatter.greeting(),
          name: name,
          roleBadge: 'SR',
          avatarUrl: user?.picture,
          stats: [
            HeroStat(
              label: 'Pending',
              value: '${complaints.length}',
              icon: Icons.inbox_rounded,
            ),
            HeroStat(
              label: 'High',
              value: '$highCount',
              icon: Icons.priority_high_rounded,
            ),
            HeroStat(
              label: 'Oldest',
              value: oldestLabel,
              icon: Icons.schedule_rounded,
            ),
          ],
        ),
        if (byCategory.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: BreakdownBars(
              title: 'Pending by category',
              data: byCategory,
              colorFor: (_) => AppColors.accent,
            ),
          ),
      ],
    );
  }
}
