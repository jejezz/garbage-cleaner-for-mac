import 'package:flutter/widgets.dart';

/// MacBroom design tokens. Dark, glossy, gradient-forward.
/// Everything visual in the app reads from here so a palette swap is one edit.
abstract final class Broom {
  // Backgrounds
  static const bg0 = Color(0xFF0A0D1C);
  static const bg1 = Color(0xFF141233);
  static const bg2 = Color(0xFF1B1441);
  static const railBg = Color(0x99070A16);

  // Glass surfaces
  static const glass = Color(0x14FFFFFF);
  static const glassHover = Color(0x1FFFFFFF);
  static const border = Color(0x1FFFFFFF);
  static const borderStrong = Color(0x40FFFFFF);

  // Text
  static const text = Color(0xFFF4F5FB);
  static const muted = Color(0xFF9CA3C0);
  static const faint = Color(0xFF5E6488);

  // Accents
  static const violet = Color(0xFF7C6CFF);
  static const pink = Color(0xFFE961FF);
  static const cyan = Color(0xFF34E0FF);
  static const mint = Color(0xFF3DF2B2);
  static const amber = Color(0xFFFFB84D);
  static const rose = Color(0xFFFF5D7A);

  static const accentGradient = LinearGradient(
    colors: [violet, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const coolGradient = LinearGradient(
    colors: [cyan, violet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const successGradient = LinearGradient(
    colors: [mint, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const dangerGradient = LinearGradient(
    colors: [rose, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const bgGradient = LinearGradient(
    colors: [bg0, bg1, bg2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0, 0.55, 1],
  );

  // Typography (system font; macOS resolves to SF Pro)
  static const display = TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: text, letterSpacing: -0.8, height: 1.1);
  static const h1 = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: text, letterSpacing: -0.4);
  static const h2 = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: text);
  static const body = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: text);
  static const caption = TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: muted);
  static const mono = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: text, fontFeatures: [FontFeature.tabularFigures()]);

  static List<BoxShadow> glow(Color c, {double blur = 24, double alpha = 0.45}) =>
      [BoxShadow(color: c.withValues(alpha: alpha), blurRadius: blur, spreadRadius: -2)];
}
