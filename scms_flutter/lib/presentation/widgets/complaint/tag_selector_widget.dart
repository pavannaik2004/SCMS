import 'package:flutter/material.dart';
import '../../../core/constants/tag_constants.dart';
import '../common/scms_chip.dart';

class TagSelectorWidget extends StatelessWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onChanged;

  const TagSelectorWidget({
    super.key,
    required this.selectedTags,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TagConstants.predefinedTags.map((tag) {
        final isSelected = selectedTags.contains(tag);
        return ScmsChip(
          label: tag,
          isSelected: isSelected,
          onTap: () {
            final newTags = List<String>.from(selectedTags);
            isSelected ? newTags.remove(tag) : newTags.add(tag);
            onChanged(newTags);
          },
        );
      }).toList(),
    );
  }
}
