import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// Animated donut showing used / total. The [extra] arc previews how much
/// would be freed by the current selection.
class DiskRing extends StatelessWidget {
  const DiskRing({super.key, required this.usedRatio, this.extraRatio = 0, required this.child, this.size = 160});
  final double usedRatio;
  final double extraRatio;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: usedRatio),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, used, _) => CustomPaint(
        size: Size.square(size),
        painter: _RingPainter(
          used: used,
          extra: extraRatio.clamp(0, used),
          track: theme.dividerColor,
          fill: theme.primaryColor,
          extraColor: const Color(0xFF34C759),
        ),
        child: SizedBox.square(dimension: size, child: Center(child: child)),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.used, required this.extra, required this.track, required this.fill, required this.extraColor});
  final double used, extra;
  final Color track, fill, extraColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, 2 * pi, false, paint..color = track);
    canvas.drawArc(r, -pi / 2, 2 * pi * used, false, paint..color = fill);
    if (extra > 0) {
      // Draw the "would be freed" slice at the end of the used arc.
      canvas.drawArc(r, -pi / 2 + 2 * pi * (used - extra), 2 * pi * extra, false, paint..color = extraColor);
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.used != used || o.extra != extra || o.fill != fill;
}
