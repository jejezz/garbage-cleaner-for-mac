import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

import '../core/scan_targets.dart';

class SafetyBadge extends StatelessWidget {
  const SafetyBadge(this.safety, {super.key});
  final Safety safety;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (safety) {
      Safety.safe => ('Safe', Colors.green),
      Safety.rebuild => ('Rebuilds', Colors.orange),
      Safety.review => ('Review', Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: MacosTheme.of(context).typography.caption2.copyWith(color: color)),
    );
  }
}
