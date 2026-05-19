import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../bloc/submit_complaint/submit_complaint_cubit.dart';
import '../../bloc/submit_complaint/submit_complaint_state.dart';
import '../../widgets/common/scms_button.dart';
import '../../widgets/common/scms_text_field.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/complaint/media_capture_widget.dart';
import '../../widgets/complaint/grammar_correction_banner.dart';
import '../../widgets/complaint/duplicate_warning_banner.dart';

class SubmitComplaintPage extends StatefulWidget {
  const SubmitComplaintPage({super.key});

  @override
  State<SubmitComplaintPage> createState() => _SubmitComplaintPageState();
}

class _SubmitComplaintPageState extends State<SubmitComplaintPage> {
  final _formKey = GlobalKey<FormState>();

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
          child: Scaffold(
            appBar: AppBar(title: const Text('New Complaint')),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ScmsTextField(
                    label: 'Subject',
                    hint: 'Brief title for your complaint',
                    onChanged: cubit.updateSubject,
                    validator: (v) => v == null || v.length < 5 ? 'Min 5 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  ScmsTextField(
                    label: 'Description',
                    hint: 'Describe the issue in detail...',
                    maxLines: 5,
                    maxLength: 500,
                    onChanged: cubit.updateDescription,
                    validator: (v) => v == null || v.length < 20 ? 'Min 20 characters' : null,
                  ),
                  // Grammar AI banner
                  if (state.isCheckingGrammar)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    ),
                  if (state.grammarResult != null && state.grammarResult!.hasCorrections)
                    GrammarCorrectionBanner(
                      correction: state.grammarResult!,
                      onAccept: cubit.applyGrammarCorrection,
                      onDismiss: () {},
                    ),
                  const SizedBox(height: 16),
                  ScmsTextField(
                    label: 'Location',
                    hint: 'Where is this issue?',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    onChanged: cubit.updateLocation,
                    validator: (v) => v == null || v.isEmpty ? 'Location is required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Severity selector
                  Text('Severity', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'LOW', label: Text('Low')),
                      ButtonSegment(value: 'MEDIUM', label: Text('Medium')),
                      ButtonSegment(value: 'HIGH', label: Text('High')),
                    ],
                    selected: {state.severity ?? 'MEDIUM'},
                    onSelectionChanged: (v) => cubit.updateSeverity(v.first),
                  ),
                  const SizedBox(height: 16),
                  // Photos
                  MediaCaptureWidget(
                    photos: state.photos,
                    onPhotoAdded: cubit.addPhoto,
                    onPhotoRemoved: cubit.removePhoto,
                  ),
                  const SizedBox(height: 16),
                  // Duplicate warning
                  if (state.duplicateResult != null && state.duplicateResult!.isDuplicate)
                    DuplicateWarningBanner(
                      duplicateResult: state.duplicateResult!,
                      onViewDuplicates: () {},
                      onSubmitAnyway: cubit.submitAnyway,
                    ),
                  const SizedBox(height: 24),
                  // Error message
                  if (state.errorMessage != null && !state.isDraft)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(state.errorMessage!, style: const TextStyle(color: Colors.red)),
                    ),
                  // Submit button
                  ScmsButton(
                    label: 'Submit Complaint',
                    icon: Icons.send_rounded,
                    isLoading: state.isLoading,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        cubit.submit();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
