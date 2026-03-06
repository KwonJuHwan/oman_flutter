import 'dart:ui';

import 'package:flutter/material.dart';

class BorderPainter extends CustomPainter {
  final double progress;
  final Color color;

  BorderPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (progress <= 0 || color == Colors.transparent) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    final path = Path()..addRRect(rrect);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    
    final metric = metrics.first;
    final double totalLength = metric.length;
    
    double bottomCenter = totalLength * 0.75; 
    double halfProgressLength = (totalLength * 0.5) * progress;

    double leftStart = bottomCenter - halfProgressLength;
    _drawPathSegment(canvas, metric, leftStart, bottomCenter, paint, totalLength);

    double rightEnd = bottomCenter + halfProgressLength;
    _drawPathSegment(canvas, metric, bottomCenter, rightEnd, paint, totalLength);
  }

  void _drawPathSegment(Canvas canvas, PathMetric metric, double start, double end, Paint paint, double total) {
    if (start < 0) {
      canvas.drawPath(metric.extractPath(total + start, total), paint);
      canvas.drawPath(metric.extractPath(0, end), paint);
    } else if (end > total) {
      canvas.drawPath(metric.extractPath(start, total), paint);
      canvas.drawPath(metric.extractPath(0, end % total), paint);
    } else {
      canvas.drawPath(metric.extractPath(start, end), paint);
    }
  }

  @override
  bool shouldRepaint(BorderPainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.color != color;
}