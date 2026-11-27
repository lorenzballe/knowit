/// A challenge on a screen of its own, opened from its tile among Explore's
/// challenges: the tile's panel grows into the app's own page
/// (challengeFlight), and the challenge is taken there in three moments,
/// each the whole screen, set as a page is: one composition the height of
/// the phone, the way out in the screen's corner inside the safe area and
/// the head one line level with it — never a card floating in the screen
/// with the cross outside it and a band of nothing (the owner's iPhone,
/// November 2026).
///
/// - What it is: its mark, the skill it trains, the name, a sentence or two
///   on what it measures and why that matters, the reader's own figures,
///   and Begin.
/// - The round: a running head — the mark, the name, how far along — and a
///   fine rule under it, then the challenge itself, content first, with
///   precise controls; each answer told by a calm colour and a short
///   phrase.
/// - How it went: a short report — the score, the figures (accuracy, the
///   time where it counts, the best), a measured line reading them,
///   "personal best" in words where it is one, the cards again, the next
///   challenge, and another round or when the next comes, and the score to
///   send.
///
/// The screen is the same for every challenge ([ChallengeScreen]); what is
/// taken on it is the challenge's own ([ChallengeGame]), kept and counted
/// as on its shelf: opened again the same day, the screen opens on how it
/// went, or where the reader left off.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../models/pill.dart' show Pill;
import '../../theme.dart';
import 'challenge_kit.dart';
import 'challenge_marks.dart';
import 'challenges.dart';
import 'parts.dart' show upper, winColor;

/// The three moments of a challenge's screen.
enum GameMoment { intro, play, result }

/// What a challenge's round is given to be played with: the screen it is
/// on, the way to the end, and a voice.
@immutable
class GameKit {
  const GameKit({
    required this.id,
    required this.look,
    required this.room,
    required this.palette,
    required this.calm,
    required this.finish,
    required this.say,
    this.ticking,
    this.markTime,
  });

  /// The game's keys' prefix.
  final String id;
  final ChallengeLook look;
  final ChallengeRoom room;

  /// The app's palette, which the screen is on.
  final Palette palette;

  /// Whether the reader asked for less motion.
  final bool calm;

  /// Ends the round, after a beat for the last answer to land.
  final void Function({Duration after}) finish;

  /// Says a verdict to a screen reader.
  final ValueChanged<String> say;

  /// What moves the mark's hand while the round is played, and where it
  /// stands.
  final Listenable? ticking;
  final double Function()? markTime;

  /// The words' ink, and the page.
  Color get ink => palette.ink;
  Color get ground => palette.surface;

  /// The challenge's tone, on this page.
  Color get accent => look.tone.on(palette);

  /// [ms], or nothing for a reader who asked for less motion.
  Duration motion(int ms) => calm ? Duration.zero : Duration(milliseconds: ms);
}

/// How a round went, as its last moment shows it.
@immutable
class GameOutcome {
  const GameOutcome({
    required this.score,
    required this.label,
    required this.line,
    this.of,
    this.best,
    this.figures = const [],
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

  /// The reading of it, in a measured line.
  final String line;

  /// "Personal best", where the round set one.
  final String? best;

  /// The round's figures: the accuracy, the time where it counts, the best.
  final List<ChallengeFigure> figures;

  /// The round at a glance.
  final Widget? board;

  /// The cards again, under their heading.
  final String? reviewTitle;
  final List<GameReviewItem> review;
}

/// A challenge, as its screen plays it: what it says before, the round,
/// and how it went. It tells the screen when anything changes.
abstract class ChallengeGame extends ChangeNotifier {
  /// The prefix of its keys: `sixty`, whose Begin is `sixty-play`.
  String get id;

  /// Whether the day's round is over: the screen opens on how it went.
  bool get over;

  /// What it measures and why it matters, or how it is taken: a sentence
  /// or two.
  String rules(AppLocalizations l);

  /// What the first moment says under the rules — how the challenge counts
  /// — with its mark, or nothing.
  (IconData, String)? note(AppLocalizations l) => null;

  /// The reader's own figures, shown before the round: the best.
  List<ChallengeFigure> figures(AppLocalizations l) => const [];

  /// The day's round, a turn to a row — the cards each turn is played
  /// with — as the first moment lists it under Today.
  List<List<Pill>> get today => const [];

  /// Each turn's verdict, where the round is under way: right, wrong, or
  /// not yet.
  List<bool?> get todayMarks => const [];

  /// The first moment's button: Begin, or Continue on a round begun.
  String playLabel(AppLocalizations l) => l.gamePlay;

  /// Given once the screen is up, for a challenge that keeps time.
  void attach(TickerProvider vsync) {}

  /// Begin was pressed: the round begins, or goes on.
  void start();

  /// The round's moment is in front of the reader, [calm] where they asked
  /// for less motion: for a challenge whose clock starts with it.
  void started({required bool calm}) {}

  /// The round.
  Widget play(BuildContext context, GameKit kit);

  /// How it went.
  GameOutcome outcome(BuildContext context, GameKit kit);

  /// Where the mark's hand stands in [moment]: Sixty seconds' time.
  double markTime(GameMoment moment) => 0.25;

  /// What moves the mark's hand while the round is played.
  Listenable? get ticking => null;

  /// Whether another round can be taken today. A challenge whose answers
  /// are the cards' own is taken once a day.
  bool get replays => false;

  /// Sends the score on.
  Future<void> share(BuildContext context);

  /// The screen is going while the round is played.
  void leave() {}
}

/// A challenge, taken on the whole screen.
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({
    super.key,
    required this.game,
    required this.look,
    required this.heroTag,
    this.next,
    this.onNext,
  });

  /// What is taken. The screen keeps it for as long as it is open, and
  /// lets it go after.
  final ChallengeGame game;

  /// The tile's words, tone and mark.
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

  /// The route's own animation: the words come once the page has grown,
  /// and go before it shrinks back.
  Animation<double>? _route;
  bool _up = false;
  bool _going = false;

  @override
  void initState() {
    super.initState();
    _game.attach(this);
    _moment = _game.over ? GameMoment.result : GameMoment.intro;
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
    super.dispose();
  }

  bool get _calm => MediaQuery.disableAnimationsOf(context);

  void _goTo(GameMoment moment) => setState(() => _moment = moment);

  void _play() {
    _game.start();
    _goTo(GameMoment.play);
    _game.started(calm: _calm);
  }

  Future<void> _finish({Duration after = Duration.zero}) async {
    if (after > Duration.zero && !_calm) {
      await Future<void>.delayed(after);
    }
    if (!mounted || _moment == GameMoment.result) return;
    _goTo(GameMoment.result);
  }

  void _close() {
    if (_moment == GameMoment.play) _game.leave();
    Navigator.of(context).maybePop();
  }

  GameKit _kit(ChallengeRoom room, Palette palette) => GameKit(
    id: _id,
    look: widget.look,
    room: room,
    palette: palette,
    calm: _calm,
    finish: ({Duration after = Duration.zero}) => _finish(after: after),
    say: (message) => announceGame(context, message),
    ticking: _game.ticking,
    markTime: () => _game.markTime(_moment),
  );

  Duration _motion(int ms) =>
      _calm ? Duration.zero : Duration(milliseconds: ms);

  @override
  Widget build(BuildContext context) {
    final MediaQueryData m = MediaQuery.of(context);
    final ChallengeRoom room = ChallengeRoom(m.size, m.padding);
    final Palette p = context.p;
    final Animation<double> route =
        ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // What the tile opened over, dimmed as the page grows.
            Positioned.fill(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: route,
                  child: const ColoredBox(color: Color(0x52000000)),
                ),
              ),
            ),
            Positioned.fill(
              child: Hero(
                tag: widget.heroTag,
                createRectTween: challengeRectTween,
                flightShuttleBuilder: challengeFlight,
                child: ChallengeGround(
                  key: ValueKey('$_id-ground'),
                  colour: widget.look.tone.page(p),
                ),
              ),
            ),
            Positioned.fill(
              child: Visibility(
                visible: !_going,
                maintainState: true,
                // The words come in once the page has grown, rising a
                // little into place.
                child: AnimatedOpacity(
                  opacity: _up ? 1 : 0,
                  duration: _motion(200),
                  curve: Curves.easeOut,
                  child: AnimatedSlide(
                    offset: _up ? Offset.zero : const Offset(0, 0.01),
                    duration: _motion(220),
                    curve: Curves.easeOutCubic,
                    child: IgnorePointer(
                      ignoring: !_up,
                      child: ChallengeToneScope(
                        tone: widget.look.tone,
                        child: _moments(context, room, p),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // The way out comes with the words, once the screen is up.
            Positioned(
              top: room.top + 2,
              right: 12,
              child: Visibility(
                visible: !_going,
                child: AnimatedOpacity(
                  opacity: _up ? 1 : 0,
                  duration: _motion(200),
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
    );
  }

  Widget _moments(BuildContext context, ChallengeRoom room, Palette p) {
    final GameKit kit = _kit(room, p);
    final Widget shown = switch (_moment) {
      GameMoment.intro => _intro(context, room, p),
      GameMoment.play => _game.play(context, kit),
      GameMoment.result => _result(context, kit),
    };
    return AnimatedSwitcher(
      duration: _motion(220),
      // The moment going is gone quickly, so the two never read as one.
      reverseDuration: _motion(150),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOut,
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.012),
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

  Widget _intro(BuildContext context, ChallengeRoom room, Palette p) {
    final l = context.l10n;
    final ChallengeLook look = widget.look;
    final (IconData, String)? note = _game.note(l);
    final List<ChallengeFigure> rows = [
      if (note != null) (label: note.$2, value: ''),
      ..._game.figures(l),
    ];
    // One composition the height of the screen, as a page of a magazine
    // is set: the skill at its head, level with the way out; the name
    // large; what it asks and what it measures; then the day's round, a
    // turn to a row, and the reader's figures, over Begin. No card inside
    // the screen, and no band of nothing: the type and the rows take the
    // room the phone has (_IntroFit).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChallengeRunningHead(
          id: _id,
          room: room,
          skill: look.skill,
          mark: look.mark,
        ),
        Expanded(
          child: _IntroPage(
            id: _id,
            title: look.title,
            rules: _game.rules(l),
            today: _game.today,
            marks: _game.todayMarks,
            figures: rows,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, room.foot),
          child: GameButton.primary(
            key: ValueKey('$_id-play'),
            label: _game.playLabel(l),
            onTap: _play,
          ),
        ),
      ],
    );
  }

  // ── How it went ───────────────────────────────────────────────────────

  Widget _result(BuildContext context, GameKit kit) {
    final l = context.l10n;
    final Palette p = kit.palette;
    final ChallengeRoom room = kit.room;
    final GameOutcome out = _game.outcome(context, kit);
    final ChallengeLook? next = widget.next;
    final String? of = out.of;
    final String? best = out.best;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    // The score, large, on the page itself under the head: the skill it
    // counts over it, how it went beside it where the round set a best,
    // and the reading, the figures and the round at a glance under it.
    final Widget score = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameLabel(widget.look.skill),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Semantics(
              container: true,
              label: out.label,
              excludeSemantics: true,
              child: _ScoreCount(
                score: out.score,
                calm: kit.calm,
                builder: (shown) => Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: shown,
                        style:
                            AppText.display(
                              size: out.score.length > 3 ? 76 : 104,
                              weight: FontWeight.w600,
                              height: 1,
                              spacing: -2.5,
                              color: p.ink,
                            ).copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                      if (of != null)
                        TextSpan(
                          text: ' / $of',
                          style: AppText.display(
                            size: 36,
                            weight: FontWeight.w600,
                            height: 1,
                            spacing: -0.5,
                            color: p.inkMuted,
                          ),
                        ),
                    ],
                  ),
                  key: ValueKey('$_id-score'),
                  textScaler: scaler.clamp(maxScaleFactor: 1.2),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (best != null)
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.bottomEnd,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PersonalBest(
                      key: ValueKey('$_id-best'),
                      text: best,
                      calm: kit.calm,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          out.line,
          key: ValueKey('$_id-line'),
          textScaler: scaler.clamp(maxScaleFactor: 1.4),
          style: AppText.display(
            size: 19,
            weight: FontWeight.w600,
            height: 1.25,
            spacing: -0.2,
            color: p.ink.withValues(alpha: 0.9),
          ),
        ),
        if (out.figures.isNotEmpty) ...[
          const SizedBox(height: 14),
          ChallengeFigures(rows: out.figures, bare: true),
        ],
        if (out.board case final Widget board) ...[
          SizedBox(height: out.figures.isEmpty ? 18 : 6),
          board,
        ],
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChallengeRunningHead(id: _id, title: widget.look.title, room: room),
        // The report is the page: the score at its top, the cards again
        // under it, a row each, and the next challenge; where it is
        // shorter than the room, what is left goes between the score and
        // the cards, and where it is longer, it scrolls under the head,
        // fading at the edges rather than cut at a line.
        Expanded(
          child: ChallengeScroll(
            scrollKey: ValueKey('$_id-end'),
            children: [
              score,
              const ChallengeSpring(min: 28),
              if (out.review.isNotEmpty)
                GameReview(
                  items: out.review,
                  label: out.reviewTitle ?? l.gameReview,
                  bare: true,
                ),
              if (next != null && widget.onNext != null) ...[
                const SizedBox(height: 26),
                GameLabel(l.gameNext),
                const SizedBox(height: 10),
                GameNextCard(id: _id, look: next, onTap: widget.onNext!),
              ],
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, room.foot),
          child: Row(
            children: [
              Expanded(
                child: _game.replays
                    ? GameButton.primary(
                        key: ValueKey('$_id-again'),
                        label: l.challengeAgain,
                        onTap: _play,
                      )
                    : _Tomorrow(key: ValueKey('$_id-tomorrow')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameButton.plain(
                  key: ValueKey('$_id-share'),
                  label: l.share,
                  icon: Icons.ios_share_rounded,
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

/// The score, counted up to once as the report comes in: briefly, slowing
/// as it lands, and at once for a reader who asked for less motion. A
/// score that is not a whole number is shown as it is.
class _ScoreCount extends StatelessWidget {
  const _ScoreCount({
    required this.score,
    required this.calm,
    required this.builder,
  });

  final String score;
  final bool calm;
  final Widget Function(String shown) builder;

  @override
  Widget build(BuildContext context) {
    final Match? m = RegExp(r'^([+\u2212-]?)(\d{1,4})$').firstMatch(score);
    if (m == null || calm) return builder(score);
    final String sign = m.group(1)!;
    final int to = int.parse(m.group(2)!);
    if (to == 0) return builder(score);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: to.toDouble()),
      duration: Duration(milliseconds: (420 + 40 * to).clamp(420, 900)),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => builder('$sign${v.round()}'),
    );
  }
}

/// A round that beat the reader's best: said as the app says a gain, a
/// small green pill, coming in once.
class _PersonalBest extends StatelessWidget {
  const _PersonalBest({super.key, required this.text, required this.calm});

  final String text;
  final bool calm;

  @override
  Widget build(BuildContext context) {
    final Color green = winColor(context);
    final Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppText.body(
          size: 12.5,
          weight: FontWeight.w700,
          height: 1.1,
          color: green,
        ),
      ),
    );
    if (calm) return pill;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
      ),
      child: pill,
    );
  }
}

/// Where another round stands on a challenge taken once a day: when the
/// next round comes. Words, not a button.
class _Tomorrow extends StatelessWidget {
  const _Tomorrow({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      alignment: Alignment.center,
      child: Text(
        l.gameTomorrow,
        textAlign: TextAlign.center,
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4),
        style: AppText.body(
          size: 13.5,
          weight: FontWeight.w600,
          height: 1.25,
          color: p.inkMuted,
        ),
      ),
    );
  }
}

/// The head of a challenge's screen, the same on every moment of every
/// challenge: one line under the status bar, level with the way out in the
/// screen's corner, never a band of its own. It carries the name in the
/// app's serif and how far along, as the app's pages carry theirs; or,
/// over a moment that sets the name large itself, the skill the challenge
/// trains, in small capitals beside its mark.
class ChallengeRunningHead extends StatelessWidget {
  const ChallengeRunningHead({
    super.key,
    required this.id,
    required this.room,
    this.title,
    this.count,
    this.skill,
    this.mark,
  });

  final String id;
  final ChallengeRoom room;
  final String? title;
  final String? count;

  /// The skill, where the head carries it instead of the name.
  final String? skill;
  final ChallengeMark? mark;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final String? count = this.count;
    final String? skill = this.skill;
    final ChallengeMark? mark = this.mark;
    final TextScaler scaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: 1.3);
    if (skill != null) {
      return Padding(
        padding: EdgeInsets.only(top: room.top, left: 20, right: 70),
        child: SizedBox(
          height: room.head - room.top,
          child: Row(
            children: [
              if (mark != null) ...[
                ChallengeMarkView(mark: mark, colour: p.inkMuted, size: 15),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  upper(context, skill),
                  key: ValueKey('$id-skill'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: scaler,
                  style: AppText.label(
                    size: 11,
                    spacing: 1.4,
                    color: p.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(top: room.top, left: 20, right: 70),
      child: SizedBox(
        height: room.head - room.top,
        child: Row(
          children: [
            // The name whole: a long one ("Platziere deinen Einsatz" beside
            // "1 von 4" on a small phone) gives way by a size or two rather
            // than lose its end to an ellipsis.
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final String name = title ?? '';
                  TextStyle style(double size) => AppText.display(
                    size: size,
                    weight: FontWeight.w600,
                    height: 1.1,
                    spacing: -0.4 * size / 22,
                    color: p.ink,
                  );
                  final TextPainter t = TextPainter(
                    text: TextSpan(
                      text: name,
                      style: DefaultTextStyle.of(context).style
                          .merge(style(22)),
                    ),
                    textDirection: Directionality.of(context),
                    textScaler: scaler,
                    maxLines: 1,
                  )..layout();
                  final double wide = t.width;
                  t.dispose();
                  final double size = wide <= box.maxWidth || wide == 0
                      ? 22
                      : (22 * box.maxWidth / wide * 0.98).clamp(16.0, 22.0);
                  return Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textScaler: scaler,
                    style: style(size),
                  );
                },
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 10),
              Text(
                count,
                key: ValueKey('$id-count'),
                textScaler: scaler,
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w700,
                  height: 1,
                  color: p.inkMuted,
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A round's own page, as every challenge lays it out: the head, the
/// round's bars where it has them, what the challenge says there
/// ([status]), the challenge, and its controls at the foot.
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
    final List<bool?>? marks = this.marks;
    const EdgeInsets side = EdgeInsets.symmetric(horizontal: 20);
    return Padding(
      padding: EdgeInsets.only(bottom: room.foot),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChallengeRunningHead(
            id: kit.id,
            title: kit.look.title,
            room: room,
            count: count,
          ),
          if (marks != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GameSegments(id: kit.id, marks: marks, at: at),
            ),
          ],
          if (status case final Widget s) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: s,
            ),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: Padding(padding: side, child: body),
          ),
          if (actions case final Widget a) ...[
            const SizedBox(height: 14),
            Padding(padding: side, child: a),
          ],
        ],
      ),
    );
  }
}

/// A flexible gap in a [ChallengeScroll]: at least [min], and the room the
/// moment leaves on a phone it is shorter than.
class ChallengeSpring extends StatelessWidget {
  const ChallengeSpring({super.key, this.min = 0});

  final double min;

  @override
  Widget build(BuildContext context) => Expanded(child: SizedBox(height: min));
}

/// What a moment shows under its head, the height of the room it has: set
/// in a column whose [ChallengeSpring]s take what is left on a phone it is
/// shorter than; on one it is longer than, it scrolls under the head,
/// fading at its edges rather than cut at a line.
class ChallengeScroll extends StatelessWidget {
  const ChallengeScroll({
    super.key,
    required this.children,
    this.scrollKey,
    this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 14),
  });

  final List<Widget> children;

  /// The scrolling part's key: `<id>-end` on the report.
  final Key? scrollKey;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (r) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0x00FFFFFF),
          Colors.white,
          Colors.white,
          Color(0x00FFFFFF),
        ],
        stops: [
          0,
          (padding.top / r.height).clamp(0.0, 0.5),
          1 - (padding.bottom / r.height).clamp(0.0, 0.5),
          1,
        ],
      ).createShader(r),
      child: SingleChildScrollView(
        key: scrollKey,
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (box.maxHeight - padding.vertical).clamp(
              0.0,
              double.infinity,
            ),
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    ),
  );
}

/// How the first moment is set on the room it has: the name's size and
/// the words', a row of the day's round, and what is left between the
/// words and the round. Chosen the way a card of the day sets its question:
/// the largest type that leaves the rows a comfortable height; then the
/// rows grown to their most; then a pause between the words and the round,
/// up to a measure; and only what is left after that above the name and
/// under the round alike, so the page is composed, never a band of nothing
/// in one place. Where even the least of it is taller than the room, it
/// scrolls.
@immutable
class _IntroFit {
  const _IntroFit({
    required this.title,
    required this.rules,
    required this.row,
    required this.gap,
    required this.top,
    required this.bottom,
    required this.scrolls,
  });

  /// The name's size, and the words'.
  final double title;
  final double rules;

  /// A row of the day's round.
  final double row;

  /// Between the words and the round.
  final double gap;

  /// Over the name, and under the round.
  final double top;
  final double bottom;
  final bool scrolls;

  /// The sizes tried for the name and the words, largest first.
  static const List<(double, double)> sizes = [
    (60, 22),
    (56, 22),
    (52, 22),
    (48, 21.5),
    (44, 21),
    (40, 20),
    (37, 19),
    (34, 18),
    (31, 17),
  ];

  /// Over the name, and under the round, at the least.
  static const double topLeast = 4;
  static const double bottomLeast = 6;

  /// Between the name and the words.
  static const double afterTitle = 14;

  /// Between the words and the round: at the least, and at the most before
  /// what is left goes above and below.
  static const double gapLeast = 28;
  static const double gapMost = 64;

  static TextStyle titleStyle(double size, Color colour) => AppText.display(
    size: size,
    weight: FontWeight.w600,
    height: 1.04,
    spacing: -size * 0.024,
    color: colour,
  );

  static TextStyle rulesStyle(double size, Color colour) => AppText.body(
    size: size,
    weight: FontWeight.w500,
    height: 1.45,
    color: colour,
  );

  /// A row of a round of [n] at its least, at ease, and at its most, never
  /// shorter than its words ([text]) with room round them.
  static (double, double, double) rows(int n, double text) {
    final (double least, double ease, double most) = n >= 7
        ? (36.0, 42.0, 50.0)
        : n >= 5
        ? (42.0, 50.0, 58.0)
        : n == 4
        ? (48.0, 56.0, 66.0)
        : (54.0, 64.0, 76.0);
    final double floor = text + 14;
    return (
      least < floor ? floor : least,
      ease < floor ? floor : ease,
      most < floor ? floor : most,
    );
  }

  static _IntroFit of(
    BuildContext context, {
    required double width,
    required double height,
    required String title,
    required String rules,
    required int rounds,
    required int figures,
  }) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextScaler titleScaler = scaler.clamp(maxScaleFactor: 1.3);
    final TextDirection direction = Directionality.of(context);
    // Measured as the words are drawn: in the style they inherit, which
    // carries its own spacing, under the one set for them.
    final TextStyle inherited = DefaultTextStyle.of(context).style;
    const Color ink = Color(0xFF000000);

    double measure(String text, TextStyle style, TextScaler s) {
      final TextPainter t = TextPainter(
        text: TextSpan(text: text, style: inherited.merge(style)),
        textDirection: direction,
        textScaler: s,
      )..layout(maxWidth: width);
      final double h = t.height;
      t.dispose();
      return h;
    }

    // A name whose longest word is wider than the page is never set at
    // that size: a word is not broken.
    bool wordsFit(double size) {
      for (final String word in title.split(RegExp(r'\s+'))) {
        if (word.isEmpty) continue;
        final TextPainter t = TextPainter(
          text: TextSpan(
            text: word,
            style: inherited.merge(titleStyle(size, ink)),
          ),
          textDirection: direction,
          textScaler: titleScaler,
          maxLines: 1,
        )..layout();
        final double w = t.width;
        t.dispose();
        if (w > width) return false;
      }
      return true;
    }

    final double label = rounds > 0
        ? scaler.clamp(maxScaleFactor: 1.4).scale(10.5) * 1.3 + 8
        : 0;
    final double figure = 22 + scaler.scale(15) * 1.3 + 1;
    final double rowText =
        scaler
            .clamp(maxScaleFactor: 1.5)
            .scale(ChallengeDeck.textSize(rounds)) *
        1.25;
    final (double least, double ease, double most) = rows(rounds, rowText);
    double need(double titleH, double rulesH, double row) =>
        topLeast +
        titleH +
        afterTitle +
        rulesH +
        gapLeast +
        label +
        rounds * (row + 1) +
        figures * figure +
        bottomLeast;

    double titleSize = sizes.last.$1, rulesSize = sizes.last.$2;
    double titleH = 0, rulesH = 0;
    bool found = false;
    for (final (double t, double r) in sizes) {
      final bool last = t == sizes.last.$1;
      if (!last && !wordsFit(t)) continue;
      titleSize = t;
      rulesSize = r;
      titleH = measure(title, titleStyle(t, ink), titleScaler);
      rulesH = measure(rules, rulesStyle(r, ink), scaler);
      // The largest sizes only for a name of two lines at most.
      final double lines = titleH / titleScaler.scale(t * 1.04);
      if (!last && lines > (t > 52 ? 2.2 : 3.2)) continue;
      if (need(titleH, rulesH, ease) <= height) {
        found = true;
        break;
      }
    }
    double row = ease;
    double spare = height - need(titleH, rulesH, row);
    if (!found && spare < 0 && rounds > 0) {
      // The rows give way first, down to their least.
      final double give = (-spare / rounds).clamp(0.0, ease - least);
      row = ease - give;
      spare = height - need(titleH, rulesH, row);
    }
    if (spare < 0) {
      return _IntroFit(
        title: titleSize,
        rules: rulesSize,
        row: row,
        gap: gapLeast,
        top: topLeast,
        bottom: bottomLeast,
        scrolls: true,
      );
    }
    if (rounds > 0) {
      final double grow = (spare / rounds).clamp(0.0, most - row);
      row += grow;
      spare -= grow * rounds;
    }
    final double pause = spare.clamp(0.0, gapMost - gapLeast);
    spare -= pause;
    return _IntroFit(
      title: titleSize,
      rules: rulesSize,
      row: row,
      gap: gapLeast + pause,
      top: topLeast + spare / 2,
      bottom: bottomLeast + spare / 2,
      scrolls: false,
    );
  }
}

/// The first moment's page under its head: the name, what it asks and
/// what it measures, the day's round and the reader's figures, set as
/// [_IntroFit] has them for the room.
class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.id,
    required this.title,
    required this.rules,
    required this.today,
    required this.marks,
    required this.figures,
  });

  final String id;
  final String title;
  final String rules;
  final List<List<Pill>> today;
  final List<bool?> marks;
  final List<ChallengeFigure> figures;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        const double side = 20;
        final _IntroFit fit = _IntroFit.of(
          context,
          width: box.maxWidth - 2 * side,
          height: box.maxHeight,
          title: title,
          rules: rules,
          rounds: today.length,
          figures: figures.length,
        );
        final List<Widget> words = [
          Semantics(
            header: true,
            child: Text(
              title,
              key: ValueKey('$id-title'),
              textScaler: scaler.clamp(maxScaleFactor: 1.3),
              style: _IntroFit.titleStyle(fit.title, p.ink),
            ),
          ),
          const SizedBox(height: _IntroFit.afterTitle),
          Text(
            rules,
            key: ValueKey('$id-rules'),
            style: _IntroFit.rulesStyle(
              fit.rules,
              p.ink.withValues(alpha: 0.86),
            ),
          ),
        ];
        final List<Widget> round = [
          if (today.isNotEmpty) ...[
            GameLabel(l.challengeToday),
            const SizedBox(height: 8),
            ChallengeDeck(
              key: ValueKey('$id-today'),
              rounds: today,
              marks: marks,
              row: fit.row,
            ),
          ],
          if (figures.isNotEmpty)
            ChallengeFigures(
              key: ValueKey('$id-record'),
              rows: figures,
              bare: true,
            ),
        ];
        if (fit.scrolls) {
          return ChallengeScroll(
            padding: const EdgeInsets.fromLTRB(side, 4, side, 10),
            children: [
              ...words,
              const ChallengeSpring(min: _IntroFit.gapLeast),
              ...round,
            ],
          );
        }
        return Padding(
          padding: EdgeInsets.fromLTRB(side, fit.top, side, fit.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...words,
              // The pause the measure chose; a word measured a hair short
              // takes from it rather than push the round off the page.
              Flexible(child: SizedBox(height: fit.gap)),
              ...round,
            ],
          ),
        );
      },
    );
  }
}
