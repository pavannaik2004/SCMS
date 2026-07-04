import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/scms_button.dart';
import '../../widgets/common/scms_text_field.dart';

/// Star-rating + optional comment screen shown after a complaint is resolved.
///
/// Wires directly to [ComplaintRepository.submitRating] — no separate BLoC
/// needed for this lightweight single-action screen.
class RatingPage extends StatefulWidget {
  final String complaintId;
  const RatingPage({super.key, required this.complaintId});

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isSubmitting,
      child: AppScaffold(
        appBar: AppBar(title: const Text('Rate Resolution')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Text('How was the resolution?', style: AppTextStyles.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Your feedback helps improve campus services.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ── Star rating row ────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < _rating;
                  return IconButton(
                    iconSize: 44,
                    icon: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: filled
                          ? const Color(0xFFFFC107)
                          : AppColors.textDisabled,
                    ),
                    onPressed: () => setState(() => _rating = i + 1.0),
                  );
                }),
              ),
              const SizedBox(height: 8),
              if (_rating > 0)
                Text(
                  _ratingLabel(_rating),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              const SizedBox(height: 24),

              // ── Optional comment ───────────────────────────────────────────
              ScmsTextField(
                label: 'Comment (optional)',
                hint: 'Tell us more about your experience...',
                controller: _commentController,
                maxLines: 3,
              ),
              const Spacer(),

              // ── Submit button ──────────────────────────────────────────────
              ScmsButton(
                label: 'Submit Rating',
                isLoading: _isSubmitting,
                onPressed: _rating > 0 ? _submit : null,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'Skip for now',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final repo = context.read<ComplaintRepository>();
      await repo.submitRating(
        widget.complaintId,
        rating: _rating,
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback! 🌟'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to submit rating. Please try again.'),
            backgroundColor: AppColors.severityHigh,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _ratingLabel(double rating) {
    switch (rating.toInt()) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent!';
      default: return '';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
