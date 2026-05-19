import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

class DuplicateComplaintsPage extends StatelessWidget {
  final String complaintId;
  const DuplicateComplaintsPage({super.key, required this.complaintId});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement full duplicate list with API call
    return Scaffold(
      appBar: AppBar(title: const Text('Similar Complaints')),
      body: Center(
        child: Text('Duplicate complaints for $complaintId', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
