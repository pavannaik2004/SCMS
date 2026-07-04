import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
                            context, 'Student', 'ROLE_USER', AppColors.systemBlue),
                        _buildMockButton(context, 'SR (Rep)', 'ROLE_SR',
                            AppColors.systemIndigo),
                        _buildMockButton(context, 'Staff', 'ROLE_STAFF',
                            AppColors.systemOrange),
                        _buildMockButton(
                            context, 'Admin', 'ROLE_ADMIN', AppColors.systemRed),
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
    String role,
    Color color,
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
      onPressed: () {
        context.read<AuthBloc>().add(MockSignInRequested(role: role));
      },
    );
  }
}
