import 'package:flutter/material.dart';

/// Sesli'nin vektörel markası: konuşma balonu içinde ses dalgaları.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 36, this.showShadow = false});

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showShadow
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: size * 0.3,
                  offset: Offset(0, size * 0.08),
                ),
              ],
            )
          : null,
      child: CustomPaint(painter: _BrandMarkPainter(), size: Size.square(size)),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.width * 0.26);

    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B4F49), Color(0xFF052A27)],
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), background);

    final bubbleRect = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.23,
      size.width * 0.64,
      size.height * 0.47,
    );
    final bubble = Paint()..color = const Color(0xFFFDF6E8);
    final bubbleRRect = RRect.fromRectAndRadius(
      bubbleRect,
      Radius.circular(size.width * 0.13),
    );
    canvas.drawRRect(bubbleRRect, bubble);

    final tail = Path()
      ..moveTo(size.width * 0.29, size.height * 0.65)
      ..lineTo(size.width * 0.29, size.height * 0.82)
      ..lineTo(size.width * 0.46, size.height * 0.68)
      ..close();
    canvas.drawPath(tail, bubble);

    final bars = <(double, double, double, Color)>[
      (0.33, 0.38, 0.16, const Color(0xFF0F766E)),
      (0.42, 0.33, 0.26, const Color(0xFF0F766E)),
      (0.51, 0.29, 0.34, const Color(0xFFE9A23B)),
      (0.60, 0.34, 0.25, const Color(0xFF0F766E)),
      (0.69, 0.39, 0.14, const Color(0xFF0F766E)),
    ];
    for (final bar in bars) {
      final x = size.width * bar.$1;
      final y = size.height * bar.$2;
      final height = size.height * bar.$3;
      final width = size.width * 0.055;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, width, height),
          Radius.circular(width / 2),
        ),
        Paint()..color = bar.$4,
      );
    }

    canvas.drawCircle(
      Offset(size.width * 0.79, size.height * 0.78),
      size.width * 0.045,
      Paint()..color = const Color(0xFFE9A23B),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
