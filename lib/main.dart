import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/comeback_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/today_screen.dart';
import 'screens/welcome_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() => runApp(const KnowitApp());

/// On the web a list should follow the mouse the way it follows a finger.
class _DragAnywhereScrollBehavior extends MaterialScrollBehavior {
  const _DragAnywhereScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

/// Owns the stored state, because the theme is part of it and has to be
/// known above MaterialApp — otherwise the choice could only repaint the
/// screen that made it.
class KnowitApp extends StatefulWidget {
  const KnowitApp({super.key});

  @override
  State<KnowitApp> createState() => _KnowitAppState();
}

class _KnowitAppState extends State<KnowitApp> {
  final AppState _app = AppState();

  @override
  void initState() {
    super.initState();
    _app.addListener(_onChanged);
    _app.init();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _app.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Knowit',
      debugShowCheckedModeBanner: false,
      theme: buildKnowitTheme(Brightness.light),
      darkTheme: buildKnowitTheme(Brightness.dark),
      themeMode: _app.themeMode,
      home: KnowitRoot(app: _app),
      scrollBehavior: const _DragAnywhereScrollBehavior(),
      builder: (context, child) => _PhoneFrame(child: child),
    );
  }
}

/// Knowit is a phone app served from a web page, so on anything wider than a
/// handset it sits in a centred column at handset width rather than stretching
/// a card across a desktop monitor.
class _PhoneFrame extends StatelessWidget {
  final Widget? child;
  const _PhoneFrame({required this.child});

  static const double _maxWidth = 460;

  @override
  Widget build(BuildContext context) {
    final content = child ?? const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width;
    if (width <= _maxWidth) return content;

    return ColoredBox(
      color: context.p.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: ClipRect(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.symmetric(
                  vertical: BorderSide(color: context.p.line),
                ),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Where the first-run flow lives. Everything before [_Stage.shell] runs once
/// per install; after that the app opens straight on the tab bar.
enum _Stage { welcome, signIn, comeback, shell }

class KnowitRoot extends StatefulWidget {
  final AppState app;
  const KnowitRoot({super.key, required this.app});

  @override
  State<KnowitRoot> createState() => _KnowitRootState();
}

class _KnowitRootState extends State<KnowitRoot> {
  AppState get _app => widget.app;
  _Stage _stage = _Stage.welcome;
  bool _stageResolved = false;

  @override
  void initState() {
    super.initState();
    _app.addListener(_onAppStateChanged);
    if (_app.ready) _onAppStateChanged();
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
    if (!_app.ready) return const _Splash();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(_stage), child: _stageScreen()),
    );
  }

  Widget _stageScreen() {
    switch (_stage) {
      case _Stage.welcome:
        return WelcomeScreen(
          // Picking a topic mix is a Knowit+ perk, so the free first run
          // goes straight to today's five on the default mix.
          onStart: _finishOnboarding,
          onSignIn: () => _go(_Stage.signIn),
        );

      case _Stage.signIn:
        return SignInScreen(
          onBack: () => _go(_Stage.welcome),
          onSignedIn: (name) async {
            await _app.setName(name);
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

/// The opening frame: the wordmark on paper, so the app never shows a bare
/// spinner while stored state loads.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.p.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Knowit',
              style: AppText.display(
                size: 30,
                weight: FontWeight.w700,
                spacing: -1,
                color: context.p.ink,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.p.ink.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KnowitShell extends StatefulWidget {
  final AppState app;
  final VoidCallback onSignedOut;

  const KnowitShell({super.key, required this.app, required this.onSignedOut});

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

    // The status bar follows the one palette, like everything else.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (context.p.isDark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: context.p.surface,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(index: _tab, children: screens),
        ),
        bottomNavigationBar: _KnowitTabBar(
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      decoration: BoxDecoration(
        color: context.p.surface,
        border: Border(top: BorderSide(color: context.p.line)),
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        10,
        18,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = i == index;
          final tab = _tabs[i];
          final onColor = context.p.ink;
          final offColor = context.p.inkFaint;
          final tint = selected ? onColor : offColor;

          return Expanded(
            child: Semantics(
              button: true,
              selected: selected,
              label: tab.label,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (selected) return;
                  HapticFeedback.selectionClick();
                  onChanged(i);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The selected tab sits in a soft pill, and the icon
                      // lifts slightly — enough to read at a glance.
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.lime.withValues(alpha: 0.22)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          scale: selected ? 1.08 : 1,
                          child: Icon(tab.icon, size: 20, color: tint),
                        ),
                      ),
                      const SizedBox(height: 5),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: AppText.body(
                          size: 10.5,
                          weight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: tint,
                        ),
                        child: Text(tab.label),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
