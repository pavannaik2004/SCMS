import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';

class SlaTimerWidget extends StatefulWidget {
  final DateTime createdAt;
  final DateTime deadline;

  const SlaTimerWidget({super.key, required this.createdAt, required this.deadline});

  @override
  State<SlaTimerWidget> createState() => _SlaTimerWidgetState();
}

class _SlaTimerWidgetState extends State<SlaTimerWidget> {
  late Timer _timer;
  late double _progress;
  late String _label;

  @override
  void initState() {
    super.initState();
    _updateSla();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _updateSla();
    });
  }

  void _updateSla() {
    setState(() {
      _progress = DateFormatter.slaProgressRatio(widget.createdAt, widget.deadline);
      _label = DateFormatter.formatSla(widget.deadline);
    });
  }

  Color get _color {
    if (_progress >= 1.0) return AppColors.severityHigh;
    if (_progress >= 0.8) return AppColors.severityMedium;
    if (_progress >= 0.5) return AppColors.severityLow;
    return AppColors.confidenceHigh;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clampedProgress = _progress.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timer_outlined, size: 14, color: _color),
            const SizedBox(width: 4),
            Text(_label, style: AppTextStyles.labelSmall.copyWith(color: _color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clampedProgress,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(_color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
