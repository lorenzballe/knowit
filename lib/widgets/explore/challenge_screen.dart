/// A challenge on a screen of its own, opened from its tile among Explore's
/// challenges: the tile's panel grows into the app's own page
/// (challengeFlight), and the challenge is taken there in three moments,
/// each the whole screen, set as a page is.
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
import '../../theme.dart';
import 'challenge_kit.dart';
import 'challenges.dart';
import 'parts.dart' show upper;

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
    this.best,
    this.figures = const [],
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

  /// The reading of it, in a measured line.
  final String line;

  /// "Personal best", where the round set one.
  final String? best;

  /// The round's figures: the accuracy, the time where it counts, the best.
  final List<ChallengeFigure> figures;

  /// What the round came to besides.
  final List<Widget> chips;

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
                  colour: p.surface,
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
                      child: _moments(context, room, p),
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
    final Color accent = look.tone.on(p);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final List<ChallengeFigure> figures = _game.figures(l);
    final (IconData, String)? note = _game.note(l);
    final List<ChallengeFigure> rows = figures.isNotEmpty
        ? figures
        : [if (note != null) (label: note.$2, value: '')];
    final Widget words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChallengeRule(colour: accent, width: 24),
        const SizedBox(height: 14),
        Text(
          upper(context, look.skill),
          key: ValueKey('$_id-skill'),
          style: challengeSmallCaps(p.inkMuted, 11),
        ),
        const SizedBox(height: 10),
        Semantics(
          header: true,
          child: Text(
            look.title,
            textScaler: scaler.clamp(maxScaleFactor: 1.3),
            style: AppText.display(
              size: 42,
              weight: FontWeight.w400,
              height: 1.05,
              spacing: -1.1,
              color: p.ink,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          _game.rules(l),
          key: ValueKey('$_id-rules'),
          style: AppText.display(
            size: 18.5,
            weight: FontWeight.w400,
            height: 1.42,
            spacing: -0.1,
            color: p.ink,
          ),
        ),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 30),
          ChallengeFigures(key: ValueKey('$_id-record'), rows: rows),
        ],
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: room.head),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            child: words,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, room.foot),
          child: GameButton.primary(
            key: ValueKey('$_id-play'),
            context: context,
            label: _game.playLabel(l),
            tone: look.tone,
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
    Widget heading(String text) => Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChallengeRule(colour: kit.accent),
          const SizedBox(height: 10),
          Text(
            upper(context, text),
            style: challengeSmallCaps(p.ink, 11),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChallengeRunningHead(kit: kit),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(height: 1, color: p.line),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: ValueKey('$_id-end'),
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
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
                            size: out.score.length > 3 ? 64 : 80,
                            weight: FontWeight.w400,
                            height: 1,
                            spacing: -2.4,
                            color: p.ink,
                          ),
                        ),
                        if (of != null)
                          TextSpan(
                            text: ' / $of',
                            style: AppText.display(
                              size: 30,
                              weight: FontWeight.w400,
                              height: 1,
                              spacing: -0.4,
                              color: p.inkMuted,
                            ),
                          ),
                      ],
                    ),
                    key: ValueKey('$_id-score'),
                    textScaler: scaler.clamp(maxScaleFactor: 1.2),
                  ),
                ),
                if (best != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    key: ValueKey('$_id-best'),
                    children: [
                      Container(width: 18, height: 1.5, color: kit.accent),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          best,
                          style: AppText.body(
                            size: 14,
                            weight: FontWeight.w600,
                            height: 1.25,
                            color: kit.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 26),
                if (out.figures.isNotEmpty) ...[
                  ChallengeFigures(rows: out.figures),
                  const SizedBox(height: 20),
                ],
                Text(
                  out.line,
                  key: ValueKey('$_id-line'),
                  style: AppText.display(
                    size: 18,
                    weight: FontWeight.w400,
                    height: 1.42,
                    spacing: -0.1,
                    color: p.ink,
                  ),
                ),
                if (out.chips.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(spacing: 18, runSpacing: 10, children: out.chips),
                ],
                if (out.board case final Widget board) ...[
                  const SizedBox(height: 20),
                  board,
                ],
                if (out.review.isNotEmpty) ...[
                  const SizedBox(height: 40),
                  heading(out.reviewTitle ?? l.gameReview),
                  const SizedBox(height: 12),
                  GameReview(items: out.review),
                ],
                if (next != null && widget.onNext != null) ...[
                  const SizedBox(height: 40),
                  heading(l.gameNext),
                  const SizedBox(height: 12),
                  GameNextCard(id: _id, look: next, onTap: widget.onNext!),
                ],
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(24, 12, 24, room.foot),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border(top: BorderSide(color: p.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _game.replays
                    ? GameButton.plain(
                        key: ValueKey('$_id-again'),
                        context: context,
                        label: l.challengeAgain,
                        onTap: _play,
                        height: 52,
                        size: 15.5,
                      )
                    : _Tomorrow(key: ValueKey('$_id-tomorrow')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GameButton.plain(
                  key: ValueKey('$_id-share'),
                  context: context,
                  label: l.share,
                  onTap: () => _game.share(context),
                  height: 52,
                  size: 15.5,
                ),
              ),
            ],
          ),
        ),
      ],
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
      constraints: const BoxConstraints(minHeight: 52),
      alignment: Alignment.center,
      child: Text(
        l.gameTomorrow,
        textAlign: TextAlign.center,
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4),
        style: AppText.body(
          size: 13.5,
          weight: FontWeight.w500,
          height: 1.25,
          color: p.inkMuted,
        ),
      ),
    );
  }
}

/// The running head of a round and of its report: the challenge's mark,
/// its name in small capitals, and how far along, level with the close.
class ChallengeRunningHead extends StatelessWidget {
  const ChallengeRunningHead({super.key, required this.kit, this.count});

  final GameKit kit;
  final String? count;

  @override
  Widget build(BuildContext context) {
    final ChallengeRoom room = kit.room;
    final Palette p = kit.palette;
    final String? count = this.count;
    return Padding(
      padding: EdgeInsets.only(top: room.top, left: 24, right: 66),
      child: SizedBox(
        height: room.head - room.top,
        child: Row(
          children: [
            Expanded(
              child: Text(
                upper(context, kit.look.title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.4),
                style: challengeSmallCaps(p.inkMuted, 11),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 10),
              Text(
                count,
                key: ValueKey('${kit.id}-count'),
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.4),
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w600,
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

/// A round's own page, as every challenge lays it out: the running head
/// and the fine rule under it — or the challenge's own [rule], a clock —
/// the round's bars where it has them, what the challenge says there
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
    this.rule,
  });

  final GameKit kit;
  final Widget body;
  final Widget? status;
  final String? count;
  final List<bool?>? marks;
  final int at;
  final Widget? actions;

  /// What stands under the running head in place of its hairline.
  final Widget? rule;

  @override
  Widget build(BuildContext context) {
    final ChallengeRoom room = kit.room;
    final Palette p = kit.palette;
    final List<bool?>? marks = this.marks;
    const EdgeInsets side = EdgeInsets.symmetric(horizontal: 24);
    return Padding(
      padding: EdgeInsets.only(bottom: room.foot),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChallengeRunningHead(kit: kit, count: count),
          Padding(
            padding: side,
            child: rule ?? Container(height: 1, color: p.line),
          ),
          if (marks != null) ...[
            const SizedBox(height: 14),
            Padding(
              padding: side,
              child: GameSegments(id: kit.id, marks: marks, at: at),
            ),
          ],
          if (status case final Widget s) ...[
            const SizedBox(height: 20),
            Padding(padding: side, child: s),
          ],
          const SizedBox(height: 20),
          Expanded(child: Padding(padding: side, child: body)),
          if (actions case final Widget a) ...[
            const SizedBox(height: 16),
            Padding(padding: side, child: a),
          ],
        ],
      ),
    );
  }
}
