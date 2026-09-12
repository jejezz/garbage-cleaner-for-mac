import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'core/app_state.dart';
import 'features/apps/apps_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/junk/junk_page.dart';

const _windowSize = Size(780, 540);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // A popover-style window: no title bar, no traffic lights, not in the Dock
  // (LSUIElement in Info.plist), hidden until the tray icon is clicked.
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      size: _windowSize,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
      skipTaskbar: true,
      alwaysOnTop: true,
    ),
    () async => windowManager.hide(),
  );

  await trayManager.setIcon('assets/tray/tray_icon.png', isTemplate: true);
  await trayManager.setContextMenu(Menu(items: [
    MenuItem(key: 'open', label: 'Open Garbage Cleaner'),
    MenuItem.separator(),
    MenuItem(key: 'quit', label: 'Quit'),
  ]));

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with TrayListener, WindowListener {
  final state = AppState();
  int page = 0;

  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
    state.refreshDisk();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  // ── Tray / window behaviour ──────────────────────────────────────────────

  @override
  void onTrayIconMouseDown() => _toggleWindow();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem item) {
    switch (item.key) {
      case 'open':
        _showUnderTray();
      case 'quit':
        exit(0);
    }
  }

  /// Popover behaviour: clicking anywhere else dismisses the window.
  @override
  void onWindowBlur() => windowManager.hide();

  Future<void> _toggleWindow() async {
    if (await windowManager.isVisible()) {
      await windowManager.hide();
    } else {
      await _showUnderTray();
    }
  }

  Future<void> _showUnderTray() async {
    final tray = await trayManager.getBounds();
    if (tray != null) {
      await windowManager.setPosition(
        Offset(tray.center.dx - _windowSize.width / 2, tray.bottom + 6),
      );
    }
    await windowManager.show();
    await windowManager.focus();
    state.refreshDisk();
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: 'Garbage Cleaner',
      debugShowCheckedModeBanner: false,
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      home: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MacosWindow(
          sidebar: Sidebar(
            minWidth: 170,
            top: const Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Text('Garbage Cleaner', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            builder: (context, scrollController) => SidebarItems(
              currentIndex: page,
              scrollController: scrollController,
              onChanged: (i) => setState(() => page = i),
              items: const [
                SidebarItem(leading: MacosIcon(CupertinoIcons.chart_pie), label: Text('Disk')),
                SidebarItem(leading: MacosIcon(CupertinoIcons.trash), label: Text('Junk')),
                SidebarItem(leading: MacosIcon(CupertinoIcons.square_grid_2x2), label: Text('Apps')),
              ],
            ),
            bottom: Padding(
              padding: const EdgeInsets.all(12),
              child: PushButton(
                controlSize: ControlSize.small,
                secondary: true,
                onPressed: () => exit(0),
                child: const Text('Quit'),
              ),
            ),
          ),
          child: IndexedStack(
            index: page,
            children: [
              DashboardPage(state: state, onGoToJunk: () => setState(() => page = 1)),
              JunkPage(state: state),
              AppsPage(state: state),
            ],
          ),
        ),
      ),
    );
  }
}
