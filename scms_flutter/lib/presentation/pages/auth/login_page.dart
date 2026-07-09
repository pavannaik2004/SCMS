import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/datasources/remote/auth_remote_datasource.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/common/scms_button.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.systemRed),
          );
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App icon tile
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.support_agent_rounded,
                          size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Text('SCMS',
                        style:
                            AppTextStyles.displayLarge.copyWith(color: primary)),
                    const SizedBox(height: 8),
                    Text(
                      'Smart Complaint Management System',
                      style:
                          AppTextStyles.bodyMedium.copyWith(color: secondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Domain notice (tinted grouped note)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Sign in with your @rvce.edu.in Google account',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Google Sign-In button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return ScmsButton(
                          label: 'Sign in with Google',
                          icon: Icons.login_rounded,
                          isLoading: state is AuthLoading,
                          onPressed: () {
                            context.read<AuthBloc>().add(GoogleSignInRequested());
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 36),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                              height: 0.5,
                              color: isDark
                                  ? AppColors.separatorDark
                                  : AppColors.separator),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'DEVELOPMENT BYPASS',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: secondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                              height: 0.5,
                              color: isDark
                                  ? AppColors.separatorDark
                                  : AppColors.separator),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildMockButton(
                          context,
                          'Student',
                          AppColors.systemBlue,
                          () => _showUserPicker(context, 'ROLE_USER',
                              'Select a Student', AppColors.systemBlue),
                        ),
                        _buildMockButton(
                          context,
                          'SR (Rep)',
                          AppColors.systemIndigo,
                          () => _showUserPicker(context, 'ROLE_SR',
                              'Select a Student Representative',
                              AppColors.systemIndigo),
                        ),
                        _buildMockButton(
                          context,
                          'Staff',
                          AppColors.systemOrange,
                          () => _showUserPicker(context, 'ROLE_STAFF',
                              'Select a Staff Member', AppColors.systemOrange),
                        ),
                        _buildMockButton(
                          context,
                          'Admin',
                          AppColors.systemRed,
                          () => _signInAsAdmin(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'RVCE Campus App • MCA Project',
                      style: AppTextStyles.caption.copyWith(color: secondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMockButton(
    BuildContext context,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return ActionChip(
      avatar: Icon(Icons.account_circle_outlined, size: 16, color: color),
      label: Text(label),
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: color.withValues(alpha: 0.10),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      onPressed: onPressed,
    );
  }

  /// Admin: there's a single seeded admin, so sign in directly (falls back to a
  /// picker if more than one exists).
  Future<void> _signInAsAdmin(BuildContext context) async {
    final repo = context.read<AuthRepository>();
    final bloc = context.read<AuthBloc>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final admins =
          (await repo.getDevUsers()).where((u) => u.role == 'ROLE_ADMIN').toList();
      if (admins.isEmpty) {
        messenger.showSnackBar(const SnackBar(
            content: Text('No demo admin found. Seed the demo data first.')));
        return;
      }
      if (admins.length == 1) {
        bloc.add(MockSignInRequested(userId: admins.first.id));
      } else if (context.mounted) {
        _showUserPicker(context, 'ROLE_ADMIN', 'Select an Admin', AppColors.systemRed);
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to load demo users: $e')));
    }
  }

  /// Opens a bottom sheet listing the seeded demo accounts for [role] so the
  /// developer can pick exactly which person to sign in as.
  void _showUserPicker(
    BuildContext context,
    String role,
    String title,
    Color color,
  ) {
    final repo = context.read<AuthRepository>();
    final bloc = context.read<AuthBloc>();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return FutureBuilder<List<DevUser>>(
          future: repo.getDevUsers(),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator.adaptive()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load demo users.\nIs the backend running in development mode?\n\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ),
              );
            }
            final users =
                (snapshot.data ?? []).where((u) => u.role == role).toList();
            if (users.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('No demo accounts found. Seed the demo data.')),
              );
            }
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Text(title, style: AppTextStyles.titleMedium),
                  ),
                  ...users.map(
                    (u) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Text(
                          u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(u.name),
                      subtitle: Text(u.departmentName ?? u.email),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        bloc.add(MockSignInRequested(userId: u.id));
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
}
