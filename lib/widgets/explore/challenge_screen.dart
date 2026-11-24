/// A challenge on a screen of its own, opened from its tile among Explore's
/// challenges: the tile grows into the whole screen in the game's colour
/// (challengeFlight), and the game is played there in three moments, each
/// the whole screen.
///
/// - What it is: the name, large; the game's picture; the rules in a line;
///   the record, or how the game counts; a large Play.
/// - The round: the picture gone up into the head, beside how far along,
///   and below it the game itself, shaped to what it asks — a deck, a
///   pair, a track, a staircase, a dial — with large targets, felt in the
///   hand, each answer told at once.
/// - How it went: the score, large; a new record, or the one standing; the
///   round as squares; the next challenge; the cards again, each as it
///   went, a tap from its card; Play again where the game plays again, and
///   the score to send.
///
/// The screen is the same for every game ([ChallengeScreen]); what is
/// played on it is the game's own ([ChallengeGame]), kept and counted as
/// on its shelf: opened again the same day, the screen opens on how it
/// went, or where the reader left off.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../theme.dart';
import 'challenge_art.dart';
import 'challenge_kit.dart';
import 'challenges.dart';
import 'parts.dart' show upper;

/// The three moments of a challenge's screen.
enum GameMoment { intro, play, result }

/// What a game's round is given to be played with: the screen it is on,
/// the way to the end, and a voice.
@immutable
class GameKit {
  const GameKit({
    required this.id,
    required this.look,
    required this.room,
    required this.calm,
    required this.finish,
    required this.say,
  });

  /// The game's keys' prefix.
  final String id;
  final ChallengeLook look;
  final ChallengeRoom room;

  /// Whether the reader asked for less motion.
  final bool calm;

  /// Ends the round: after a beat for the last answer to land, cheered
  /// with a burst of paper when [cheer] — a record, or all right.
  final void Function({bool cheer, Duration after}) finish;

  /// Says a verdict to a screen reader.
  final ValueChanged<String> say;

  Color get ink => look.ink;
  Color get ground => look.colour;

  /// [ms], or nothing for a reader who asked for less motion.
  Duration motion(int ms) =>
      calm ? Duration.zero : Duration(milliseconds: ms);
}

/// How a round went, as its last moment shows it.
@immutable
class GameOutcome {
  const GameOutcome({
    required this.score,
    required this.label,
    required this.line,
    this.of,
    this.chips = const [],
    this.board,
    this.reviewTitle,
    this.review = const [],
  });

  /// The score, large: "6", "+40".
  final String score;

  /// What it is out of, smaller beside it: "8". None where it is out of
  /// nothing.
  final String? of;

  /// The score as a screen reader says it.
  final String label;

  /// The line under it.
  final String line;

  /// The record, or what the round came to besides.
  final List<Widget> chips;

  /// The round at a glance: its squares.
  final Widget? board;

  /// The cards again, under their heading.
  final String? reviewTitle;
  final List<GameReviewItem> review;
}

/// A game, as its screen plays it: what it says before, the round, and how
/// it went. It tells the screen when anything changes.
abstract class ChallengeGame extends ChangeNotifier {
  /// The prefix of its keys: `sixty`, whose Play is `sixty-play`.
  String get id;

  /// Whether the day's round is over: the screen opens on how it went.
  bool get over;

  /// The rules, in a line.
  String rules(AppLocalizations l);

  /// What the first moment says under the rules — the record, or how the
  /// game counts — with its mark, or nothing.
  (IconData, String)? note(AppLocalizations l) => null;

  /// The first moment's button: Play, or Continue on a round begun.
  String playLabel(AppLocalizations l) => l.gamePlay;

  /// Given once the screen is up, for a game that keeps time.
  void attach(TickerProvider vsync) {}

  /// Play was pressed: the round begins, or goes on.
  void start();

  /// The round's moment is in front of the reader, [calm] where they asked
  /// for less motion: for a game whose clock starts with it.
  void started({required bool calm}) {}

  /// The round.
  Widget play(BuildContext context, GameKit kit);

  /// How it went.
  GameOutcome outcome(BuildContext context, GameKit kit);

  /// Where the picture's hand stands in [moment]: the stopwatch's time.
  double artTime(GameMoment moment) => 0.25;

  /// What moves the picture's hand while the round is played.
  Listenable? get ticking => null;

  /// Whether Play again plays another round today. A game whose answers
  /// are the cards' own plays its round once a day.
  bool get replays => false;

  /// Sends the score on.
  Future<void> share(BuildContext context);

  /// The screen is going while the round is played.
  void leave() {}
}

/// A challenge, played on the whole screen.
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({
    super.key,
    required this.game,
    required this.look,
    required this.heroTag,
    this.next,
    this.onNext,
  });

  /// What is played. The screen keeps it for as long as it is open, and
  /// lets it go after.
  final ChallengeGame game;

  /// The tile's colour, picture and name.
  final ChallengeLook look;

  /// The tile it grew out of, and goes back into.
  final Object heroTag;

  /// The challenge after this one, offered at the end.
  final ChallengeLook? next;
  final VoidCallback? onNext;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with TickerProviderStateMixin {
  ChallengeGame get _game => widget.game;
  String get _id => _game.id;

  late GameMoment _moment;

  /// The picture's glide from one moment's place to the next.
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  Rect? _artFrom;
  Rect _artNow = Rect.zero;
  double _timeFrom = 0.25;
  double _timeNow = 0.25;

  /// The route's own animation: the words come once the tile has grown,
  /// and go before it shrinks back.
  Animation<double>? _route;
  bool _up = false;
  bool _going = false;

  /// How many times a round has been cheered: a new burst each time.
  int _cheers = 0;

  @override
  void initState() {
    super.initState();
    _game.attach(this);
    _moment = _game.over ? GameMoment.result : GameMoment.intro;
    _timeNow = _game.artTime(_moment);
    _game.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
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
    _game.removeListener(_changed);
    _game.dispose();
    _move.dispose();
    super.dispose();
  }

  bool get _calm => MediaQuery.disableAnimationsOf(context);

  /// Moves to [moment], the picture gliding to its place in it.
  void _goTo(GameMoment moment) {
    _artFrom = _artNow;
    _timeFrom = _timeNow;
    setState(() => _moment = moment);
    if (_calm) {
      _move.value = 1;
    } else {
      _move.forward(from: 0);
    }
  }

  void _play() {
    HapticFeedback.mediumImpact();
    _game.start();
    _goTo(GameMoment.play);
    _game.started(calm: _calm);
  }

  Future<void> _finish({
    bool cheer = false,
    Duration after = Duration.zero,
  }) async {
    if (after > Duration.zero && !_calm) {
      await Future<void>.delayed(after);
    }
    if (!mounted || _moment == GameMoment.result) return;
    _goTo(GameMoment.result);
    if (cheer) {
      HapticFeedback.mediumImpact();
      if (!_calm) setState(() => _cheers++);
    }
  }

  void _close() {
    if (_moment == GameMoment.play) _game.leave();
    Navigator.of(context).maybePop();
  }

  GameKit _kit(ChallengeRoom room) => GameKit(
    id: _id,
    look: widget.look,
    room: room,
    calm: _calm,
    finish: ({bool cheer = false, Duration after = Duration.zero}) =>
        _finish(cheer: cheer, after: after),
    say: (message) => announceGame(context, message),
  );

  // ── Where the picture stands ──────────────────────────────────────────

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
    final (IconData, String)? note = _game.note(l);
    return measure(widget.look.title, _titleStyle(ink), _titleScaler(scaler)) +
        12 +
        measure(_game.rules(l), _rulesStyle(ink), scaler) +
        (note == null
            ? 0
            : 18 +
                  math.max(
                    38,
                    measure(note.$2, _chipStyle(ink), scaler) + 18,
                  )) +
        28 +
        _playHeight;
  }

  /// Where the moment has the picture.
  Rect _artFor(BuildContext context, GameMoment moment, ChallengeRoom room) {
    if (moment != GameMoment.intro) return room.emblem;
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

  @override
  Widget build(BuildContext context) {
    final MediaQueryData m = MediaQuery.of(context);
    final ChallengeRoom room = ChallengeRoom(m.size, m.padding);
    final ChallengeLook look = widget.look;
    final bool light =
        ThemeData.estimateBrightnessForColor(look.colour) == Brightness.light;
    final Animation<double> route =
        ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation;
    final Listenable? ticking = _game.ticking;
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
                  animation: ticking == null
                      ? _move
                      : Listenable.merge([_move, ticking]),
                  builder: (context, _) {
                    final Rect to = _artFor(context, _moment, room);
                    final double toTime = _game.artTime(_moment);
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
                        key: ValueKey('$_id-ground'),
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
              if (_cheers > 0 && _moment == GameMoment.result && !_going)
                Positioned.fill(
                  child: IgnorePointer(
                    child: GameConfetti(
                      key: ValueKey('$_id-cheer-$_cheers'),
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
                      child: GameClose(id: _id, onTap: _close),
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

  Widget _moments(BuildContext context, ChallengeRoom room) {
    final GameKit kit = _kit(room);
    final Widget shown = switch (_moment) {
      GameMoment.intro => _intro(context, room),
      GameMoment.play => _game.play(context, kit),
      GameMoment.result => _result(context, kit),
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
        key: ValueKey('$_id-moment-${_moment.name}'),
        child: shown,
      ),
    );
  }

  // ── What it is ────────────────────────────────────────────────────────

  Widget _intro(BuildContext context, ChallengeRoom room) {
    final l = context.l10n;
    final ChallengeLook look = widget.look;
    final Color ink = look.ink;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final (IconData, String)? note = _game.note(l);
    final Widget words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: _titleScaler(scaler)),
            child: Text(look.title, style: _titleStyle(ink)),
          ),
        ),
        const SizedBox(height: 12),
        Text(_game.rules(l), style: _rulesStyle(ink)),
        if (note != null) ...[
          const SizedBox(height: 18),
          GameChip(
            key: ValueKey('$_id-record'),
            icon: note.$1,
            label: note.$2,
            ink: ink,
            ground: look.colour,
          ),
        ],
        const SizedBox(height: 28),
        GameButton(
          key: ValueKey('$_id-play'),
          label: _game.playLabel(l),
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

  // ── How it went ───────────────────────────────────────────────────────

  Widget _result(BuildContext context, GameKit kit) {
    final l = context.l10n;
    final ChallengeRoom room = kit.room;
    final ChallengeLook look = widget.look;
    final Color ink = look.ink;
    final GameOutcome out = _game.outcome(context, kit);
    final ChallengeLook? next = widget.next;
    final String? of = out.of;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: room.head,
          child: Padding(
            padding: EdgeInsets.only(
              top: room.top,
              left: room.emblem.right + 4,
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
            key: ValueKey('$_id-end'),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  container: true,
                  label: out.label,
                  excludeSemantics: true,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: out.score,
                          style: AppText.display(
                            size: out.score.length > 3 ? 88 : 112,
                            weight: FontWeight.w700,
                            height: 0.95,
                            spacing: -5,
                            color: ink,
                          ),
                        ),
                        if (of != null)
                          TextSpan(
                            text: ' /$of',
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
                    key: ValueKey('$_id-score'),
                    textScaler: MediaQuery.textScalerOf(
                      context,
                    ).clamp(maxScaleFactor: 1.2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  out.line,
                  key: ValueKey('$_id-line'),
                  style: AppText.body(
                    size: 17,
                    weight: FontWeight.w600,
                    height: 1.3,
                    color: ink.withValues(alpha: 0.82),
                  ),
                ),
                if (out.chips.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: out.chips),
                ],
                if (out.board case final Widget board) ...[
                  const SizedBox(height: 22),
                  board,
                ],
                if (next != null && widget.onNext != null) ...[
                  const SizedBox(height: 26),
                  GameNextCard(id: _id, look: next, onTap: widget.onNext!),
                ],
                if (out.review.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Semantics(
                    header: true,
                    child: Text(
                      upper(context, out.reviewTitle ?? l.gameReview),
                      style: AppText.label(
                        size: 12,
                        weight: FontWeight.w800,
                        spacing: 1.4,
                        color: ink.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GameReview(items: out.review),
                ],
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
                child: _game.replays
                    ? GameButton(
                        key: ValueKey('$_id-again'),
                        label: l.sixtyAgain,
                        icon: Icons.replay_rounded,
                        face: kArtCream,
                        ink: kArtInk,
                        height: 60,
                        onTap: _play,
                      )
                    : _Tomorrow(key: ValueKey('$_id-tomorrow'), ink: ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GameButton(
                  key: ValueKey('$_id-share'),
                  label: l.share,
                  icon: Icons.ios_share_rounded,
                  face: kArtInk,
                  ink: kArtCream,
                  height: 60,
                  onTap: () => _game.share(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Where Play again stands on a game played once a day: when the next
/// round comes. Words, not a button.
class _Tomorrow extends StatelessWidget {
  const _Tomorrow({super.key, required this.ink});

  final Color ink;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ink.withValues(alpha: 0.4), width: 2),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 20, color: ink),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              l.gameTomorrow,
              textAlign: TextAlign.center,
              textScaler: MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.4),
              style: AppText.body(
                size: 14,
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
}

/// A round's own head and parts, as every game lays them out: beside the
/// picture what the game says there ([status]) and how far along
/// ([count]); the bars of the round under them; the game; and its
/// buttons at the foot.
class GamePlayFrame extends StatelessWidget {
  const GamePlayFrame({
    super.key,
    required this.kit,
    required this.body,
    this.status,
    this.count,
    this.marks,
    this.at = 0,
    this.actions,
  });

  final GameKit kit;
  final Widget body;
  final Widget? status;
  final String? count;
  final List<bool?>? marks;
  final int at;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final ChallengeRoom room = kit.room;
    final Color ink = kit.ink;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final List<bool?>? marks = this.marks;
    final String? count = this.count;
    return Padding(
      padding: EdgeInsets.only(bottom: room.foot),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: room.top,
              left: room.emblem.right + 2,
              right: 64,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: room.head - room.top),
              child: Row(
                children: [
                  if (status case final Widget s)
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: s,
                      ),
                    )
                  else
                    const Spacer(),
                  if (count != null) ...[
                    const SizedBox(width: 10),
                    Text(
                      count,
                      key: ValueKey('${kit.id}-count'),
                      textScaler: scaler.clamp(maxScaleFactor: 1.6),
                      style: AppText.body(
                        size: 15,
                        weight: FontWeight.w800,
                        height: 1,
                        color: ink,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (marks != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GameSegments(
                id: kit.id,
                marks: marks,
                at: at,
                ink: ink,
                ground: kit.ground,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: body,
            ),
          ),
          if (actions case final Widget a) ...[
            const SizedBox(height: 18),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: a),
          ],
        ],
      ),
    );
  }
}
