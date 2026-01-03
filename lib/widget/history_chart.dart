import 'package:flutter/material.dart';

class HistoryChart extends StatelessWidget {
  final List<double> values;
  final String title;
  final Color color;

  const HistoryChart({
    super.key,
    required this.values,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🏷️ TITLE
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        // 📊 CHART AREA (FIX OVERFLOW)
        Expanded(
          child: CustomPaint(
            painter: _ChartPainter(values, color),
            child: Container(),
          ),
        ),
      ],
    );
  }
}

// ================== PAINTER ==================
class _ChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _ChartPainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final range = (maxValue - minValue == 0) ? 1 : maxValue - minValue;

    final stepX = size.width / (values.length - 1);

    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final x = stepX * i;
      final y = size.height -
          ((values[i] - minValue) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // 🔵 DRAW POINTS
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final x = stepX * i;
      final y = size.height -
          ((values[i] - minValue) / range) * size.height;

      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
