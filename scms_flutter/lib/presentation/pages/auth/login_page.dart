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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.severityHigh),
          );
        }
        // Navigation handled by GoRouter redirect
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Logo + branding
                const Icon(Icons.support_agent_rounded, size: 80, color: AppColors.primary),
                const SizedBox(height: 16),
                Text('SCMS', style: AppTextStyles.displayLarge.copyWith(color: AppColors.primary)),
                const SizedBox(height: 8),
                Text(
                  'Smart Complaint Management System',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 2),
                // Domain notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sign in with your @rvce.edu.in Google account',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
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
                const Spacer(),
                // Footer
                Text(
                  'RVCE Campus App • MCA Project',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
