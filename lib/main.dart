import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cloud.dart';
import 'data/topics.dart';
import 'debug_flags.dart';
import 'screens/comeback_screen.dart';
import 'screens/deck_viewer_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/mix_screen.dart';
import 'screens/today_screen.dart';
import 'state/app_state.dart';
import 'sync/account.dart';
import 'sync/push.dart';
import 'sync/subscription.dart';
import 'theme.dart';
import 'widgets/ambient.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Never blocks the app: see Cloud.start.
  await Cloud.start();
  runApp(const AstutoApp());
}

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
/// The onboarding is two screens and no more: the intro that says what the
/// app is, then the subject run that fills the deck. Everything else waits
/// until there is something worth signing in to keep.
enum _Stage { intro, subjects, comeback, shell }

class AstutoRoot extends StatefulWidget {
  final AppState app;
  const AstutoRoot({super.key, required this.app});

  @override
  State<AstutoRoot> createState() => _AstutoRootState();
}

class _AstutoRootState extends State<AstutoRoot> {
  AppState get _app => widget.app;

  /// One account for the whole app. It works signed out — this only decides
  /// whether the phone's work also lives somewhere it survives the phone.
  final Account _account = Account();

  /// Backing up is best done at the last moment anything is certain to run,
  /// which on a phone is the moment the app leaves the screen.
  AppLifecycleListener? _lifecycle;

  final Push _push = Push();
  bool _askingForPush = false;
  _Stage _stage = _Stage.intro;
  bool _stageResolved = false;

  @override
  void initState() {
    super.initState();
    _account.watch(_app);
    _lifecycle = AppLifecycleListener(
      onPause: _account.flush,
      onDetach: _account.flush,
    );
    _refreshPushToken();
    _startAccountAndStore();
    _app.addListener(_onAppStateChanged);
    if (_app.ready) _onAppStateChanged();
  }

  /// The account comes first: the store is told who the reader is, so the
  /// entitlement follows them to a new phone rather than staying on this one.
  Future<void> _startAccountAndStore() async {
    await _account.ensureAnonymous(_app);
    if (!mounted) return;
    final Subscription store = Subscription.instance
      ..addListener(_onEntitlementChanged);
    await store.start(accountId: _account.uid);
  }

  void _onEntitlementChanged() {
    final Subscription store = Subscription.instance;
    // Until the store has answered, the app should not decide the reader has
    // nothing: a launch with no network would drop them off their own plan.
    if (store.ready) _app.applyEntitlement(store.isPlus);
  }

  /// A token the system reissued is one the server can no longer reach, so
  /// it is picked up again on every launch — without asking anything.
  Future<void> _refreshPushToken() async {
    final String? token = await _push.refresh();
    if (token != null && mounted) await _app.rememberPushToken(token);
  }

  /// The one prompt iOS allows, spent at the only moment it is worth
  /// something: a day is finished, so there is a streak to protect and the
  /// reader knows what they would be agreeing to.
  Future<void> _askForPush() async {
    if (_askingForPush) return;
    _askingForPush = true;
    final String? token = await _push.ask();
    if (!mounted) return;
    await _app.notedPushAnswer(token: token);
    _askingForPush = false;
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    setState(() {
      // The opening stage is decided once, the first time state is ready:
      // after that the flow drives itself and must not be reset under it.
      if (_app.ready && !_stageResolved) {
        _stageResolved = true;
        if (!_app.onboarded) {
          _stage = _Stage.intro;
        } else if (_app.shouldShowComeback) {
          _stage = _Stage.comeback;
        } else {
          _stage = _Stage.shell;
        }
      }
    });
    if (_stage == _Stage.shell && _app.shouldAskForPush) _askForPush();
  }

  @override
  void dispose() {
    _app.removeListener(_onAppStateChanged);
    _lifecycle?.dispose();
    Subscription.instance.removeListener(_onEntitlementChanged);
    _account.dispose();
    super.dispose();
  }

  void _go(_Stage stage) => setState(() => _stage = stage);

  /// Returns whether the intro should move on. Only backing out of the
  /// provider's own sheet keeps the reader where they are.
  Future<bool> _signIn(
    String label,
    Future<SignInOutcome> Function(AppState) run,
  ) async {
    final outcome = await run(_app);
    if (!mounted) return false;
    switch (outcome) {
      case SignInOutcome.signedIn:
        // The account id may have changed, and the entitlement belongs to the
        // reader rather than to the phone.
        await Subscription.instance.switchTo(_account.uid);
        return true;
      // Firebase is not running. This used to move on in silence, which made
      // a broken build look exactly like a successful sign-in: press, no
      // sheet, next screen. Say it instead.
      case SignInOutcome.unavailable:
        _say('Sign-in is unavailable: ${_account.lastError ?? "unknown"}');
        return true;
      case SignInOutcome.cancelled:
        return false;
      case SignInOutcome.failed:
        // While the debug tools are on, show what actually went wrong. A
        // polite sentence is the right thing for a reader and the wrong
        // thing for the person trying to fix it.
        _say(
          kDebugTools && _account.lastError != null
              ? '$label sign-in failed — ${_account.lastError}'
              : 'Could not sign in with $label. You can carry on without an '
                    'account.',
        );
        return false;
    }
  }

  void _say(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

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
      case _Stage.intro:
        return IntroScreen(
          onContinue: () => _go(_Stage.subjects),
          onApple: () => _signIn('Apple', _account.signInWithApple),
          onGoogle: () => _signIn('Google', _account.signInWithGoogle),
          onNotConnected: (provider) => _say(
            '$provider sign-in is not connected yet. Your cards are '
            'kept on this device.',
          ),
        );

      case _Stage.subjects:
        return MixScreen(
          onDone: (weights) async {
            await _app.setTopicMix(weights);
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
          account: _account,
          onSignedOut: () => setState(() {
            _stageResolved = true;
            _stage = _Stage.intro;
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
      body: Stack(
        children: [
          // The colour arrives before anything else does. A launch screen is
          // the one moment the app is only a promise, and a plain background
          // spends it saying nothing.
          Positioned.fill(child: AmbientBlooms(colors: kSceneBlooms.first)),
          const Positioned.fill(child: Bokeh()),
          Center(
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
        ],
      ),
    );
  }
}

class AstutoShell extends StatefulWidget {
  final AppState app;
  final Account account;
  final VoidCallback onSignedOut;

  const AstutoShell({
    super.key,
    required this.app,
    required this.account,
    required this.onSignedOut,
  });

  @override
  State<AstutoShell> createState() => _AstutoShellState();
}

class _AstutoShellState extends State<AstutoShell> {
  int _tab = 0;

  /// True while a card is under the finger.
  bool _cardMoving = false;

  /// True while the reader is on Today with cards still in front of them.
  bool get _cardsShowing => _tab == 0 && !widget.app.todayCompleted;

  /// Three hues off today's deck, for the light behind the app.
  ///
  /// Taken from the cards the reader actually has in hand rather than picked
  /// once and fixed, which is the whole point: nothing here is Astuto's
  /// colour, it is today's.
  List<Color> get _bloomColours {
    final List<Color> deck = widget.app.todaysDeck
        .map((pill) => pill.color)
        .toList();
    if (deck.isEmpty) return kSpectrum.take(3).toList();
    return [deck[0], deck[deck.length ~/ 2], deck[deck.length - 1]];
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      TodayScreen(
        app: widget.app,
        onCardMotion: (moving) {
          if (moving != _cardMoving) setState(() => _cardMoving = moving);
        },
      ),
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
      ProfileScreen(
        app: widget.app,
        account: widget.account,
        onSignedOut: widget.onSignedOut,
      ),
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
        body: Stack(
          children: [
            // The same light the onboarding sits in, and the same rule: the
            // colour is the day's own. Five cards, five hues, drifting
            // behind everything — so the app is never one colour, and never
            // the same colour two days running.
            //
            // Not behind the cards themselves. A card is already a field of
            // its own colour, and a second colour washing about behind it
            // fights it; the deck reads better lifted off plain black. The
            // light comes back once the day is finished and the cards are
            // gone.
            if (context.p.isDark && !_cardsShowing)
              Positioned.fill(child: AmbientBlooms(colors: _bloomColours)),
            SafeArea(
              bottom: false,
              child: IndexedStack(index: _tab, children: screens),
            ),
          ],
        ),
        // The bar steps aside while a card is being thrown. Two rows of
        // controls along the bottom edge was one too many, and a card thrown
        // downward should not be thrown at a row of buttons.
        bottomNavigationBar: _AstutoTabBar(
          hidden: _cardMoving,
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
  final bool hidden;
  const _AstutoTabBar({
    required this.index,
    required this.onChanged,
    this.hidden = false,
  });

  static const _tabs = [
    (icon: Icons.wb_sunny_rounded, label: 'Today'),
    (icon: Icons.bookmark_rounded, label: 'Saved'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    // Faded and lifted away rather than removed: taking it out of the tree
    // would change the page's height mid-gesture and shove the card.
    return AnimatedSlide(
      offset: hidden ? const Offset(0, 0.6) : Offset.zero,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: hidden ? 0 : 1,
        duration: const Duration(milliseconds: 180),
        child: IgnorePointer(ignoring: hidden, child: _bar(context)),
      ),
    );
  }

  Widget _bar(BuildContext context) {
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
            final tint = selected ? context.p.onInverse : context.p.inkFaint;

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
                        color: selected
                            ? context.p.inverse
                            : Colors.transparent,
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
