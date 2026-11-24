/// Sixty seconds on a screen of its own (lib/widgets/explore/
/// challenge_screen.dart): the claim in front of the reader on a deck of
/// the eight, False and True under it, large — or the card swiped either
/// way — the stopwatch become the clock, and how far along the eight.
/// Each answer is told at once, on the card and in the hand.
///
/// The round is the day's round, kept and counted as on its shelf
/// ([SixtyRound]): opened again the same day, the screen opens on how it
/// went. The stopwatch is one picture the whole way: the tile's, the first
/// moment's, the clock of the round and the time the round took.
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
import 'challenge_art.dart';
import 'challenge_kit.dart';
import 'challenge_screen.dart';
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

  /// Whether the round that just ended beat the record.
  bool _newRecord = false;

  /// The round's minute: a minute whatever the phone says of motion, which
  /// would otherwise run a controller twenty times as fast.
  AnimationController? _clock;

  /// The screen's way to the end, as the round's moment was given it.
  GameKit? _kit;

  /// The last whole second the clock said, for the ticks of the last five.
  int _lastSecond = _seconds;

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
  (IconData, String)? note(AppLocalizations l) {
    final int b = best();
    return b > 0
        ? (Icons.emoji_events_rounded, l.exploreSixtyRecord(b, pills.length))
        : (Icons.flag_rounded, l.exploreSixtyFirst);
  }

  @override
  void attach(TickerProvider vsync) {
    _clock ??=
        AnimationController(
            vsync: vsync,
            duration: const Duration(seconds: _seconds),
            animationBehavior: AnimationBehavior.preserve,
          )
          ..addListener(_second)
          ..addStatusListener(_ticked);
  }

  AnimationController get clock => _clock!;

  @override
  Listenable? get ticking => _clock;

  @override
  double artTime(GameMoment moment) => switch (moment) {
    GameMoment.intro => 0.25,
    GameMoment.play => _clock?.value ?? 0,
    GameMoment.result => (round.took ?? 0) / _seconds,
  };

  @override
  void start() {
    round.start();
    _newRecord = false;
    _lastSecond = _seconds;
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
    Future<void>.delayed(const Duration(milliseconds: 360), () {
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

  void _second() {
    if (!round.running) return;
    final int s = secondsLeft;
    if (s == _lastSecond) return;
    _lastSecond = s;
    if (s <= 5 && s > 0) HapticFeedback.selectionClick();
  }

  void _ticked(AnimationStatus status) {
    if (status == AnimationStatus.completed && round.running) {
      HapticFeedback.heavyImpact();
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
    // last card to fly, nor for a reader who closes the screen first.
    final Future<void> kept = onFinished(right);
    _kit?.finish(
      cheer: _newRecord || right == pills.length,
      after: after,
    );
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
    final int b = best();
    final Color ink = kit.ink;
    return GameOutcome(
      score: '$right',
      of: '$n',
      label: l.nOfM(right, n),
      line: right == n
          ? l.sixtyPerfect
          : round.allAnswered
          ? l.sixtyIn((round.took ?? 0).round())
          : l.sixtyTimeUp,
      chips: [
        if (_newRecord)
          GameChip(
            key: const ValueKey('sixty-new-record'),
            icon: Icons.emoji_events_rounded,
            label: l.sixtyNewRecord,
            ink: kit.ground,
            ground: ink,
          )
        else if (b > 0)
          GameChip(
            key: const ValueKey('sixty-record'),
            icon: Icons.emoji_events_rounded,
            label: l.exploreSixtyRecord(b, n),
            ink: ink,
            ground: kit.ground,
          ),
      ],
      board: GameSquares(marks: [for (int i = 0; i < n; i++) round.rightAt(i)]),
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

/// The round: the clock, the deck, and the two answers.
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

  /// When the last claim was answered, by the frames' clock.
  Duration? _saidAt;

  @override
  void dispose() {
    _leave.dispose();
    _back.dispose();
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
    if (right) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    widget.kit.say(right ? context.l10n.gameRight : context.l10n.gameWrong);
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
    _back.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final GameKit kit = widget.kit;
    final Color ink = kit.ink;
    final int n = _pills.length;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final SixtyRound round = _game.round;
    return GamePlayFrame(
      kit: kit,
      count: l.nOfM(math.min((round.answers?.length ?? 0) + 1, n), n),
      marks: [for (int i = 0; i < n; i++) round.rightAt(i)],
      at: round.answers?.length ?? 0,
      status: AnimatedBuilder(
        animation: _game.clock,
        builder: (context, _) {
          final double left = _game.left;
          final int secs = _game.secondsLeft;
          final double beat = secs <= 10 && !_calm
              ? 1 + 0.12 * math.max(0, 1 - (secs - left) * 4)
              : 1;
          return Semantics(
            label: l.sixtySecondsLeftLabel(secs),
            excludeSemantics: true,
            child: Transform.scale(
              scale: beat,
              alignment: Alignment.centerLeft,
              child: Text(
                '$secs',
                key: const ValueKey('sixty-clock'),
                textScaler: scaler.clamp(maxScaleFactor: 1.3),
                style: AppText.display(
                  size: 36,
                  weight: FontWeight.w700,
                  height: 1,
                  spacing: -1,
                  color: ink,
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
          );
        },
      ),
      body: LayoutBuilder(builder: (context, box) => _deck(box.biggest)),
      actions: Row(
        children: [
          Expanded(
            child: GameButton(
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
            child: GameButton(
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
    );
  }

  /// The deck: the claim in front, the ones still to come under it, and the
  /// one just answered on its way off, its verdict on it.
  Widget _deck(Size area) {
    final int n = _pills.length;
    final int at = math.min(_game.round.answers?.length ?? 0, n);
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
        final List<Widget> layers = [];
        // The ones under the front one: blank backs, at most two.
        for (int depth = math.min(left - 1, 2); depth >= 1; depth--) {
          layers.add(
            DeckCard(
              index: at + depth,
              depth: depth + (1 - rise),
              child: const ClaimCard(pill: null),
            ),
          );
        }
        if (left > 0) {
          final Pill p = _pills[at];
          final double lean = (_drag / (width * 0.9)).clamp(-1.0, 1.0);
          layers.add(
            DeckCard(
              index: at,
              depth: 1 - rise,
              child: GestureDetector(
                key: const ValueKey('sixty-card'),
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: _dragged,
                onHorizontalDragEnd: (d) => _dropped(d, width),
                child: Transform.translate(
                  offset: Offset(_drag, 0),
                  child: Transform.rotate(
                    angle: lean * 0.16,
                    child: ClaimCard(
                      key: ValueKey('sixty-claim-${p.id}'),
                      pill: p,
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
            DeckCard(
              index: leaving.at,
              depth: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: (1 - go * 0.6).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(x, -12 * go),
                    child: Transform.rotate(
                      angle: dir * 0.24 * go + leaving.from / width * 0.16,
                      child: ClaimCard(
                        pill: _pills[leaving.at],
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
}

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
