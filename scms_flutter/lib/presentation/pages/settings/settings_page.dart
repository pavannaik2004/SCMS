import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_model.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/inset_grouped_section.dart';
import '../../widgets/common/inset_list_row.dart';
import '../../widgets/common/scms_button.dart';

class SettingsPage extends StatefulWidget {
	const SettingsPage({super.key});

	@override
	State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
	final _prefs = AppPreferences.instance;

	@override
	Widget build(BuildContext context) {
		return AppScaffold(
			appBar: AppBar(title: const Text('Settings')),
			body: BlocBuilder<AuthBloc, AuthState>(
				builder: (context, state) {
					final user = state is AuthAuthenticated ? state.user : null;
					return ListView(
						padding: const EdgeInsets.all(16),
						children: [
							_buildProfileCard(user),
							const SizedBox(height: 24),
							InsetGroupedSection(
								header: 'Preferences',
								children: [
									_buildNotificationRow(),
									_buildThemeRow(),
								],
							),
							const SizedBox(height: 24),
							InsetGroupedSection(
								header: 'About',
								children: [
									InsetListRow(
										leading: _icon(Icons.info_outline_rounded, AppColors.systemBlue),
										title: AppConstants.appName,
										subtitle: AppConstants.appTagline,
									),
									InsetListRow(
										leading: _icon(Icons.tag_rounded, AppColors.systemGray),
										title: 'Version',
										trailing: Text(
											'${AppConstants.appVersion} (${AppConstants.buildNumber})',
											style: AppTextStyles.bodyMedium
													.copyWith(color: AppColors.textSecondary),
										),
									),
								],
							),
							const SizedBox(height: 28),
							ScmsButton(
								label: 'Logout',
								variant: ScmsButtonVariant.destructive,
								onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
							),
							const SizedBox(height: 24),
						],
					);
				},
			),
		);
	}

	Widget _icon(IconData icon, Color color) {
		return Container(
			width: 30,
			height: 30,
			decoration: BoxDecoration(
				color: color,
				borderRadius: BorderRadius.circular(7),
			),
			child: Icon(icon, size: 18, color: Colors.white),
		);
	}

	Widget _buildProfileCard(UserModel? user) {
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final accent = isDark ? AppColors.primaryLight : AppColors.primary;
		final secondary =
				isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
		final initials = user?.name.isNotEmpty == true
				? user!.name.trim().substring(0, 1).toUpperCase()
				: 'U';

		return InsetGroupedSection(
			children: [
				Padding(
					padding: const EdgeInsets.all(16),
					child: Row(
						children: [
							CircleAvatar(
								radius: 28,
								backgroundColor: accent.withValues(alpha: 0.14),
								backgroundImage: user?.picture != null
										? NetworkImage(user!.picture!)
										: null,
								child: user?.picture == null
										? Text(initials,
												style: AppTextStyles.titleLarge.copyWith(color: accent))
										: null,
							),
							const SizedBox(width: 16),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(user?.name ?? 'Guest User',
												style: AppTextStyles.titleLarge),
										const SizedBox(height: 4),
										Text(
											user?.email ?? 'Not signed in',
											style: AppTextStyles.bodySmall.copyWith(color: secondary),
										),
									],
								),
							),
							Container(
								padding:
										const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
								decoration: BoxDecoration(
									color: accent.withValues(alpha: 0.12),
									borderRadius: BorderRadius.circular(100),
								),
								child: Text(
									_roleLabel(user?.role),
									style: AppTextStyles.labelSmall
											.copyWith(color: accent, fontWeight: FontWeight.w700),
								),
							),
						],
					),
				),
			],
		);
	}

	Widget _buildNotificationRow() {
		return InsetListRow(
			leading: _icon(Icons.notifications_rounded, AppColors.systemRed),
			title: 'Notifications',
			subtitle: 'Push updates and reminders',
			trailing: Switch.adaptive(
				value: _prefs.notificationsEnabled,
				onChanged: (value) =>
						setState(() => _prefs.setNotificationsEnabled(value)),
			),
		);
	}

	Widget _buildThemeRow() {
		return InsetListRow(
			leading: _icon(Icons.dark_mode_rounded, AppColors.systemIndigo),
			title: 'Theme',
			trailing: DropdownButtonHideUnderline(
				child: DropdownButton<ThemeMode>(
					value: _prefs.themeMode,
					borderRadius: BorderRadius.circular(12),
					items: const [
						DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
						DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
						DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
					],
					onChanged: (mode) {
						if (mode == null) return;
						setState(() => _prefs.setThemeMode(mode));
					},
				),
			),
		);
	}

	String _roleLabel(String? role) {
		switch (role) {
			case 'ROLE_ADMIN':
				return 'ADMIN';
			case 'ROLE_DEPT_HEAD':
				return 'DEPT HEAD';
			case 'ROLE_STAFF':
				return 'STAFF';
			case 'ROLE_SR':
				return 'SR';
			default:
				return 'USER';
		}
	}
}
