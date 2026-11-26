/// Sixty seconds on a screen of its own (lib/widgets/explore/
/// challenge_screen.dart): the claim in front of the reader on its
/// subject's card, as the app's cards are everywhere, False and True under
/// it — or the card swiped either way — the minute a fine rule running
/// down under the running head, and how far along the eight in short rules
/// over the answers. Each answer is told at once, by a calm colour and a
/// word.
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
import 'challenge_kit.dart';
import 'challenge_screen.dart';
import 'challenges.dart';
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
  List<List<Pill>> get today => [
    for (final Pill p in pills) [p],
  ];

  @override
  List<bool?> get todayMarks => [
    for (int i = 0; i < pills.length; i++) round.rightAt(i),
  ];

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
      status: _SixtyClock(game: _game),
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
                  label: l.sayFalse,
                  height: 64,
                  size: 17,
                  onTap: () => _say(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GameButton.plain(
                  key: const ValueKey('sixty-true'),
                  label: l.sayTrue,
                  height: 64,
                  size: 17,
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
                          weight: FontWeight.w700,
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
                opacity: appear,
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
                      lean: lean,
                    ),
                  ),
                ),
              ),
            ),
          );
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

/// The minute, as a fine rule in the page's ink running down from the
/// right, and the seconds left beside it in tabular figures.
class _SixtyClock extends StatelessWidget {
  const _SixtyClock({required this.game});

  final SixtyChallenge game;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
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
                  height: 8,
                  child: CustomPaint(
                    painter: _ClockRule(
                      left: game.left / SixtyRound.seconds,
                      track: p.ink.withValues(alpha: 0.14),
                      colour: p.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l.challengeSeconds(secs),
                key: const ValueKey('sixty-clock'),
                textScaler: scaler.clamp(maxScaleFactor: 1.3),
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w700,
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
    final Radius r = const Radius.circular(2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, y - 2, size.width, 4), r),
      Paint()..color = track,
    );
    final double w = size.width * left.clamp(0.0, 1.0);
    if (w <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, y - 2, w, 4), r),
      Paint()..color = colour,
    );
  }

  @override
  bool shouldRepaint(_ClockRule old) =>
      old.left != left || old.track != track || old.colour != colour;
}

/// A claim of the round on its subject's card, as the app sets a card of
/// the day: its subject's mark and name at its head, the claim in the
/// app's serif, as large as the card takes. As the finger moves it, the
/// answer it leans to shows at the head's end.
class _SixtyClaim extends StatelessWidget {
  const _SixtyClaim({super.key, required this.pill, this.lean = 0});

  final Pill pill;
  final double lean;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SubjectCard(
      pill: pill,
      trailing: lean.abs() > 0.02
          ? Opacity(
              opacity: (lean.abs() * 3).clamp(0.0, 1.0),
              child: SubjectTag(
                pill: pill,
                text: lean > 0 ? l.sayTrue : l.sayFalse,
              ),
            )
          : null,
      child: Semantics(
        liveRegion: true,
        child: SubjectWords(text: claimOf(pill), ink: pill.ink),
      ),
    );
  }
}
