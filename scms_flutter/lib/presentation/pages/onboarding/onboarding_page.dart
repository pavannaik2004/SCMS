import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/common/scms_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      icon: Icons.campaign_rounded,
      title: 'Report Issues Easily',
      description: 'Snap a photo, describe the problem, and submit — AI helps you write better complaints.',
    ),
    _OnboardingSlide(
      icon: Icons.track_changes_rounded,
      title: 'Track in Real-Time',
      description: 'Follow your complaint from submission to resolution with live status updates and SLA timers.',
    ),
    _OnboardingSlide(
      icon: Icons.insights_rounded,
      title: 'Smarter Campus',
      description: 'AI detects duplicates, categorizes automatically, and helps staff resolve issues faster.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go(Routes.login),
                child: const Text('Skip'),
              ),
            ),
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) {
                  final slide = _slides[i];
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final accent =
                      isDark ? AppColors.primaryLight : AppColors.primary;
                  final secondary = isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Icon(slide.icon, size: 60, color: accent),
                        ),
                        const SizedBox(height: 44),
                        Text(slide.title,
                            style: AppTextStyles.headlineLarge,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        Text(slide.description,
                            style: AppTextStyles.bodyLarge
                                .copyWith(color: secondary, height: 1.4),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == i ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Next / Get Started
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ScmsButton(
                label: _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                onPressed: () {
                  if (_currentPage == _slides.length - 1) {
                    context.go(Routes.login);
                  } else {
                    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardingSlide({required this.icon, required this.title, required this.description});
}
