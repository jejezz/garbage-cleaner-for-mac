import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;

import '../../core/native_bridge.dart';
import '../../theme/broom_theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/glass.dart';

/// Step-by-step walkthrough for granting Full Disk Access.
/// Screenshots live in assets/guide/step{1..5}.png, composed by scripts/compose_guide.py.
/// While open, it polls the permission every 2 s and jumps to the last step
/// as soon as macOS reports it granted.
Future<void> showFdaGuide(BuildContext context, {required Future<void> Function() onGranted}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'dismiss',
    barrierColor: Broom.bg0.withValues(alpha: 0.82),
    transitionDuration: const Duration(milliseconds: 220),
    transitionBuilder: (_, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)), child: child),
    ),
    pageBuilder: (ctx, _, _) => Center(child: _FdaGuide(onGranted: onGranted)),
  );
}

class _Step {
  const _Step({required this.title, required this.body, this.image});
  final String title;
  final String body;
  final String? image;
}

const _steps = <_Step>[
  _Step(
    title: 'Open Full Disk Access settings',
    body: 'macOS keeps some folders (Safari, Mail, Messages…) private unless you allow an app explicitly. '
        'Press the button below to jump straight to System Settings › Privacy & Security › Full Disk Access.',
    image: 'assets/guide/step1.png',
  ),
  _Step(
    title: 'Click “+” and unlock',
    body: 'Click the “+” button under the list. macOS asks for Touch ID or your password before it lets you change this setting.',
    image: 'assets/guide/step2.png',
  ),
  _Step(
    title: 'Pick MacBroom',
    body: 'In the file picker, type “MacBroom” in the search field (or browse to Applications), select MacBroom.app and click Open. '
        'You can also drag MacBroom from a Finder window straight into the list.',
    image: 'assets/guide/step3.png',
  ),
  _Step(
    title: 'Quit & Reopen',
    body: 'macOS explains that MacBroom only gets the permission after a restart. Click “Quit & Reopen” — MacBroom comes right back, '
        'and the warning banner is gone.',
    image: 'assets/guide/step4.png',
  ),
  _Step(
    title: 'All set',
    body: 'MacBroom now shows a blue switch in the list. Rescanning will include caches that were hidden before.',
    image: 'assets/guide/step5.png',
  ),
];

class _FdaGuide extends StatefulWidget {
  const _FdaGuide({required this.onGranted});
  final Future<void> Function() onGranted;

  @override
  State<_FdaGuide> createState() => _FdaGuideState();
}

class _FdaGuideState extends State<_FdaGuide> {
  int step = 0;
  bool granted = false;
  Timer? poll;

  @override
  void initState() {
    super.initState();
    poll = Timer.periodic(const Duration(seconds: 2), (_) => _check());
    _check();
  }

  @override
  void dispose() {
    poll?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    final ok = await NativeBridge.hasFullDiskAccess();
    if (!mounted || ok == granted) return;
    setState(() {
      granted = ok;
      if (ok) step = _steps.length - 1;
    });
    if (ok) {
      poll?.cancel();
      await widget.onGranted();
    }
  }

  /// The running .app bundle: `<bundle>/Contents/MacOS/<exe>`.
  String get _appPath => p.dirname(p.dirname(p.dirname(Platform.resolvedExecutable)));

  @override
  Widget build(BuildContext context) {
    final s = _steps[step];
    final last = step == _steps.length - 1;
    // Fit inside the window: the screenshot shrinks before the text does.
    final maxH = MediaQuery.sizeOf(context).height - 36;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 620, maxHeight: maxH),
      child: GlassCard(
        opaque: true,
        padding: EdgeInsets.zero,
        glowColor: granted ? Broom.mint : Broom.violet,
        child: DefaultTextStyle(
          style: Broom.body,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // ── Screenshot ──
            Flexible(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: ColoredBox(
                  color: Broom.bg0,
                  child: Center(
                    heightFactor: 1, // shrink to the image instead of filling the leftover height
                    child: AspectRatio(
                      aspectRatio: 1200 / 750,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: s.image == null
                            ? const ColoredBox(color: Broom.bg0)
                            : Image.asset(s.image!, key: ValueKey(s.image), fit: BoxFit.cover, filterQuality: FilterQuality.medium,
                                errorBuilder: (_, _, _) => const ColoredBox(color: Broom.bg0)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  for (var i = 0; i < _steps.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == step ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: i == step ? (granted ? Broom.successGradient : Broom.accentGradient) : null,
                        color: i == step ? null : (i < step ? Broom.muted : Broom.faint),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const Spacer(),
                  _StatusPill(granted: granted),
                ]),
                const SizedBox(height: 10),
                Text('${step + 1}. ${s.title}', style: Broom.h1.copyWith(fontSize: 18)),
                const SizedBox(height: 6),
                Text(s.body, style: Broom.caption.copyWith(fontSize: 12.5, height: 1.45)),
                const SizedBox(height: 14),
                Row(children: [
                  if (step == 0 || step == 1 || step == 3)
                    GradientButton(label: 'Open System Settings', icon: CupertinoIcons.gear_alt_fill, onPressed: NativeBridge.openFullDiskAccessSettings),
                  if (step == 2) ...[
                    GradientButton(label: 'Open System Settings', icon: CupertinoIcons.gear_alt_fill, onPressed: NativeBridge.openFullDiskAccessSettings),
                    const SizedBox(width: 8),
                    GhostButton(label: 'Show MacBroom in Finder', icon: CupertinoIcons.folder, onPressed: () => NativeBridge.revealInFinder(_appPath)),
                  ],
                  if (last) GradientButton(label: 'Done', gradient: Broom.successGradient, onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                  GhostButton(label: 'Back', small: true, onPressed: step == 0 ? null : () => setState(() => step--)),
                  const SizedBox(width: 6),
                  GhostButton(label: last ? 'Close' : 'Next', small: true, onPressed: last ? () => Navigator.pop(context) : () => setState(() => step++)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.granted});
  final bool granted;
  @override
  Widget build(BuildContext context) => granted
      ? const Pill('GRANTED', color: Broom.mint, icon: CupertinoIcons.checkmark_seal_fill)
      : const Pill('WAITING FOR PERMISSION…', color: Broom.amber, icon: CupertinoIcons.hourglass);
}
