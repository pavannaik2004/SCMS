import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/common/pressable_scale.dart';
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
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: List.generate(
          4,
          (i) => _cache[i] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: _BlurredTabBar(
        selectedIndex: _index,
        onSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// iOS-style translucent, blurred floating tab bar.
class _BlurredTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _BlurredTabBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _items = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    (Icons.list_alt_outlined, Icons.list_alt_rounded, 'All'),
    (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Stats'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glass = isDark ? AppColors.glassFillDark : AppColors.glassFillLight;
    final sep = isDark ? AppColors.separatorDark : AppColors.separator;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final inactive =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: glass,
            border: Border(top: BorderSide(color: sep, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: PressableScale(
                        onTap: () => onSelected(i),
                        child: _TabItem(
                          icon: i == selectedIndex
                              ? _items[i].$2
                              : _items[i].$1,
                          label: _items[i].$3,
                          color: i == selectedIndex ? accent : inactive,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
