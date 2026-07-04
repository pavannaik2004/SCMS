import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// iOS large-title scaffold. Provide content as [slivers]; the large title
/// collapses smoothly into a blurred inline nav bar on scroll.
///
/// A single [FlexibleSpaceBar] title is scaled up when expanded (via
/// [expandedTitleScale]) and settles to the standard 17pt nav title when
/// collapsed, so there is never a double-title overlap.
class LargeTitleScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final List<Widget> slivers;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Future<void> Function()? onRefresh;

  const LargeTitleScaffold({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    required this.slivers,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.background;
    final glass = isDark ? AppColors.glassFillDark : AppColors.glassFillLight;
    final sep = isDark ? AppColors.separatorDark : AppColors.separator;
    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    Widget scrollView = CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          leading: leading,
          actions: actions,
          expandedHeight: 108,
          collapsedHeight: 56,
          centerTitle: false,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: glass,
                  border: Border(
                    bottom: BorderSide(color: sep, width: 0.5),
                  ),
                ),
                child: FlexibleSpaceBar(
                  expandedTitleScale: 2.0,
                  titlePadding:
                      const EdgeInsets.only(left: 16, bottom: 14, right: 16),
                  title: Text(
                    title,
                    style: AppTextStyles.titleLarge.copyWith(color: primary),
                  ),
                ),
              ),
            ),
          ),
        ),
        ...slivers,
      ],
    );

    if (onRefresh != null) {
      scrollView = RefreshIndicator(onRefresh: onRefresh!, child: scrollView);
    }

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: scrollView,
    );
  }
}
