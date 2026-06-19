import 'package:go_router/go_router.dart';

import '../../core/constants/route_constants.dart';
import 'settings/settings_page.dart';
import 'shell/main_shell.dart';
import 'sr/sr_review_detail_page.dart';
import 'staff/staff_complaint_detail_page.dart';

// Every role's home routes to the shared [MainShell] (role-aware Dashboard +
// All / Stats / Profile tabs). The role-specific detail screens stay as-is.
final List<GoRoute> prabhavaRoutes = [
  GoRoute(
    path: Routes.staffHome,
    builder: (context, state) => const MainShell(),
  ),
  GoRoute(
    path: Routes.staffComplaintDetail,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return StaffComplaintDetailPage(complaintId: id);
    },
  ),
  GoRoute(
    path: Routes.srHome,
    builder: (context, state) => const MainShell(),
  ),
  GoRoute(
    path: Routes.srReviewDetail,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return SrReviewDetailPage(complaintId: id);
    },
  ),
  GoRoute(
    path: Routes.adminHome,
    builder: (context, state) => const MainShell(),
  ),
  GoRoute(
    path: Routes.settings,
    builder: (context, state) => const SettingsPage(),
  ),
];
