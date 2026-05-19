import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

import '../../widgets/common/scms_button.dart';
import '../../widgets/common/scms_text_field.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Resolution')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Text('How was the resolution?', style: AppTextStyles.titleLarge),
            const SizedBox(height: 24),
            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  iconSize: 40,
                  icon: Icon(
                    i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: i < _rating ? AppColors.severityLow : AppColors.textDisabled,
                  ),
                  onPressed: () => setState(() => _rating = i + 1.0),
                );
              }),
            ),
            const SizedBox(height: 24),
            ScmsTextField(
              label: 'Comment (optional)',
              hint: 'Any additional feedback...',
              controller: _commentController,
              maxLines: 3,
            ),
            const Spacer(),
            ScmsButton(
              label: 'Submit Rating',
              isLoading: _isSubmitting,
              onPressed: _rating > 0 ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    // TODO: This is a simplified version. In production, inject the repository properly.
    try {
      // For now just pop back — the actual submission will use proper DI
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
