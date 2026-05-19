import 'package:flutter/material.dart';
import '../../../data/models/category_model.dart';
import '../common/scms_chip.dart';

class CategorySelectorWidget extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const CategorySelectorWidget({
    super.key,
    required this.categories,
    this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return ScmsChip(
            label: cat.name,
            isSelected: cat.id == selectedId,
            onTap: () => onSelected(cat.id),
          );
        },
      ),
    );
  }
}
