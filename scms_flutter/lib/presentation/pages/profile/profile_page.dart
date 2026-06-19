import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/user_model.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/complaint/complaint_bloc.dart';
import '../../bloc/complaint/complaint_event.dart';
import '../../bloc/complaint/complaint_state.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/scms_button.dart';

/// Unified profile screen used by every role (replaces the student-only profile
/// tab and gives staff/SR/admin a real profile). Solid-brand header + glass-ish
/// cards, with working preference toggles, settings access and logout.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _prefs = AppPreferences.instance;

  @override
  void initState() {
    super.initState();
    // Ensure the personal activity stats have data to show.
    final state = context.read<ComplaintBloc>().state;
    if (state is! MyComplaintsLoaded) {
      context.read<ComplaintBloc>().add(LoadMyComplaints());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _Header(user: user),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your activity', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 10),
                    _buildActivityStats(),
                    const SizedBox(height: 24),
                    Text('Account', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 10),
                    if (user?.departmentName != null)
                      _InfoTile(
                        icon: Icons.business_rounded,
                        label: 'Department',
                        value: user!.departmentName!,
                      ),
                    const _InfoTile(
                      icon: Icons.verified_user_outlined,
                      label: 'Account',
                      value: 'RVCE Verified',
                    ),
                    const SizedBox(height: 24),
                    Text('Preferences', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 10),
                    _buildNotificationToggle(),
                    const SizedBox(height: 12),
                    _buildThemeSelector(),
                    const SizedBox(height: 24),
                    ScmsButton(
                      label: 'All Settings',
                      variant: ScmsButtonVariant.secondary,
                      icon: Icons.settings_rounded,
                      onPressed: () => context.push(Routes.settings),
                    ),
                    const SizedBox(height: 12),
                    ScmsButton(
                      label: 'Log Out',
                      variant: ScmsButtonVariant.destructive,
                      icon: Icons.logout_rounded,
                      onPressed: () =>
                          context.read<AuthBloc>().add(LogoutRequested()),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        '${AppConstants.appName} · v${AppConstants.appVersion} (${AppConstants.buildNumber})',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivityStats() {
    return BlocBuilder<ComplaintBloc, ComplaintState>(
      builder: (context, state) {
        final List<ComplaintModel> complaints =
            state is MyComplaintsLoaded ? state.complaints : const [];
        final total = complaints.length;
        final active = complaints
            .where((c) =>
                !['RESOLVED', 'CLOSED', 'REJECTED'].contains(c.status))
            .length;
        final resolved = complaints
            .where((c) => c.status == 'RESOLVED' || c.status == 'CLOSED')
            .length;
        return Row(
          children: [
            _StatTile(label: 'Total', value: '$total', color: AppColors.primary),
            const SizedBox(width: 12),
            _StatTile(
                label: 'Active',
                value: '$active',
                color: AppColors.statusInProgress),
            const SizedBox(width: 12),
            _StatTile(
                label: 'Resolved',
                value: '$resolved',
                color: AppColors.statusResolved),
          ],
        );
      },
    );
  }

  Widget _buildNotificationToggle() {
    return Card(
      child: SwitchListTile(
        value: _prefs.notificationsEnabled,
        onChanged: (v) => setState(() => _prefs.setNotificationsEnabled(v)),
        title: Text('Notifications', style: AppTextStyles.titleSmall),
        subtitle: Text(
          'Enable push updates and reminders',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<ThemeMode>(
              value: _prefs.themeMode,
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (mode) {
                if (mode == null) return;
                setState(() => _prefs.setThemeMode(mode));
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final UserModel? user;
  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'Guest User';
    final email = user?.email ?? 'Not signed in';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                ),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage:
                      user?.picture != null ? NetworkImage(user!.picture!) : null,
                  child: user?.picture == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: AppTextStyles.displayLarge
                              .copyWith(color: Colors.white),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.white.withOpacity(0.85)),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _roleLabel(user?.role),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'ROLE_ADMIN':
        return 'ADMINISTRATOR';
      case 'ROLE_DEPT_HEAD':
        return 'DEPARTMENT HEAD';
      case 'ROLE_STAFF':
        return 'STAFF';
      case 'ROLE_SR':
        return 'STUDENT REP';
      default:
        return 'STUDENT';
    }
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: AppTextStyles.headlineMedium.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 14),
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.titleSmall,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
