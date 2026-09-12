import 'dart:math';

import 'package:flutter/widgets.dart';

import '../theme/broom_theme.dart';

/// Glowing gradient donut. [extraRatio] previews how much of the used arc the
/// current selection would free (drawn in the success gradient).
class DiskRing extends StatelessWidget {
  const DiskRing({super.key, required this.usedRatio, this.extraRatio = 0, required this.child, this.size = 180});
  final double usedRatio;
  final double extraRatio;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: usedRatio),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, used, _) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: extraRatio.clamp(0, used)),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, extra, _) => CustomPaint(
          painter: _RingPainter(used: used, extra: extra),
          child: SizedBox.square(dimension: size, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.used, required this.extra});
  final double used, extra;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = (Offset.zero & size).deflate(stroke / 2 + 6);
    final center = rect.center;
    final start = -pi / 2;

    // Track
    canvas.drawArc(rect, 0, 2 * pi, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0x14FFFFFF));

    // Used arc: gradient sweep + outer glow
    final sweep = 2 * pi * used;
    final grad = SweepGradient(
      startAngle: 0,
      endAngle: 2 * pi,
      colors: const [Broom.cyan, Broom.violet, Broom.pink, Broom.cyan],
      stops: const [0, 0.45, 0.85, 1],
      transform: GradientRotation(start),
    ).createShader(rect);

    canvas.drawArc(rect, start, sweep, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = grad
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
      ..color = const Color(0x80FFFFFF));
    canvas.drawArc(rect, start, sweep, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = grad);

    // Preview of what would be freed, at the tail of the used arc
    if (extra > 0.002) {
      final eSweep = 2 * pi * extra;
      final ePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = Broom.successGradient.createShader(rect);
      canvas.drawArc(rect, start + sweep - eSweep, eSweep, false, ePaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      canvas.drawArc(rect, start + sweep - eSweep, eSweep, false, ePaint..maskFilter = null);
    }

    // Inner soft disc for depth
    canvas.drawCircle(center, rect.width / 2 - stroke, Paint()
      ..shader = RadialGradient(colors: [Broom.violet.withValues(alpha: 0.18), const Color(0x00000000)]).createShader(rect));
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.used != used || o.extra != extra;
}
