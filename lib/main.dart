import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/comeback_screen.dart';
import 'screens/deck_viewer_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/today_screen.dart';
import 'screens/topic_mix_screen.dart';
import 'screens/welcome_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() => runApp(const AstutoApp());

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
class AstutoApp extends StatefulWidget {
  const AstutoApp({super.key});

  @override
  State<AstutoApp> createState() => _AstutoAppState();
}

class _AstutoAppState extends State<AstutoApp> {
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
      title: 'Astuto',
      debugShowCheckedModeBanner: false,
      theme: buildAstutoTheme(Brightness.light),
      darkTheme: buildAstutoTheme(Brightness.dark),
      themeMode: _app.themeMode,
      home: AstutoRoot(app: _app),
      scrollBehavior: const _DragAnywhereScrollBehavior(),
      builder: (context, child) => _PhoneFrame(child: child),
    );
  }
}

/// Astuto is a phone app served from a web page, so on anything wider than a
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
enum _Stage { welcome, topics, signIn, comeback, shell }

class AstutoRoot extends StatefulWidget {
  final AppState app;
  const AstutoRoot({super.key, required this.app});

  @override
  State<AstutoRoot> createState() => _AstutoRootState();
}

class _AstutoRootState extends State<AstutoRoot> {
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
          onStart: () => _go(_Stage.topics),
          onSignIn: () => _go(_Stage.signIn),
        );

      case _Stage.topics:
        return TopicMixScreen(
          onDone: (weights) async {
            await _app.setTopicMix(weights);
            await _finishOnboarding();
          },
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
        return AstutoShell(
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
              'Astuto',
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

class AstutoShell extends StatefulWidget {
  final AppState app;
  final VoidCallback onSignedOut;

  const AstutoShell({super.key, required this.app, required this.onSignedOut});

  @override
  State<AstutoShell> createState() => _AstutoShellState();
}

class _AstutoShellState extends State<AstutoShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      TodayScreen(app: widget.app),
      SavedScreen(
        app: widget.app,
        // A day still to do belongs on Today, where it can be answered. A day
        // already worked through opens as a re-read instead, because sending
        // someone back to a finished recap is not "today's five".
        onBackToToday: () {
          final app = widget.app;
          if (app.todayCompleted && app.todaysDeck.isNotEmpty) {
            openDeckViewer(context, app, app.todaysDeck, "Today's five");
          } else {
            setState(() => _tab = 0);
          }
        },
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
        bottomNavigationBar: _AstutoTabBar(
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
      ),
    );
  }
}

/// The tab bar, floating.
///
/// It used to be a full-width slab pinned to the bottom edge with a hairline
/// over it, and two rows of content — icon above label — which made it the
/// thickest thing on the screen after the card. A detached pill reads as
/// something laid on top of the app rather than part of its frame, and
/// putting the label beside the icon rather than under it takes a row out.
///
/// The Scaffold still reserves the height rather than letting content run
/// underneath: a bar that floats over a scrolling list has to be paid for in
/// bottom padding on every screen, and getting that wrong hides the last row
/// of something.
class _AstutoTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _AstutoTabBar({required this.index, required this.onChanged});

  static const _tabs = [
    (icon: Icons.wb_sunny_rounded, label: 'Today'),
    (icon: Icons.bookmark_rounded, label: 'Saved'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        4,
        18,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: context.p.surfaceRaised,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: context.p.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: context.p.isDark ? 0.5 : 0.1,
              ),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final selected = i == index;
            final tab = _tabs[i];
            final tint = selected ? AppColors.limeInk : context.p.inkFaint;

            return Expanded(
              child: Semantics(
                key: ValueKey('tab-${tab.label}'),
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
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: selected ? 14 : 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.lime : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tab.icon, size: 19, color: tint),
                          // The label has to be able to take less than it
                          // asks for: a third of the bar is not much, and it
                          // is briefly narrower still while the pill grows.
                          //
                          // The label belongs to the tab you are on. Three of
                          // them side by side is a legend nobody reads.
                          Flexible(
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              child: selected
                                  ? Padding(
                                      padding: const EdgeInsets.only(left: 7),
                                      child: Text(
                                        tab.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.body(
                                          size: 13,
                                          weight: FontWeight.w700,
                                          color: tint,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
