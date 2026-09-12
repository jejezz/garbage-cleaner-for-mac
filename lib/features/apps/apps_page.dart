import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path/path.dart' as p;

import '../../core/app_scanner.dart';
import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/native_bridge.dart';

/// Master/detail: app list on the left, leftovers for the selected app on the right.
class AppsPage extends StatefulWidget {
  const AppsPage({super.key, required this.state});
  final AppState state;

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  String filter = '';

  @override
  void initState() {
    super.initState();
    // Defer: notifying listeners synchronously inside initState would fire during build.
    if (widget.state.apps.isEmpty) Future.microtask(widget.state.loadApps);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final apps = state.apps.where((a) => a.name.toLowerCase().contains(filter.toLowerCase())).toList();

    return Row(
      children: [
        // ── App list ──
        SizedBox(
          width: 260,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: MacosSearchField(
                  placeholder: 'Search apps',
                  onChanged: (v) => setState(() => filter = v),
                ),
              ),
              Expanded(
                child: state.loadingApps
                    ? const Center(child: ProgressCircle())
                    : ListView.builder(
                        itemCount: apps.length,
                        itemBuilder: (_, i) => _AppRow(
                          app: apps[i],
                          selected: apps[i] == state.selectedApp,
                          onTap: () => state.selectApp(apps[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
        Container(width: 1, color: MacosTheme.of(context).dividerColor),
        // ── Detail ──
        Expanded(child: state.selectedApp == null ? _empty(context) : _Detail(state: state)),
      ],
    );
  }

  Widget _empty(BuildContext context) => Center(
        child: Text('Select an app to see its leftover files',
            style: MacosTheme.of(context).typography.body.copyWith(color: MacosColors.secondaryLabelColor)),
      );
}

class _AppRow extends StatelessWidget {
  const _AppRow({required this.app, required this.selected, required this.onTap});
  final InstalledApp app;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = MacosTheme.of(context).typography;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        color: selected ? MacosTheme.of(context).primaryColor.withValues(alpha: 0.15) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(app.name, style: t.body, overflow: TextOverflow.ellipsis)),
            Text(formatBytes(app.bytes), style: t.caption1.copyWith(color: MacosColors.secondaryLabelColor)),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final t = MacosTheme.of(context).typography;
    final app = state.selectedApp!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(app.name, style: t.title2),
              Text(
                '${app.info.bundleId ?? 'no bundle id'}  ·  v${app.info.version ?? '?'}',
                style: t.caption1.copyWith(color: MacosColors.secondaryLabelColor),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _row(
                context,
                checked: state.removeAppBundle,
                onChanged: state.setRemoveAppBundle,
                title: p.basename(app.info.path),
                subtitle: p.dirname(app.info.path),
                bytes: app.bytes,
                path: app.info.path,
                bold: true,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                child: Text('Leftovers in ~/Library (${state.leftovers.length})',
                    style: t.caption1.copyWith(color: MacosColors.secondaryLabelColor)),
              ),
              for (final l in state.leftovers)
                _row(
                  context,
                  checked: state.selectedLeftovers.contains(l.path),
                  onChanged: (v) => state.toggleLeftover(l.path, v),
                  title: p.basename(l.path),
                  subtitle: p.dirname(l.path).replaceFirst(_home, '~'),
                  bytes: l.bytes,
                  path: l.path,
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: MacosTheme.of(context).dividerColor))),
          child: Row(
            children: [
              Expanded(child: Text('${formatBytes(state.uninstallBytes)} to remove', style: t.body)),
              PushButton(
                controlSize: ControlSize.large,
                onPressed: state.cleaning || state.uninstallBytes == 0 ? null : () => _confirm(context),
                child: Text(state.cleaning ? 'Removing…' : 'Uninstall'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String get _home => Platform.environment['HOME'] ?? '';

  Widget _row(
    BuildContext context, {
    required bool checked,
    required ValueChanged<bool> onChanged,
    required String title,
    required String subtitle,
    required int bytes,
    required String path,
    bool bold = false,
  }) {
    final t = MacosTheme.of(context).typography;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          MacosCheckbox(value: checked, onChanged: onChanged),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: bold ? t.headline : t.body, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: t.caption2.copyWith(color: MacosColors.secondaryLabelColor), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          MacosIconButton(
            icon: const MacosIcon(CupertinoIcons.folder, size: 14),
            onPressed: () => NativeBridge.revealInFinder(path),
          ),
          SizedBox(width: 72, child: Text(formatBytes(bytes), style: t.body, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final app = state.selectedApp!;
    final ok = await showMacosAlertDialog<bool>(
      context: context,
      builder: (ctx) => MacosAlertDialog(
        appIcon: const MacosIcon(CupertinoIcons.trash, size: 56),
        title: Text('Uninstall ${app.name}?'),
        message: Text(
          '${formatBytes(state.uninstallBytes)} will be moved to the Trash.',
          textAlign: TextAlign.center,
        ),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Uninstall'),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (ok == true) await state.uninstallSelectedApp();
  }
}
