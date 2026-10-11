import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../analytics.dart';
import 'session.dart';

/// Which screen the reader is on, how long they stay on it, how far down
/// they scroll and how often they touch it, said once, when they leave.
///
/// A screen is named where it is built, by wrapping it in a [ScreenView],
/// and never taken from the route. The app's three tabs and every step of
/// its first run live on one route, so a route observer reporting names
/// would see "/" over and over and call it a session; and the pushed screens
/// carry no names at all. Naming the screen itself means a screen reachable
/// from two places is one name, and one that gains a third way in is not
/// quietly missed.
///
/// The route is still watched ([ScreenObserver]), for the one thing a
/// screen cannot know about itself: whether something has been pushed over
/// it. That is how a visit is told apart from a stay — see [Screens].
class ScreenView extends StatefulWidget {
  final String name;
  final Widget child;

  /// False while this screen is built but is not the one in front: a tab
  /// the reader is not on, kept alive beside the one they are.
  final bool showing;

  const ScreenView({
    super.key,
    required this.name,
    required this.child,
    this.showing = true,
  });

  @override
  State<ScreenView> createState() => _ScreenViewState();
}

/// What a screen's own widgets may ask of it: whether the reader is looking
/// at it now, and which stay on it this is.
///
/// The deck uses it to stop a card's clocks when its screen goes out of
/// sight, and Explore to know what was on screen rather than merely built:
/// the tab beside the one in front is built before it is reached.
class ScreenPresence extends ChangeNotifier {
  ScreenPresence._();

  bool _showing = false;
  bool _visiting = false;
  int _visit = 0;
  String? _left;

  /// True while this screen is the one in front of the reader.
  bool get showing => _showing;

  /// True from the reader's arrival to their leaving, including the time a
  /// screen pushed over this one keeps it covered.
  bool get visiting => _visiting;

  /// Counts the stays, so a listener can tell a new one from a return.
  int get visit => _visit;

  /// Why it last stopped showing: `push` (covered by a pushed screen),
  /// `background`, `back` (its own route closed), `switch` (another screen
  /// took its place on the same route: a tab, a step), or `gone`.
  String? get left => _left;

  void _set({required bool showing, required bool visiting, String? left}) {
    final bool fresh = visiting && !_visiting;
    if (showing == _showing &&
        visiting == _visiting &&
        !fresh &&
        (left == null || left == _left)) {
      return;
    }
    _showing = showing;
    _visiting = visiting;
    if (fresh) _visit++;
    if (left != null) _left = left;
    notifyListeners();
  }

  /// The presence of the screen [context] is in, or null outside of one —
  /// a widget under test, pumped on its own.
  static ScreenPresence? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ScreenScope>()?.presence;
}

class _ScreenScope extends InheritedWidget {
  const _ScreenScope({required this.presence, required super.child});

  final ScreenPresence presence;

  @override
  bool updateShouldNotify(_ScreenScope old) => old.presence != presence;
}

/// Watches the navigator for the one thing a screen cannot see from inside:
/// which full-screen route is on top. Sheets and dialogs are not screens and
/// cover nothing: the screen under them is still the one being used.
///
/// Never reports a name, and never sends anything.
class ScreenObserver extends NavigatorObserver {
  final List<Route<dynamic>> _pages = [];

  /// The full-screen route on top, or null before there is one.
  Route<dynamic>? get topPage {
    for (int i = _pages.length - 1; i >= 0; i--) {
      if (_pages[i].isActive) return _pages[i];
    }
    return null;
  }

  /// Whether [route] is one this observer has seen pushed.
  bool holds(Route<dynamic> route) => _pages.contains(route);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _pages.add(route);
    Screens.instance._schedule();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pages.remove(route);
    Screens.instance._schedule();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pages.remove(route);
    Screens.instance._schedule();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final int at = oldRoute == null ? -1 : _pages.indexOf(oldRoute);
    if (at >= 0) _pages.removeAt(at);
    if (newRoute is PageRoute) {
      _pages.insert(at >= 0 ? at : _pages.length, newRoute);
    }
    Screens.instance._schedule();
  }
}

/// One stay on one screen.
class _Visit {
  _Visit(this.name, this.from, this.seat);

  final String name;
  final String from;
  final _ScreenViewState seat;

  /// Runs while the screen is in front: a screen pushed over it, or the
  /// app in the background, stops it.
  final Stopwatch on = Stopwatch();
  int taps = 0;
  int scrolls = 0;

  /// How far down its list the reader saw, 0 to 100, or null for a screen
  /// that does not scroll.
  double? seen;

  /// The screens opened over this one during the stay.
  int opened = 0;

  /// The screen that covered it last, which is where it was left for if it
  /// never comes back to the front.
  String? coveredBy;
}

/// Decides which screen is in front, and turns the reader's movements
/// between screens into visits.
///
/// A visit begins when the reader arrives on a screen: a tab, a pushed
/// screen, a step of the first run, the app opening or coming back from the
/// background. It ends when they leave it: for another tab or step, back
/// to the screen under it, or out of the app. A screen pushed over it pauses
/// it rather than ending it — its clock and its taps stop, and the visit
/// carries on when the reader comes back — so a stay in Explore with five
/// cards opened from it is one visit to Explore and five to the viewer, each
/// with its own time, rather than eleven slices of Explore.
///
/// Each visit sends PostHog's `$screen` when it begins and one 'screen left'
/// when it ends. The visits are settled once a frame is done, when every
/// screen of it has been built and every route moved: a tab tapped, or a
/// screen pushed, is one change, whatever order its pieces arrive in.
class Screens {
  Screens._();

  /// One for the app, as there is one reader in front of one screen.
  static final Screens instance = Screens._();

  final List<_ScreenViewState> _seats = [];
  _ScreenViewState? _front;

  /// Visits paused under a pushed screen, the oldest first.
  final List<_Visit> _under = [];

  /// Where the next visit comes from.
  String _last = 'launch';
  bool _foreground = true;
  int _order = 0;
  bool _scheduled = false;
  int _begun = 0;

  /// The screen in front, by name, or null when none is.
  String? get current => _front?._visit?.name;

  /// How many visits have begun since the app started: one while the
  /// reader is still on the screen it opened on.
  int get begun => _begun;

  /// Forgets everything: the screens, the stays and the counts. For the
  /// tests, which build and tear down whole apps one after another.
  @visibleForTesting
  void resetForTest() {
    _seats.clear();
    _front = null;
    _under.clear();
    _last = 'launch';
    _foreground = true;
    _order = 0;
    _scheduled = false;
    _begun = 0;
  }

  /// The app left the screen. Every visit ends here, whatever is in front,
  /// and synchronously: there is no next frame to wait for, and the session
  /// that is said next counts them.
  void background() {
    if (!_foreground) return;
    _foreground = false;
    _settleNow();
  }

  /// The app is back. What is in front starts a visit of its own, said as
  /// coming from the background, once the first frame is drawn.
  void foreground() {
    if (_foreground) return;
    _foreground = true;
    _schedule();
  }

  void _attach(_ScreenViewState seat) {
    _seats.add(seat);
    _schedule();
  }

  void _detach(_ScreenViewState seat) {
    _seats.remove(seat);
    // The last screen taken down is the whole app going: its visit ends
    // now, not in a frame that may already belong to whatever comes next.
    if (_seats.isEmpty) {
      _settleNow();
    } else {
      _schedule();
    }
  }

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) => _settleNow())
      ..ensureVisualUpdate();
  }

  void _settleNow() {
    _scheduled = false;
    if (!_foreground) {
      _leaveAll();
      return;
    }

    // Visits paused under a screen whose route has since gone — closed
    // from above, all at once — were left for whatever covered them.
    for (final _Visit visit in List.of(_under)) {
      if (!visit.seat._stillThere) {
        _under.remove(visit);
        _send(visit, leftTo: visit.coveredBy);
      }
    }

    _ScreenViewState? next;
    for (final _ScreenViewState seat in _seats) {
      if (!seat._eligible) {
        seat._since = 0;
        continue;
      }
      if (seat._since == 0) seat._since = ++_order;
      if (next == null || seat._since > next._since) next = seat;
    }

    final _ScreenViewState? was = _front;
    final _Visit? had = was?._visit;
    final bool renamed =
        was != null &&
        identical(next, was) &&
        had != null &&
        had.name != was.widget.name;
    if (identical(next, was) && !renamed && (next == null || had != null)) {
      return;
    }

    // The screen that was in front: covered, or left.
    if (was != null && had != null && (!identical(next, was) || renamed)) {
      if (!renamed && was._covered) {
        had.on.stop();
        had.coveredBy = next?.widget.name;
        had.opened++;
        _under.add(had);
        was._tell(showing: false, visiting: true, left: 'push');
      } else {
        was._visit = null;
        was._tell(
          showing: false,
          visiting: false,
          left: renamed ? 'switch' : was._why,
        );
        _send(had, leftTo: next?.widget.name);
      }
      _last = had.name;
    }

    _front = next;
    if (next == null) return;
    final _Visit? paused = next._visit;
    if (paused != null && _under.contains(paused)) {
      // Back from a screen pushed over it: the same visit carries on, and
      // anything still paused above it was closed on the way down.
      final int at = _under.indexOf(paused);
      for (final _Visit above in _under.sublist(at + 1).reversed) {
        above.seat._tell(showing: false, visiting: false, left: 'back');
        _send(above, leftTo: above.coveredBy);
      }
      _under.removeRange(at, _under.length);
      paused.on.start();
      next._tell(showing: true, visiting: true);
      Analytics.currentScreen = paused.name;
    } else {
      _begin(next);
    }
    _last = next.widget.name;
  }

  void _begin(_ScreenViewState seat) {
    final String name = seat.widget.name;
    final _Visit visit = _Visit(name, _last, seat)
      ..seen = seat._seen
      ..on.start();
    seat._visit = visit;
    _begun++;
    Session.instance.screenBegun(name);
    Analytics.currentScreen = name;
    Analytics.screen(name);
    seat._tell(showing: true, visiting: true);
  }

  /// Ends every visit, the one in front and those paused under it: the one
  /// in front was left for the background, and each paused one for the
  /// screen pushed over it.
  void _leaveAll() {
    final _Visit? top = _front?._visit;
    final List<_Visit> stack = [
      ..._under,
      if (top != null && !_under.contains(top)) top,
    ];
    for (int i = stack.length - 1; i >= 0; i--) {
      final _Visit visit = stack[i];
      final bool covered = _under.contains(visit);
      visit.seat._tell(showing: false, visiting: false, left: 'background');
      _send(
        visit,
        leftTo: covered
            ? (visit.coveredBy ??
                  (i + 1 < stack.length ? stack[i + 1].name : 'background'))
            : 'background',
      );
    }
    _under.clear();
    _front = null;
    for (final _ScreenViewState seat in _seats) {
      seat._since = 0;
    }
    _last = 'background';
  }

  void _send(_Visit visit, {String? leftTo}) {
    visit.on.stop();
    if (visit.seat._visit == visit) visit.seat._visit = null;
    Analytics.capture('screen left', {
      'screen': visit.name,
      'ms_on_screen': visit.on.elapsedMilliseconds,
      'max_scroll_pct': visit.seen?.round(),
      'scrolls': visit.scrolls,
      'taps': visit.taps,
      'screens_opened': visit.opened,
      'from': visit.from,
      'left_to': leftTo,
    });
  }
}

class _ScreenViewState extends State<ScreenView> {
  final ScreenPresence presence = ScreenPresence._();

  ModalRoute<Object?>? _route;
  ScreenObserver? _observer;

  /// When this screen last became one that could be in front: the newest
  /// such screen is the one that is.
  int _since = 0;

  /// The visit this screen holds — in front, or paused under another.
  _Visit? _visit;

  /// How far down its list the reader can see now, kept while the screen is
  /// not in front too, so a tab returned to starts from where it was left.
  double? _seen;

  /// Where each finger on the glass went down, to tell a tap from a drag.
  final Map<int, Offset> _downs = {};

  /// Whether the drag going on now has been counted as a scroll yet.
  bool _counted = false;

  @override
  void initState() {
    super.initState();
    Screens.instance._attach(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A dependency on the route's status: told again whenever it stops or
    // starts being the one on top.
    _route = ModalRoute.of(context);
    _observer = Navigator.maybeOf(context)?.widget.observers
        .whereType<ScreenObserver>()
        .firstOrNull;
    Screens.instance._schedule();
  }

  @override
  void didUpdateWidget(covariant ScreenView old) {
    super.didUpdateWidget(old);
    if (old.showing != widget.showing || old.name != widget.name) {
      Screens.instance._schedule();
    }
  }

  @override
  void dispose() {
    Screens.instance._detach(this);
    presence.dispose();
    super.dispose();
  }

  /// Whether this screen's route is the full-screen one on top.
  bool get _onTop {
    final ModalRoute<Object?>? route = _route;
    if (route == null) return true;
    final ScreenObserver? watch = _observer;
    if (watch != null && watch.holds(route)) {
      return identical(watch.topPage, route);
    }
    return route.isCurrent;
  }

  /// Whether it could be the screen in front.
  bool get _eligible =>
      mounted && widget.showing && Screens.instance._foreground && _onTop;

  /// Whether its route is still on the navigator.
  bool get _stillThere => mounted && (_route?.isActive ?? true);

  /// Whether it is out of sight only because a screen was pushed over it.
  bool get _covered => _stillThere && widget.showing && !_onTop;

  /// Why it stopped being in front, when it was not covered.
  String get _why {
    if (!mounted) return 'gone';
    if (!(_route?.isActive ?? true)) return 'back';
    return 'switch';
  }

  bool get _inFront => identical(Screens.instance._front, this);

  /// Tells this screen's own widgets, while there are any to tell: a screen
  /// already taken down has nobody left listening.
  void _tell({required bool showing, required bool visiting, String? left}) {
    if (!mounted) return;
    presence._set(showing: showing, visiting: visiting, left: left);
  }

  void _down(PointerDownEvent event) => _downs[event.pointer] = event.position;

  void _up(PointerUpEvent event) {
    final Offset? at = _downs.remove(event.pointer);
    final _Visit? visit = _visit;
    if (at == null || visit == null || !_inFront) return;
    // A tap is a touch that came up where it went down. The end of a
    // scroll is a scroll, and counted as one.
    if ((event.position - at).distance <= kTouchSlop) visit.taps++;
  }

  bool _scrolled(ScrollNotification note) {
    final _Visit? visit = _visit;
    if (note is ScrollStartNotification) {
      _counted = false;
    } else if (movedByFinger(note) && !_counted) {
      // One scroll per drag that moved something. A drag that never moved
      // is a tap on a list, which is how Flutter reports one.
      _counted = true;
      if (visit != null && _inFront) visit.scrolls++;
    }
    if (note.depth == 0) _measure(note.metrics);
    return false;
  }

  bool _resized(ScrollMetricsNotification note) {
    if (note.depth == 0) _measure(note.metrics);
    return false;
  }

  /// How far down the screen's own list the reader can see, as the share of
  /// it that has passed the bottom of the screen: a list read to its foot is
  /// 100, one never moved is however much fitted. Sideways rows, and lists
  /// that fit without scrolling, do not count.
  void _measure(ScrollMetrics metrics) {
    final double? seen = seenOf(metrics);
    if (seen == null) return;
    _seen = seen;
    final _Visit? visit = _visit;
    if (visit != null && _inFront && seen > (visit.seen ?? -1)) {
      visit.seen = seen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ScreenScope(
      presence: presence,
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _resized,
        child: NotificationListener<ScrollNotification>(
          onNotification: _scrolled,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _down,
            onPointerUp: _up,
            onPointerCancel: (event) => _downs.remove(event.pointer),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Whether [note] is a finger moving a list: an update with a drag behind
/// it that actually moved. A tap on a list with nothing else to take it is
/// reported as a drag that never moved, and is not one.
bool movedByFinger(ScrollNotification note) =>
    note is ScrollUpdateNotification &&
    note.dragDetails != null &&
    (note.scrollDelta ?? 0) != 0;

/// How much of a vertical list has been in sight, 0 to 100: the share of
/// it above the bottom of its window. Null for a list that fits, or one
/// that runs sideways.
double? seenOf(ScrollMetrics metrics) {
  if (metrics.axis != Axis.vertical || !metrics.hasContentDimensions) {
    return null;
  }
  final double before = metrics.extentBefore;
  final double inside = metrics.extentInside;
  final double after = metrics.extentAfter;
  if (before + after < 1) return null;
  return ((before + inside) / (before + inside + after) * 100).clamp(0, 100);
}
