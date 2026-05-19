import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/complaint/complaint_bloc.dart';
import '../../bloc/complaint/complaint_event.dart';
import '../../bloc/complaint/complaint_state.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/scms_button.dart';
import '../../widgets/complaint/complaint_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    context.read<ComplaintBloc>().add(LoadMyComplaints());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        _buildDashboard(),
        _buildMyComplaintsTab(),
        _buildProfileTab(),
      ][_currentTab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'My Complaints'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.submitComplaint),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Complaint'),
      ),
    );
  }

  Widget _buildDashboard() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final name = state is AuthAuthenticated ? state.user.name.split(' ').first : '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${DateFormatter.greeting()},', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      Text(name, style: AppTextStyles.headlineMedium),
                    ],
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<ComplaintBloc, ComplaintState>(
              builder: (context, state) {
                if (state is MyComplaintsLoaded) {
                  final active = state.complaints.where((c) => !['RESOLVED', 'CLOSED', 'REJECTED'].contains(c.status)).length;
                  final resolved = state.complaints.where((c) => c.status == 'RESOLVED').length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _statCard('Active', '$active', AppColors.statusInProgress),
                        const SizedBox(width: 12),
                        _statCard('Resolved', '$resolved', AppColors.statusResolved),
                        const SizedBox(width: 12),
                        _statCard('Total', '${state.complaints.length}', AppColors.primary),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Recent Complaints', style: AppTextStyles.titleLarge),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          BlocBuilder<ComplaintBloc, ComplaintState>(
            builder: (context, state) {
              if (state is ComplaintLoading) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              if (state is MyComplaintsLoaded && state.complaints.isEmpty) {
                return const SliverFillRemaining(
                  child: EmptyStateWidget(title: 'No complaints yet', subtitle: 'Tap + to report an issue'),
                );
              }
              if (state is MyComplaintsLoaded) {
                final recent = state.complaints.take(5).toList();
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => ComplaintCard(
                      complaint: recent[i],
                      onTap: () => context.push('/complaint/${recent[i].id}'),
                    ),
                    childCount: recent.length,
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.headlineMedium.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.labelSmall.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildMyComplaintsTab() {
    return const MyComplaintsTab();
  }

  Widget _buildProfileTab() {
    return SafeArea(
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) return const SizedBox.shrink();
          final user = state.user;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                CircleAvatar(radius: 40, backgroundImage: user.picture != null ? NetworkImage(user.picture!) : null,
                    child: user.picture == null ? const Icon(Icons.person, size: 40) : null),
                const SizedBox(height: 16),
                Text(user.name, style: AppTextStyles.titleLarge),
                Text(user.email, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(user.role.replaceAll('ROLE_', ''), style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                ),
                const Spacer(),
                ScmsButton(
                  label: 'Settings',
                  variant: ScmsButtonVariant.secondary,
                  icon: Icons.settings_rounded,
                  onPressed: () => context.push(Routes.settings),
                ),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Extracted so it can be reused as tab
class MyComplaintsTab extends StatelessWidget {
  const MyComplaintsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('My Complaints', style: AppTextStyles.headlineMedium),
          ),
          // Reuses my_complaints_page logic
          Expanded(
            child: BlocBuilder<ComplaintBloc, ComplaintState>(
              builder: (context, state) {
                if (state is ComplaintLoading) return const Center(child: CircularProgressIndicator());
                if (state is ComplaintError) return Center(child: Text(state.message));
                if (state is MyComplaintsLoaded && state.complaints.isEmpty) {
                  return const EmptyStateWidget(title: 'No complaints yet');
                }
                if (state is MyComplaintsLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async => context.read<ComplaintBloc>().add(RefreshComplaints()),
                    child: ListView.builder(
                      itemCount: state.complaints.length,
                      itemBuilder: (ctx, i) => ComplaintCard(
                        complaint: state.complaints[i],
                        onTap: () => context.push('/complaint/${state.complaints[i].id}'),
                      ),
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
}
