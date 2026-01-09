/* widget for document icon */

import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

/// custom icon widget showing two overlapping documents
/// matches the provided icon design with two overlapping rectangular shapes
class DocumentsIcon extends StatelessWidget {
  final double? size;
  final Color? color;

  const DocumentsIcon({
    super.key,
    this.size = AppConstants.docIconSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? IconTheme.of(context).color ?? AppConstants.docIconFallbackColor;
    final iconSize = size ?? AppConstants.docIconSize;

    return CustomPaint(
      size: Size(iconSize, iconSize),
      painter: _DocumentsIconPainter(color: iconColor),
    );
  }
}

class _DocumentsIconPainter extends CustomPainter {
  final Color color;

  _DocumentsIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppConstants.docIconStrokeWidth;

    final fillPaint = Paint()
      ..color = AppConstants.docIconFillColor
      ..style = PaintingStyle.fill;

    // back document (bottom, left) - slightly larger
    final backRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.18,
        size.width * 0.72,
        size.height * 0.72,
      ),
      const Radius.circular(2),
    );
    // fill back document
    canvas.drawRRect(backRect, fillPaint);
    // stroke back document
    canvas.drawRRect(backRect, paint);

    // front document (top, right, overlapping) - slightly smaller and offset
    final frontRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.10,
        size.width * 0.72,
        size.height * 0.72,
      ),
      const Radius.circular(2),
    );
    // fill front document
    canvas.drawRRect(frontRect, fillPaint);
    // stroke front document
    canvas.drawRRect(frontRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
