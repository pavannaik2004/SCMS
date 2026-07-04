import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/duplicate_check_model.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../bloc/submit_complaint/submit_complaint_cubit.dart';
import '../../bloc/submit_complaint/submit_complaint_state.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/scms_button.dart';
import '../../widgets/common/scms_text_field.dart';
import '../../widgets/common/segmented_tabs.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/complaint/media_capture_widget.dart';
import '../../widgets/complaint/category_selector_widget.dart';
import '../../widgets/complaint/grammar_correction_banner.dart';
import '../../widgets/complaint/duplicate_warning_banner.dart';
import '../../widgets/complaint/status_badge.dart';

class SubmitComplaintPage extends StatefulWidget {
  const SubmitComplaintPage({super.key});

  @override
  State<SubmitComplaintPage> createState() => _SubmitComplaintPageState();
}

class _SubmitComplaintPageState extends State<SubmitComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  late final Future<List<CategoryModel>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = context.read<ComplaintRepository>().getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubmitComplaintCubit, SubmitComplaintState>(
      listener: (context, state) {
        if (state.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Complaint submitted successfully!')),
          );
          context.read<SubmitComplaintCubit>().reset();
          context.pop();
        }
        if (state.isDraft) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Saved as draft')),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<SubmitComplaintCubit>();
        return LoadingOverlay(
          isLoading: state.isLoading,
          message: 'Submitting complaint...',
          child: AppScaffold(
            appBar: AppBar(
              title: const Text('New Complaint'),
              leadingWidth: 88,
              leading: TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Subject ────────────────────────────────────────────────
                  ScmsTextField(
                    label: 'Subject',
                    hint: 'Brief title for your complaint',
                    onChanged: cubit.updateSubject,
                    validator: (v) => v == null || v.length < 5 ? 'Min 5 characters' : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Description + AI banner ────────────────────────────────
                  ScmsTextField(
                    label: 'Description',
                    hint: 'Describe the issue in detail...',
                    maxLines: 5,
                    maxLength: 500,
                    onChanged: cubit.updateDescription,
                    validator: (v) => v == null || v.length < 20 ? 'Min 20 characters' : null,
                  ),
                  if (state.isCheckingGrammar)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    ),
                  if (state.grammarResult != null &&
                      state.grammarResult!.hasCorrections &&
                      !state.grammarDismissed)
                    GrammarCorrectionBanner(
                      correction: state.grammarResult!,
                      onAccept: cubit.applyGrammarCorrection,
                      onDismiss: cubit.dismissGrammar,
                    ),
                  const SizedBox(height: 16),

                  // ── Location ───────────────────────────────────────────────
                  ScmsTextField(
                    label: 'Location',
                    hint: 'Where is this issue? e.g. Hostel Block C, Room 204',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    onChanged: cubit.updateLocation,
                    validator: (v) => v == null || v.isEmpty ? 'Location is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Category selector ──────────────────────────────────────
                  Text('Category', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  FutureBuilder<List<CategoryModel>>(
                    future: _categoriesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 40,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final categories = snapshot.data ?? [];
                      if (categories.isEmpty) {
                        return Text(
                          'No categories available',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        );
                      }
                      return CategorySelectorWidget(
                        categories: categories,
                        selectedId: state.categoryId,
                        onSelected: cubit.updateCategory,
                      );
                    },
                  ),
                  if (state.categoryId == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Please select a category',
                        style: AppTextStyles.caption.copyWith(color: AppColors.severityHigh),
                      ),
                    ),

                  // ── AI preview banner ──────────────────────────────────────
                  if (state.isCategorizing)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    ),
                  if (state.aiPreview != null && !state.aiPreviewAccepted)
                    _AiPreviewBanner(
                      preview: state.aiPreview!,
                      onAccept: cubit.acceptAiPreview,
                      onDismiss: cubit.dismissAiPreview,
                    ),
                  const SizedBox(height: 20),

                  // ── Severity ───────────────────────────────────────────────
                  Text('Severity', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    const values = ['LOW', 'MEDIUM', 'HIGH'];
                    final selected = state.severity ?? 'MEDIUM';
                    return CupertinoSegmentedTabs(
                      segments: const ['Low', 'Medium', 'High'],
                      selectedIndex: values.indexOf(selected).clamp(0, 2),
                      onChanged: (i) => cubit.updateSeverity(values[i]),
                    );
                  }),
                  const SizedBox(height: 16),

                  // ── Photos ─────────────────────────────────────────────────
                  MediaCaptureWidget(
                    photos: state.photos,
                    onPhotoAdded: cubit.addPhoto,
                    onPhotoRemoved: cubit.removePhoto,
                  ),
                  const SizedBox(height: 16),

                  // ── Duplicate warning ──────────────────────────────────────
                  if (state.duplicateResult != null && state.duplicateResult!.isDuplicate)
                    DuplicateWarningBanner(
                      duplicateResult: state.duplicateResult!,
                      onViewDuplicates: () => _showDuplicatesSheet(context, state.duplicateResult!),
                      onSubmitAnyway: cubit.submitAnyway,
                    ),
                  const SizedBox(height: 24),

                  // ── Error message ──────────────────────────────────────────
                  if (state.errorMessage != null && !state.isDraft)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  // ── Submit button ──────────────────────────────────────────
                  ScmsButton(
                    label: 'Submit Complaint',
                    icon: Icons.send_rounded,
                    isLoading: state.isLoading,
                    onPressed: () {
                      if (_formKey.currentState!.validate() && state.categoryId != null) {
                        cubit.submit();
                      } else if (state.categoryId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a category')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDuplicatesSheet(BuildContext context, DuplicateCheckModel result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Similar Complaints (${result.similarCount})',
                style: AppTextStyles.titleMedium,
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: result.allMatches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final match = result.allMatches[i];
                  final similarity = (match.score * 100).toStringAsFixed(0);
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      GoRouter.of(context).push('/complaint/${match.id}');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.severityMedium.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$similarity% match',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.severityMedium,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                match.complaintNumber,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              StatusBadge(status: match.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            match.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to view details →',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── AI Preview Banner ────────────────────────────────────────────────────────

class _AiPreviewBanner extends StatelessWidget {
  final Map<String, dynamic> preview;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const _AiPreviewBanner({
    required this.preview,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final category = preview['suggestedCategoryName'] as String? ?? '';
    final severity = preview['suggestedSeverity'] as String? ?? '';
    final confidence = (preview['confidenceScore'] as num?)?.toDouble() ?? 0.0;
    final reasoning = preview['reasoning'] as String? ?? '';
    final confidenceColor = AppColors.confidenceColor(confidence);
    final confidencePct = '${(confidence * 100).toStringAsFixed(0)}%';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('AI Suggestion', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: confidenceColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  confidencePct,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: confidenceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _chip(category, AppColors.primary),
              const SizedBox(width: 8),
              _chip(severity, AppColors.severityColor(severity)),
            ],
          ),
          if (reasoning.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              reasoning,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDismiss,
                child: const Text('Change it'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onAccept,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Looks right'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
