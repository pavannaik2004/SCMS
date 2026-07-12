import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/server_url_override.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/datasources/remote/auth_remote_datasource.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/common/scms_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// When true, the role buttons enter the app WITHOUT any backend call
  /// (no picker, no token exchange) so the server URL can be set from Settings.
  bool _offline = false;

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
                    const SizedBox(height: 16),
                    _buildOfflineToggle(secondary),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildMockButton(
                          context,
                          'Student',
                          AppColors.systemBlue,
                          () => _onRoleTap(context, 'ROLE_USER',
                              'Select a Student', AppColors.systemBlue),
                        ),
                        _buildMockButton(
                          context,
                          'SR (Rep)',
                          AppColors.systemIndigo,
                          () => _onRoleTap(context, 'ROLE_SR',
                              'Select a Student Representative',
                              AppColors.systemIndigo),
                        ),
                        _buildMockButton(
                          context,
                          'Staff',
                          AppColors.systemOrange,
                          () => _onRoleTap(context, 'ROLE_STAFF',
                              'Select a Staff Member', AppColors.systemOrange),
                        ),
                        _buildMockButton(
                          context,
                          'Admin',
                          AppColors.systemRed,
                          () => _onRoleTap(context, 'ROLE_ADMIN',
                              'Select an Admin', AppColors.systemRed),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Lets testers point the app at a backend (LAN IP / tunnel)
                    // before signing in — the dev bypass buttons above call the
                    // backend, so this must be reachable without logging in.
                    TextButton.icon(
                      onPressed: () => _showServerUrlDialog(context),
                      icon: Icon(Icons.dns_rounded, size: 16, color: secondary),
                      label: Text(
                        'Configure server URL',
                        style:
                            AppTextStyles.bodySmall.copyWith(color: secondary),
                      ),
                    ),
                    const SizedBox(height: 12),
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

  /// Toggle that switches the dev-bypass buttons between the normal online
  /// picker (needs the backend) and a fully offline entry (no server call).
  Widget _buildOfflineToggle(Color secondary) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 18, color: secondary),
            const SizedBox(width: 8),
            Text(
              'Offline (no server)',
              style: AppTextStyles.bodySmall.copyWith(color: secondary),
            ),
            Switch.adaptive(
              value: _offline,
              onChanged: (v) => setState(() => _offline = v),
            ),
          ],
        ),
        if (_offline)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Enters the app without contacting the backend so you can set the '
              'Server URL in Settings. Data loads once a reachable server is set.',
              style: AppTextStyles.caption.copyWith(color: secondary),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  /// Handles a dev-bypass role tap. In offline mode, enters the app directly
  /// with no backend call; otherwise runs the normal online flow (admin signs
  /// in directly, other roles open the seeded-user picker).
  void _onRoleTap(
    BuildContext context,
    String role,
    String pickerTitle,
    Color color,
  ) {
    if (_offline) {
      context.read<AuthBloc>().add(OfflineMockSignInRequested(role: role));
      return;
    }
    if (role == 'ROLE_ADMIN') {
      _signInAsAdmin(context);
    } else {
      _showUserPicker(context, role, pickerTitle, color);
    }
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

  /// Opens the server-URL override dialog so a tester can point the app at a
  /// reachable backend (LAN IP / tunnel) before signing in. Mirrors the dialog
  /// in the Settings page; the override is read per-request by [DioClient], so
  /// the next dev-bypass call uses the new URL without an app restart.
  Future<void> _showServerUrlDialog(BuildContext context) async {
    final current = await ServerUrlOverride.get();
    if (!context.mounted) return;
    final controller = TextEditingController(text: current ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Server URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Point the app at your backend before signing in.\n'
              'e.g. 192.168.1.104:3000 (scheme optional, defaults to http://)',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: ApiConstants.baseUrl,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, ''),
            child: const Text('Reset to default'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return; // cancelled

    await ServerUrlOverride.set(result.isEmpty ? null : result);
    final saved = await ServerUrlOverride.get();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved == null
              ? 'Reset to default server (${ApiConstants.baseUrl}).'
              : 'Server URL set to $saved.',
        ),
      ),
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
