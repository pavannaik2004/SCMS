import 'package:flutter/material.dart';

/// Custom painter to overlay GPS watermark text on captured media
class WatermarkPainter extends CustomPainter {
  final String locationText;
  final String dateTimeText;
  final String? additionalInfo;

  WatermarkPainter({
    required this.locationText,
    required this.dateTimeText,
    this.additionalInfo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent black background strip at bottom
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final stripHeight = additionalInfo != null ? 70.0 : 50.0;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - stripHeight, size.width, stripHeight),
      bgPaint,
    );

    // Location text
    final locationPainter = TextPainter(
      text: TextSpan(
        text: '📍 $locationText',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    locationPainter.layout(maxWidth: size.width - 16);
    locationPainter.paint(canvas, Offset(8, size.height - stripHeight + 6));

    // DateTime text
    final datePainter = TextPainter(
      text: TextSpan(
        text: '🕐 $dateTimeText',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    datePainter.layout(maxWidth: size.width - 16);
    datePainter.paint(canvas, Offset(8, size.height - stripHeight + 26));

    // Additional info line
    if (additionalInfo != null) {
      final infoPainter = TextPainter(
        text: TextSpan(
          text: additionalInfo!,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 9,
            fontWeight: FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      infoPainter.layout(maxWidth: size.width - 16);
      infoPainter.paint(canvas, Offset(8, size.height - stripHeight + 46));
    }
  }

  @override
  bool shouldRepaint(covariant WatermarkPainter oldDelegate) {
    return locationText != oldDelegate.locationText ||
        dateTimeText != oldDelegate.dateTimeText ||
        additionalInfo != oldDelegate.additionalInfo;
  }
}
