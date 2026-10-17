import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../analytics.dart';
import '../../data/explore_mix.dart';
import '../../l10n/l10n.dart';
import '../../measure/screens.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import '../scenes/story_view.dart';
import '../subject_icon.dart';
import 'parts.dart';

/// True stories, played the way a story plays on a phone.
///
/// The shelf drew its cards like stories — bars across the top, a play
/// mark at the foot — and a tap opened the ordinary card. A tap plays the
/// story now: full screen, on the card's own colour, its subject's mark and
/// name at the head as on the card's front, a beat at a time. The bars
/// across the top fill as each beat plays, and a beat stays up as long as
/// it takes to read unhurried (see [beatMs]); a tap on the right goes on, a
/// tap on the left goes back, a finger held down stops the clock, and the
/// story pulled down goes back into the tile it grew out of.
///
/// The beats are the card's hook — its question — and then its answer a
/// sentence at a time ([toldBeats]). A card written with a story to play
/// ([StoryScene]) plays that instead, since it is the better telling: its
/// scenes, its drawings turning one into the next, and the question it
/// stops on, which waits for the reader's pick, then what happened and why.
/// Every story ends on a last screen with the line to keep, and what the
/// card itself offers: keeping it, sharing it, and opening it whole.
///
/// With animations off, or a screen reader on, nothing moves on by itself:
/// a tap goes on.
class StoryPlayer extends StatefulWidget {
  const StoryPlayer({
    super.key,
    required this.pill,
    this.from,
    this.saved = false,
    this.onSave,
    this.onShare,
    this.onOpenCard,
    this.facts = const {},
    this.rank,
  });

  final Pill pill;

  /// The tile the story was opened from, on the screen: it grows out of it
  /// and goes back into it.
  final Rect? from;

  /// Whether the card is kept, and what keeping it, sharing it and opening
  /// it do: what the last screen offers.
  final bool saved;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onOpenCard;

  /// The card's facts, said with the story's opening.
  final Map<String, Object?> facts;

  /// Where the story stood on its shelf, from 1.
  final int? rank;

  @override
  State<StoryPlayer> createState() => _StoryPlayerState();
}

/// The route a story plays in: over Explore rather than instead of it, so
/// a story pulled down shows the shelf it came from behind it. The player
/// draws its own way in and out, from the route's animation.
class StoryRoute extends PageRoute<void> {
  StoryRoute({required this.builder, super.settings});

  final WidgetBuilder builder;

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 440);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 340);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

/// One beat of a story.
sealed class _Beat {
  const _Beat();
}

/// A beat in the card's own words: its question, or a sentence of its
/// answer.
class _Told extends _Beat {
  const _Told(this.text);

  final String text;
}

/// A stop of a story written to be played: a scene, the question it stops
/// on, or what happened.
class _Staged extends _Beat {
  const _Staged(this.stop);

  final int stop;
}

class _StoryPlayerState extends State<StoryPlayer>
    with TickerProviderStateMixin {
  late final Pill _pill = widget.pill;

  /// The story written to be played, when the card has one.
  late final StoryScene? _scene = switch (_pill.scene) {
    final StoryScene s => s,
    _ => null,
  };

  late final List<_Beat> _beats = _scene == null
      ? [for (final String line in toldBeats(_pill)) _Told(line)]
      : [for (int i = 0; i < _scene.stops; i++) _Staged(i)];

  /// Plays the written story: the scene moves, and says when it has.
  late final StorySceneController? _staged = _scene == null
      ? null
      : (StorySceneController()..addListener(_stagedMoved));

  /// The beat on show; one past the last is the last screen.
  int _at = 0;

  bool get _atEnd => _at >= _beats.length;

  /// How far through the beat on show its clock is.
  late final AnimationController _clock = AnimationController(vsync: this)
    ..addStatusListener(_ticked);

  /// Whether the clock is running towards the next beat, rather than
  /// standing full on a beat that waits for a tap.
  bool _timing = false;

  /// A finger on the story stops its clock; one held there long hides
  /// everything but the words.
  bool _pressed = false;
  bool _holding = false;

  /// How far the story has been pulled down to close it, and the motion
  /// that lets it go: back up, or away.
  double _pull = 0;
  late final AnimationController _letGo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  )..addListener(_lettingGo);
  double _letGoFrom = 0;
  double _letGoTo = 0;

  /// Pulled away, or closing into the card itself: the way out is not back
  /// into the tile.
  bool _flown = false;
  bool _toCard = false;

  /// The route's own animation: the way in and out.
  Animation<double>? _route;
  bool _begun = false;
  bool? _wasAuto;

  // What the story is measured by: how long it was open, which beats were
  // shown, how often the reader went back or held it, how it ended.
  final Stopwatch _open = Stopwatch()..start();
  final Set<int> _seen = {0};
  int _backs = 0;
  int _holds = 0;
  bool _finished = false;
  String _exit = 'back';

  /// Whether the story plays itself: not with animations off, nor with a
  /// screen reader, which a beat moving on by itself would talk over.
  bool get _auto =>
      !MediaQuery.disableAnimationsOf(context) &&
      !MediaQuery.accessibleNavigationOf(context);

  @override
  void initState() {
    super.initState();
    Analytics.capture('explore story opened', {
      ...widget.facts,
      'pill_id': _pill.id,
      'beats': _beats.length,
      'authored': _scene != null,
      'rank': widget.rank,
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Animation<double>? route = ModalRoute.of(context)?.animation;
    if (route != _route) {
      _route?.removeStatusListener(_arrived);
      _route = route;
      route?.addStatusListener(_arrived);
    }
    _staged
      ?..onTap = _next
      ..hint = context.l10n.storyTapOn;
    final bool auto = _auto;
    if (!_begun) {
      // The first beat's clock waits for the story to be all the way open.
      if (route == null || route.isCompleted) {
        _begun = true;
        _start();
      }
    } else if (auto != _wasAuto) {
      _start();
    }
    _wasAuto = auto;
  }

  void _arrived(AnimationStatus status) {
    if (status != AnimationStatus.completed || _begun || !mounted) return;
    _begun = true;
    _start();
  }

  @override
  void dispose() {
    _route?.removeStatusListener(_arrived);
    Analytics.capture('explore story closed', {
      'pill_id': _pill.id,
      'beats': _beats.length,
      'beats_seen': _seen.length,
      'finished': _finished,
      'ms_in_story': _open.elapsedMilliseconds,
      'taps_back': _backs,
      'holds': _holds,
      'exit': _exit,
    });
    _clock.dispose();
    _letGo.dispose();
    _staged?.dispose();
    super.dispose();
  }

  // ── The clock ───────────────────────────────────────────────────────────

  /// How long [beat] stays up when the story plays itself, or null for the
  /// question of a story written to be played, which waits for a pick.
  int? _msOf(_Beat beat) {
    switch (beat) {
      case _Told(:final String text):
        return beatMs(text);
      case _Staged(:final int stop):
        final StoryScene s = _scene!;
        if (stop < s.askAt) {
          return beatMs('${s.scenes[stop].fact} ${s.scenes[stop].line}');
        }
        if (stop == s.askAt) return null;
        return beatMs('${s.outcome.fact} ${s.outcome.line} ${s.why}');
    }
  }

  /// The beat on show, started: its clock from nought when the story plays
  /// itself, or its bar full when it waits for a tap.
  void _start() {
    _timing = false;
    _clock.stop();
    if (_atEnd) {
      _clock.value = 1;
      return;
    }
    final _Beat beat = _beats[_at];
    final int? ms = _msOf(beat);
    if (!_auto || ms == null) {
      _clock.value = 1;
      return;
    }
    // What happened is read once it has finished arriving.
    if (beat is _Staged && beat.stop == _scene!.outcomeAt && !_staged!.landed) {
      _clock.value = 0;
      return;
    }
    _clock.duration = Duration(milliseconds: ms);
    _timing = true;
    _clock.forward(from: 0);
    if (_pressed || _pull > 0) _clock.stop();
  }

  void _ticked(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_timing) return;
    _timing = false;
    _next(auto: true);
  }

  /// The clock goes on, unless a finger is still on the story.
  void _resume() {
    if (!mounted || !_timing || _pressed || _pull > 0) return;
    if (!_clock.isAnimating) _clock.forward();
  }

  // ── Going on and back ───────────────────────────────────────────────────

  void _next({bool auto = false}) {
    if (_atEnd) return;
    final _Beat beat = _beats[_at];
    if (beat is _Staged && beat.stop <= _scene!.askAt) {
      // The question waits for a pick; a scene moves the written story on,
      // which says so (see _stagedMoved).
      if (beat.stop == _scene.askAt) return;
      if (!auto) HapticFeedback.selectionClick();
      _staged!.next();
      return;
    }
    if (!auto) HapticFeedback.selectionClick();
    _show(_at + 1);
  }

  void _back() {
    _backs++;
    HapticFeedback.selectionClick();
    if (_atEnd) {
      _show(_beats.length - 1);
      return;
    }
    final _Beat beat = _beats[_at];
    if (beat is _Staged) {
      // The first scene starts again; what happened stands, once picked.
      if (beat.stop == 0 || beat.stop > _scene!.askAt) {
        _start();
      } else {
        _staged!.back();
      }
      return;
    }
    if (_at == 0) {
      _start();
    } else {
      _show(_at - 1);
    }
  }

  /// Shows beat [to], or the last screen, and starts it.
  void _show(int to) {
    setState(() => _at = to);
    if (!_atEnd) _seen.add(to);
    if (_atEnd && !_finished) {
      _finished = true;
      HapticFeedback.lightImpact();
      final int? pick = _staged?.pick;
      Analytics.capture('explore story finished', {
        'pill_id': _pill.id,
        'beats': _beats.length,
        'authored': _scene != null,
        'ms_to_finish': _open.elapsedMilliseconds,
        'picked_right': pick == null ? null : pick == _scene!.answer,
      });
    }
    _start();
  }

  /// The written story moved: on or back a scene, or to what happened once
  /// the reader picked; or what happened finished arriving.
  void _stagedMoved() {
    if (!mounted || _atEnd) return;
    final int at = _staged!.at;
    if (at != _at) {
      _show(at);
    } else if (at == _scene!.outcomeAt && !_timing && _clock.value == 0) {
      _start();
    }
  }

  // ── Fingers ─────────────────────────────────────────────────────────────

  void _press(bool down) {
    _pressed = down;
    if (down) {
      _clock.stop();
    } else {
      _resume();
    }
  }

  void _hold(bool on) {
    if (on) _holds++;
    setState(() => _holding = on);
    if (!on) _resume();
  }

  void _tapped(TapUpDetails d) {
    if (d.globalPosition.dx < MediaQuery.sizeOf(context).width * 0.3) {
      _back();
    } else {
      _next();
    }
  }

  void _pullStart(DragStartDetails d) {
    _letGo.stop();
    _clock.stop();
  }

  void _pullUpdate(DragUpdateDetails d) {
    setState(() => _pull = math.max(0, _pull + d.delta.dy));
  }

  void _pullEnd(DragEndDetails d) {
    final double height = MediaQuery.sizeOf(context).height;
    final double v = d.primaryVelocity ?? 0;
    if (_pull > height * 0.16 || (v > 700 && _pull > 8)) {
      _exit = 'swiped down';
      _flown = true;
      if (MediaQuery.disableAnimationsOf(context)) {
        Navigator.of(context).pop();
      } else {
        _slide(height, then: () => Navigator.of(context).pop());
      }
    } else {
      _slide(0, then: _resume);
    }
  }

  VoidCallback? _afterSlide;

  void _slide(double to, {required VoidCallback then}) {
    _letGoFrom = _pull;
    _letGoTo = to;
    _afterSlide = then;
    if (_pull == to) {
      then();
      return;
    }
    _letGo.forward(from: 0).whenCompleteOrCancel(() {
      if (!mounted || _letGo.value < 1) return;
      _afterSlide?.call();
    });
  }

  void _lettingGo() {
    final double t = Curves.easeOutCubic.transform(_letGo.value);
    setState(() => _pull = lerpDouble(_letGoFrom, _letGoTo, t)!);
  }

  // ── The last screen's three ─────────────────────────────────────────────

  void _close() {
    _exit = 'closed';
    Navigator.of(context).pop();
  }

  void _openCard() {
    _exit = 'card';
    setState(() => _toCard = true);
    widget.onOpenCard?.call();
  }

  // ── Drawing it ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final Pill p = _pill;
    final Animation<double> route = _route ?? kAlwaysCompleteAnimation;
    // Dark ink means a light card, and dark icons in the status bar over it.
    final SystemUiOverlayStyle bar = p.ink.computeLuminance() < 0.5
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;
    return ScreenView(
      name: 'story',
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: bar.copyWith(statusBarColor: Colors.transparent),
        child: AnimatedBuilder(
          animation: route,
          builder: (context, story) => _frame(context, route, story!),
          child: _story(context),
        ),
      ),
    );
  }

  /// The story where it is on the way in or out: grown out of its tile, or
  /// pulled down towards it, over the shelf dimmed behind it.
  Widget _frame(BuildContext context, Animation<double> route, Widget story) {
    final Size screen = MediaQuery.sizeOf(context);
    final Rect full = Offset.zero & screen;
    final bool calm = MediaQuery.disableAnimationsOf(context);
    final double t = route.value;
    final bool closing = route.status == AnimationStatus.reverse;
    final double pulled = (_pull / screen.height).clamp(0.0, 1.0);

    Rect box = full;
    double radius = 0;
    double opacity = 1;
    double dim = t;
    if (_pull > 0 || _flown) {
      // Pulled down: smaller and rounder the further it goes.
      final double k = 1 - 0.14 * pulled;
      box = Rect.fromLTWH(
        (screen.width - screen.width * k) / 2,
        _pull,
        screen.width * k,
        screen.height * k,
      );
      radius = 34 * math.min(1, pulled * 5);
      dim = (1 - pulled) * (_flown ? t : 1);
    } else if (calm || _toCard) {
      // No growing: the story fades in and out where it is.
      opacity = t;
    } else {
      final Curve curve = closing ? Curves.easeInCubic : Curves.easeOutQuart;
      final double g = curve.transform(t);
      final Rect from =
          widget.from ??
          Rect.fromCenter(
            center: full.center,
            width: screen.width * 0.9,
            height: screen.height * 0.9,
          );
      box = Rect.lerp(from, full, g)!;
      radius = lerpDouble(22, 0, g)!;
      if (widget.from == null) opacity = t;
      dim = g;
    }
    final double scale = box.width / screen.width;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.55 * dim),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: box,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: screen.width,
                maxWidth: screen.width,
                minHeight: screen.height,
                maxHeight: screen.height,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topLeft,
                  child: IgnorePointer(
                    ignoring: !route.isCompleted || _flown || _toCard,
                    child: story,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The story itself, the size of the screen.
  Widget _story(BuildContext context) {
    final Pill p = _pill;
    final Size screen = MediaQuery.sizeOf(context);
    final EdgeInsets pad = MediaQuery.paddingOf(context);
    final bool calm = MediaQuery.disableAnimationsOf(context);
    final Duration fade = Duration(milliseconds: calm ? 0 : 220);

    // A Material under the words, so they are set as the app sets them and
    // not in the debug underline a page with none gets.
    return Material(
      key: const ValueKey('story-player'),
      color: p.color,
      child: Stack(
        children: [
          // A story told in the card's words has no drawings of its own:
          // its subject's mark, large, in a darker tone of its colour, turns
          // a little at every beat.
          if (_scene == null)
            Positioned(
              right: -screen.width * 0.24,
              bottom: pad.bottom - screen.width * 0.2,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: AnimatedRotation(
                    turns: -0.02 * _at,
                    duration: Duration(milliseconds: calm ? 0 : 900),
                    curve: Curves.easeOutCubic,
                    child: SubjectIcon(
                      subject: p.topic,
                      size: screen.width * 0.95,
                      stroke: 2.2,
                      ink: shade(p.color, 0.86),
                    ),
                  ),
                ),
              ),
            ),
          _fingers(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: pad.top + 10),
                _Bars(count: _beats.length, at: _at, clock: _clock, ink: p.ink),
                AnimatedOpacity(
                  opacity: _holding ? 0 : 1,
                  duration: fade,
                  child: _head(context),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: _atEnd,
                          child: AnimatedOpacity(
                            opacity: _atEnd ? 0 : 1,
                            duration: fade,
                            child: _beatsLayer(context),
                          ),
                        ),
                      ),
                      if (_atEnd)
                        Positioned.fill(
                          child: _Arriving(calm: calm, child: _end(context)),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: pad.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A tap on the right goes on and on the left goes back; a finger held
  /// down stops the clock; a pull down closes. Buttons in the story take
  /// their own taps.
  Widget _fingers(Widget child) => Listener(
    onPointerDown: (_) => _press(true),
    onPointerUp: (_) => _press(false),
    onPointerCancel: (_) => _press(false),
    child: RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      gestures: {
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(debugOwner: this),
              (tap) => tap.onTapUp = _tapped,
            ),
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                duration: const Duration(milliseconds: 250),
                debugOwner: this,
              ),
              (press) => press
                ..onLongPressStart = ((_) => _hold(true))
                ..onLongPressEnd = ((_) => _hold(false))
                ..onLongPressCancel = (() => _hold(false)),
            ),
        VerticalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer(debugOwner: this),
              (drag) => drag
                ..onStart = _pullStart
                ..onUpdate = _pullUpdate
                ..onEnd = _pullEnd
                ..onCancel = (() => _pullEnd(DragEndDetails())),
            ),
      },
      child: child,
    ),
  );

  /// The subject's mark and its name, as on the card's front, and the way
  /// out.
  Widget _head(BuildContext context) {
    final Pill p = _pill;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 10, 0),
      child: Row(
        children: [
          ExcludeSemantics(
            child: SubjectIcon(subject: p.topic, size: 16, ink: p.ink),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              upper(context, p.topic),
              style: AppText.label(
                size: 11,
                spacing: 1.4,
                color: p.ink.withValues(alpha: 0.72),
              ),
            ),
          ),
          Semantics(
            key: const ValueKey('story-close'),
            button: true,
            label: context.l10n.storyClose,
            excludeSemantics: true,
            onTap: _close,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: _close,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.close_rounded, size: 24, color: p.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The beats, under the hint at the foot.
  Widget _beatsLayer(BuildContext context) {
    final Pill p = _pill;
    final l = context.l10n;
    final bool calm = MediaQuery.disableAnimationsOf(context);
    // Under the last screen, the last beat, as it was.
    final int shown = math.min(_at, _beats.length - 1);
    final _Beat beat = _beats[shown];
    final bool asks =
        beat is _Staged && beat.stop == _scene!.askAt && _staged!.pick == null;
    // How to go on, said once, on the first beat, while the story plays
    // itself; on every beat when it does not; and at the question, how to
    // answer it.
    final String? hint = asks
        ? l.sceneTapToPick
        : !_auto
        ? l.storyTapOn
        : _at == 0 && _seen.length == 1
        ? l.storyHint
        : null;

    final Widget body = switch (_scene) {
      final StoryScene s => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: StorySceneView(
          scene: s,
          ink: p.ink,
          ground: p.color,
          controller: _staged,
        ),
      ),
      null => AnimatedSwitcher(
        duration: Duration(milliseconds: calm ? 0 : 460),
        reverseDuration: Duration(milliseconds: calm ? 0 : 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) =>
            Stack(fit: StackFit.expand, children: [...previous, ?current]),
        // The new beat rises into place; the one before lifts away.
        transitionBuilder: (child, animation) {
          final bool rising = child.key == ValueKey<int>(shown);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, rising ? 0.035 : -0.025),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _ToldBeat(
          key: ValueKey<int>(shown),
          text: (beat as _Told).text,
          hook: shown == 0,
          ink: p.ink,
          label: '${l.sceneNOfM(shown + 1, _beats.length)}. ${beat.text}',
          hint: l.storyTapOn,
          onNext: _next,
          onBack: shown == 0 ? null : _back,
          backLabel: l.storyPrevious,
        ),
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: body),
        // Every hint there can be, one shown: the foot is as tall as the
        // tallest, so the words above never move when it changes.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
          child: Stack(
            children: [
              for (final String h in {
                l.storyHint,
                l.storyTapOn,
                if (_scene != null) l.sceneTapToPick,
              })
                AnimatedOpacity(
                  key: h == hint ? const ValueKey('story-hint') : null,
                  opacity: h == hint && !_holding ? 1 : 0,
                  duration: Duration(milliseconds: calm ? 0 : 260),
                  child: Text(
                    h,
                    style: AppText.body(
                      size: 13,
                      weight: FontWeight.w600,
                      height: 1.3,
                      color: p.ink.withValues(alpha: 0.62),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// The last screen: the line the card leaves the reader with, and what
  /// the card offers.
  Widget _end(BuildContext context) {
    final Pill p = _pill;
    final l = context.l10n;
    final bool keep = p.barMove.isNotEmpty;
    final String line = keep ? p.barMove : p.ask;
    return Semantics(
      key: const ValueKey('story-end'),
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (keep) ...[
                    Text(
                      upper(context, l.barMoveCaps),
                      style: AppText.label(
                        size: 11,
                        weight: FontWeight.w700,
                        spacing: 1.6,
                        color: p.ink.withValues(alpha: 0.66),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (line.isNotEmpty)
                    Flexible(
                      child: _Fitted(
                        text: line,
                        min: 20,
                        max: 34,
                        styleFor: (size) => _display(size, p.ink),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Keeping and sharing side by side where both words fit on
                // a line beside their marks, one over the other where a
                // language or the reader's text size makes them longer.
                LayoutBuilder(
                  builder: (context, box) {
                    final Widget save = _Action(
                      key: const ValueKey('story-save'),
                      icon: widget.saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      label: widget.saved ? l.storySaved : l.storySave,
                      said: widget.saved ? l.removeFromSaved : l.saveThisPill,
                      selected: widget.saved,
                      ink: p.ink,
                      ground: p.color,
                      onTap: widget.onSave == null
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              widget.onSave!();
                            },
                    );
                    final Widget share = _Action(
                      key: const ValueKey('story-share'),
                      icon: Icons.ios_share_rounded,
                      label: l.storyShare,
                      said: l.shareThisPill,
                      ink: p.ink,
                      ground: p.color,
                      onTap: widget.onShare,
                    );
                    final double half = (box.maxWidth - 10) / 2;
                    final bool side = [
                      l.storySave,
                      l.storySaved,
                      l.storyShare,
                    ].every((word) => _Action.fitsBeside(context, word, half));
                    if (!side) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [save, const SizedBox(height: 10), share],
                      );
                    }
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: save),
                          const SizedBox(width: 10),
                          Expanded(child: share),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _Action(
                  key: const ValueKey('story-open-card'),
                  icon: Icons.arrow_forward_rounded,
                  label: l.storyOpenCard,
                  ink: p.ink,
                  ground: p.color,
                  filled: true,
                  onTap: widget.onOpenCard == null ? null : _openCard,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The face every beat is set in: the card's own, as on its front.
TextStyle _display(double size, Color ink) => AppText.display(
  size: size,
  weight: FontWeight.w600,
  height: 1.1,
  spacing: -0.4 - size * 0.026,
  color: ink,
);

/// The bars across the top: full for the beats gone by, filling for the
/// one on show, empty for those to come.
class _Bars extends StatelessWidget {
  const _Bars({
    required this.count,
    required this.at,
    required this.clock,
    required this.ink,
  });

  final int count;
  final int at;
  final Animation<double> clock;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: AnimatedBuilder(
          animation: clock,
          builder: (context, _) => Row(
            children: [
              for (int i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      height: 3,
                      child: ColoredBox(
                        color: ink.withValues(alpha: 0.26),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            key: ValueKey('story-bar-$i'),
                            widthFactor: i < at
                                ? 1
                                : i == at
                                ? clock.value
                                : 0,
                            heightFactor: 1,
                            child: ColoredBox(color: ink),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A beat in the card's own words, as large as the space takes it: the
/// question a size up, being the hook.
class _ToldBeat extends StatelessWidget {
  const _ToldBeat({
    super.key,
    required this.text,
    required this.hook,
    required this.ink,
    required this.label,
    required this.hint,
    required this.onNext,
    required this.backLabel,
    this.onBack,
  });

  final String text;
  final bool hook;
  final Color ink;

  /// What a screen reader says of it: which beat, and its words.
  final String label;
  final String hint;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      button: true,
      label: label,
      hint: hint,
      onTap: onNext,
      customSemanticsActions: {
        CustomSemanticsAction(label: backLabel): ?onBack,
      },
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _Fitted(
              text: text,
              min: hook ? 22 : 20,
              max: hook ? 40 : 36,
              styleFor: (size) => _display(size, ink),
            ),
          ),
        ),
      ),
    );
  }
}

/// Type set as large as its box takes it, from [max] down to [min], with
/// the reader's own text size counted in, and never so large that a word
/// is broken across two lines. A little under [min] they still fit
/// without scrolling; past that the words scroll rather than being cut; a
/// word wider than the screen at [min], in the largest text a phone
/// allows, is set smaller still before it is broken.
class _Fitted extends StatelessWidget {
  const _Fitted({
    required this.text,
    required this.styleFor,
    required this.min,
    required this.max,
  });

  final String text;
  final TextStyle Function(double size) styleFor;
  final double min;
  final double max;

  /// The smallest a word is ever set to keep it whole.
  static const double _floor = 9;

  /// How far under [min] the words may go to fit without scrolling.
  static const double _grace = 0.85;

  @override
  Widget build(BuildContext context) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection direction = Directionality.of(context);
    final List<String> words = text.split(RegExp(r'\s+'));
    return LayoutBuilder(
      builder: (context, box) {
        // How wide [s] is on one line, or with [width], how tall.
        double measure(String s, double size, {double? width}) {
          final TextPainter painter = TextPainter(
            text: TextSpan(text: s, style: styleFor(size)),
            textDirection: direction,
            textScaler: scaler,
          )..layout(maxWidth: width ?? double.infinity);
          final double extent = width == null ? painter.width : painter.height;
          painter.dispose();
          return extent;
        }

        bool whole(double size) =>
            words.every((w) => measure(w, size) <= box.maxWidth);
        bool fits(double size) =>
            whole(size) &&
            measure(text, size, width: box.maxWidth) <= box.maxHeight;

        // The largest size between [lo] and [hi] that [ok] allows.
        double largest(double lo, double hi, bool Function(double) ok) {
          while (hi - lo > 0.25) {
            final double mid = (lo + hi) / 2;
            if (ok(mid)) {
              lo = mid;
            } else {
              hi = mid;
            }
          }
          return lo;
        }

        // In the band if anything in it fits; a little under it rather
        // than scroll by less than a line, which reads as words cut off,
        // not as more to come; at its foot, scrolling, if only the height
        // is short; smaller than it only to keep a word.
        final double under = min * _grace;
        final double size = fits(max)
            ? max
            : fits(min)
            ? largest(min, max, fits)
            : fits(under)
            ? largest(under, min, fits)
            : whole(min)
            ? min
            : largest(_floor, min, whole);
        final Widget set = Text(text, style: styleFor(size));
        if (measure(text, size, width: box.maxWidth) <= box.maxHeight) {
          return set;
        }
        return SingleChildScrollView(child: set);
      },
    );
  }
}

/// One of the three things the last screen offers: a word and its mark,
/// filled for the one that leads on.
class _Action extends StatelessWidget {
  const _Action({
    super.key,
    required this.icon,
    required this.label,
    required this.ink,
    required this.ground,
    this.said,
    this.onTap,
    this.filled = false,
    this.selected = false,
  });

  final IconData icon;
  final String label;

  /// What a screen reader says it does, where the word alone is too short.
  final String? said;
  final Color ink;
  final Color ground;
  final VoidCallback? onTap;
  final bool filled;
  final bool selected;

  static const double _pad = 16;
  static const double _mark = 19;
  static const double _gap = 8;

  static TextStyle _style(Color color) => AppText.body(
    size: 15,
    weight: FontWeight.w700,
    height: 1.2,
    color: color,
  );

  /// Whether [label] fits on one line beside its mark in a button [width]
  /// wide, at the reader's own text size.
  static bool fitsBeside(BuildContext context, String label, double width) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: label,
        style: DefaultTextStyle.of(context).style
            .merge(_style(const Color(0xFF000000))),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final double words = painter.width;
    painter.dispose();
    return _pad + _mark + _gap + words + _pad <= width;
  }

  @override
  Widget build(BuildContext context) {
    final Color fg = filled ? ground : ink;
    final bool darkInk = ink.computeLuminance() < 0.5;
    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: said ?? label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: filled ? 56 : 50),
          padding: const EdgeInsets.symmetric(horizontal: _pad, vertical: 12),
          decoration: BoxDecoration(
            // Solid, so the mark drawn large behind the story never shows
            // through a button.
            color: filled
                ? ink
                : Color.alphaBlend(
                    ink.withValues(alpha: darkInk ? 0.1 : 0.18),
                    ground,
                  ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!filled) ...[
                Icon(icon, size: _mark, color: fg),
                const SizedBox(width: _gap),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: _style(fg),
                ),
              ),
              if (filled) ...[
                const SizedBox(width: _gap),
                Icon(icon, size: _mark, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The last screen coming in: up a little, out of nothing.
class _Arriving extends StatelessWidget {
  const _Arriving({required this.calm, required this.child});

  final bool calm;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (calm) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
