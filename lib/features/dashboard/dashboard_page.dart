import 'package:flutter/cupertino.dart';

import '../../core/app_state.dart';
import '../../core/format.dart';
import '../../core/native_bridge.dart';
import '../../theme/broom_theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/disk_ring.dart';
import '../../widgets/glass.dart';
import 'fda_guide.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.state, required this.onGoToJunk, required this.onGoToApps});
  final AppState state;
  final VoidCallback onGoToJunk;
  final VoidCallback onGoToApps;

  @override
  Widget build(BuildContext context) {
    final v = state.volume;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Macintosh HD', style: Broom.h1)),
              GhostButton(label: 'Refresh', icon: CupertinoIcons.arrow_clockwise, small: true, onPressed: state.refreshDisk),
            ],
          ),
          const SizedBox(height: 18),

          // ── Hero card ──
          GlassCard(
            padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
            glowColor: Broom.violet,
            child: Row(
              children: [
                DiskRing(
                  usedRatio: v?.usedRatio ?? 0,
                  extraRatio: v == null || v.total == 0 ? 0 : state.selectedBytes / v.total,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GradientText(v == null ? '—' : '${(v.usedRatio * 100).round()}%', style: Broom.display, gradient: Broom.coolGradient),
                      const Text('used', style: Broom.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 30),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Stat(label: 'Free', value: v == null ? '—' : formatBytes(v.free), color: Broom.mint),
                      _Stat(label: 'Used', value: v == null ? '—' : formatBytes(v.used), color: Broom.violet),
                      _Stat(label: 'Total', value: v == null ? '—' : formatBytes(v.total), color: Broom.muted),
                      const SizedBox(height: 10),
                      Container(height: 1, color: Broom.border),
                      const SizedBox(height: 10),
                      _Stat(
                        label: 'Junk found',
                        value: state.junk.isEmpty
                            ? (state.scanning ? 'scanning…' : 'not scanned yet')
                            : formatBytes(state.totalJunkBytes),
                        color: Broom.pink,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Quick actions ──
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: CupertinoIcons.sparkles,
                  gradient: Broom.accentGradient,
                  title: 'Smart Scan',
                  subtitle: 'Caches, logs & build junk',
                  onTap: state.scanning
                      ? null
                      : () {
                          onGoToJunk();
                          state.scanJunk();
                        },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ActionCard(
                  icon: CupertinoIcons.square_grid_2x2_fill,
                  gradient: Broom.coolGradient,
                  title: 'Uninstaller',
                  subtitle: 'Remove apps with leftovers',
                  onTap: onGoToApps,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (state.fullDiskAccess == false) _FdaBanner(onHelp: () => showFdaGuide(context, onGranted: state.refreshDisk)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: Broom.glow(color, blur: 8, alpha: 0.8))),
          const SizedBox(width: 10),
          SizedBox(width: 92, child: Text(label, style: Broom.caption)),
          Text(value, style: Broom.mono.copyWith(fontSize: 14)),
        ]),
      );
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({required this.icon, required this.gradient, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final Gradient gradient;
  final String title, subtitle;
  final VoidCallback? onTap;
  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool hover = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: hover && enabled ? 1.02 : 1,
          duration: const Duration(milliseconds: 150),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            glowColor: hover ? widget.gradient.colors.first : null,
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(gradient: widget.gradient, borderRadius: BorderRadius.circular(14), boxShadow: Broom.glow(widget.gradient.colors.first, blur: 18)),
                child: Icon(widget.icon, size: 20, color: const Color(0xFFFFFFFF)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.title, style: Broom.h2),
                  const SizedBox(height: 2),
                  Text(widget.subtitle, style: Broom.caption),
                ]),
              ),
              Icon(CupertinoIcons.chevron_right, size: 14, color: hover ? Broom.text : Broom.faint),
            ]),
          ),
        ),
      ),
    );
  }
}

class _FdaBanner extends StatelessWidget {
  const _FdaBanner({required this.onHelp});
  final VoidCallback onHelp;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: Broom.amber.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Broom.amber.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          const Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 16, color: Broom.amber),
          const SizedBox(width: 10),
          const Expanded(child: Text('Full Disk Access is off — some caches (Safari, Mail…) stay hidden.', style: Broom.caption)),
          GradientButton(label: 'Show me how', icon: CupertinoIcons.question_circle_fill, onPressed: onHelp),
          const SizedBox(width: 8),
          GhostButton(label: 'Open Settings', small: true, onPressed: NativeBridge.openFullDiskAccessSettings),
        ]),
      );
}
