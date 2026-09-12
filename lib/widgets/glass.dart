import 'package:flutter/widgets.dart';

import '../theme/broom_theme.dart';

/// Frosted panel with a hairline border and a subtle top highlight.
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 16, this.glowColor});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Broom.glass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Broom.border),
        boxShadow: glowColor == null ? null : Broom.glow(glowColor!, blur: 40, alpha: 0.25),
        gradient: const LinearGradient(
          colors: [Color(0x1FFFFFFF), Color(0x0AFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Text painted with a gradient.
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, required this.style, this.gradient = Broom.accentGradient});
  final String text;
  final TextStyle style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (b) => gradient.createShader(Offset.zero & b.size),
        child: Text(text, style: style.copyWith(color: const Color(0xFFFFFFFF))),
      );
}

/// Small rounded label (Safe / Rebuilds / Review, counts, etc.)
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 11, color: color), const SizedBox(width: 4)],
          Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3)),
        ]),
      );
}
