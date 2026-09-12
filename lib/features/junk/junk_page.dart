import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/native_bridge.dart';
import '../../core/scan_targets.dart';
import '../../core/scanner.dart';
import '../../widgets/safety_badge.dart';

class JunkPage extends StatelessWidget {
  const JunkPage({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final t = MacosTheme.of(context).typography;

    // Group rows by target, keep the target order from scan_targets.dart.
    final byTarget = <ScanTarget, List<JunkItem>>{};
    for (final j in state.junk) {
      byTarget.putIfAbsent(j.target, () => []).add(j);
    }
    final targets = scanTargets.where(byTarget.containsKey).toList();

    return Column(
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Junk Files', style: t.title2),
                    Text(
                      state.scanning
                          ? 'Scanning… ${formatBytes(state.totalJunkBytes)} found so far'
                          : state.junk.isEmpty
                              ? 'Run a scan to find caches, logs and build artifacts.'
                              : '${formatBytes(state.totalJunkBytes)} in ${state.junk.length} items',
                      style: t.caption1.copyWith(color: MacosColors.secondaryLabelColor),
                    ),
                  ],
                ),
              ),
              if (state.scanning) const ProgressCircle(),
              const SizedBox(width: 8),
              PushButton(
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: state.scanning ? null : state.scanJunk,
                child: const Text('Rescan'),
              ),
            ],
          ),
        ),
        if (state.lastError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(state.lastError!, style: t.caption1.copyWith(color: MacosColors.systemRedColor)),
          ),

        // ── List ──
        Expanded(
          child: state.junk.isEmpty && !state.scanning
              ? Center(
                  child: PushButton(
                    controlSize: ControlSize.large,
                    onPressed: state.scanJunk,
                    child: const Text('Scan Now'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: targets.length,
                  itemBuilder: (_, i) => _TargetSection(state: state, target: targets[i], items: byTarget[targets[i]]!),
                ),
        ),

        // ── Footer ──
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: MacosTheme.of(context).dividerColor))),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${formatBytes(state.selectedBytes)} selected',
                  style: t.body,
                ),
              ),
              PushButton(
                controlSize: ControlSize.large,
                onPressed: state.selected.isEmpty || state.cleaning ? null : () => _confirmClean(context),
                child: Text(state.cleaning ? 'Cleaning…' : 'Move to Trash'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmClean(BuildContext context) async {
    final ok = await showMacosAlertDialog<bool>(
      context: context,
      builder: (ctx) => MacosAlertDialog(
        appIcon: const MacosIcon(CupertinoIcons.trash, size: 56),
        title: const Text('Move to Trash?'),
        message: Text(
          '${state.selected.length} items (${formatBytes(state.selectedBytes)}) will be moved to the Trash. '
          'You can restore them from the Trash until you empty it.',
          textAlign: TextAlign.center,
        ),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Move to Trash'),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (ok == true) await state.cleanSelected();
  }
}

class _TargetSection extends StatefulWidget {
  const _TargetSection({required this.state, required this.target, required this.items});
  final AppState state;
  final ScanTarget target;
  final List<JunkItem> items;

  @override
  State<_TargetSection> createState() => _TargetSectionState();
}

class _TargetSectionState extends State<_TargetSection> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = MacosTheme.of(context).typography;
    final state = widget.state;
    final items = widget.items;
    final total = items.fold(0, (s, j) => s + j.bytes);
    final selectedCount = items.where((j) => state.selected.contains(j.path)).length;
    final all = selectedCount == items.length;
    final none = selectedCount == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header row
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => expanded = !expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                MacosCheckbox(
                  value: all ? true : (none ? false : null),
                  onChanged: (v) => state.toggleTarget(widget.target, !all),
                ),
                const SizedBox(width: 8),
                MacosIcon(expanded ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_right, size: 12),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(widget.target.title, style: t.headline),
                        const SizedBox(width: 8),
                        SafetyBadge(widget.target.safety),
                      ]),
                      Text(widget.target.description,
                          style: t.caption1.copyWith(color: MacosColors.secondaryLabelColor)),
                    ],
                  ),
                ),
                Text(formatBytes(total), style: t.body),
              ],
            ),
          ),
        ),
        if (expanded)
          for (final j in items)
            Padding(
              padding: const EdgeInsets.only(left: 52, right: 4, top: 2, bottom: 2),
              child: Row(
                children: [
                  MacosCheckbox(
                    value: state.selected.contains(j.path),
                    onChanged: (v) => state.toggle(j.path, v),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(j.name, style: t.body, overflow: TextOverflow.ellipsis)),
                  MacosIconButton(
                    icon: const MacosIcon(CupertinoIcons.folder, size: 14),
                    onPressed: () => NativeBridge.revealInFinder(j.path),
                  ),
                  SizedBox(width: 72, child: Text(formatBytes(j.bytes), style: t.body, textAlign: TextAlign.right)),
                ],
              ),
            ),
        Container(height: 1, color: MacosTheme.of(context).dividerColor),
      ],
    );
  }
}
