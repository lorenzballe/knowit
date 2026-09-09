import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cloud.dart';
import 'debug_flags.dart';
import 'screens/comeback_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/know_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/explore_screen.dart';
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
      title: 'Astut',
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

/// Astut is a phone app served from a web page, so on anything wider than a
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
enum _Stage { intro, subjects, know, comeback, shell }

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
      // Coming back to the foreground re-arms tomorrow's nudge with today's
      // streak in it, and quietly — no prompt ever comes from here.
      onResume: _app.refreshDailyReminder,
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
            if (mounted) _go(_Stage.know);
          },
        );

      // One more question, and a way past it: what the reader already
      // knows of what they just asked for. The cards start either way.
      case _Stage.know:
        return KnowScreen(
          app: _app,
          onDone: (levels) async {
            await _app.setTopicLevels(levels);
            await _finishOnboarding();
          },
          onSkip: _finishOnboarding,
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
                  'Astut',
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

class _AstutoShellState extends State<AstutoShell>
    with SingleTickerProviderStateMixin {
  /// The tab the app is on. Only ever changed once a move has settled:
  /// setting it mid-gesture would rebuild the shell — and swap the page
  /// physics — while a finger is still on the glass.
  int _tab = 0;

  /// The three tabs as pages, so a finger can slide between them.
  final PageController _pages = PageController();

  /// How lit each tab is, 0 to 1, rebuilt every frame of a move.
  ///
  /// The bar used to follow the page index, which changes once, in the
  /// middle of a move: two tabs apart that meant two 240ms animations
  /// starting one on top of the other, which is what read as a stutter.
  /// This is a number per tab instead, and nothing else on the screen
  /// rebuilds while it changes.
  final ValueNotifier<List<double>> _lit = ValueNotifier(const [1, 0, 0]);

  /// Carries the bar across a jump the page does not animate.
  late final AnimationController _jump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  int _jumpFrom = 0;
  int _jumpTo = 0;

  /// True while a card is under the finger.
  bool _cardMoving = false;

  /// The Explore tab keeps its state across tab changes, which is right
  /// until the finished day sends the reader to "today's best" and finds
  /// the tab still on last week's month filter.
  final GlobalKey<ExploreScreenState> _explore = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pages.addListener(_followPage);
    _jump.addListener(_followJump);
  }

  @override
  void dispose() {
    _pages.removeListener(_followPage);
    _pages.dispose();
    _jump.dispose();
    _lit.dispose();
    super.dispose();
  }

  /// The bar follows the page while the page is moving under a finger, or
  /// animating to the tab beside it.
  void _followPage() {
    if (_jump.isAnimating || !_pages.hasClients) return;
    final double? page = _pages.page;
    if (page == null) return;
    final int lo = page.floor().clamp(0, _AstutoTabBar.tabs.length - 1);
    final int hi = page.ceil().clamp(0, _AstutoTabBar.tabs.length - 1);
    final double t = page - lo;
    _lit.value = [
      for (int i = 0; i < _AstutoTabBar.tabs.length; i++)
        i == lo && i == hi
            ? 1
            : i == lo
            ? 1 - t
            : i == hi
            ? t
            : 0,
    ];
  }

  void _followJump() {
    final double t = Curves.easeOutCubic.transform(_jump.value);
    _lit.value = [
      for (int i = 0; i < _AstutoTabBar.tabs.length; i++)
        i == _jumpFrom
            ? 1 - t
            : i == _jumpTo
            ? t
            : 0,
    ];
  }

  /// Goes to a tab from the bar.
  ///
  /// The tab beside this one slides, because there is nothing in between to
  /// drag across. Two tabs apart, the page cuts instead: a slide would haul
  /// the middle screen over the glass on its way past, which is a screen
  /// nobody asked for. The bar carries that move on its own, and it moves
  /// from the tab you left to the tab you asked for without lighting the
  /// one between them.
  void _goTo(int tab) {
    if (tab == _tab || !mounted) return;
    HapticFeedback.selectionClick();
    final int from = _tab;
    setState(() => _tab = tab);
    if ((tab - from).abs() == 1) {
      _jump.stop();
      _pages.animateToPage(
        tab,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _jumpFrom = from;
    _jumpTo = tab;
    _jump
      ..reset()
      ..forward();
    _pages.jumpToPage(tab);
  }

  /// A move is over. This is the only place the tab is written down, so a
  /// drag that crosses into Today is not cut short by the page locking
  /// under the finger that is still dragging it.
  bool _settle(ScrollNotification note) {
    if (note is! ScrollEndNotification || !_pages.hasClients) return false;
    final int page = (_pages.page ?? _tab.toDouble()).round();
    if (page != _tab) setState(() => _tab = page);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      TodayScreen(
        app: widget.app,
        onCardMotion: (moving) {
          if (moving != _cardMoving) setState(() => _cardMoving = moving);
        },
        onExplore: () {
          _explore.currentState?.showBest();
          _goTo(1);
        },
      ),
      ExploreScreen(key: _explore, app: widget.app),
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
        // Still, and black. The drifting light belongs to the onboarding,
        // which is a pitch and can afford atmosphere; this is the thing
        // itself, and a tool reads as well made when it holds still. The
        // cards are the only colour, which is the whole idea.
        backgroundColor: context.p.surface,
        // The body runs the whole height, under the tab bar, and each
        // screen puts the bar's height back as padding — so nothing moves,
        // and a card thrown downward is not sliced off at the top of a bar
        // that has already faded out of its way. A card is the thing on
        // this screen: nothing should be able to cover it.
        extendBody: true,
        body: SafeArea(
          bottom: false,
          // A browser has no status bar to sit under, so the page would
          // otherwise start hard against the top edge. On a phone the real
          // inset is larger and this does nothing.
          minimum: const EdgeInsets.only(top: 12),
          // The tabs slide under the finger, the way they do in every app
          // with three of them side by side, and the bar is the other way
          // to the same place.
          //
          // Except while the day is running. Today is then a screen with
          // one thing on it, and every sideways drag belongs to the card
          // being thrown — a page that slid instead, depending on where the
          // finger landed, was the worst of both. The five are a screen you
          // finish, not one you slide off. The bar still goes anywhere; it
          // is the sliding that stops.
          //
          // No glow at the ends: there is nothing past the last tab, and
          // the Android indicator would say so in a colour of its own.
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(overscroll: false),
            child: NotificationListener<ScrollNotification>(
              onNotification: _settle,
              child: PageView(
                controller: _pages,
                physics: _tab == 0 && !widget.app.todayCompleted
                    ? const NeverScrollableScrollPhysics()
                    : null,
                // The next tab is built before it is reached, so the first
                // swipe does not pay for a screen being laid out
                // mid-gesture.
                allowImplicitScrolling: true,
                children: [
                  // Clipped to its own page. A screen is free to paint past
                  // its edges — the shelf lets a card's glow bleed, a card
                  // being thrown goes under the tab bar — and without this
                  // the overflow lands on the tab beside it and rides there
                  // until the next repaint.
                  //
                  // The padding is the height the tab bar would have taken
                  // if it still reserved room, read back from the media
                  // query the Scaffold hands a body it has extended. The
                  // page is taller than the screen it draws; the screens
                  // are exactly where they were.
                  for (final screen in screens)
                    ClipRect(
                      child: _KeepAlive(
                        child: Builder(
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.paddingOf(context).bottom,
                            ),
                            child: screen,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // The bar steps aside while a card is being thrown. Two rows of
        // controls along the bottom edge was one too many, and a card thrown
        // downward should not be thrown at a row of buttons.
        bottomNavigationBar: _AstutoTabBar(
          hidden: _cardMoving,
          lit: _lit,
          onChanged: _goTo,
        ),
      ),
    );
  }
}

/// Keeps a tab alive while another is on screen.
///
/// The tabs used to sit in an IndexedStack, which builds all three and
/// keeps them. A page view lets go of a page once it has slid out of
/// reach, and a tab that forgets its search, its range or how far down it
/// was scrolled every time the reader looks away is a worse tab than the
/// one it replaced.
class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
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
  /// How lit each tab is, 0 to 1. A number rather than a selected index, so
  /// the bar can follow a finger between two tabs and cross straight from
  /// one end to the other without the middle one lighting up on the way.
  final ValueListenable<List<double>> lit;
  final ValueChanged<int> onChanged;
  final bool hidden;
  const _AstutoTabBar({
    required this.lit,
    required this.onChanged,
    this.hidden = false,
  });

  static const tabs = [
    (icon: Icons.wb_sunny_rounded, label: 'Today'),
    // A compass, not a bookmark and not a lens: the middle tab stopped being
    // the reader's own shelf and became the one place with cards nobody
    // dealt them. Saved moved into the profile, where a list of your own
    // things belongs, and the tab is named for the shelf rather than for
    // the search field at the top of it.
    //
    // Drawn in outline, like the lens it replaced. Filled, it is a solid
    // disc — the heaviest thing on the bar by some way, and enough on its
    // own to make a bar whose measurements never changed look fatter.
    (icon: Icons.explore_outlined, label: 'Explore'),
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
        // Only the row of tabs is rebuilt as a move runs. The bar itself —
        // its ground, its ring, its shadow — is built once and held.
        child: ValueListenableBuilder<List<double>>(
          valueListenable: lit,
          builder: (context, lit, _) => Row(
            children: List.generate(tabs.length, (i) {
              final double on = lit[i].clamp(0.0, 1.0);
              final tab = tabs[i];
              final Color tint = Color.lerp(
                context.p.inkFaint,
                context.p.onInverse,
                on,
              )!;

              return Expanded(
                child: Semantics(
                  key: ValueKey('tab-${tab.label}'),
                  button: true,
                  selected: on > 0.5,
                  label: tab.label,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10 + 4 * on,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.p.inverse.withValues(alpha: on),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tab.icon, size: 19, color: tint),
                            // The label belongs to the tab you are on, and
                            // unfurls as you arrive rather than appearing
                            // once you have. Three of them side by side is
                            // a legend nobody reads.
                            //
                            // It has to be able to take less than it asks
                            // for: a third of the bar is not much, and it
                            // is narrower still while the pill grows.
                            Flexible(
                              child: ClipRect(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: on,
                                  // Width only. Left to size itself, an
                                  // Align takes all the height it is
                                  // offered, which stretched the pill from
                                  // the height of its own contents to the
                                  // height of the whole bar — a pill with
                                  // its ends against both edges, which is
                                  // what a bar looks like when it has got
                                  // fat without a single number changing.
                                  heightFactor: 1,
                                  // The fade is in the colour rather than
                                  // in an Opacity: three of those is three
                                  // saved layers on every frame of a move,
                                  // for text that is only ever one colour.
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 7),
                                    child: Text(
                                      tab.label,
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.body(
                                        size: 13,
                                        weight: FontWeight.w700,
                                        color: tint.withValues(alpha: on),
                                      ),
                                    ),
                                  ),
                                ),
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
      ),
    );
  }
}
