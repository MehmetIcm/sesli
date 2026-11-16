import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// PCM örneklerinden tepe noktaları çıkarıp dalga formu çizer.
class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.samples,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.barCount,
  });

  final Float32List samples;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final int barCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty || size.width <= 0) return;

    final peaks = _peaks(samples, barCount);
    final gap = size.width / barCount;
    final barWidth = math.max(1.5, gap * 0.42);
    final mid = size.height / 2;
    final activeBars = (progress.clamp(0.0, 1.0) * barCount).floor();

    final activePaint = Paint()..color = activeColor;
    final inactivePaint = Paint()..color = inactiveColor;

    for (var i = 0; i < barCount; i++) {
      final peak = peaks[i].clamp(0.06, 1.0).toDouble();
      final height = math.max(3.0, peak * size.height * 0.92);
      final x = i * gap + (gap - barWidth) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, mid - height / 2, barWidth, height),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, i < activeBars ? activePaint : inactivePaint);
    }
  }

  static List<double> _peaks(Float32List samples, int count) {
    final peaks = List<double>.filled(count, 0);
    final step = math.max(1, (samples.length / count).floor());
    for (var i = 0; i < count; i++) {
      final start = i * step;
      final end = math.min(samples.length, start + step);
      var peak = 0.0;
      for (var j = start; j < end; j++) {
        final value = samples[j].abs();
        if (value > peak) peak = value;
      }
      peaks[i] = peak;
    }

    // Komşu barlarla hafif yumuşatma; daha dengeli bir görünüm verir.
    final smoothed = List<double>.filled(count, 0);
    for (var i = 0; i < count; i++) {
      final prev = peaks[math.max(0, i - 1)];
      final next = peaks[math.min(count - 1, i + 1)];
      smoothed[i] = (prev + peaks[i] * 2 + next) / 4;
    }
    return smoothed;
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.samples != samples ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
