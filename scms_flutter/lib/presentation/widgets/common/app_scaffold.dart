import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// A [Scaffold] that paints the soft brand backdrop gradient behind a
/// transparent surface, so frosted-glass cards/app-bars read correctly on top.
/// Use this instead of a plain Scaffold on redesigned pages.
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;
  final Gradient? gradient;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ??
            (isDark ? AppColors.backdropDark : AppColors.backdropLight),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: bottomNavigationBar,
        body: body,
      ),
    );
  }
}
