import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/route_constants.dart';
import 'core/theme/app_theme.dart';

import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_state.dart';
import 'presentation/pages/splash/splash_page.dart';
import 'presentation/pages/onboarding/onboarding_page.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/home/home_page.dart';

import 'presentation/pages/complaint/submit_complaint_page.dart';
import 'presentation/pages/complaint/complaint_detail_page.dart';
import 'presentation/pages/complaint/duplicate_complaints_page.dart';
import 'presentation/pages/complaint/rating_page.dart';
import 'presentation/pages/route_helpers.dart';

class ScmsApp extends StatelessWidget {
  const ScmsApp({super.key, this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    final router = _buildRouter(navigatorKey);
    return MaterialApp.router(
      title: 'SCMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }

  static GoRouter _buildRouter(GlobalKey<NavigatorState>? navigatorKey) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: Routes.splash,
      redirect: (context, state) {
        final authState = context.read<AuthBloc>().state;
        final isLoggedIn = authState is AuthAuthenticated;

        final authPages = {
          Routes.splash,
          Routes.login,
          Routes.onboarding,
        };
        final isOnAuthPage = authPages.contains(state.matchedLocation);

        if (!isLoggedIn && !isOnAuthPage) return Routes.login;
        if (isLoggedIn && isOnAuthPage) {
          return _getRoleHome(authState.user.role);
        }
        return null;
      },
      routes: [
        GoRoute(
          path: Routes.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: Routes.onboarding,
          builder: (context, state) => const OnboardingPage(),
        ),
        GoRoute(
          path: Routes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: Routes.userHome,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: Routes.submitComplaint,
          builder: (context, state) => const SubmitComplaintPage(),
        ),
        GoRoute(
          path: Routes.complaintDetail,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ComplaintDetailPage(complaintId: id);
          },
        ),
        GoRoute(
          path: Routes.duplicateComplaints,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return DuplicateComplaintsPage(complaintId: id);
          },
        ),
        GoRoute(
          path: Routes.ratingPage,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return RatingPage(complaintId: id);
          },
        ),
        ...prabhavaRoutes,
      ],
    );
  }

  static String _getRoleHome(String role) {
    switch (role) {
      case 'ROLE_ADMIN':
      case 'ROLE_DEPT_HEAD':
        return Routes.adminHome;
      case 'ROLE_STAFF':
        return Routes.staffHome;
      case 'ROLE_SR':
        return Routes.srHome;
      default:
        return Routes.userHome;
    }
  }
}
