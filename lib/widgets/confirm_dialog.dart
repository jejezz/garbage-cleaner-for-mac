import 'package:flutter/cupertino.dart';

import '../theme/broom_theme.dart';
import 'buttons.dart';
import 'glass.dart';

/// Glass confirmation sheet. Resolves true when the primary button is pressed.
Future<bool> showConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  IconData icon = CupertinoIcons.trash_fill,
  Gradient gradient = Broom.dangerGradient,
}) async {
  final r = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'dismiss',
    barrierColor: Broom.bg0.withValues(alpha: 0.82),
    transitionDuration: const Duration(milliseconds: 200),
    transitionBuilder: (_, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)), child: child),
    ),
    pageBuilder: (ctx, _, _) => Center(
      child: SizedBox(
        width: 380,
        child: GlassCard(
          opaque: true,
          padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
          glowColor: gradient.colors.first,
          child: DefaultTextStyle(
            style: Broom.body,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle, boxShadow: Broom.glow(gradient.colors.first, blur: 26)),
                child: Icon(icon, size: 24, color: const Color(0xFFFFFFFF)),
              ),
              const SizedBox(height: 16),
              Text(title, style: Broom.h1.copyWith(fontSize: 18), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message, style: Broom.caption.copyWith(fontSize: 12.5, height: 1.4), textAlign: TextAlign.center),
              const SizedBox(height: 22),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                GhostButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx, false)),
                const SizedBox(width: 10),
                GradientButton(label: action, gradient: gradient, onPressed: () => Navigator.pop(ctx, true)),
              ]),
            ]),
          ),
        ),
      ),
    ),
  );
  return r == true;
}
