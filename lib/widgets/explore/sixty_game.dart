/// Sixty seconds on a screen of its own, opened from its tile among
/// Explore's challenges: the tile grows into the whole screen in the game's
/// colour (challengeFlight), and the round is played there in three
/// moments, each the whole screen.
///
/// - What it is: the name, large; the stopwatch; the rules in a line; the
///   record; a large Play.
/// - The round: the claim in front of the reader on a deck of the eight,
///   False and True under it, large — or the card swiped either way — the
///   stopwatch become the clock, and how far along the eight; nothing else.
///   Each answer is told at once, on the card and in the hand.
/// - How it went: the score, large; a new record, or the one standing; the
///   eight as squares, the next challenge, and the eight claims again, each
///   as it was said, a tap from its card; Play again, and the score to send.
///
/// The round is the day's round, kept and counted as on its shelf
/// ([SixtyRound]): opened again the same day, the screen opens on how it
/// went. The stopwatch is one picture the whole way: the tile's, the first
/// moment's, the clock of the round and the time the round took.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../analytics.dart';
import '../../data/explore_mix.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import '../../utils/share_link.dart';
import '../glass_round.dart';
import '../scaled_text.dart';
import 'challenge_art.dart';
import 'challenges.dart';
import 'parts.dart';
import 'sixty_seconds.dart';

/// The green a right answer is told in, and the coral of a wrong one: the
/// drawn cards' own.
const Color _right = Color(0xFF2BD67B);
const Color _wrong = Color(0xFFFF5A4E);

/// Sixty seconds, opened over Explore out of its tile: the screen's ground
/// is the tile's, grown. With motion reduced it is there at once.
Route<void> sixtyGameRoute(SixtyGame game, {bool calm = false}) =>
    PageRouteBuilder<void>(
      transitionDuration: calm
          ? Duration.zero
          : const Duration(milliseconds: 480),
      reverseTransitionDuration: calm
          ? Duration.zero
          : const Duration(milliseconds: 380),
      pageBuilder: (_, _, _) => game,
    );

/// The screen.
class SixtyGame extends StatefulWidget {
  const SixtyGame({
    super.key,
    required this.look,
    required this.heroTag,
    required this.pills,
    required this.best,
    required this.onFinished,
    required this.onOpen,
    this.onShown,
    this.next,
    this.onNext,
  });

  /// The game's colour, picture and name, as its tile has them.
  final ChallengeLook look;

  /// The tile's: what the ground flies from and back to.
  final Object heroTag;

  /// The day's eight claims.
  final List<Pill> pills;

  /// The most ever right in one round (`AppState.sixtyBest`).
  final int Function() best;

  /// A round ended with this many right: the record is kept from it.
  final Future<void> Function(int right) onFinished;

  /// A claim's card, opened among the eight.
  final void Function(List<Pill>, Pill) onOpen;

  /// A claim put in front of the reader.
  final ValueChanged<Pill>? onShown;

  /// The challenge after this one, offered at the end, and how it opens.
  final ChallengeLook? next;
  final VoidCallback? onNext;

  @override
  State<SixtyGame> createState() => _SixtyGameState();
}

enum _Moment { intro, play, result }

/// Where things stand on a screen of [size] with [safe] insets.
class _Room {
  _Room(this.size, this.safe);

  final Size size;
  final EdgeInsets safe;

  /// The row of controls at the top: the close, and in the round the clock.
  double get top => safe.top + 6;
  double get head => top + 52;

  /// The room left under the last button.
  double get foot => math.max(safe.bottom, 16.0) + 14;

  /// The stopwatch become the clock: small, in the top row's corner.
  Rect get clock => Rect.fromLTWH(8, top - 2, 56 * kArtAspect, 56);
}

class _SixtyGameState extends State<SixtyGame> with TickerProviderStateMixin {
  static const int _seconds = SixtyRound.seconds;

  late final SixtyRound _round = SixtyRound(widget.pills);
  late _Moment _moment;

  /// The round's minute: a minute whatever the phone says of motion, which
  /// would otherwise run a controller twenty times as fast.
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: _seconds),
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener(_ticked);

  /// The picture moving from where it was ([_artFrom], its time
  /// [_timeFrom]) to where the moment has it.
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  Rect? _artFrom;
  double _timeFrom = 0.25;
  Rect _artNow = Rect.zero;
  double _timeNow = 0.25;

  /// A claim answered, leaving the deck: which, what was said, whether it
  /// was right, and how far the finger had already moved it.
  late final AnimationController _leave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  ({int at, bool said, bool right, double from})? _leaving;

  /// The card in front, as the finger moves it.
  double _drag = 0;
  late final AnimationController _back =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 220),
      )..addListener(
        () => setState(
          () => _drag =
              _dragFrom * (1 - Curves.easeOutBack.transform(_back.value)),
        ),
      );
  double _dragFrom = 0;

  /// Whether the screen is all the way up; whether it is going back.
  bool _up = false;
  bool _going = false;
  Animation<double>? _route;

  /// The record before the round that just ended, and whether it beat it.
  bool _newRecord = false;

  /// The last whole second the clock said, for the ticks of the last five.
  int _lastSecond = _seconds;

  final Set<String> _shown = {};

  @override
  void initState() {
    super.initState();
    // A round played earlier today: the screen opens on how it went.
    _moment = _round.restore() ? _Moment.result : _Moment.intro;
    _timeNow = _moment == _Moment.result ? (_round.took ?? 0) / _seconds : 0.25;
    _clock.addListener(_second);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Animation<double>? animation = ModalRoute.of(context)?.animation;
    if (animation != _route) {
      _route?.removeStatusListener(_routed);
      _route = animation;
      animation?.addStatusListener(_routed);
    }
    if (animation == null || animation.isCompleted) _arrive();
  }

  void _routed(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.completed) {
      _arrive();
    } else if (status == AnimationStatus.reverse && !_going) {
      setState(() => _going = true);
    }
  }

  void _arrive() {
    if (_up) return;
    if (ModalRoute.of(context)?.offstage ?? false) return;
    setState(() => _up = true);
  }

  @override
  void dispose() {
    _route?.removeStatusListener(_routed);
    _clock.dispose();
    _move.dispose();
    _leave.dispose();
    _back.dispose();
    super.dispose();
  }

  bool get _calm => MediaQuery.disableAnimationsOf(context);

  void _announce(String message) {
    if (!MediaQuery.supportsAnnounceOf(context)) return;
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  }

  /// Moves to [moment], the picture gliding to its place in it.
  void _goTo(_Moment moment) {
    _artFrom = _artNow;
    _timeFrom = _timeNow;
    setState(() => _moment = moment);
    if (_calm) {
      _move.value = 1;
    } else {
      _move.forward(from: 0);
    }
  }

  // ── The round ─────────────────────────────────────────────────────────

  void _play() {
    HapticFeedback.mediumImpact();
    _round.start();
    _leaving = null;
    _saidAt = null;
    _drag = 0;
    _lastSecond = _seconds;
    _clock.value = 0;
    _goTo(_Moment.play);
    _showing();
    // The clock starts once the first claim is in front of the reader.
    if (_calm) {
      _clock.forward(from: 0);
    } else {
      Future<void>.delayed(const Duration(milliseconds: 360), () {
        if (mounted && _moment == _Moment.play && _round.running) {
          _clock.forward(from: _clock.value);
        }
      });
    }
  }

  void _showing() {
    final int at = _round.answers?.length ?? 0;
    if (at >= widget.pills.length) return;
    final Pill p = widget.pills[at];
    if (_shown.add(p.id)) widget.onShown?.call(p);
  }

  /// What is left of the minute, in seconds, and as the clock says it: a
  /// second is not counted as begun for a hair's breadth of arithmetic.
  double get _left => (1 - _clock.value) * _seconds;
  int get _secondsLeft => (_left - 1e-6).ceil().clamp(0, _seconds);

  void _second() {
    if (!_round.running) return;
    final int left = _secondsLeft;
    if (left == _lastSecond) return;
    _lastSecond = left;
    if (left <= 5 && left > 0) HapticFeedback.selectionClick();
  }

  void _ticked(AnimationStatus status) {
    if (status == AnimationStatus.completed && _round.running) {
      HapticFeedback.heavyImpact();
      _finish();
    }
  }

  /// When the last claim was answered, by the frames' clock.
  Duration? _saidAt;

  /// [sayTrue] said of the claim in front, by a button or a swipe.
  void _say(bool sayTrue) {
    if (!_round.running || _moment != _Moment.play) return;
    // Two taps in the same instant are one: the second never answers the
    // claim that came in behind the first, unseen.
    final Duration now = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    final Duration? before = _saidAt;
    if (before != null && now - before < const Duration(milliseconds: 140)) {
      return;
    }
    _saidAt = now;
    final int at = _round.answers!.length;
    final bool right = sayTrue == trueOrFalseAnswer(widget.pills[at]);
    if (right) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    _announce(right ? context.l10n.gameRight : context.l10n.gameWrong);
    final bool last = _round.answer(sayTrue);
    _back.stop();
    setState(() {
      _leaving = (at: at, said: sayTrue, right: right, from: _drag);
      _drag = 0;
    });
    if (_calm) {
      _leave.value = 1;
    } else {
      _leave.forward(from: 0);
    }
    if (last) {
      _finish(after: _calm ? Duration.zero : const Duration(milliseconds: 280));
    } else {
      _showing();
    }
  }

  Future<void> _finish({Duration after = Duration.zero}) async {
    _clock.stop();
    final double took = _clock.value * _seconds;
    final int before = widget.best();
    final int right = _round.finish(took);
    _newRecord = right > before && right > 0;
    // Counted at once, as on the shelf: the record does not wait for the
    // last card to fly, nor for a reader who closes the screen first.
    final Future<void> kept = widget.onFinished(right);
    if (after > Duration.zero) await Future<void>.delayed(after);
    if (!mounted) return;
    _goTo(_Moment.result);
    // A new record, or all eight right, is cheered: once, as it lands.
    if (_newRecord || right == widget.pills.length) {
      HapticFeedback.mediumImpact();
      if (!_calm) setState(() => _cheers++);
    }
    await kept;
    if (mounted) setState(() {});
  }

  /// How many times a round has been cheered: a new burst each time.
  int _cheers = 0;

  void _dragged(DragUpdateDetails d) {
    if (!_round.running) return;
    _back.stop();
    setState(() => _drag += d.delta.dx);
  }

  void _dropped(DragEndDetails d, double width) {
    if (!_round.running) return;
    final double v = d.primaryVelocity ?? 0;
    if (_drag.abs() > width * 0.26 || v.abs() > 900) {
      _say((_drag.abs() > 8 ? _drag : v) > 0);
      return;
    }
    _dragFrom = _drag;
    _back.forward(from: 0);
  }

  void _close() {
    if (_round.running) _clock.stop();
    Navigator.of(context).maybePop();
  }

  Future<void> _share() async {
    final l = context.l10n;
    final String locale = Localizations.localeOf(context).toString();
    String date;
    try {
      date = DateFormat.MMMd(locale).format(DateTime.now());
    } catch (_) {
      date = DateFormat.MMMd('en').format(DateTime.now());
    }
    final int n = widget.pills.length;
    final String squares = [
      for (int i = 0; i < n; i++)
        switch (_round.rightAt(i)) {
          true => '🟩',
          false => '🟥',
          null => '⬜',
        },
    ].join();
    final String text = [
      l.sixtyShareHead(date),
      l.sixtyShareScore(_round.right, n, (_round.took ?? 0).round()),
      squares,
      ShareRef.sixty.link,
    ].join('\n');
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    final String copied = l.copiedToClipboard;
    final bool shared = await sendText(text);
    Analytics.capture('explore sixty shared', {
      'right': _round.right,
      'as': shared ? 'link' : 'copied',
    });
    if (!shared) {
      await Clipboard.setData(ClipboardData(text: text));
      messenger?.showSnackBar(
        SnackBar(content: Text(copied), duration: const Duration(seconds: 2)),
      );
    }
  }

  // ── Where the picture stands ──────────────────────────────────────────

  /// The first moment's words, measured as they will be set: what the
  /// picture has above them.
  double _introWords(BuildContext context, double width) {
    final l = context.l10n;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection direction = Directionality.of(context);
    double measure(String text, TextStyle style, TextScaler s) {
      final TextPainter p = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: s,
      )..layout(maxWidth: width);
      final double h = p.height;
      p.dispose();
      return h;
    }

    final Color ink = widget.look.ink;
    return measure(widget.look.title, _titleStyle(ink), _titleScaler(scaler)) +
        12 +
        measure(l.sixtyRules, _rulesStyle(ink), scaler) +
        18 +
        math.max(38, measure(_recordWords(l), _chipStyle(ink), scaler) + 18) +
        28 +
        _playHeight;
  }

  static const double _playHeight = 66;

  TextScaler _titleScaler(TextScaler s) => s.clamp(maxScaleFactor: 1.3);

  TextStyle _titleStyle(Color ink) => AppText.display(
    size: 46,
    weight: FontWeight.w700,
    height: 1.02,
    spacing: -1.4,
    color: ink,
  );

  TextStyle _rulesStyle(Color ink) => AppText.body(
    size: 17,
    weight: FontWeight.w500,
    height: 1.35,
    color: ink.withValues(alpha: 0.82),
  );

  TextStyle _chipStyle(Color ink) => AppText.body(
    size: 13.5,
    weight: FontWeight.w700,
    height: 1.2,
    color: ink,
  );

  String _recordWords(AppLocalizations l) {
    final int best = widget.best();
    return best > 0
        ? l.exploreSixtyRecord(best, widget.pills.length)
        : l.exploreSixtyFirst;
  }

  /// Where the moment has the picture.
  Rect _artFor(BuildContext context, _Moment moment, _Room room) {
    if (moment != _Moment.intro) return room.clock;
    final Size size = room.size;
    final double words = _introWords(context, size.width - 56);
    final double bottom = size.height - room.foot - words - 26;
    final double top = room.head + 6;
    final double tall = bottom - top;
    if (tall < 72) {
      return Rect.fromCenter(
        center: Offset(size.width / 2, top),
        width: 0,
        height: 0,
      );
    }
    // As large as the screen is wide, nearly: the picture has room of its
    // own round its thing.
    double width = math.min(size.width - 16, 420);
    double height = width / kArtAspect;
    if (height > tall) {
      height = tall;
      width = height * kArtAspect;
    }
    return Rect.fromLTWH(
      (size.width - width) / 2,
      top + (tall - height) * 0.6,
      width,
      height,
    );
  }

  double _timeFor(_Moment moment) => switch (moment) {
    _Moment.intro => 0.25,
    _Moment.play => _clock.value,
    _Moment.result => (_round.took ?? 0) / _seconds,
  };

  @override
  Widget build(BuildContext context) {
    final MediaQueryData m = MediaQuery.of(context);
    final _Room room = _Room(m.size, m.padding);
    final ChallengeLook look = widget.look;
    final bool light =
        ThemeData.estimateBrightnessForColor(look.colour) == Brightness.light;
    final Animation<double> route =
        ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation;
    // The screen is the game's colour, whatever the app's: its own palette,
    // so the close and anything else that asks for ink gets one that reads
    // on it.
    return Theme(
      data: buildAstutoTheme(light ? Brightness.light : Brightness.dark),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // What the tile opened over, darkened as the tile grows.
              Positioned.fill(
                child: IgnorePointer(
                  child: FadeTransition(
                    opacity: route,
                    child: const ColoredBox(color: Color(0x73000000)),
                  ),
                ),
              ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_move, _clock]),
                  builder: (context, _) {
                    final Rect to = _artFor(context, _moment, room);
                    final double toTime = _timeFor(_moment);
                    final double k = Curves.easeInOutCubicEmphasized.transform(
                      _move.value,
                    );
                    final Rect? from = _artFrom;
                    _artNow = from == null || _move.isCompleted
                        ? to
                        : Rect.lerp(from, to, k)!;
                    _timeNow = from == null || _move.isCompleted
                        ? toTime
                        : _timeFrom + (toTime - _timeFrom) * k;
                    final Rect art = _artNow;
                    final double time = _timeNow;
                    return Hero(
                      tag: widget.heroTag,
                      createRectTween: challengeRectTween,
                      flightShuttleBuilder: challengeFlight,
                      curve: Curves.easeInOutCubicEmphasized,
                      child: ChallengeGround(
                        key: const ValueKey('sixty-ground'),
                        colour: look.colour,
                        art: look.art,
                        artAt: (_) => art,
                        time: time,
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: Visibility(
                  visible: !_going,
                  maintainState: true,
                  // The words come in once the ground has landed, rising a
                  // little into place.
                  child: AnimatedOpacity(
                    opacity: _up ? 1 : 0,
                    duration: _calm
                        ? Duration.zero
                        : const Duration(milliseconds: 240),
                    child: AnimatedSlide(
                      offset: _up ? Offset.zero : const Offset(0, 0.015),
                      duration: _calm
                          ? Duration.zero
                          : const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      child: IgnorePointer(
                        ignoring: !_up,
                        child: _moments(context, room),
                      ),
                    ),
                  ),
                ),
              ),
              if (_cheers > 0 && _moment == _Moment.result && !_going)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _Confetti(
                      key: ValueKey('sixty-cheer-$_cheers'),
                      from: Offset(92, room.head + 64),
                    ),
                  ),
                ),
              // The way out comes with the words, once the screen is up.
              Positioned(
                top: room.top,
                right: 10,
                child: Visibility(
                  visible: !_going,
                  child: AnimatedOpacity(
                    opacity: _up ? 1 : 0,
                    duration: _calm
                        ? Duration.zero
                        : const Duration(milliseconds: 240),
                    child: IgnorePointer(
                      ignoring: !_up,
                      child: _CloseButton(onTap: _close),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moments(BuildContext context, _Room room) {
    final Widget shown = switch (_moment) {
      _Moment.intro => _intro(context, room),
      _Moment.play => _playing(context, room),
      _Moment.result => _result(context, room),
    };
    return AnimatedSwitcher(
      duration: _calm ? Duration.zero : const Duration(milliseconds: 300),
      // The moment going is gone quickly, so the two never read as one.
      reverseDuration: _calm
          ? Duration.zero
          : const Duration(milliseconds: 140),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey('sixty-moment-${_moment.name}'),
        child: shown,
      ),
    );
  }

  // ── What it is ────────────────────────────────────────────────────────

  Widget _intro(BuildContext context, _Room room) {
    final l = context.l10n;
    final ChallengeLook look = widget.look;
    final Color ink = look.ink;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final int best = widget.best();
    final Widget words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: _titleScaler(scaler)),
            child: Text(look.title, style: _titleStyle(ink)),
          ),
        ),
        const SizedBox(height: 12),
        Text(l.sixtyRules, style: _rulesStyle(ink)),
        const SizedBox(height: 18),
        _Chip(
          key: const ValueKey('sixty-record'),
          icon: best > 0 ? Icons.emoji_events_rounded : Icons.flag_rounded,
          label: _recordWords(l),
          ink: ink,
          ground: look.colour,
        ),
        const SizedBox(height: 28),
        _GameButton(
          key: const ValueKey('sixty-play'),
          label: l.gamePlay,
          icon: Icons.play_arrow_rounded,
          face: ink,
          ink: look.colour,
          height: _playHeight,
          onTap: _play,
        ),
      ],
    );
    final double words0 = _introWords(context, room.size.width - 56);
    final bool fits = room.size.height - room.foot - words0 >= room.head;
    if (!fits) {
      // Words too large for the screen: they scroll, under the close.
      return Padding(
        padding: EdgeInsets.only(top: room.head),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(28, 8, 28, room.foot),
          child: words,
        ),
      );
    }
    return Stack(
      children: [
        Positioned(left: 28, right: 28, bottom: room.foot, child: words),
      ],
    );
  }

  // ── The round ─────────────────────────────────────────────────────────

  Widget _playing(BuildContext context, _Room room) {
    final l = context.l10n;
    final Color ink = widget.look.ink;
    final int n = widget.pills.length;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: room.foot),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: room.top,
              left: room.clock.right + 2,
              right: 64,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: room.head - room.top),
              child: AnimatedBuilder(
                animation: _clock,
                builder: (context, _) {
                  final double left = _left;
                  final int secs = _secondsLeft;
                  final double beat = secs <= 10 && !_calm
                      ? 1 + 0.12 * math.max(0, 1 - (secs - left) * 4)
                      : 1;
                  return Row(
                    children: [
                      Semantics(
                        label: l.sixtySecondsLeftLabel(secs),
                        excludeSemantics: true,
                        child: Transform.scale(
                          scale: beat,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$secs',
                            key: const ValueKey('sixty-clock'),
                            textScaler: scaler.clamp(maxScaleFactor: 1.3),
                            style:
                                AppText.display(
                                  size: 36,
                                  weight: FontWeight.w700,
                                  height: 1,
                                  spacing: -1,
                                  color: ink,
                                ).copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l.nOfM(
                          math.min((_round.answers?.length ?? 0) + 1, n),
                          n,
                        ),
                        key: const ValueKey('sixty-count'),
                        textScaler: scaler.clamp(maxScaleFactor: 1.6),
                        style: AppText.body(
                          size: 15,
                          weight: FontWeight.w800,
                          height: 1,
                          color: ink,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _Segments(round: _round, ink: ink),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(
                builder: (context, box) => _deck(context, box.biggest),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _GameButton(
                    key: const ValueKey('sixty-false'),
                    label: l.sayFalse,
                    icon: Icons.close_rounded,
                    face: kArtCream,
                    ink: kArtInk,
                    height: 84,
                    onTap: () => _say(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GameButton(
                    key: const ValueKey('sixty-true'),
                    label: l.sayTrue,
                    icon: Icons.check_rounded,
                    face: kArtInk,
                    ink: kArtCream,
                    height: 84,
                    onTap: () => _say(true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The deck: the claim in front, the ones still to come under it, and the
  /// one just answered on its way off, its verdict on it.
  Widget _deck(BuildContext context, Size area) {
    final int n = widget.pills.length;
    final int at = math.min(_round.answers?.length ?? 0, n);
    final int left = n - at;
    final double width = area.width;
    return AnimatedBuilder(
      animation: _leave,
      builder: (context, _) {
        final ({int at, bool said, bool right, double from})? leaving =
            _leaving;
        final double t = leaving == null ? 1 : _leave.value;
        final double rise = Curves.easeOutCubic.transform(
          (t / 0.8).clamp(0.0, 1.0),
        );
        // Depth 0 is the card in front; a card one deeper peeks out under
        // it, a little narrower, a little turned. While a card leaves, the
        // rest rise one step.
        const double peek = 9;
        Widget place(Widget child) => Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: peek * 2,
          child: child,
        );
        Widget card(int index, double depth, {required Widget child}) {
          final double d = depth;
          return place(
            Transform.translate(
              offset: Offset(0, peek * d),
              child: Transform.rotate(
                angle: (index.isEven ? -1 : 1) * 0.016 * d,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(1 - 0.05 * d, 1, 1),
                  child: child,
                ),
              ),
            ),
          );
        }

        final List<Widget> layers = [];
        // The ones under the front one: blank backs, at most two.
        for (int depth = math.min(left - 1, 2); depth >= 1; depth--) {
          layers.add(
            card(
              at + depth,
              depth + (1 - rise),
              child: _ClaimCard(pill: null, width: width),
            ),
          );
        }
        if (left > 0) {
          final Pill p = widget.pills[at];
          final double lean = (_drag / (width * 0.9)).clamp(-1.0, 1.0);
          layers.add(
            card(
              at,
              1 - rise,
              child: GestureDetector(
                key: const ValueKey('sixty-card'),
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: _dragged,
                onHorizontalDragEnd: (d) => _dropped(d, width),
                child: Transform.translate(
                  offset: Offset(_drag, 0),
                  child: Transform.rotate(
                    angle: lean * 0.16,
                    child: _ClaimCard(
                      key: ValueKey('sixty-claim-${p.id}'),
                      pill: p,
                      width: width,
                      lean: lean,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        if (leaving != null && t < 1) {
          final double go = Curves.easeInCubic.transform(t);
          final double dir = leaving.said ? 1 : -1;
          final double x =
              leaving.from + (dir * width * 1.25 - leaving.from) * go;
          layers.add(
            place(
              IgnorePointer(
                child: Opacity(
                  opacity: (1 - go * 0.6).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(x, -12 * go),
                    child: Transform.rotate(
                      angle: dir * 0.24 * go + leaving.from / width * 0.16,
                      child: _ClaimCard(
                        pill: widget.pills[leaving.at],
                        width: width,
                        verdict: leaving.right,
                        stamp: Curves.easeOutBack.transform(
                          (t / 0.35).clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return Stack(clipBehavior: Clip.none, children: layers);
      },
    );
  }

  // ── How it went ───────────────────────────────────────────────────────

  Widget _result(BuildContext context, _Room room) {
    final l = context.l10n;
    final ChallengeLook look = widget.look;
    final Color ink = look.ink;
    final int n = widget.pills.length;
    final int right = _round.right;
    final int best = widget.best();
    final bool perfect = right == n;
    final ChallengeLook? next = widget.next;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: room.head,
          child: Padding(
            padding: EdgeInsets.only(
              top: room.top,
              left: room.clock.right + 4,
              right: 64,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                look.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.display(
                  size: 20,
                  weight: FontWeight.w700,
                  height: 1.1,
                  spacing: -0.4,
                  color: ink,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('sixty-end'),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  container: true,
                  label: l.nOfM(right, n),
                  excludeSemantics: true,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$right',
                          style: AppText.display(
                            size: 112,
                            weight: FontWeight.w700,
                            height: 0.95,
                            spacing: -5,
                            color: ink,
                          ),
                        ),
                        TextSpan(
                          text: ' /$n',
                          style: AppText.display(
                            size: 44,
                            weight: FontWeight.w600,
                            height: 0.95,
                            spacing: -1,
                            color: ink.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ),
                    key: const ValueKey('sixty-score'),
                    textScaler: MediaQuery.textScalerOf(context)
                        .clamp(maxScaleFactor: 1.2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  perfect
                      ? l.sixtyPerfect
                      : _round.allAnswered
                      ? l.sixtyIn((_round.took ?? 0).round())
                      : l.sixtyTimeUp,
                  style: AppText.body(
                    size: 17,
                    weight: FontWeight.w600,
                    height: 1.3,
                    color: ink.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_newRecord)
                      _Chip(
                        key: const ValueKey('sixty-new-record'),
                        icon: Icons.emoji_events_rounded,
                        label: l.sixtyNewRecord,
                        ink: look.colour,
                        ground: ink,
                      )
                    else if (best > 0)
                      _Chip(
                        key: const ValueKey('sixty-record'),
                        icon: Icons.emoji_events_rounded,
                        label: l.exploreSixtyRecord(best, n),
                        ink: ink,
                        ground: look.colour,
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                _Squares(round: _round, ink: ink),
                if (next != null && widget.onNext != null) ...[
                  const SizedBox(height: 26),
                  _NextCard(look: next, onTap: widget.onNext!),
                ],
                const SizedBox(height: 28),
                Semantics(
                  header: true,
                  child: Text(
                    upper(context, l.sixtyReview),
                    style: AppText.label(
                      size: 12,
                      weight: FontWeight.w800,
                      spacing: 1.4,
                      color: ink.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _Review(
                  round: _round,
                  onOpen: (p) => widget.onOpen(widget.pills, p),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, room.foot),
          decoration: BoxDecoration(
            color: look.colour,
            border: Border(top: BorderSide(color: ink.withValues(alpha: 0.14))),
          ),
          child: Row(
            children: [
              Expanded(
                child: _GameButton(
                  key: const ValueKey('sixty-again'),
                  label: l.sixtyAgain,
                  icon: Icons.replay_rounded,
                  face: kArtCream,
                  ink: kArtInk,
                  height: 60,
                  onTap: _play,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GameButton(
                  key: const ValueKey('sixty-share'),
                  label: l.share,
                  icon: Icons.ios_share_rounded,
                  face: kArtInk,
                  ink: kArtCream,
                  height: 60,
                  onTap: _share,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A burst of paper from the score, once, for a new record or all eight
/// right: the pictures' own flat colours and line, falling away in a
/// second and a half.
class _Confetti extends StatefulWidget {
  const _Confetti({super.key, required this.from});

  /// Where the burst starts, on the screen.
  final Offset from;

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _run,
    builder: (context, _) => _run.isCompleted
        ? const SizedBox.shrink()
        : CustomPaint(
            painter: _ConfettiPainter(t: _run.value, from: widget.from),
            size: Size.infinite,
          ),
  );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.t, required this.from});

  final double t;
  final Offset from;

  static const List<Color> _colours = [
    _right,
    _wrong,
    kArtCream,
    Color(0xFF2F7FE0),
    Color(0xFFFF5A1F),
    Color(0xFFFF8FB4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // The same burst every time: the pieces are drawn from a fixed seed.
    final math.Random r = math.Random(7);
    final Paint line = Paint()
      ..color = kArtInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    final double fade = t < 0.75 ? 1 : 1 - (t - 0.75) / 0.25;
    for (int i = 0; i < 34; i++) {
      final double angle = -math.pi * (0.08 + 0.84 * r.nextDouble());
      final double speed = 340 + 520 * r.nextDouble();
      final double spin = (r.nextDouble() - 0.5) * 14;
      final Color colour = _colours[i % _colours.length];
      final double s = 7 + 6 * r.nextDouble();
      final double secs = t * 1.5;
      // Out fast, slowed by the air, pulled down.
      final double drag = (1 - math.exp(-2.6 * secs)) / 2.6;
      final Offset at =
          from +
          Offset(math.cos(angle), math.sin(angle)) * speed * drag +
          Offset(0, 420 * secs * secs);
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(spin * secs);
      final Paint fill = Paint()..color = colour.withValues(alpha: fade);
      line.color = kArtInk.withValues(alpha: fade);
      final Rect piece = Rect.fromCenter(
        center: Offset.zero,
        width: s,
        height: i.isEven ? s * 0.55 : s,
      );
      if (i % 3 == 0) {
        canvas.drawOval(piece, fill);
        canvas.drawOval(piece, line);
      } else {
        final RRect rr = RRect.fromRectAndRadius(
          piece,
          const Radius.circular(2),
        );
        canvas.drawRRect(rr, fill);
        canvas.drawRRect(rr, line);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t || old.from != from;
}

/// The way out, as the app's controls are drawn: Apple's own glass on iOS
/// 26 and later, and elsewhere a round button of paper and ink, as the
/// game's cards are.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const Color ink = kArtInk;
    return GlassRound(
      symbol: GlassRound.close,
      label: l.closeLabel,
      onPressed: onTap,
      fallback: Semantics(
        button: true,
        label: l.closeLabel,
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          key: const ValueKey('sixty-close'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kArtCream,
                  border: Border.all(color: ink, width: 2.4),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.close_rounded, size: 21, color: ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A button with a thickness to it, drawn as the pictures are: a face with
/// a line of ink round it, on an edge of ink it sinks into under the finger
/// (the app's chunky buttons, lib/widgets/chunky.dart, in the drawn cards'
/// manner).
class _GameButton extends StatefulWidget {
  const _GameButton({
    super.key,
    required this.label,
    required this.face,
    required this.ink,
    required this.onTap,
    this.icon,
    this.height = 64,
  });

  final String label;
  final IconData? icon;
  final Color face;
  final Color ink;
  final VoidCallback onTap;
  final double height;

  @override
  State<_GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<_GameButton> {
  bool _down = false;

  static const double _depth = 5;

  void _press(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final bool calm = MediaQuery.disableAnimationsOf(context);
    final double sink = _down ? _depth : 0;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: widget.onTap,
        child: SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              Positioned.fill(
                top: _depth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: kArtInk,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: calm
                    ? Duration.zero
                    : const Duration(milliseconds: 70),
                left: 0,
                right: 0,
                top: sink,
                bottom: _depth - sink,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.face,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kArtInk, width: 3),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 26, color: widget.ink),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          maxLines: 1,
                          style: AppText.body(
                            size: 19,
                            weight: FontWeight.w800,
                            height: 1,
                            spacing: 0.2,
                            color: widget.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pill with a mark and a few words: the record.
class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.icon,
    required this.label,
    required this.ink,
    required this.ground,
  });

  final IconData icon;
  final String label;
  final Color ink;
  final Color ground;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 38),
    padding: const EdgeInsets.fromLTRB(11, 8, 14, 8),
    decoration: BoxDecoration(
      color: ground,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: kArtInk, width: 2.4),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: ink),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: AppText.body(
              size: 13.5,
              weight: FontWeight.w700,
              height: 1.2,
              color: ink,
            ),
          ),
        ),
      ],
    ),
  );
}

/// How far along the eight: one bar each, the ones answered green or coral
/// for right or wrong, the one in front open, the rest to come.
class _Segments extends StatelessWidget {
  const _Segments({required this.round, required this.ink});

  final SixtyRound round;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final int n = round.pills.length;
    final int at = round.answers?.length ?? 0;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (int i = 0; i < n; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: AnimatedContainer(
                key: ValueKey(
                  'sixty-seg-$i-${switch (round.rightAt(i)) {
                    true => 'right',
                    false => 'wrong',
                    null => i == at ? 'now' : 'next',
                  }}',
                ),
                duration: const Duration(milliseconds: 200),
                height: 12,
                decoration: BoxDecoration(
                  color: switch (round.rightAt(i)) {
                    true => _right,
                    false => _wrong,
                    null => i == at ? kArtCream : Colors.transparent,
                  },
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: i > at ? ink.withValues(alpha: 0.35) : kArtInk,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A claim on a card of the deck: its subject and the claim, as large as
/// it goes. With no [pill], the back of a card still to come. [lean] is how
/// far the finger has moved it, and which way: the answer it is leaning
/// to shows in its corner. [verdict], on a card answered, is whether it was
/// right, stamped on it as it goes.
class _ClaimCard extends StatelessWidget {
  const _ClaimCard({
    super.key,
    required this.pill,
    required this.width,
    this.lean = 0,
    this.verdict,
    this.stamp = 0,
  });

  final Pill? pill;
  final double width;
  final double lean;
  final bool? verdict;
  final double stamp;

  @override
  Widget build(BuildContext context) {
    final Pill? p = pill;
    final l = context.l10n;
    final BoxDecoration face = BoxDecoration(
      color: kArtCream,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: kArtInk, width: 3),
    );
    if (p == null) return DecoratedBox(decoration: face);
    final bool? v = verdict;
    return Container(
      decoration: face,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CardHead(
                pill: p,
                ink: kArtInk,
                labelInk: kArtInk.withValues(alpha: 0.62),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Semantics(
                  liveRegion: v == null,
                  child: ScaledText(
                    text: claimOf(p),
                    min: 17,
                    max: 40,
                    alignment: Alignment.centerLeft,
                    styleFor: (size) => AppText.display(
                      size: size,
                      weight: FontWeight.w600,
                      height: 1.12,
                      spacing: -0.025 * size,
                      color: kArtInk,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // The answer the card leans to, as the finger moves it.
          if (lean.abs() > 0.02 && v == null)
            Positioned(
              top: 0,
              right: lean < 0 ? 0 : null,
              left: lean > 0 ? 0 : null,
              child: Opacity(
                opacity: (lean.abs() * 3).clamp(0.0, 1.0),
                child: _Lean(sayTrue: lean > 0),
              ),
            ),
          if (v != null)
            Center(
              child: Transform.scale(
                scale: stamp,
                child: Semantics(
                  label: v ? l.gameRight : l.gameWrong,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: v ? _right : _wrong,
                      shape: BoxShape.circle,
                      border: Border.all(color: kArtInk, width: 3.5),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      v ? Icons.check_rounded : Icons.close_rounded,
                      size: 62,
                      color: kArtCream,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "True" or "False" in a card's corner, while the finger swipes it.
class _Lean extends StatelessWidget {
  const _Lean({required this.sayTrue});

  final bool sayTrue;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Transform.rotate(
      angle: sayTrue ? -0.12 : 0.12,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
        decoration: BoxDecoration(
          color: sayTrue ? kArtInk : kArtCream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kArtInk, width: 2.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sayTrue ? Icons.check_rounded : Icons.close_rounded,
              size: 18,
              color: sayTrue ? kArtCream : kArtInk,
            ),
            const SizedBox(width: 4),
            Text(
              upper(context, sayTrue ? l.sayTrue : l.sayFalse),
              style: AppText.label(
                size: 13,
                weight: FontWeight.w800,
                spacing: 1,
                color: sayTrue ? kArtCream : kArtInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The round as squares, one a claim: green right, coral wrong, open not
/// answered. What the score is sent as, too.
class _Squares extends StatelessWidget {
  const _Squares({required this.round, required this.ink});

  final SixtyRound round;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        children: [
          for (int i = 0; i < round.pills.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 40),
                  decoration: BoxDecoration(
                    color: switch (round.rightAt(i)) {
                      true => _right,
                      false => _wrong,
                      null => kArtCream,
                    },
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: kArtInk, width: 2.4),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    switch (round.rightAt(i)) {
                      true => Icons.check_rounded,
                      false => Icons.close_rounded,
                      null => Icons.remove_rounded,
                    },
                    size: 20,
                    color: round.rightAt(i) == null ? kArtInk : kArtCream,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The challenge after this one: its colour, its picture, its name, a tap
/// away.
class _NextCard extends StatelessWidget {
  const _NextCard({required this.look, required this.onTap});

  final ChallengeLook look;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = look.ink;
    // Half as large again at most: the card shares its row with a picture
    // and an arrow.
    final TextScaler scaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: 1.5);
    return Semantics(
      button: true,
      label: '${l.gameNext}: ${look.title}',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        key: const ValueKey('sixty-next'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          decoration: BoxDecoration(
            color: look.colour,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kArtInk, width: 3),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: SizedBox(
                  width: 104,
                  height: 78,
                  child: ChallengeArtView(art: look.art, ground: look.colour),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // One line, smaller where it must be: a label broken
                      // in two reads as two words.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          upper(context, l.gameNext),
                          maxLines: 1,
                          textScaler: scaler,
                          style: AppText.label(
                            size: 11,
                            weight: FontWeight.w800,
                            spacing: 1.2,
                            // Small: near full ink, to read on any game's
                            // colour.
                            color: ink.withValues(alpha: 0.86),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        look.title,
                        textScaler: scaler,
                        style: AppText.display(
                          size: 21,
                          weight: FontWeight.w700,
                          height: 1.05,
                          spacing: -0.4,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: kArtInk,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 22,
                    color: look.colour,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The eight claims again, on a card of paper: each as it was said, right
/// or wrong, and what it is. A tap opens its card, where the why is.
class _Review extends StatelessWidget {
  const _Review({required this.round, required this.onOpen});

  final SixtyRound round;
  final ValueChanged<Pill> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final List<Pill> pills = round.pills;
    return Container(
      decoration: BoxDecoration(
        color: kArtCream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kArtInk, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < pills.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1.5,
                color: kArtInk.withValues(alpha: 0.12),
              ),
            Builder(
              builder: (context) {
                final Pill p = pills[i];
                final bool? right = round.rightAt(i);
                final bool truth = trueOrFalseAnswer(p);
                final String verdict = switch (right) {
                  true => l.gameRight,
                  false => l.gameWrong,
                  null => l.gameUnanswered,
                };
                final String said = truth ? l.sayTrue : l.sayFalse;
                return Semantics(
                  button: true,
                  label: '${claimOf(p)} $said. $verdict.',
                  excludeSemantics: true,
                  onTap: () => onOpen(p),
                  child: InkWell(
                    key: ValueKey('sixty-miss-${p.id}'),
                    onTap: () => onOpen(p),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: switch (right) {
                                true => _right,
                                false => _wrong,
                                null => kArtCream,
                              },
                              shape: BoxShape.circle,
                              border: Border.all(color: kArtInk, width: 2.2),
                            ),
                            child: Icon(
                              switch (right) {
                                true => Icons.check_rounded,
                                false => Icons.close_rounded,
                                null => Icons.remove_rounded,
                              },
                              size: 17,
                              color: right == null ? kArtInk : kArtCream,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              claimOf(p),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body(
                                size: 14.5,
                                weight: FontWeight.w600,
                                height: 1.3,
                                color: kArtInk,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: truth ? kArtInk : kArtCream,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: kArtInk, width: 1.8),
                            ),
                            child: Text(
                              upper(context, said),
                              style: AppText.label(
                                size: 10.5,
                                weight: FontWeight.w800,
                                spacing: 0.8,
                                height: 1,
                                color: truth ? kArtCream : kArtInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
