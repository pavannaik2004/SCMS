import 'package:flutter/material.dart';

/// Maps category names / backend icon slugs to Material icons so the UI can
/// render a recognisable glyph for every complaint category.
class CategoryIcons {
  CategoryIcons._();

  static IconData forCategory(String? nameOrSlug) {
    final key = (nameOrSlug ?? '').toLowerCase().trim();

    if (key.contains('plumb') || key.contains('water') || key.contains('leak')) {
      return Icons.water_drop_rounded;
    }
    if (key.contains('electric') || key.contains('power') || key.contains('light')) {
      return Icons.bolt_rounded;
    }
    if (key.contains('it') || key.contains('network') || key.contains('wifi') || key.contains('internet')) {
      return Icons.wifi_rounded;
    }
    if (key.contains('clean') || key.contains('housekeep') || key.contains('sanit')) {
      return Icons.cleaning_services_rounded;
    }
    if (key.contains('civil') || key.contains('construct') || key.contains('build')) {
      return Icons.foundation_rounded;
    }
    if (key.contains('carpen') || key.contains('furnit') || key.contains('wood')) {
      return Icons.chair_rounded;
    }
    if (key.contains('security') || key.contains('safety')) {
      return Icons.shield_rounded;
    }
    if (key.contains('hvac') || key.contains('ac') || key.contains('air') || key.contains('cool')) {
      return Icons.ac_unit_rounded;
    }
    if (key.contains('paint')) return Icons.format_paint_rounded;
    if (key.contains('garden') || key.contains('landscap')) return Icons.grass_rounded;
    if (key.contains('food') || key.contains('mess') || key.contains('canteen')) {
      return Icons.restaurant_rounded;
    }
    if (key.contains('transport') || key.contains('bus') || key.contains('vehicle')) {
      return Icons.directions_bus_rounded;
    }
    return Icons.report_problem_rounded;
  }
}
