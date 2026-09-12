import 'package:flutter/cupertino.dart';

import '../core/scan_targets.dart';
import '../theme/broom_theme.dart';
import 'glass.dart';

class SafetyBadge extends StatelessWidget {
  const SafetyBadge(this.safety, {super.key});
  final Safety safety;

  static Color colorOf(Safety s) => switch (s) {
        Safety.safe => Broom.mint,
        Safety.rebuild => Broom.amber,
        Safety.review => Broom.rose,
      };

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (safety) {
      Safety.safe => ('SAFE', CupertinoIcons.checkmark_shield_fill),
      Safety.rebuild => ('REBUILDS', CupertinoIcons.arrow_2_circlepath),
      Safety.review => ('REVIEW', CupertinoIcons.eye_fill),
    };
    return Pill(label, color: colorOf(safety), icon: icon);
  }
}
