import 'package:flutter/material.dart';

import 'screens/profile_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/today_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() {
  runApp(const KnowitApp());
}

class KnowitApp extends StatelessWidget {
  const KnowitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Knowit',
      debugShowCheckedModeBanner: false,
      theme: buildKnowitTheme(),
      home: const KnowitShell(),
    );
  }
}

class KnowitShell extends StatefulWidget {
  const KnowitShell({super.key});

  @override
  State<KnowitShell> createState() => _KnowitShellState();
}

class _KnowitShellState extends State<KnowitShell> {
  final AppState _app = AppState();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _app.addListener(_onAppStateChanged);
    _app.init();
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _app.removeListener(_onAppStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_app.ready) {
      return const Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = [
      TodayScreen(app: _app),
      SavedScreen(app: _app),
      ProfileScreen(app: _app),
    ];

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        top: false,
        child: IndexedStack(index: _tab, children: screens),
      ),
      bottomNavigationBar: _KnowitTabBar(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _KnowitTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _KnowitTabBar({required this.index, required this.onChanged});

  static const _tabs = [
    (icon: Icons.wb_sunny_rounded, label: 'Today'),
    (icon: Icons.bookmark_rounded, label: 'Saved'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        30,
        12,
        30,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = i == index;
          final tab = _tabs[i];
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab.icon,
                    size: 20,
                    color: selected
                        ? AppColors.ink
                        : Colors.black.withValues(alpha: 0.32),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tab.label,
                    style: AppText.figtree(
                      size: 10.5,
                      weight: FontWeight.w500,
                      color: selected
                          ? AppColors.ink
                          : Colors.black.withValues(alpha: 0.32),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
