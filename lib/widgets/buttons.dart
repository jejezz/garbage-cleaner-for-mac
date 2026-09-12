import 'package:flutter/widgets.dart';

import '../theme/broom_theme.dart';

/// Primary CTA: gradient fill, glow, hover lift, press shrink.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient = Broom.accentGradient,
    this.large = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient gradient;
  final bool large;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool hover = false, down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final glowColor = widget.gradient.colors.first;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => down = true) : null,
        onTapUp: enabled ? (_) => setState(() => down = false) : null,
        onTapCancel: () => setState(() => down = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: down ? 0.96 : (hover && enabled ? 1.03 : 1),
          duration: const Duration(milliseconds: 120),
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.4,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: widget.large ? 22 : 16, vertical: widget.large ? 13 : 9),
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: enabled ? Broom.glow(glowColor, blur: hover ? 30 : 18, alpha: hover ? 0.6 : 0.4) : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: widget.large ? 16 : 14, color: const Color(0xFFFFFFFF)),
                  const SizedBox(width: 8),
                ],
                Text(widget.label,
                    style: TextStyle(
                      fontSize: widget.large ? 14.5 : 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFFFFF),
                      letterSpacing: 0.2,
                    )),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary: glass outline.
class GhostButton extends StatefulWidget {
  const GhostButton({super.key, required this.label, required this.onPressed, this.icon, this.small = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool small;

  @override
  State<GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<GhostButton> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsets.symmetric(horizontal: widget.small ? 10 : 14, vertical: widget.small ? 5 : 8),
          decoration: BoxDecoration(
            color: hover && enabled ? Broom.glassHover : Broom.glass,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: hover && enabled ? Broom.borderStrong : Broom.border),
          ),
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (widget.icon != null) ...[Icon(widget.icon, size: 13, color: Broom.text), const SizedBox(width: 6)],
              Text(widget.label, style: TextStyle(fontSize: widget.small ? 11.5 : 12.5, fontWeight: FontWeight.w600, color: Broom.text)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Icon-only glass button (reveal in Finder etc.)
class IconGhostButton extends StatefulWidget {
  const IconGhostButton({super.key, required this.icon, required this.onPressed, this.tooltip});
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  State<IconGhostButton> createState() => _IconGhostButtonState();
}

class _IconGhostButtonState extends State<IconGhostButton> {
  bool hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => hover = true),
        onExit: (_) => setState(() => hover = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: hover ? Broom.glassHover : const Color(0x00000000),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, size: 14, color: hover ? Broom.text : Broom.muted),
          ),
        ),
      );
}

/// Gradient checkbox (supports tri-state via null).
class BroomCheckbox extends StatelessWidget {
  const BroomCheckbox({super.key, required this.value, required this.onChanged});
  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final on = value != false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(value != true),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            gradient: on ? Broom.accentGradient : null,
            color: on ? null : const Color(0x00000000),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: on ? const Color(0x00000000) : Broom.borderStrong, width: 1.5),
            boxShadow: on ? Broom.glow(Broom.violet, blur: 10, alpha: 0.5) : null,
          ),
          child: on
              ? Center(
                  child: value == null
                      ? Container(width: 8, height: 2, color: const Color(0xFFFFFFFF))
                      : const _Check(),
                )
              : null,
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check();
  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(10, 8), painter: _CheckPainter());
}

class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    c.drawPath(Path()..moveTo(0.5, s.height * 0.55)..lineTo(s.width * 0.38, s.height - 0.5)..lineTo(s.width - 0.5, 0.5), p);
  }

  @override
  bool shouldRepaint(_) => false;
}
