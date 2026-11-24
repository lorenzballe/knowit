/// Sixty seconds on a screen of its own (lib/widgets/explore/
/// challenge_screen.dart): the claim in front of the reader set as a page
/// is, False and True under it — or the claim swiped either way — the
/// minute a fine rule running down under the running head, and how far
/// along the eight in short rules over the answers. Each answer is told at
/// once, by a calm colour and a word.
///
/// The round is the day's round, kept and counted as on its shelf
/// ([SixtyRound]): opened again the same day, the screen opens on how it
/// went. Its mark is a clock, whose hand is the round's own time.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../data/explore_mix.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import '../../utils/share_link.dart';
import '../scaled_text.dart';
import 'challenge_kit.dart';
import 'challenge_screen.dart';
import 'challenges.dart';
import 'parts.dart';
import 'sixty_seconds.dart';

/// Sixty seconds, as its screen plays it.
class SixtyChallenge extends ChallengeGame {
  SixtyChallenge({
    required this.pills,
    required this.best,
    required this.onFinished,
    required this.onOpen,
    this.onShown,
  }) : round = SixtyRound(pills) {
    round.restore();
  }

  /// The day's eight claims.
  final List<Pill> pills;

  /// The reader's record, as it stands now.
  final int Function() best;

  /// Keeps a round's score: the record, if it beats it.
  final Future<void> Function(int right) onFinished;

  /// Opens a claim's card, from the review.
  final void Function(List<Pill>, Pill) onOpen;

  /// A claim was put in front of the reader.
  final ValueChanged<Pill>? onShown;

  /// The round, kept as on the shelf.
  final SixtyRound round;

  static const int _seconds = SixtyRound.seconds;

  /// What guessing alone gets right of the eight, on average.
  static const int chance = 4;

  /// Whether the round that just ended beat the record.
  bool _newRecord = false;

  /// The round's minute: a minute whatever the phone says of motion, which
  /// would otherwise run a controller twenty times as fast.
  AnimationController? _clock;

  /// The screen's way to the end, as the round's moment was given it.
  GameKit? _kit;

  final Set<String> _shown = {};

  @override
  String get id => 'sixty';

  @override
  bool get over => round.over;

  @override
  bool get replays => true;

  @override
  String rules(AppLocalizations l) => l.sixtyRules;

  @override
  List<ChallengeFigure> figures(AppLocalizations l) {
    final int b = best();
    return [
      if (b > 0) (label: l.challengeBest, value: '$b/${pills.length}'),
    ];
  }

  @override
  void attach(TickerProvider vsync) {
    _clock ??= AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: _seconds),
      animationBehavior: AnimationBehavior.preserve,
    )..addStatusListener(_ticked);
  }

  AnimationController get clock => _clock!;

  @override
  Listenable? get ticking => _clock;

  @override
  double markTime(GameMoment moment) => switch (moment) {
    GameMoment.intro => 0.25,
    GameMoment.play => _clock?.value ?? 0,
    GameMoment.result => (round.took ?? 0) / _seconds,
  };

  @override
  void start() {
    round.start();
    _newRecord = false;
    _clock?.value = 0;
    _showing();
    notifyListeners();
  }

  /// The clock starts once the first claim is in front of the reader.
  @override
  void started({required bool calm}) {
    final AnimationController c = clock;
    if (calm) {
      c.forward(from: 0);
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 240), () {
      if (_clock != null && round.running && !c.isAnimating) {
        c.forward(from: c.value);
      }
    });
  }

  void _showing() {
    final int at = round.answers?.length ?? 0;
    if (at >= pills.length) return;
    final Pill p = pills[at];
    if (_shown.add(p.id)) onShown?.call(p);
  }

  /// What is left of the minute, in seconds, and as the clock says it: a
  /// second is not counted as begun for a hair's breadth of arithmetic.
  double get left => (1 - clock.value) * _seconds;
  int get secondsLeft => (left - 1e-6).ceil().clamp(0, _seconds);

  void _ticked(AnimationStatus status) {
    if (status == AnimationStatus.completed && round.running) {
      HapticFeedback.lightImpact();
      _finish();
    }
  }

  /// [sayTrue] said of the claim in front: whether it was right, and
  /// whether it was the last.
  (bool right, bool last) say(bool sayTrue) {
    final int at = round.answers!.length;
    final bool right = sayTrue == trueOrFalseAnswer(pills[at]);
    final bool last = round.answer(sayTrue);
    if (last) {
      _finish(after: const Duration(milliseconds: 280));
    } else {
      _showing();
    }
    notifyListeners();
    return (right, last);
  }

  Future<void> _finish({Duration after = Duration.zero}) async {
    clock.stop();
    final double took = clock.value * _seconds;
    final int before = best();
    final int right = round.finish(took);
    _newRecord = right > before && right > 0;
    // Counted at once, as on the shelf: the record does not wait for the
    // last claim to go, nor for a reader who closes the screen first.
    final Future<void> kept = onFinished(right);
    _kit?.finish(after: after);
    await kept;
    notifyListeners();
  }

  @override
  void leave() {
    if (round.running) _clock?.stop();
  }

  @override
  void dispose() {
    _clock?.dispose();
    _clock = null;
    super.dispose();
  }

  @override
  Widget play(BuildContext context, GameKit kit) {
    _kit = kit;
    return _SixtyPlay(game: this, kit: kit);
  }

  @override
  GameOutcome outcome(BuildContext context, GameKit kit) {
    final l = context.l10n;
    final int n = pills.length;
    final int right = round.right;
    final int answered = math.min(round.answers?.length ?? 0, n);
    final int b = best();
    return GameOutcome(
      score: '$right',
      of: '$n',
      label: l.nOfM(right, n),
      best: _newRecord ? l.challengePersonalBest : null,
      figures: [
        (
          label: l.challengeAccuracy,
          value: answered == 0 ? '–' : gamePercent(context, right, answered),
        ),
        (
          label: l.challengeTime,
          value: l.challengeSeconds((round.took ?? 0).round()),
        ),
        if (!_newRecord && b > 0) (label: l.challengeBest, value: '$b/$n'),
      ],
      line: right == n
          ? l.sixtyPerfect
          : !round.allAnswered
          ? l.sixtyUnanswered(n - answered)
          : challengeChance(l, right: right, chance: chance, of: n),
      reviewTitle: l.sixtyReview,
      review: [
        for (int i = 0; i < n; i++)
          () {
            final Pill p = pills[i];
            final bool? right = round.rightAt(i);
            final bool truth = trueOrFalseAnswer(p);
            final String verdict = switch (right) {
              true => l.gameRight,
              false => l.gameWrong,
              null => l.gameUnanswered,
            };
            final String said = truth ? l.sayTrue : l.sayFalse;
            return GameReviewItem(
              key: ValueKey('sixty-miss-${p.id}'),
              text: claimOf(p),
              semantics: '${claimOf(p)} $said. $verdict.',
              mark: right,
              tag: said,
              tagDark: truth,
              onTap: () => onOpen(pills, p),
            );
          }(),
      ],
    );
  }

  @override
  Future<void> share(BuildContext context) {
    final l = context.l10n;
    final int n = pills.length;
    final String text = [
      l.sixtyShareHead(gameDate(context)),
      l.sixtyShareScore(round.right, n, (round.took ?? 0).round()),
      gameSquares([for (int i = 0; i < n; i++) round.rightAt(i)]),
      ShareRef.sixty.link,
    ].join('\n');
    return shareGame(
      context,
      text: text,
      event: 'explore sixty shared',
      facts: {'right': round.right},
    );
  }
}

/// The round: the minute, the claim in front, and the two answers.
class _SixtyPlay extends StatefulWidget {
  const _SixtyPlay({required this.game, required this.kit});

  final SixtyChallenge game;
  final GameKit kit;

  @override
  State<_SixtyPlay> createState() => _SixtyPlayState();
}

class _SixtyPlayState extends State<_SixtyPlay> with TickerProviderStateMixin {
  SixtyChallenge get _game => widget.game;
  List<Pill> get _pills => _game.pills;

  /// A claim answered, leaving the page: which, what was said, and how far
  /// the finger had already moved it.
  late final AnimationController _leave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  ({int at, bool said, double from})? _leaving;

  /// The claim in front, as the finger moves it, and its way back.
  double _drag = 0;
  late final AnimationController _back =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      )..addListener(
        () => setState(
          () => _drag =
              _dragFrom * (1 - Curves.easeOutCubic.transform(_back.value)),
        ),
      );
  double _dragFrom = 0;

  /// The last answer's verdict, and how long it has been said.
  bool? _verdict;
  late final AnimationController _told = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// When the last claim was answered, by the frames' clock.
  Duration? _saidAt;

  @override
  void dispose() {
    _leave.dispose();
    _back.dispose();
    _told.dispose();
    super.dispose();
  }

  bool get _calm => widget.kit.calm;

  /// [sayTrue] said of the claim in front, by a button or a swipe.
  void _say(bool sayTrue) {
    if (!_game.round.running) return;
    // Two taps in the same instant are one: the second never answers the
    // claim that came in behind the first, unseen.
    final Duration now = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    final Duration? before = _saidAt;
    if (before != null && now - before < const Duration(milliseconds: 140)) {
      return;
    }
    _saidAt = now;
    final int at = _game.round.answers!.length;
    final (bool right, _) = _game.say(sayTrue);
    HapticFeedback.selectionClick();
    widget.kit.say(right ? context.l10n.gameRight : context.l10n.gameWrong);
    _back.stop();
    setState(() {
      _leaving = (at: at, said: sayTrue, from: _drag);
      _drag = 0;
      _verdict = right;
    });
    if (_calm) {
      _leave.value = 1;
      _told.value = 0.5;
    } else {
      _leave.forward(from: 0);
      _told.forward(from: 0);
    }
  }

  void _dragged(DragUpdateDetails d) {
    if (!_game.round.running) return;
    _back.stop();
    setState(() => _drag += d.delta.dx);
  }

  void _dropped(DragEndDetails d, double width) {
    if (!_game.round.running) return;
    final double v = d.primaryVelocity ?? 0;
    if (_drag.abs() > width * 0.26 || v.abs() > 900) {
      _say((_drag.abs() > 8 ? _drag : v) > 0);
      return;
    }
    _dragFrom = _drag;
    if (_calm) {
      setState(() => _drag = 0);
    } else {
      _back.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final GameKit kit = widget.kit;
    final int n = _pills.length;
    final SixtyRound round = _game.round;
    final int at = round.answers?.length ?? 0;
    return GamePlayFrame(
      kit: kit,
      count: l.nOfM(math.min(at + 1, n), n),
      rule: _SixtyClock(game: _game, kit: kit),
      body: LayoutBuilder(builder: (context, box) => _claims(box.biggest)),
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _verdictLine(context, kit),
          const SizedBox(height: 10),
          GameSegments(
            id: 'sixty',
            marks: [for (int i = 0; i < n; i++) round.rightAt(i)],
            at: at,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GameButton.plain(
                  key: const ValueKey('sixty-false'),
                  context: context,
                  label: l.sayFalse,
                  height: 58,
                  size: 16.5,
                  onTap: () => _say(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GameButton.plain(
                  key: const ValueKey('sixty-true'),
                  context: context,
                  label: l.sayTrue,
                  height: 58,
                  size: 16.5,
                  onTap: () => _say(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The last answer, told: a calm colour and a word, gone in a second.
  Widget _verdictLine(BuildContext context, GameKit kit) {
    final l = context.l10n;
    final bool? v = _verdict;
    final Palette p = kit.palette;
    return SizedBox(
      height: 20,
      child: v == null
          ? null
          : AnimatedBuilder(
              animation: _told,
              builder: (context, _) {
                final double t = _told.value;
                final double shown = _calm
                    ? 1
                    : t < 0.12
                    ? t / 0.12
                    : t > 0.7
                    ? (1 - t) / 0.3
                    : 1;
                final Color colour = v
                    ? challengeRight(p)
                    : challengeWrong(p);
                return Opacity(
                  opacity: shown.clamp(0.0, 1.0),
                  child: Row(
                    key: ValueKey('sixty-told-${v ? 'right' : 'wrong'}'),
                    children: [
                      GameVerdictGlyph(right: v, colour: colour, size: 13),
                      const SizedBox(width: 8),
                      Text(
                        v ? l.gameRight : l.gameWrong,
                        style: AppText.body(
                          size: 14,
                          weight: FontWeight.w600,
                          height: 1.2,
                          color: colour,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  /// The claim in front, the one just answered on its way off the page,
  /// and the answer the claim leans to as the finger moves it.
  Widget _claims(Size area) {
    final l = context.l10n;
    final Palette p = widget.kit.palette;
    final int n = _pills.length;
    final int at = math.min(_game.round.answers?.length ?? 0, n);
    final double width = area.width;
    return AnimatedBuilder(
      animation: _leave,
      builder: (context, _) {
        final ({int at, bool said, double from})? leaving = _leaving;
        final double t = leaving == null ? 1 : _leave.value;
        final List<Widget> layers = [];
        if (at < n) {
          final Pill pill = _pills[at];
          final double appear = Curves.easeOut.transform(
            ((t - 0.3) / 0.7).clamp(0.0, 1.0),
          );
          final double lean = (_drag / (width * 0.8)).clamp(-1.0, 1.0);
          layers.add(
            Positioned.fill(
              child: Opacity(
                opacity: appear * (1 - lean.abs() * 0.55),
                child: Transform.translate(
                  offset: Offset(_drag, 8 * (1 - appear)),
                  child: GestureDetector(
                    key: const ValueKey('sixty-card'),
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: _dragged,
                    onHorizontalDragEnd: (d) => _dropped(d, width),
                    child: _SixtyClaim(
                      key: ValueKey('sixty-claim-${pill.id}'),
                      pill: pill,
                    ),
                  ),
                ),
              ),
            ),
          );
          if (lean.abs() > 0.02) {
            layers.add(
              Positioned(
                top: 0,
                right: lean > 0 ? 0 : null,
                left: lean < 0 ? 0 : null,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: (lean.abs() * 3).clamp(0.0, 1.0),
                    child: Text(
                      upper(context, lean > 0 ? l.sayTrue : l.sayFalse),
                      style: challengeSmallCaps(p.ink, 11.5),
                    ),
                  ),
                ),
              ),
            );
          }
        }
        if (leaving != null && t < 1) {
          final double go = Curves.easeOut.transform((t / 0.6).clamp(0.0, 1.0));
          final double dir = leaving.said ? 1 : -1;
          layers.add(
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 1 - go,
                  child: Transform.translate(
                    offset: Offset(leaving.from + dir * 32 * go, 0),
                    child: _SixtyClaim(pill: _pills[leaving.at]),
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
}

/// The minute, as a fine rule in the challenge's tone running down from
/// the right, and the seconds left beside it in tabular figures.
class _SixtyClock extends StatelessWidget {
  const _SixtyClock({required this.game, required this.kit});

  final SixtyChallenge game;
  final GameKit kit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = kit.palette;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    return AnimatedBuilder(
      animation: game.clock,
      builder: (context, _) {
        final int secs = game.secondsLeft;
        return Semantics(
          label: l.sixtySecondsLeftLabel(secs),
          excludeSemantics: true,
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 12,
                  child: CustomPaint(
                    painter: _ClockRule(
                      left: game.left / SixtyRound.seconds,
                      track: p.line,
                      colour: kit.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$secs',
                key: const ValueKey('sixty-clock'),
                textScaler: scaler.clamp(maxScaleFactor: 1.3),
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w600,
                  height: 1,
                  color: p.ink,
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The rule the minute runs down: a hairline the whole way, and over it,
/// from the left, what is left of the minute.
class _ClockRule extends CustomPainter {
  const _ClockRule({
    required this.left,
    required this.track,
    required this.colour,
  });

  final double left;
  final Color track;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final double y = size.height / 2;
    canvas.drawRect(
      Rect.fromLTWH(0, y - 0.5, size.width, 1),
      Paint()..color = track,
    );
    final double w = size.width * left.clamp(0.0, 1.0);
    if (w <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(0, y - 1, w, 2),
      Paint()..color = colour,
    );
  }

  @override
  bool shouldRepaint(_ClockRule old) =>
      old.left != left || old.track != track || old.colour != colour;
}

/// A claim of the round, set as a page is: its subject in small capitals,
/// and the claim in the app's serif, as large as its room takes.
class _SixtyClaim extends StatelessWidget {
  const _SixtyClaim({super.key, required this.pill});

  final Pill pill;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          upper(context, context.l10n.subjectOf(pill.topic)),
          style: challengeSmallCaps(p.inkMuted),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: ScaledText(
              text: claimOf(pill),
              min: 18,
              max: 31,
              alignment: Alignment.topLeft,
              styleFor: (size) => AppText.display(
                size: size,
                weight: FontWeight.w400,
                height: 1.24,
                spacing: -0.012 * size,
                color: p.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── The cards of a deck ─────────────────────────────────────────────────
//
// True or false (true_false_game.dart) still deals its claims on a deck of
// cards of paper, until it is set as Sixty seconds is.

/// A card of a deck, [depth] cards down: one deeper peeks out under the
/// one above it, a little narrower, a little turned.
class DeckCard extends StatelessWidget {
  const DeckCard({
    super.key,
    required this.index,
    required this.depth,
    required this.child,
  });

  /// Its place in the deck, which turns it one way or the other.
  final int index;
  final double depth;
  final Widget child;

  static const double peek = 9;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    top: 0,
    bottom: peek * 2,
    child: Transform.translate(
      offset: Offset(0, peek * depth),
      child: Transform.rotate(
        angle: (index.isEven ? -1 : 1) * 0.016 * depth,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(1 - 0.05 * depth, 1, 1),
          child: child,
        ),
      ),
    ),
  );
}

/// A claim on a card of the deck: its subject and the claim, as large as
/// it goes. With no [pill], the back of a card still to come. [lean] is how
/// far the finger has moved it, and which way: the answer it is leaning
/// to shows in its corner. [verdict], on a card answered, is whether it was
/// right, stamped on it as it goes.
class ClaimCard extends StatelessWidget {
  const ClaimCard({
    super.key,
    required this.pill,
    this.lean = 0,
    this.verdict,
    this.stamp = 0,
    this.text,
    this.max = 40,
  });

  final Pill? pill;
  final double lean;
  final bool? verdict;
  final double stamp;

  /// The words, when not the claim the card makes.
  final String? text;

  /// The largest the words are set.
  final double max;

  @override
  Widget build(BuildContext context) {
    final Pill? p = pill;
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
                    text: text ?? claimOf(p),
                    min: 17,
                    max: max,
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
            Center(child: GameStamp(right: v, scale: stamp)),
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
