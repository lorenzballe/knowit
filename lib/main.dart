import 'package:flutter/material.dart';

import 'screens/comeback_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/today_screen.dart';
import 'screens/topics_screen.dart';
import 'screens/welcome_screen.dart';
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
      home: const KnowitRoot(),
    );
  }
}

/// Where the first-run flow lives. Everything before [_Stage.shell] runs once
/// per install; after that the app opens straight on the tab bar.
enum _Stage { welcome, signIn, topics, notifications, comeback, shell }

class KnowitRoot extends StatefulWidget {
  const KnowitRoot({super.key});

  @override
  State<KnowitRoot> createState() => _KnowitRootState();
}

class _KnowitRootState extends State<KnowitRoot> {
  final AppState _app = AppState();
  _Stage _stage = _Stage.welcome;
  bool _stageResolved = false;

  @override
  void initState() {
    super.initState();
    _app.addListener(_onAppStateChanged);
    _app.init();
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    setState(() {
      // The opening stage is decided once, the first time state is ready:
      // after that the flow drives itself and must not be reset under it.
      if (_app.ready && !_stageResolved) {
        _stageResolved = true;
        if (!_app.onboarded) {
          _stage = _Stage.welcome;
        } else if (_app.shouldShowComeback) {
          _stage = _Stage.comeback;
        } else {
          _stage = _Stage.shell;
        }
      }
    });
  }

  @override
  void dispose() {
    _app.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _go(_Stage stage) => setState(() => _stage = stage);

  Future<void> _finishOnboarding() async {
    await _app.completeOnboarding();
    if (mounted) _go(_Stage.shell);
  }

  @override
  Widget build(BuildContext context) {
    if (!_app.ready) {
      return const Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (_stage) {
      case _Stage.welcome:
        return WelcomeScreen(
          onStart: () => _go(_Stage.topics),
          onSignIn: () => _go(_Stage.signIn),
        );

      case _Stage.signIn:
        return SignInScreen(
          onBack: () => _go(_Stage.welcome),
          onSignedIn: (name) async {
            await _app.setName(name);
            if (mounted) _go(_Stage.topics);
          },
        );

      case _Stage.topics:
        return TopicsScreen(
          initial: _app.pickedTopics,
          onDone: (picked) async {
            await _app.setTopics(picked);
            if (mounted) _go(_Stage.notifications);
          },
        );

      case _Stage.notifications:
        return NotificationScreen(
          previewPill: _app.todaysDeck.first,
          time: _app.notifyTime,
          onEnable: () async {
            await _app.setNotifications(true);
            await _finishOnboarding();
          },
          onSkip: () async {
            await _app.setNotifications(false);
            await _finishOnboarding();
          },
        );

      case _Stage.comeback:
        return ComebackScreen(
          app: _app,
          onContinue: () async {
            await _app.dismissComeback();
            if (mounted) _go(_Stage.shell);
          },
        );

      case _Stage.shell:
        return KnowitShell(
          app: _app,
          onSignedOut: () => setState(() {
            _stageResolved = true;
            _stage = _Stage.welcome;
          }),
        );
    }
  }
}

class KnowitShell extends StatefulWidget {
  final AppState app;
  final VoidCallback onSignedOut;

  const KnowitShell({
    super.key,
    required this.app,
    required this.onSignedOut,
  });

  @override
  State<KnowitShell> createState() => _KnowitShellState();
}

class _KnowitShellState extends State<KnowitShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      TodayScreen(app: widget.app),
      SavedScreen(
        app: widget.app,
        onBackToToday: () => setState(() => _tab = 0),
      ),
      ProfileScreen(app: widget.app, onSignedOut: widget.onSignedOut),
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
