import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/native_bridge.dart';
import '../../widgets/disk_ring.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.state, required this.onGoToJunk});
  final AppState state;
  final VoidCallback onGoToJunk;

  @override
  Widget build(BuildContext context) {
    final t = MacosTheme.of(context).typography;
    final v = state.volume;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Macintosh HD', style: t.title1),
          const SizedBox(height: 20),
          Row(
            children: [
              DiskRing(
                usedRatio: v?.usedRatio ?? 0,
                extraRatio: v == null || v.total == 0 ? 0 : state.selectedBytes / v.total,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(v == null ? '—' : '${(v.usedRatio * 100).round()}%', style: t.largeTitle),
                    Text('used', style: t.caption1),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _stat(context, 'Free', v == null ? '—' : formatBytes(v.free)),
                    _stat(context, 'Used', v == null ? '—' : formatBytes(v.used)),
                    _stat(context, 'Total', v == null ? '—' : formatBytes(v.total)),
                    const SizedBox(height: 12),
                    _stat(context, 'Junk found',
                        state.junk.isEmpty ? (state.scanning ? 'scanning…' : 'not scanned') : formatBytes(state.totalJunkBytes)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (state.fullDiskAccess == false) _fdaBanner(context),
          const Spacer(),
          Row(
            children: [
              PushButton(
                controlSize: ControlSize.large,
                onPressed: state.scanning ? null : () async {
                  onGoToJunk();
                  await state.scanJunk();
                },
                child: Text(state.scanning ? 'Scanning…' : 'Scan for Junk'),
              ),
              const SizedBox(width: 12),
              PushButton(
                controlSize: ControlSize.large,
                secondary: true,
                onPressed: state.refreshDisk,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    final t = MacosTheme.of(context).typography;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: t.body.copyWith(color: MacosColors.secondaryLabelColor))),
          Text(value, style: t.body),
        ],
      ),
    );
  }

  Widget _fdaBanner(BuildContext context) {
    final t = MacosTheme.of(context).typography;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MacosColors.systemOrangeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const MacosIcon(CupertinoIcons.exclamationmark_triangle, color: MacosColors.systemOrangeColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Full Disk Access is off. Some caches (Safari, Mail, …) will be invisible.',
              style: t.caption1,
            ),
          ),
          PushButton(
            controlSize: ControlSize.small,
            secondary: true,
            onPressed: NativeBridge.openFullDiskAccessSettings,
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
