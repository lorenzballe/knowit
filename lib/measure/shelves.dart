import 'package:flutter/widgets.dart';

import '../analytics.dart';
import 'screens.dart';
import 'session.dart';

/// What Explore put in front of the reader during one stay on the tab: each
/// shelf that came on screen, for how long, how many of its cards were
/// shown and how many opened, and whether it was turned sideways — said
/// once per shelf when the reader leaves Explore, as 'explore shelf seen'.
///
/// A stay is the reader's time on the Explore tab, from arriving to going
/// to another tab or out of the app. A card opened from a shelf does not
/// end it: the shelves only wait, with their clocks stopped, until the
/// reader comes back to them, which is what lets a shelf say how many of its
/// cards were opened.
///
/// A shelf counts as on screen while at least half of it is — or, for one
/// taller than the screen, while it fills at least half of the screen —
/// and is said only once it has been on screen for a second in all: a shelf
/// flung past in a scroll was not seen in any sense worth an event.
///
/// Which cards a shelf showed is the trace's own measure (Explore's
/// `_seen`): a card is shown when its shelf builds it, which a row does
/// just before it slides into view.
class ShelfSight {
  ShelfSight();

  /// Under this, a shelf on screen was passed, not seen.
  static const int seenMs = 1000;

  /// No closer together than this while the list is moving.
  static const int _measureEveryMs = 100;

  final Stopwatch _clock = Stopwatch()..start();
  final Set<_ShelfWatchState> _watches = {};
  final Map<String, _Shelf> _shelves = {};

  /// The shelves that can be turned sideways, as their rows have said: kept
  /// across stays, since a row says it once, when it is laid out.
  final Set<String> _turnable = {};

  bool _staying = false;
  bool _looking = false;
  int _lastMeasure = -_measureEveryMs;
  bool _measureDue = false;

  /// The shelf the reader last put a finger on, and when: what a card
  /// opened a moment later was opened from.
  String? _touched;
  int _touchedAt = -1;

  /// Whether a stay is open, and whether Explore is in sight now.
  bool get staying => _staying;
  bool get looking => _looking;

  /// The reader arrived on Explore.
  void arrive() {
    if (_staying) leave();
    _staying = true;
    _looking = true;
    _shelves.clear();
    measureSoon();
  }

  /// Explore went out of sight under a pushed screen: the stay carries on,
  /// its clocks stopped.
  void cover() {
    if (!_looking) return;
    _looking = false;
    final int now = _clock.elapsedMilliseconds;
    for (final _Shelf shelf in _shelves.values) {
      shelf.hide(now);
    }
  }

  /// The reader is back on Explore from a screen pushed over it.
  void uncover() {
    if (!_staying || _looking) return;
    _looking = true;
    measureSoon();
  }

  /// The reader left Explore: one event for each shelf that was seen.
  void leave() {
    if (!_staying) return;
    cover();
    _staying = false;
    final List<_Shelf> seen =
        _shelves.values.where((s) => s.msVisible >= seenMs).toList()
          ..sort((a, b) => a.position.compareTo(b.position));
    for (final _Shelf shelf in seen) {
      Analytics.capture('explore shelf seen', {
        'shelf': shelf.name,
        'position': shelf.position,
        'ms_visible': shelf.msVisible,
        'tiles_seen': shelf.tiles.length,
        'tiles_opened': shelf.opened,
        'scrolled_sideways': shelf.turned
            ? true
            : _turnable.contains(shelf.name)
            ? false
            : null,
      });
    }
    _shelves.clear();
  }

  /// A card the shelf built, with Explore in sight.
  void tile(String shelf, String pillId) {
    if (!_looking) return;
    _shelf(shelf).tiles.add(pillId);
  }

  /// A card was opened from Explore: from the shelf touched a moment
  /// before, if one was.
  void opened() {
    Session.instance.exploreOpened();
    final String? shelf = _touched;
    final bool recent =
        shelf != null && _clock.elapsedMilliseconds - _touchedAt < 2000;
    _touched = null;
    if (!recent || !_staying) return;
    _shelf(shelf).opened++;
  }

  /// A card opened by something other than a finger on a shelf — a tap on
  /// a home-screen widget — is not the last shelf touched's.
  void forgetTouch() => _touched = null;

  _Shelf _shelf(String name) => _shelves.putIfAbsent(name, () => _Shelf(name));

  /// The shelves list moved: measured again, at most every tenth of a
  /// second while it moves, and once more when it stops.
  bool scrolled(ScrollNotification note) {
    if (note.depth != 0 || note.metrics.axis != Axis.vertical) return false;
    final int now = _clock.elapsedMilliseconds;
    if (note is ScrollEndNotification ||
        now - _lastMeasure >= _measureEveryMs) {
      measure();
    }
    return false;
  }

  /// Measures again after the frame: the shelves have moved or changed.
  void measureSoon() {
    if (_measureDue || !_looking) return;
    _measureDue = true;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        _measureDue = false;
        measure();
      })
      ..ensureVisualUpdate();
  }

  /// Which shelves are on screen now, against the list's own window.
  void measure() {
    final int now = _clock.elapsedMilliseconds;
    _lastMeasure = now;
    if (!_looking) return;
    for (final _ShelfWatchState watch in _watches) {
      final bool on = watch.onScreen();
      final _Shelf? known = _shelves[watch.widget.shelf];
      if (!on && known == null) continue;
      final _Shelf shelf = known ?? _shelf(watch.widget.shelf);
      shelf.position = watch.widget.position;
      if (on) {
        shelf.show(now);
      } else {
        shelf.hide(now);
      }
    }
  }
}

class _Shelf {
  _Shelf(this.name);

  final String name;
  int position = 0;
  final Set<String> tiles = {};
  int opened = 0;
  int msVisible = 0;
  int? _since;

  /// Whether the reader turned the shelf sideways in this stay.
  bool turned = false;

  void show(int now) => _since ??= now;

  void hide(int now) {
    final int? since = _since;
    if (since == null) return;
    msVisible += now - since;
    _since = null;
  }
}

/// One shelf of Explore, watched: where it sits, whether it is on screen,
/// whether it scrolls sideways, and which shelf a finger is on.
class ShelfWatch extends StatefulWidget {
  const ShelfWatch({
    super.key,
    required this.sight,
    required this.shelf,
    required this.position,
    required this.child,
  });

  final ShelfSight sight;

  /// The shelf's name, the same one its cards are noted under.
  final String shelf;

  /// Its place on the page, 1 for the first shelf.
  final int position;
  final Widget child;

  @override
  State<ShelfWatch> createState() => _ShelfWatchState();
}

class _ShelfWatchState extends State<ShelfWatch> {
  ScrollableState? _list;

  @override
  void initState() {
    super.initState();
    widget.sight._watches.add(this);
    widget.sight.measureSoon();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _list = Scrollable.maybeOf(context);
  }

  @override
  void didUpdateWidget(covariant ShelfWatch old) {
    super.didUpdateWidget(old);
    if (old.sight != widget.sight) {
      old.sight._watches.remove(this);
      widget.sight._watches.add(this);
    }
  }

  @override
  void dispose() {
    // Gone from the list's built range: off screen, whatever it was.
    final ShelfSight sight = widget.sight;
    sight._watches.remove(this);
    sight._shelves[widget.shelf]?.hide(sight._clock.elapsedMilliseconds);
    super.dispose();
  }

  /// Whether at least half of this shelf is inside the list's window, or,
  /// for a shelf taller than the window, half the window is this shelf.
  bool onScreen() {
    if (!mounted) return false;
    final RenderObject? self = context.findRenderObject();
    final RenderObject? window = _list?.context.findRenderObject();
    if (self is! RenderBox ||
        window is! RenderBox ||
        !self.attached ||
        !window.attached ||
        !self.hasSize ||
        !window.hasSize) {
      return false;
    }
    final double height = self.size.height;
    final double room = window.size.height;
    if (height <= 0 || room <= 0) return false;
    final double top = self.localToGlobal(Offset.zero, ancestor: window).dy;
    final double inside =
        (top + height).clamp(0.0, room) - top.clamp(0.0, room);
    return inside >= 0.5 * (height < room ? height : room);
  }

  bool _turnedSideways(ScrollNotification note) {
    if (note.metrics.axis == Axis.horizontal &&
        movedByFinger(note) &&
        widget.sight._looking) {
      widget.sight._shelf(widget.shelf).turned = true;
    }
    return false;
  }

  bool _laidOut(ScrollMetricsNotification note) {
    final ScrollMetrics m = note.metrics;
    if (m.axis == Axis.horizontal &&
        m.hasContentDimensions &&
        m.maxScrollExtent > m.minScrollExtent) {
      widget.sight._turnable.add(widget.shelf);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        final ShelfSight sight = widget.sight;
        sight._touched = widget.shelf;
        sight._touchedAt = sight._clock.elapsedMilliseconds;
      },
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _laidOut,
        child: NotificationListener<ScrollNotification>(
          onNotification: _turnedSideways,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Keeps a [ShelfSight] in step with the screen it lives on: arriving,
/// covered, uncovered and gone.
class ShelfStay {
  ShelfStay(this.sight, {this.onArrive});

  final ShelfSight sight;

  /// Called on each new stay, after the frame, so the shelves can be built
  /// again and say what is on them for this stay.
  final VoidCallback? onArrive;

  ScreenPresence? _presence;
  int _visit = 0;

  /// Listens to [presence], the screen Explore is drawn on.
  void watch(ScreenPresence? presence) {
    if (identical(presence, _presence)) return;
    _presence?.removeListener(_moved);
    _presence = presence;
    presence?.addListener(_moved);
    _moved();
  }

  void _moved() {
    final ScreenPresence? presence = _presence;
    if (presence == null) return;
    if (presence.showing && presence.visit != _visit) {
      _visit = presence.visit;
      sight.arrive();
      final VoidCallback? arrive = onArrive;
      if (arrive != null) {
        WidgetsBinding.instance
          ..addPostFrameCallback((_) => arrive())
          ..ensureVisualUpdate();
      }
    } else if (presence.showing) {
      sight.uncover();
    } else if (presence.visiting) {
      sight.cover();
    } else {
      sight.leave();
    }
  }

  void dispose() {
    _presence?.removeListener(_moved);
    _presence = null;
    sight.leave();
  }
}
