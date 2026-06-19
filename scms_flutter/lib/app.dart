import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/app_preferences.dart';
import 'core/constants/route_constants.dart';
import 'core/theme/app_theme.dart';

import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_state.dart';
import 'presentation/pages/splash/splash_page.dart';
import 'presentation/pages/onboarding/onboarding_page.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/shell/main_shell.dart';

import 'presentation/pages/complaint/submit_complaint_page.dart';
import 'presentation/pages/complaint/complaint_detail_page.dart';
import 'presentation/pages/complaint/duplicate_complaints_page.dart';
import 'presentation/pages/complaint/my_complaints_page.dart';
import 'presentation/pages/complaint/rating_page.dart';
import 'presentation/pages/complaints/all_complaints_page.dart';
import 'presentation/pages/stats/stats_page.dart';
import 'presentation/pages/route_helpers.dart';

import 'dart:async';

class ScmsApp extends StatefulWidget {
  const ScmsApp({super.key, this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<ScmsApp> createState() => _ScmsAppState();
}

class _ScmsAppState extends State<ScmsApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      navigatorKey: widget.navigatorKey,
      initialLocation: Routes.splash,
      refreshListenable: GoRouterRefreshStream(context.read<AuthBloc>().stream),
      redirect: (context, state) {
        final authState = context.read<AuthBloc>().state;

        // If auth is still checking or loading, do not redirect anywhere yet
        if (authState is AuthInitial || authState is AuthLoading) {
          return null;
        }

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
          builder: (context, state) => const MainShell(),
        ),
        GoRoute(
          path: Routes.submitComplaint,
          builder: (context, state) => const SubmitComplaintPage(),
        ),
        GoRoute(
          path: Routes.allComplaints,
          builder: (context, state) => AllComplaintsPage(
            initialStatus: state.uri.queryParameters['status'],
            initialCategoryName: state.uri.queryParameters['categoryName'],
          ),
        ),
        GoRoute(
          path: Routes.stats,
          builder: (context, state) => const StatsPage(),
        ),
        GoRoute(
          path: Routes.myComplaints,
          builder: (context, state) => const MyComplaintsPage(),
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppPreferences.instance,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'SCMS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: AppPreferences.instance.themeMode,
          routerConfig: _router,
        );
      },
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

/// Helper class to convert a stream of changes (like AuthBloc state stream)
/// into a Listenable that GoRouter can subscribe to.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
