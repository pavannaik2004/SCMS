import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/user_model.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/complaint/complaint_bloc.dart';
import '../../bloc/complaint/complaint_event.dart';
import '../../bloc/complaint/complaint_state.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/inset_grouped_section.dart';
import '../../widgets/common/inset_list_row.dart';
import '../../widgets/common/scms_button.dart';

/// Unified iOS-clean profile screen used by every role. Clean header on the
/// grouped background, activity stat tiles, grouped account/preferences, and
/// settings + logout actions.
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              _Header(user: user),
              const SizedBox(height: 8),
              _buildActivityStats(),
              const SizedBox(height: 24),
              InsetGroupedSection(
                header: 'Account',
                children: [
                  if (user?.departmentName != null)
                    InsetListRow(
                      leading: _icon(Icons.business_rounded, AppColors.systemBlue),
                      title: 'Department',
                      trailing: _trailingValue(user!.departmentName!),
                    ),
                  InsetListRow(
                    leading:
                        _icon(Icons.verified_user_rounded, AppColors.systemGreen),
                    title: 'Account',
                    trailing: _trailingValue('RVCE Verified'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              InsetGroupedSection(
                header: 'Preferences',
                children: [
                  InsetListRow(
                    leading:
                        _icon(Icons.notifications_rounded, AppColors.systemRed),
                    title: 'Notifications',
                    subtitle: 'Push updates and reminders',
                    trailing: Switch.adaptive(
                      value: _prefs.notificationsEnabled,
                      onChanged: (v) =>
                          setState(() => _prefs.setNotificationsEnabled(v)),
                    ),
                  ),
                  InsetListRow(
                    leading:
                        _icon(Icons.dark_mode_rounded, AppColors.systemIndigo),
                    title: 'Theme',
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<ThemeMode>(
                        value: _prefs.themeMode,
                        borderRadius: BorderRadius.circular(12),
                        items: const [
                          DropdownMenuItem(
                              value: ThemeMode.system, child: Text('System')),
                          DropdownMenuItem(
                              value: ThemeMode.light, child: Text('Light')),
                          DropdownMenuItem(
                              value: ThemeMode.dark, child: Text('Dark')),
                        ],
                        onChanged: (mode) {
                          if (mode == null) return;
                          setState(() => _prefs.setThemeMode(mode));
                        },
                      ),
                    ),
                  ),
                ],
              ),
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
          );
        },
      ),
    );
  }

  Widget _icon(IconData icon, Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }

  Widget _trailingValue(String value) {
    return Text(
      value,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
    );
  }

  Widget _buildActivityStats() {
    return BlocBuilder<ComplaintBloc, ComplaintState>(
      builder: (context, state) {
        final List<ComplaintModel> complaints =
            state is MyComplaintsLoaded ? state.complaints : const [];
        final total = complaints.length;
        final active = complaints
            .where((c) => !['RESOLVED', 'CLOSED', 'REJECTED'].contains(c.status))
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
}

class _Header extends StatelessWidget {
  final UserModel? user;
  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final name = user?.name ?? 'Guest User';
    final email = user?.email ?? 'Not signed in';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 46,
              backgroundColor: accent.withValues(alpha: 0.14),
              backgroundImage:
                  user?.picture != null ? NetworkImage(user!.picture!) : null,
              child: user?.picture == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: AppTextStyles.displayLarge.copyWith(color: accent),
                    )
                  : null,
            ),
            const SizedBox(height: 14),
            Text(
              name,
              style: AppTextStyles.headlineLarge.copyWith(color: primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(email, style: AppTextStyles.bodyMedium.copyWith(color: secondary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                (user?.role ?? '').toRoleLabel().toUpperCase(),
                style: AppTextStyles.labelMedium.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: surface,
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
            Text(value,
                style: AppTextStyles.headlineMedium.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.labelMedium.copyWith(color: secondary)),
          ],
        ),
      ),
    );
  }
}
