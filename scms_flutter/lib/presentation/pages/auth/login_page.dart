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

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.severityHigh),
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : AppColors.background,
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark.withOpacity(0.8)
                          : AppColors.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Premium Logo + branding
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.15),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            size: 64,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'SCMS',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: isDark ? AppColors.textPrimaryDark : AppColors.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Smart Complaint Management System',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 36),
                        // Domain notice
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.12),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Sign in with your @rvce.edu.in Google account',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
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
                                height: 1,
                                color: isDark ? AppColors.borderDark : AppColors.border,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'DEVELOPMENT BYPASS',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                height: 1,
                                color: isDark ? AppColors.borderDark : AppColors.border,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildMockButton(context, 'Student', 'ROLE_USER', Colors.blue, isDark),
                            _buildMockButton(context, 'SR (Rep)', 'ROLE_SR', Colors.purple, isDark),
                            _buildMockButton(context, 'Staff', 'ROLE_STAFF', Colors.orange, isDark),
                            _buildMockButton(context, 'Admin', 'ROLE_ADMIN', Colors.red, isDark),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Footer
                        Text(
                          'RVCE Campus App • MCA Project',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.textSecondaryDark.withOpacity(0.5) : AppColors.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
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
    bool isDark,
  ) {
    return ActionChip(
      avatar: Icon(Icons.account_circle_outlined, size: 16, color: color),
      label: Text(label),
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: color.withOpacity(isDark ? 0.12 : 0.08),
      side: BorderSide(color: color.withOpacity(0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onPressed: () {
        context.read<AuthBloc>().add(MockSignInRequested(role: role));
      },
    );
  }
}
