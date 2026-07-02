import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../admin/admin_dashboard_page.dart';
import '../complaints/all_complaints_page.dart';
import '../home/home_page.dart';
import '../profile/profile_page.dart';
import '../sr/sr_dashboard_page.dart';
import '../staff/staff_dashboard_page.dart';
import '../stats/stats_page.dart';

/// The single role-aware home shell used by every role after login.
///
/// Bottom-nav tabs: a role-specific Dashboard, then the three shared screens
/// (All Complaints feed, Stats, Profile). Tabs are built lazily on first visit
/// and kept alive afterwards, so an unopened tab never fires its network calls.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final Map<int, Widget> _cache = {};

  /// Role the cached dashboard tab (index 0) was built for. If the role
  /// changes (late auth resolution, token-refresh re-auth), the cached
  /// dashboard is invalidated so the correct role's view is rebuilt.
  String? _cachedRole;

  Widget _dashboardFor(String role) {
    switch (role) {
      case 'ROLE_ADMIN':
      case 'ROLE_DEPT_HEAD':
        return const AdminDashboardPage();
      case 'ROLE_STAFF':
        return const StaffDashboardPage();
      case 'ROLE_SR':
        return const SrDashboardPage();
      default:
        return const StudentDashboardView();
    }
  }

  Widget _buildTab(int i, String role) {
    switch (i) {
      case 0:
        return _dashboardFor(role);
      case 1:
        return const AllComplaintsPage();
      case 2:
        return const StatsPage();
      default:
        return const ProfilePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final role =
        authState is AuthAuthenticated ? authState.user.role : 'ROLE_USER';

    // The dashboard tab depends on role — drop its cache entry if the role
    // changed so we never show a stale wrong-role dashboard.
    if (_cachedRole != role) {
      _cache.remove(0);
      _cachedRole = role;
    }

    // Build the active tab on demand; previously visited tabs stay cached.
    _cache.putIfAbsent(_index, () => _buildTab(_index, role));

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: List.generate(
          4,
          (i) => _cache[i] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          height: 68,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt_rounded),
              label: 'All',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Stats',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
