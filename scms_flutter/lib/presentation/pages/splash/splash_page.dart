import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(milliseconds: AppConstants.splashMinDurationMsec), () {
      if (mounted) _navigate();
    });
  }

  void _navigate() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.go(Routes.userHome);
    } else if (authState is AuthUnauthenticated && authState.showOnboarding) {
      context.go(Routes.onboarding);
    } else {
      context.go(Routes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.support_agent_rounded, size: 80, color: Colors.white),
              const SizedBox(height: 16),
              Text('SCMS', style: AppTextStyles.displayLarge.copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              Text(AppConstants.appTagline,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
