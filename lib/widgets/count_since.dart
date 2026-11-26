/// Figures that count from where the reader last saw them.
///
/// Your journey remembers every figure on it as the reader last saw it
/// (AppState.journeySeen). Opened again, a figure that has moved since
/// stands where it was, and once it is on screen counts, calmly, to where it
/// is now, leaving a quiet mark of how far it went: "+12". What the day's
/// cards did to the scores is read here, counting, rather than in a sheet
/// over the finished day (the owner: the scores that went up belong to the
/// journey, updated against the last time, the little numbers counting up).
///
/// A figure counts once a visit, when it is first on screen, not when it is
/// built: the page is long, and a figure counted below the fold would land
/// before anyone saw it move. What the reader has seen is written down as it
/// is seen, so a figure never scrolled to still counts from where they last
/// saw it next time. Whoever asked for less motion gets every figure where
/// it stands, with its mark.
library;

import 'dart:async' show scheduleMicrotask;
import 'dart:ui' show FontFeature, lerpDouble;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme.dart';
import 'skill_score.dart' show scoreUp, signedNumber;

/// Which way a figure gets better: most get better as they rise; how far
/// off the reader's confidence runs gets better as it falls.
enum Better { higher, lower, neither }

/// The figures of one visit: as the reader last saw them, frozen when the
/// page opened, and as they are seen this time, written down as they are.
class LastSeen {
  LastSeen({required Map<String, double> was, required this.onSeen})
    : was = Map.unmodifiable(was);

  /// Each figure as the reader last saw it, by its name.
  final Map<String, double> was;

  /// Writes down what has been seen this visit.
  final void Function(Map<String, double> seen) onSeen;

  /// What this visit has seen, by name.
  final Map<String, double> _seen = {};

  /// The figures that have counted this visit: built again, they stand
  /// where they ended rather than counting a second time.
  final Set<String> _counted = {};

  /// True once a figure on the page has moved since the last visit.
  final ValueNotifier<bool> moved = ValueNotifier(false);

  /// How long the page has been open: a figure on screen as it opens waits
  /// for the page to arrive before it counts; one scrolled to later need
  /// not.
  final Stopwatch _open = Stopwatch()..start();

  bool get _opening => _open.elapsed < const Duration(milliseconds: 600);

  bool _writing = false;

  /// [id] seen at [value]: written down once whatever is being done now is
  /// done, with every other figure seen in the same moment.
  void saw(String id, double value) {
    if (_seen[id] == value) return;
    _seen[id] = value;
    if (_writing) return;
    _writing = true;
    scheduleMicrotask(() {
      _writing = false;
      onSeen(Map.of(_seen));
    });
  }

  void dispose() => moved.dispose();
}

/// Hands a visit's [LastSeen] to the figures under it.
class LastSeenScope extends InheritedWidget {
  const LastSeenScope({super.key, required this.seen, required super.child});

  final LastSeen seen;

  static LastSeen? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LastSeenScope>()?.seen;

  @override
  bool updateShouldNotify(LastSeenScope old) => !identical(old.seen, seen);
}

/// A figure that counts from where the reader last saw it to [value].
///
/// [shows] is how it reads: a move that does not change how it reads is no
/// move. [builder] draws it at each step of the count with the mark of how
/// far it went, where the figure puts it: null when nothing moved, and kept
/// in its place, unseen, while the count runs, so nothing beside it shifts
/// when it arrives. Outside a [LastSeenScope] it is simply the figure.
class CountSince extends StatefulWidget {
  const CountSince({
    super.key,
    required this.id,
    required this.value,
    required this.shows,
    required this.builder,
    this.mark,
    this.better = Better.higher,
  });

  /// What the figure is, as it is remembered: 'score', 'skill.focus'.
  final String id;

  /// Where it stands.
  final double value;

  /// How it reads at a value.
  final String Function(double value) shows;

  /// The figure at [value], a step of the count, and the mark.
  final Widget Function(BuildContext context, double value, Widget? mark)
  builder;

  /// How the mark says how far it went, from [was] to [now]: by default
  /// the whole numbers' difference, with its sign.
  final String Function(BuildContext context, double was, double now)? mark;

  final Better better;

  /// How long a count takes, once it starts.
  static const Duration duration = Duration(milliseconds: 1300);

  /// The beat before the figures on screen as the page opens begin: the
  /// page has to have arrived first.
  static const Duration opening = Duration(milliseconds: 420);

  /// The beat before a figure scrolled to begins.
  static const Duration reached = Duration(milliseconds: 140);

  @override
  State<CountSince> createState() => _CountSinceState();
}

class _CountSinceState extends State<CountSince>
    with SingleTickerProviderStateMixin {
  LastSeen? _seen;

  /// Where the figure was last seen, while it has still to count this
  /// visit; null once it has, or when it has nothing to count.
  double? _from;

  /// Where it was last seen, when it has moved since, as it reads.
  double? _was;

  AnimationController? _count;
  Animation<double> _curve = kAlwaysCompleteAnimation;

  ScrollPosition? _watching;
  bool _shown = false;
  bool _queued = false;

  /// Whether the page is the one in front: false while something has risen
  /// over it, as a level rises over Your journey as it opens
  /// (lib/widgets/level_up.dart). A figure waits while it is covered, and
  /// one covered as it counts counts again from the start once it is
  /// uncovered: a count run behind it would land unseen.
  bool _inFront = true;

  /// True as the page comes back in front, until the figure is looked at:
  /// what covered the page is still going, so a count waits as it does as
  /// the page opens.
  bool _returning = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool inFront = ModalRoute.isCurrentOf(context) ?? true;
    if (inFront != _inFront) {
      _inFront = inFront;
      inFront ? _uncovered() : _covered();
    }
    final LastSeen? seen = LastSeenScope.of(context);
    if (identical(seen, _seen)) return;
    _seen = seen;
    _weigh();
    if (seen == null) return;
    if (_was != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) seen.moved.value = true;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _look());
  }

  /// Works out whether the figure moved since it was last seen.
  void _weigh() {
    final LastSeen? seen = _seen;
    final double? was = seen?.was[widget.id];
    final bool moved =
        was != null && widget.shows(was) != widget.shows(widget.value);
    _was = moved ? was : null;
    _from = moved && !seen!._counted.contains(widget.id) && !_shown
        ? was
        : null;
  }

  @override
  void didUpdateWidget(covariant CountSince old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value && old.id == widget.id) return;
    // Moved while on the page: it stands where it now is, and that is what
    // has been seen.
    _count?.stop();
    _weigh();
    _from = null;
    if (_shown) _seen?.saw(widget.id, widget.value);
  }

  /// The page moved: looked at again once it is laid out where it moved
  /// to, at the end of the frame, once however often it moved in it.
  void _scrolled() {
    if (_queued) return;
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      _look();
    });
  }

  /// Something rose over the page: a count under way goes back to where it
  /// starts, to run again once the page is in front.
  void _covered() {
    final AnimationController? count = _count;
    if (count != null && count.isAnimating) {
      count.stop();
      count.value = 0;
    }
  }

  /// The page in front again: a count put back runs from its start, beat
  /// included, so it begins once what covered the page has gone; a figure
  /// not yet looked at is looked at.
  void _uncovered() {
    final AnimationController? count = _count;
    if (count != null && _from != null && count.isDismissed) {
      count.forward(from: 0);
    } else if (!_shown) {
      _returning = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _look());
    }
  }

  /// Once the figure is on screen, with nothing over the page: written down
  /// as seen, and counted if it moved. Until then, watched as the page
  /// scrolls.
  void _look() {
    if (!mounted || _shown || !_inFront) return;
    final bool returning = _returning;
    _returning = false;
    if (!_onScreen()) {
      if (_watching == null) {
        final ScrollPosition? position = Scrollable.maybeOf(context)?.position;
        _watching = position?..addListener(_scrolled);
      }
      return;
    }
    _unwatch();
    _shown = true;
    final LastSeen seen = _seen!;
    seen.saw(widget.id, widget.value);
    if (_from == null) return;
    seen._counted.add(widget.id);
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _from = null);
      return;
    }
    // The figures there as the page opens, or as it comes back in front,
    // wait for it to arrive; one scrolled to begins at once.
    final Duration wait = seen._opening || returning
        ? CountSince.opening
        : CountSince.reached;
    final Duration total = wait + CountSince.duration;
    final AnimationController count = AnimationController(
      vsync: this,
      duration: total,
    );
    _count = count;
    setState(() {
      _curve = CurvedAnimation(
        parent: count,
        curve: Interval(
          wait.inMicroseconds / total.inMicroseconds,
          1,
          curve: Curves.easeInOutCubic,
        ),
      );
    });
    count.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _from = null);
      }
    });
    count.forward();
  }

  /// Whether a good part of the figure is inside what its page shows.
  bool _onScreen() {
    final RenderObject? box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    final Rect rect = box.localToGlobal(Offset.zero) & box.size;
    Rect view = Offset.zero & MediaQuery.sizeOf(context);
    final RenderObject? port = Scrollable.maybeOf(context)?.context
        .findRenderObject();
    if (port is RenderBox && port.attached && port.hasSize) {
      view = view.intersect(port.localToGlobal(Offset.zero) & port.size);
    }
    // Half of it, or forty points of a tall one, inside the view.
    final double inside =
        rect.bottom.clamp(view.top, view.bottom) -
        rect.top.clamp(view.top, view.bottom);
    return inside > 0 && inside >= (rect.height / 2).clamp(1, 40);
  }

  void _unwatch() {
    _watching?.removeListener(_scrolled);
    _watching = null;
  }

  @override
  void dispose() {
    _unwatch();
    _count?.dispose();
    super.dispose();
  }

  /// The mark of how far the figure went: null when it did not move, and
  /// there but unseen while it counts.
  Widget? _markOf(BuildContext context, {required bool landed}) {
    final double? was = _was;
    if (was == null) return null;
    final String text =
        widget.mark?.call(context, was, widget.value) ??
        signedNumber(context, widget.value.round() - was.round());
    final double by = widget.value - was;
    final bool good = switch (widget.better) {
      Better.higher => by > 0,
      Better.lower => by < 0,
      Better.neither => false,
    };
    return SinceMark(text: text, good: good, shown: landed);
  }

  @override
  Widget build(BuildContext context) {
    // Built the same way counting or not, so the mark is the same mark
    // when it arrives, and fades in rather than appearing.
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, _) {
        final double? from = _from;
        final double at = from == null
            ? widget.value
            : _count == null
            // Not on screen yet: where it was last seen.
            ? from
            : lerpDouble(from, widget.value, _curve.value)!;
        return widget.builder(
          context,
          at,
          _markOf(context, landed: from == null),
        );
      },
    );
  }
}

/// The quiet mark beside a figure that moved since the reader last saw it:
/// how far, in green when it went the good way, in the page's quieter ink
/// when it did not. It arrives as the count lands.
class SinceMark extends StatelessWidget {
  const SinceMark({
    super.key,
    required this.text,
    required this.good,
    this.shown = true,
  });

  final String text;
  final bool good;

  /// False while the figure counts: the mark keeps its room, unseen.
  final bool shown;

  /// How a mark is set, in [color]: what a box measures it by, too.
  static TextStyle styleIn(Color color) => AppText.body(
    size: 11,
    weight: FontWeight.w700,
    height: 1.1,
    color: color,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: shown ? context.l10n.journeySinceMark(text) : null,
      excludeSemantics: true,
      child: AnimatedOpacity(
        opacity: shown ? 1 : 0,
        duration: Duration(milliseconds: still ? 0 : 420),
        curve: Curves.easeOut,
        child: Text(
          text,
          key: const ValueKey('since-mark'),
          maxLines: 1,
          softWrap: false,
          style: styleIn(
            good ? scoreUp(context) : context.p.ink.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}
