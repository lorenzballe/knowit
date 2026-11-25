/// The games of bets that are a game on their own, each on a screen of its
/// own among Explore's challenges (lib/widgets/explore/challenge_screen.dart):
/// Which is bigger?, Closer, closer, Orders of magnitude, Bet a range,
/// Place your bet and Your number.
///
/// A screen plays the cards its shelf deals today ([BetBlock.deal]), one at
/// a time, each the whole screen: the card's question on its card of
/// paper, and under it the game shaped to what it asks — two figures to
/// tap, a track halving, a staircase, a track and its widths, the amounts
/// and the stakes, a counter and its steppers — with large targets and a
/// click in the hand at every step. Once laid, the bet is told on the card
/// itself, with the first lines of why, and the next card is a tap away.
///
/// Every bet is laid exactly as its tile lays it — the same function
/// ([pickBigger], [stepCloser], [layMagnitude], [layRange], [layStake],
/// [layNumber]), the same drafts kept for the day, the same how sure — so
/// a bet counts the same wherever it is played, and a card half played on
/// its shelf goes on here where it was left.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../utils/share_link.dart';
import '../../../widgets/explore/challenge_kit.dart';
import '../../../widgets/explore/challenge_screen.dart';
import '../../../widgets/explore/parts.dart' show CardHead;
import '../../../widgets/scaled_text.dart';
import '../../explore_block.dart';
import 'answers.dart';
import 'bets_day.dart';
import 'bigger.dart';
import 'closer.dart';
import 'deal.dart';
import 'magnitude.dart';
import 'number.dart';
import 'parts.dart';
import 'range.dart';
import 'stake.dart';

/// What every game of bets on a screen does the same way: the cards, one
/// at a time, the bet told on the card, the next a tap away, and the
/// round's end from the bets laid.
abstract class BetChallenge extends ChallengeGame {
  BetChallenge({
    required this.host,
    required this.shelf,
    required this.cards,
    required this.title,
  }) {
    BetsDay.instance.addListener(notifyListeners);
    host.app.addListener(notifyListeners);
  }

  final ExploreHost host;
  final BetSection shelf;

  /// The cards the shelf deals today.
  final List<BetAnswer> cards;

  /// The game's name, for the score sent on.
  final String title;

  /// The game's name among the challenges: `bets-closer`.
  String get game;

  /// How many rounds there are: one a card, or a pair.
  int get count => cards.length;

  /// The cards of round [i].
  List<Pill> pillsAt(int i) => [cards[i].pill];

  /// Whether round [i] is done with: its bet laid, or its card answered
  /// elsewhere and not to be bet on.
  bool settledAt(int i);

  /// Whether round [i]'s bet came in; null while it has none.
  bool? rightAt(int i);

  /// Round [i]'s card answered elsewhere, so not bet on here.
  bool elsewhereAt(int i) => false;

  /// What round [i]'s answer is, in a tag: "42%".
  String tagAt(BuildContext context, int i);

  /// What round [i]'s bet came to, in words.
  String? verdictAt(BuildContext context, int i);

  /// The round's play: the card's question, and the game under it.
  Widget face(BuildContext context, GameKit kit, int i);

  /// The buttons at the foot while round [i] is played, if any.
  Widget? actions(BuildContext context, GameKit kit, int i) => null;

  /// What the head says beside the picture while round [i] is played.
  Widget? status(BuildContext context, GameKit kit, int i) => null;

  /// What the round came to besides how many came in: the points.
  List<Widget> chips(BuildContext context, GameKit kit) => const [];

  /// The score: how many came in, of how many.
  (int, int) get score => (
    [for (int i = 0; i < count; i++) rightAt(i)].where((r) => r == true).length,
    count,
  );

  List<bool?> get marks => [for (int i = 0; i < count; i++) rightAt(i)];

  /// The round as squares, at the end and in the score sent on: one a
  /// round, or one a step where the score counts steps.
  List<bool?> get board => marks;

  /// The first round not done with, or null.
  int? get next {
    for (int i = 0; i < count; i++) {
      if (!settledAt(i)) return i;
    }
    return null;
  }

  @override
  String get id => game.replaceFirst('bets-', '');

  @override
  bool get over => next == null;

  @override
  String playLabel(AppLocalizations l) =>
      [for (int i = 0; i < count; i++) settledAt(i)].any((s) => s) && !over
      ? l.gameContinue
      : l.gamePlay;

  @override
  (IconData, String)? note(AppLocalizations l) =>
      (Icons.today_rounded, l.gameCardsToday(count));

  @override
  void start() {}

  /// Round [i] was put in front of the reader.
  void shown(int i) {
    for (final Pill p in pillsAt(i)) {
      host.seen(shelf.section, p);
    }
  }

  /// Opens [pill]'s card, among the round's.
  void open(Pill pill) =>
      host.open(shelf.section, [for (final c in cards) c.pill], pill);

  BetNumbers numbers(BuildContext context) =>
      BetNumbers(Localizations.localeOf(context).languageCode);

  @override
  void dispose() {
    BetsDay.instance.removeListener(notifyListeners);
    host.app.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  Widget play(BuildContext context, GameKit kit) =>
      _BetPlay(game: this, kit: kit);

  /// The review's rows: one a card.
  List<GameReviewItem> review(BuildContext context) {
    final l = context.l10n;
    return [
      for (int i = 0; i < count; i++)
        () {
          final Pill p = cards[i].pill;
          final String? verdict = elsewhereAt(i)
              ? l.betsAnsweredAlready
              : verdictAt(context, i);
          final String tag = tagAt(context, i);
          return GameReviewItem(
            key: ValueKey('$id-row-${p.id}'),
            text: p.question,
            tag: tag,
            tagDark: true,
            mark: rightAt(i),
            detail: verdict,
            semantics: [p.question, tag, ?verdict].join('. '),
            onTap: () => open(p),
          );
        }(),
    ];
  }

  @override
  GameOutcome outcome(BuildContext context, GameKit kit) {
    final l = context.l10n;
    final (int right, int of) = score;
    return GameOutcome(
      score: '$right',
      of: '$of',
      label: l.nOfM(right, of),
      line: right == of ? l.gameAllRight : l.betsScoreSentence(right, of),
      chips: chips(context, kit),
      board: GameSquares(marks: board),
      review: review(context),
    );
  }

  @override
  Future<void> share(BuildContext context) {
    final l = context.l10n;
    final (int right, int of) = score;
    return shareGame(
      context,
      text: [
        l.gameShareHead(title, gameDate(context)),
        l.gameShareScore(right, of),
        gameSquares(board),
        ShareRef.challenges.link,
      ].join('\n'),
      event: 'explore $game shared',
      facts: {'right': right},
    );
  }

  /// The card of round [i]: its subject, and its question — or once told,
  /// the question smaller, what the bet came to, and the first lines of
  /// why.
  Widget card(BuildContext context, int i, {String? told}) {
    final Pill p = cards[i].pill;
    return GamePaper(
      key: ValueKey('$id-card-${p.id}'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHead(
            pill: p,
            ink: kArtInk,
            labelInk: kArtInk.withValues(alpha: 0.62),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: told == null
                ? ScaledText(
                    text: p.question,
                    min: 15,
                    max: 28,
                    alignment: Alignment.centerLeft,
                    styleFor: (size) => AppText.display(
                      size: size,
                      weight: FontWeight.w600,
                      height: 1.14,
                      spacing: -0.02 * size,
                      color: kArtInk,
                    ),
                  )
                : _Told(question: p.question, verdict: told, why: p.answer),
          ),
        ],
      ),
    );
  }
}

/// A bet told on its card: the question, smaller; what it came to; and the
/// first lines of why. It scrolls where it must.
class _Told extends StatelessWidget {
  const _Told({
    required this.question,
    required this.verdict,
    required this.why,
  });

  final String question;
  final String verdict;
  final String why;

  @override
  Widget build(BuildContext context) => Align(
    // In the middle of its card where it has room; scrolled where not.
    alignment: AlignmentDirectional.centerStart,
    child: SingleChildScrollView(
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: AppText.body(
                size: 14.5,
                weight: FontWeight.w600,
                height: 1.3,
                color: kArtInk.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              verdict,
              style: AppText.display(
                size: 23,
                weight: FontWeight.w700,
                height: 1.18,
                spacing: -0.4,
                color: kArtInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              firstLines(why),
              style: AppText.body(
                size: 15.5,
                weight: FontWeight.w500,
                height: 1.4,
                color: kArtInk.withValues(alpha: 0.86),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The round of a game of bets: the head, the bars of the round, the card
/// in front with its game, and its buttons — or, once its bet is told, the
/// way on to the next.
class _BetPlay extends StatefulWidget {
  const _BetPlay({required this.game, required this.kit});

  final BetChallenge game;
  final GameKit kit;

  @override
  State<_BetPlay> createState() => _BetPlayState();
}

class _BetPlayState extends State<_BetPlay> {
  BetChallenge get _game => widget.game;

  late int _at = _game.next ?? 0;

  @override
  void initState() {
    super.initState();
    _game.shown(_at);
  }

  void _next() {
    final int? next = _game.next;
    if (next == null) {
      widget.kit.finish();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _at = next);
    _game.shown(_at);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final GameKit kit = widget.kit;
    final int n = _game.count;
    final bool settled = _game.settledAt(_at);
    return GamePlayFrame(
      kit: kit,
      count: l.nOfM(_at + 1, n),
      marks: _game.marks,
      at: _at,
      status: _game.status(context, kit, _at),
      body: AnimatedSwitcher(
        duration: kit.motion(280),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey('${_game.id}-round-$_at'),
          child: _game.face(context, kit, _at),
        ),
      ),
      actions: settled
          ? GameButton(
              key: ValueKey('${_game.id}-next-card'),
              label: _game.next == null ? l.gameSeeResult : l.gameNextCard,
              icon: Icons.arrow_forward_rounded,
              face: kArtInk,
              ink: kArtCream,
              height: 72,
              onTap: _next,
            )
          : _game.actions(context, kit, _at),
    );
  }
}

/// Says what a bet came to, and feels it: a light click for one that came
/// in, nothing more for one that did not — a bet lost is not an error.
void _told(GameKit kit, bool won, String verdict) {
  if (won) BetFeel.won();
  kit.say(verdict);
}

// ── Which is bigger? ─────────────────────────────────────────────────────

/// Which is bigger?: two figures, hidden, one over the other; a tap on the
/// one that is bigger.
class BiggerChallenge extends BetChallenge {
  BiggerChallenge({
    required super.host,
    required super.shelf,
    required super.cards,
    required super.title,
  });

  @override
  String get game => 'bets-bigger';

  @override
  int get count => cards.length ~/ 2;

  @override
  List<Pill> pillsAt(int i) => [cards[i * 2].pill, cards[i * 2 + 1].pill];

  Bet? _bet(int i) => BetsDay.instance.betOn('bigger', cards[i * 2].pill.id);

  @override
  bool settledAt(int i) => _bet(i) != null;

  @override
  bool? rightAt(int i) => _bet(i)?.right;

  @override
  String rules(AppLocalizations l) => l.betsBiggerLine;

  @override
  String tagAt(BuildContext context, int i) => '';

  @override
  String? verdictAt(BuildContext context, int i) => null;

  @override
  (IconData, String)? note(AppLocalizations l) =>
      (Icons.today_rounded, l.biggerPairsToday(count));

  @override
  Widget? status(BuildContext context, GameKit kit, int i) {
    final l = context.l10n;
    final bool? right = rightAt(i);
    return _HeadWords(
      switch (right) {
        null => l.betsTapIfBigger,
        true => l.gameRight,
        false => l.gameWrong,
      },
      kit: kit,
    );
  }

  @override
  Widget face(BuildContext context, GameKit kit, int i) {
    final l = context.l10n;
    final BetAnswer a = cards[i * 2], b = cards[i * 2 + 1];
    final Bet? bet = _bet(i);
    final int? picked = bet == null ? null : int.tryParse(bet.said);
    final int bigger = a.value > b.value ? 0 : 1;
    final BetNumbers n = numbers(context);

    Future<void> pick(int j) async {
      if (_bet(i) != null) return;
      BetFeel.lay();
      await pickBigger(host, shelf, a, b, j);
      _told(
        kit,
        j == bigger,
        '${j == bigger ? l.gameRight : l.gameWrong}. '
        '${n.percent(a.value)}, ${n.percent(b.value)}.',
      );
    }

    Widget half(int j, BetAnswer c) => _Half(
      key: ValueKey('bigger-half-${c.pill.id}'),
      answer: c,
      figure: n.percent(c.value),
      picked: picked,
      side: j,
      bigger: bigger,
      onTap: picked == null ? () => pick(j) : () => open(c.pill),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: half(0, a)),
            const SizedBox(height: 12),
            Expanded(child: half(1, b)),
          ],
        ),
        IgnorePointer(
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kit.ground,
              shape: BoxShape.circle,
              border: Border.all(color: kArtInk, width: 3),
            ),
            child: Text(
              l.betsOr,
              style: AppText.display(
                size: 17,
                weight: FontWeight.w800,
                height: 1,
                color: kArtInk,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  List<GameReviewItem> review(BuildContext context) {
    final l = context.l10n;
    final BetNumbers n = numbers(context);
    return [
      for (int i = 0; i < count; i++)
        for (int j = 0; j < 2; j++)
          () {
            final BetAnswer c = cards[i * 2 + j];
            final BetAnswer o = cards[i * 2 + 1 - j];
            final Bet? bet = _bet(i);
            final bool mine = bet != null && int.tryParse(bet.said) == j;
            final bool big = c.value > o.value;
            final String detail = [
              if (big) l.betsBigger,
              if (mine) l.betsYourPick,
            ].join(' · ');
            return GameReviewItem(
              key: ValueKey('bigger-row-${c.pill.id}'),
              text: c.pill.question,
              tag: n.percent(c.value),
              tagDark: big,
              mark: mine ? bet.right : null,
              detail: detail.isEmpty ? null : detail,
              semantics: [
                c.pill.question,
                n.percent(c.value),
                if (detail.isNotEmpty) detail,
              ].join('. '),
              onTap: () => open(c.pill),
            );
          }(),
    ];
  }
}

/// One of the two figures: what it is the answer to, the figure hidden
/// until the pick, and what the pick made of it.
class _Half extends StatelessWidget {
  const _Half({
    super.key,
    required this.answer,
    required this.figure,
    required this.picked,
    required this.side,
    required this.bigger,
    required this.onTap,
  });

  final BetAnswer answer;
  final String figure;
  final int? picked;
  final int side;
  final int bigger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bool done = picked != null;
    final bool big = done && side == bigger;
    final bool mine = picked == side;
    final Color face = big ? kArtInk : gameFace(context);
    final Color ink = big ? kArtCream : kArtInk;
    return Semantics(
      button: true,
      label: done
          ? '${answer.pill.question} $figure. '
                '${big ? l.betsBigger : ''} ${mine ? l.betsYourPick : ''}'
          : '${answer.pill.question} ${l.betsTapIfBigger}',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                decoration: BoxDecoration(
                  color: face,
                  borderRadius: BorderRadius.circular(24),
                  border: gameBorder(context),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ScaledText(
                        text: answer.pill.question,
                        min: 13,
                        max: 22,
                        alignment: Alignment.centerLeft,
                        styleFor: (size) => AppText.display(
                          size: size,
                          weight: FontWeight.w600,
                          height: 1.14,
                          spacing: -0.02 * size,
                          color: ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 96,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            done ? figure : '?',
                            style: AppText.display(
                              size: 40,
                              weight: FontWeight.w700,
                              height: 1,
                              spacing: -1.2,
                              color: ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (done && mine)
              Positioned(
                right: -6,
                top: -10,
                child: GameStamp(right: side == bigger, size: 46),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Closer, closer ───────────────────────────────────────────────────────

/// Closer, closer: a share closed in on, more or less, step by step.
class CloserChallenge extends BetChallenge {
  CloserChallenge({
    required super.host,
    required super.shelf,
    required super.cards,
    required super.title,
  });

  @override
  String get game => 'bets-closer';

  int get steps => CloserBlock.stepsOf(shelf);

  Bet? _bet(int i) => BetsDay.instance.betOn('closer', cards[i].pill.id);

  CloserGame _gameAt(int i) =>
      CloserGame.of(closerTaps(cards[i]), cards[i].value, steps);

  @override
  bool settledAt(int i) => _bet(i) != null;

  @override
  bool? rightAt(int i) => _bet(i)?.right;

  /// Every step said right, of every step taken.
  @override
  (int, int) get score {
    int right = 0, taken = 0;
    for (int i = 0; i < count; i++) {
      final Bet? bet = _bet(i);
      if (bet == null) continue;
      right += (bet.facts['right'] as num?)?.toInt() ?? 0;
      taken += (bet.facts['steps'] as num?)?.toInt() ?? 0;
    }
    return (right, taken);
  }

  /// One square a step: each said right or not.
  @override
  List<bool?> get board => [
    for (int i = 0; i < count; i++)
      if (_bet(i) case final Bet bet)
        for (int k = 1; k <= bet.said.length; k++)
          if (CloserGame.of(bet.said.substring(0, k), cards[i].value, steps)
                  .last
              case (final bool said, final bool truth, _))
            said == truth,
  ];

  @override
  String rules(AppLocalizations l) => l.betsCloserLine('$steps');

  @override
  String tagAt(BuildContext context, int i) =>
      numbers(context).percent(cards[i].value);

  @override
  String? verdictAt(BuildContext context, int i) {
    final Bet? bet = _bet(i);
    if (bet == null) return null;
    final CloserGame g = _gameAt(i);
    return context.l10n.betsScore(g.right, g.taken);
  }

  String _message(BuildContext context, int i, CloserGame g) {
    final l = context.l10n;
    final BetNumbers n = numbers(context);
    final String said = n.percent(cards[i].value);
    if (g.done) {
      return g.exact
          ? '${l.betsCloserExact(said)} ${l.betsScoreSentence(g.right, g.taken)}'
          : l.betsCloserDone(said, g.right, g.taken);
    }
    final last = g.last;
    if (last == null) return l.betsCloserStart('$steps');
    final (bool more, bool truthMore, double at) = last;
    final String v = n.percent(at);
    return more == truthMore
        ? (truthMore ? l.betsCloserYesMore(v) : l.betsCloserYesLess(v))
        : (truthMore ? l.betsCloserNoMore(v) : l.betsCloserNoLess(v));
  }

  @override
  Widget face(BuildContext context, GameKit kit, int i) {
    final l = context.l10n;
    final BetNumbers n = numbers(context);
    final CloserGame g = _gameAt(i);
    final bool done = _bet(i) != null || g.done;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: card(context, i, told: done ? _message(context, i, g) : null),
        ),
        const SizedBox(height: 16),
        _Halving(
          lo: g.lo,
          hi: g.hi,
          answer: done ? cards[i].value : null,
          labels: [n.percent(0), n.percent(50), n.percent(100)],
          calm: kit.calm,
        ),
        if (!done) ...[
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  l.betsMoreOrLess(n.percent(g.middle)),
                  key: ValueKey('closer-ask-${cards[i].pill.id}'),
                  textScaler: scaler.clamp(maxScaleFactor: 1.5),
                  style: AppText.display(
                    size: 24,
                    weight: FontWeight.w700,
                    height: 1.12,
                    spacing: -0.5,
                    color: kit.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l.betsStepOf(math.min(g.taken + 1, steps), steps),
                textScaler: scaler.clamp(maxScaleFactor: 1.5),
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w800,
                  height: 1.2,
                  color: kit.ink,
                ),
              ),
            ],
          ),
          if (g.last != null) ...[
            const SizedBox(height: 6),
            Semantics(
              liveRegion: true,
              child: Text(
                _message(context, i, g),
                key: ValueKey('closer-said-${cards[i].pill.id}'),
                textScaler: scaler.clamp(maxScaleFactor: 1.5),
                style: AppText.body(
                  size: 15,
                  weight: FontWeight.w700,
                  height: 1.3,
                  color: kit.ink.withValues(alpha: 0.86),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  @override
  Widget? actions(BuildContext context, GameKit kit, int i) {
    final l = context.l10n;
    Future<void> step(bool more) async {
      if (_bet(i) != null) return;
      BetFeel.tick();
      final CloserGame after = await stepCloser(
        host,
        shelf,
        cards[i],
        steps: steps,
        taps: closerTaps(cards[i]),
        more: more,
      );
      if (!context.mounted) return;
      final (bool said, bool truth, _) = after.last!;
      if (after.done) {
        _told(kit, after.right == after.taken, _message(context, i, after));
      } else {
        kit.say(_message(context, i, after));
        if (said == truth) HapticFeedback.lightImpact();
      }
    }

    return Row(
      children: [
        Expanded(
          child: GameButton(
            key: ValueKey('closer-less-${cards[i].pill.id}'),
            label: l.betsLess,
            icon: Icons.arrow_downward_rounded,
            face: kArtCream,
            ink: kArtInk,
            height: 76,
            onTap: () => step(false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GameButton(
            key: ValueKey('closer-more-${cards[i].pill.id}'),
            label: l.betsMore,
            icon: Icons.arrow_upward_rounded,
            face: kArtInk,
            ink: kArtCream,
            height: 76,
            onTap: () => step(true),
          ),
        ),
      ],
    );
  }
}

/// The track a game of more or less is played on, large: the rail, the
/// stretch the answer is still in, gliding as it halves, and at the end
/// the answer itself.
class _Halving extends StatelessWidget {
  const _Halving({
    required this.lo,
    required this.hi,
    required this.answer,
    required this.labels,
    required this.calm,
  });

  final double lo;
  final double hi;
  final double? answer;
  final List<String> labels;
  final bool calm;

  @override
  Widget build(BuildContext context) {
    final TextStyle tick = AppText.body(
      size: 12,
      weight: FontWeight.w800,
      height: 1,
      color: kArtInk,
    );
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: lo),
            duration: calm ? Duration.zero : const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, l, _) => TweenAnimationBuilder<double>(
              tween: Tween(end: hi),
              duration: calm
                  ? Duration.zero
                  : const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (context, h, _) => SizedBox(
                height: 40,
                child: CustomPaint(
                  painter: _HalvingPainter(lo: l, hi: h, answer: answer),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [for (final String s in labels) Text(s, style: tick)],
          ),
        ],
      ),
    );
  }
}

class _HalvingPainter extends CustomPainter {
  const _HalvingPainter({
    required this.lo,
    required this.hi,
    required this.answer,
  });

  final double lo;
  final double hi;
  final double? answer;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final Paint line = Paint()
      ..color = kArtInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final RRect rail = RRect.fromLTRBR(0, 8, w, size.height - 8, const Radius.circular(12));
    canvas.drawRRect(rail, Paint()..color = kArtCream);
    final double left = w * lo / 100;
    final double right = math.max(left + 8, w * hi / 100);
    final RRect band = RRect.fromLTRBR(
      left,
      8,
      right,
      size.height - 8,
      const Radius.circular(12),
    );
    canvas.drawRRect(band, Paint()..color = const Color(0xFFFFC83D));
    canvas.drawRRect(band, line);
    canvas.drawRRect(rail, line);
    final double? a = answer;
    if (a != null) {
      final double x = (w * a / 100).clamp(5, w - 5);
      canvas.drawRRect(
        RRect.fromLTRBR(x - 5, 0, x + 5, size.height, const Radius.circular(5)),
        Paint()..color = kGameRight,
      );
      canvas.drawRRect(
        RRect.fromLTRBR(x - 5, 0, x + 5, size.height, const Radius.circular(5)),
        line..strokeWidth = 2.4,
      );
    }
  }

  @override
  bool shouldRepaint(_HalvingPainter old) =>
      old.lo != lo || old.hi != hi || old.answer != answer;
}

// ── Orders of magnitude ──────────────────────────────────────────────────

/// Orders of magnitude: a size picked from a staircase of powers of ten.
class MagnitudeChallenge extends BetChallenge {
  MagnitudeChallenge({
    required super.host,
    required super.shelf,
    required super.cards,
    required super.title,
  });

  @override
  String get game => 'bets-magnitude';

  Bet? _bet(int i) => BetsDay.instance.betOn('magnitude', cards[i].pill.id);

  @override
  bool elsewhereAt(int i) =>
      _bet(i) == null && host.app.answerFor(cards[i].pill.id) != null;

  @override
  bool settledAt(int i) => _bet(i) != null || elsewhereAt(i);

  @override
  bool? rightAt(int i) => _bet(i)?.right;

  int? _picked(int i) {
    final Bet? bet = _bet(i);
    if (bet != null) return (bet.facts['at'] as num?)?.toInt();
    final Object? d = BetsDay.instance.draft(
      BetsDay.draftKey('magnitude', cards[i].pill.id),
    );
    return d is Map ? (d['p'] as num?)?.toInt() : null;
  }

  @override
  String rules(AppLocalizations l) => l.betsMagnitudeLine;

  @override
  String tagAt(BuildContext context, int i) {
    final Notches notches = Notches.of(cards[i])!;
    return numbers(context).compact(notches.values[notches.right]);
  }

  @override
  String? verdictAt(BuildContext context, int i) {
    final l = context.l10n;
    final Bet? bet = _bet(i);
    if (bet == null) return null;
    final int o = (bet.facts['off'] as num?)?.toInt() ?? 0;
    final String verdict = bet.right || o == 0
        ? l.betsMagnitudeRight
        : l.betsMagnitudeOff(o);
    final int? s = bet.confidence;
    return s == null ? verdict : '$verdict ${l.betsYouWereSure(s)}';
  }

  @override
  Widget face(BuildContext context, GameKit kit, int i) {
    final l = context.l10n;
    final BetAnswer answer = cards[i];
    final Notches notches = Notches.of(answer)!;
    final BetNumbers n = numbers(context);
    final Bet? bet = _bet(i);
    final bool laid = bet != null;
    final bool open = !settledAt(i);
    final int? picked = _picked(i);
    final bool pending = open && picked != null && shelf.asksSure;
    final int count = notches.values.length;

    Future<void> lay(int at, int? sure) async {
      await layMagnitude(host, shelf, answer, at: at, sure: sure);
      if (context.mounted) {
        _told(kit, at == notches.right, verdictAt(context, i) ?? '');
      }
    }

    void pick(int at) {
      BetFeel.tick();
      if (shelf.asksSure) {
        BetsDay.instance.keepDraft(
          BetsDay.draftKey('magnitude', answer.pill.id),
          {'p': at},
        );
      } else {
        BetFeel.lay();
        lay(at, null);
      }
    }

    final Widget stairs = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int j = 0; j < count; j++) ...[
          if (j > 0) const SizedBox(width: 6),
          Expanded(
            child: GameButton(
              key: ValueKey('magnitude-${answer.pill.id}-$j'),
              label: answer.odds
                  ? n.plain(notches.values[j], decimals: 0)
                  : n.compact(notches.values[j]),
              semantics: answer.odds
                  ? l.betsOneIn(n.plain(notches.values[j], decimals: 0))
                  : '${n.plain(notches.values[j], decimals: 3)} ${answer.unit}',
              selected: j == picked,
              face: laid
                  ? (j == notches.right
                        ? kGameRight
                        : j == picked
                        ? kGameWrong
                        : kArtCream)
                  : j == picked
                  ? kArtInk
                  : kArtCream,
              ink: !laid && j == picked ? kArtCream : kArtInk,
              height: 56.0 + (count > 4 ? 12 : 20) * j,
              size: 15,
              radius: 14,
              fade: !laid && !(pending && j == picked),
              onTap: open && j != picked ? () => pick(j) : null,
            ),
          ),
        ],
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: card(
            context,
            i,
            told: laid
                ? verdictAt(context, i)
                : elsewhereAt(i)
                ? l.betsAnsweredAlready
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          answer.odds ? l.betsOneInLabel : answer.unit,
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(maxScaleFactor: 1.5),
          style: AppText.body(
            size: 14,
            weight: FontWeight.w800,
            height: 1.2,
            color: kit.ink,
          ),
        ),
        const SizedBox(height: 8),
        stairs,
        if (pending) ...[
          const SizedBox(height: 14),
          GameSure(
            id: 'magnitude',
            ink: kit.ink,
            onPick: (s) => lay(picked, s),
          ),
        ],
      ],
    );
  }
}

// ── Bet a range ──────────────────────────────────────────────────────────

/// Bet a range: a share set on a track, a range either side of it, and
/// the narrower the range the more it pays, if the answer is in it.
class RangeChallenge extends BetChallenge {
  RangeChallenge({
    required super.host,
    required super.shelf,
    required super.cards,
    required super.title,
  });

  @override
  String get game => 'bets-range';

  List<RangeWidth> get widths => rangeWidthsOf(shelf);

  Bet? _bet(int i) => BetsDay.instance.betOn('range', cards[i].pill.id);

  @override
  bool elsewhereAt(int i) =>
      _bet(i) == null && host.app.answerFor(cards[i].pill.id) != null;

  @override
  bool settledAt(int i) => _bet(i) != null || elsewhereAt(i);

  /// A range that came in: the answer inside it.
  @override
  bool? rightAt(int i) {
    final Bet? bet = _bet(i);
    return bet == null ? null : bet.facts['hit'] == true;
  }

  int get won => [
    for (int i = 0; i < count; i++)
      if (_bet(i) case final Bet bet when bet.facts['hit'] == true)
        (bet.facts['pays'] as num?)?.toInt() ?? 0,
  ].fold(0, (a, b) => a + b);

  @override
  String rules(AppLocalizations l) => l.betsRangeLine;

  @override
  String tagAt(BuildContext context, int i) =>
      numbers(context).percent(cards[i].value);

  @override
  String? verdictAt(BuildContext context, int i) {
    final l = context.l10n;
    final Bet? bet = _bet(i);
    if (bet == null) return null;
    final String said = numbers(context).percent(cards[i].value);
    return bet.facts['hit'] == true
        ? l.betsInRange((bet.facts['pays'] as num?)?.toInt() ?? 0, said)
        : l.betsMissedRange(said);
  }

  @override
  List<Widget> chips(BuildContext context, GameKit kit) => [
    GameChip(
      key: const ValueKey('range-won'),
      icon: Icons.stars_rounded,
      label: '+${context.l10n.gamePoints(won)}',
      ink: kit.ink,
      ground: kit.ground,
    ),
  ];

  (double, int) _drafted(int i) {
    final Bet? bet = _bet(i);
    final int middle = (widths.length - 1) ~/ 2;
    if (bet != null) {
      return (
        double.tryParse(bet.said) ?? 50,
        (bet.facts['w'] as num?)?.toInt() ?? middle,
      );
    }
    final Object? d = BetsDay.instance.draft(
      BetsDay.draftKey('range', cards[i].pill.id),
    );
    final Map draft = d is Map ? d : const {};
    return (
      (draft['g'] as num?)?.toDouble() ?? 50,
      ((draft['w'] as num?)?.toInt() ?? middle).clamp(0, widths.length - 1),
    );
  }

  void _keep(int i, {double? g, int? w}) {
    final (double guess, int at) = _drafted(i);
    BetsDay.instance.keepDraft(BetsDay.draftKey('range', cards[i].pill.id), {
      'g': g ?? guess,
      'w': w ?? at,
    });
  }

  @override
  Widget face(BuildContext context, GameKit kit, int i) {
    final l = context.l10n;
    final BetNumbers n = numbers(context);
    final (double guess, int at) = _drafted(i);
    final RangeWidth width = widths[at.clamp(0, widths.length - 1)];
    final (double lo, double hi) = rangeAround(guess, width);
    final bool laid = _bet(i) != null;
    final bool open = !settledAt(i);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: card(
            context,
            i,
            told: laid
                ? verdictAt(context, i)
                : elsewhereAt(i)
                ? l.betsAnsweredAlready
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              n.percent(guess),
              key: ValueKey('range-guess-${cards[i].pill.id}'),
              textScaler: scaler.clamp(maxScaleFactor: 1.2),
              style: AppText.display(
                size: 40,
                weight: FontWeight.w700,
                height: 1,
                spacing: -1.4,
                color: kit.ink,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                n.range(lo, hi),
                textAlign: TextAlign.right,
                textScaler: scaler.clamp(maxScaleFactor: 1.5),
                style: AppText.body(
                  size: 15,
                  weight: FontWeight.w800,
                  height: 1.1,
                  color: kit.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ShareTrack(
          key: ValueKey('range-track-${cards[i].pill.id}'),
          value: guess,
          band: width.half.toDouble(),
          label: l.betsYourGuess,
          say: n.percent,
          answer: laid ? cards[i].value : null,
          onChanged: open ? (v) => _keep(i, g: v) : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (int j = 0; j < widths.length; j++) ...[
              if (j > 0) const SizedBox(width: 8),
              Expanded(
                child: GameButton(
                  key: ValueKey('range-${cards[i].pill.id}-w$j'),
                  label: l.betsRangeWidth(widths[j].half, widths[j].pays),
                  selected: j == at,
                  face: j == at ? kArtInk : kArtCream,
                  ink: j == at ? kArtCream : kArtInk,
                  height: 50,
                  size: 14,
                  radius: 14,
                  fade: j != at,
                  onTap: open && j != at
                      ? () {
                          BetFeel.tick();
                          _keep(i, w: j);
                        }
                      : null,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget? actions(BuildContext context, GameKit kit, int i) {
    final l = context.l10n;
    return GameButton(
      key: ValueKey('range-bet-${cards[i].pill.id}'),
      label: l.betsBet,
      icon: Icons.check_rounded,
      face: kArtInk,
      ink: kArtCream,
      height: 72,
      onTap: () async {
        if (_bet(i) != null) return;
        BetFeel.lay();
        final (double guess, int at) = _drafted(i);
        await layRange(
          host,
          shelf,
          cards[i],
          guess: guess,
          at: at,
          widths: widths,
        );
        if (context.mounted) {
          _told(kit, rightAt(i) == true, verdictAt(context, i) ?? '');
        }
      },
    );
  }
}

/// A share set on a track from nought to a hundred, large: the rail, a
/// band either side of the thumb, the thumb, and once the bet is laid the
/// answer. It snaps to whole points and clicks at every tenth.
class ShareTrack extends StatelessWidget {
  const ShareTrack({
    super.key,
    required this.value,
    required this.label,
    required this.say,
    this.band = 0,
    this.answer,
    this.onChanged,
  });

  final double value;
  final String label;
  final String Function(double) say;
  final double band;
  final double? answer;
  final ValueChanged<double>? onChanged;

  void _set(double v) {
    final ValueChanged<double>? set = onChanged;
    if (set == null || v == value) return;
    if ((value / 10).floor() != (v / 10).floor() || v == 0 || v == 100) {
      BetFeel.tick();
    }
    set(v);
  }

  @override
  Widget build(BuildContext context) {
    final bool open = onChanged != null;
    return Semantics(
      slider: open,
      label: label,
      value: say(value),
      increasedValue: open ? say(math.min(100, value + 1)) : null,
      decreasedValue: open ? say(math.max(0, value - 1)) : null,
      onIncrease: open ? () => _set(math.min(100, value + 1)) : null,
      onDecrease: open ? () => _set(math.max(0, value - 1)) : null,
      child: LayoutBuilder(
        builder: (context, box) {
          double at(Offset p) =>
              ((p.dx - 22) / math.max(1, box.maxWidth - 44) * 100)
                  .clamp(0, 100)
                  .roundToDouble();
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: open ? (d) => _set(at(d.localPosition)) : null,
            onHorizontalDragUpdate: open
                ? (d) => _set(at(d.localPosition))
                : null,
            child: SizedBox(
              height: 60,
              width: double.infinity,
              child: CustomPaint(
                painter: _TrackPainter(
                  value: value,
                  band: band,
                  answer: answer,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  const _TrackPainter({
    required this.value,
    required this.band,
    required this.answer,
  });

  final double value;
  final double band;
  final double? answer;

  @override
  void paint(Canvas canvas, Size size) {
    const double pad = 22;
    final double w = size.width - pad * 2;
    double x(double v) => pad + w * v / 100;
    final double mid = size.height / 2;
    final Paint line = Paint()
      ..color = kArtInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final RRect rail = RRect.fromLTRBR(
      pad - 6,
      mid - 9,
      pad + w + 6,
      mid + 9,
      const Radius.circular(9),
    );
    canvas.drawRRect(rail, Paint()..color = kArtCream);
    if (band > 0) {
      final RRect b = RRect.fromLTRBR(
        x(math.max(0, value - band)),
        mid - 15,
        x(math.min(100, value + band)),
        mid + 15,
        const Radius.circular(10),
      );
      canvas.drawRRect(b, Paint()..color = const Color(0xFFFFC83D));
      canvas.drawRRect(b, line);
    }
    canvas.drawRRect(rail, line);
    final double? a = answer;
    if (a != null) {
      final RRect mark = RRect.fromLTRBR(
        x(a) - 5,
        mid - 24,
        x(a) + 5,
        mid + 24,
        const Radius.circular(5),
      );
      canvas.drawRRect(mark, Paint()..color = kGameRight);
      canvas.drawRRect(mark, line);
    }
    final Offset thumb = Offset(x(value), mid);
    canvas.drawCircle(thumb, 12, Paint()..color = kArtInk);
    canvas.drawCircle(thumb, 7, Paint()..color = kArtCream);
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.value != value || old.band != band || old.answer != answer;
}

// ── Place your bet ───────────────────────────────────────────────────────

/// Place your bet: amounts to pick from, a stake from the day's points on
/// one of them, doubled or lost.
class StakeChallenge extends BetChallenge {
  StakeChallenge({
    required super.host,
    required super.shelf,
    required super.cards,
    required super.title,
  });

  @override
  String get game => 'bets-stake';

  List<int> get stakes => StakeBlock.stakesOf(shelf);

  Bet? _bet(int i) => BetsDay.instance.betOn('stake', cards[i].pill.id);

  @override
  bool elsewhereAt(int i) =>
      _bet(i) == null && host.app.answerFor(cards[i].pill.id) != null;

  @override
  bool settledAt(int i) => _bet(i) != null || elsewhereAt(i);

  @override
  bool? rightAt(int i) => _bet(i)?.right;

  int get net => [
    for (int i = 0; i < count; i++) _bet(i)?.points ?? 0,
  ].fold(0, (a, b) => a + b);

  @override
  String rules(AppLocalizations l) => l.betsStakeLine(BetsDay.dailyPoints);

  @override
  (IconData, String)? note(AppLocalizations l) =>
      (Icons.toll_rounded, l.betsWalletSays(BetsDay.instance.points));

  @override
  Widget? status(BuildContext context, GameKit kit, int i) => _HeadWords(
    context.l10n.betsWalletSays(BetsDay.instance.points),
    kit: kit,
    key: const ValueKey('stake-wallet'),
  );

  @override
  String tagAt(BuildContext context, int i) =>
      cards[i].options[cards[i].correct];

  @override
  String? verdictAt(BuildContext context, int i) {
    final l = context.l10n;
    final Bet? bet = _bet(i);
    if (bet == null) return null;
    final int stake = (bet.facts['stake'] as num?)?.toInt() ?? 0;
    final String verdict = bet.right ? l.betsWin(stake) : l.betsLose(stake);
    final int? s = bet.confidence;
    return s == null ? verdict : '$verdict ${l.betsYouWereSure(s)}';
  }

  @override
  List<Widget> chips(BuildContext context, GameKit kit) {
    final l = context.l10n;
    return [
      GameChip(
        key: const ValueKey('stake-net'),
        icon: Icons.stars_rounded,
        label: '${net > 0 ? '+' : net < 0 ? '−' : ''}${l.gamePoints(net.abs())}',
        ink: kit.ink,
        ground: kit.ground,
      ),
      GameChip(
        key: const ValueKey('stake-left'),
        icon: Icons.toll_rounded,
        label: l.betsWalletSays(BetsDay.instance.points),
        ink: kit.ink,
        ground: kit.ground,
      ),
    ];
  }

  Map _draft(int i) {
    final Object? d = BetsDay.instance.draft(
      BetsDay.draftKey('stake', cards[i].pill.id),
    );
    return d is Map ? d : const {};
  }

  int? _picked(int i) {
    final Bet? bet = _bet(i);
    return bet != null
        ? int.tryParse(bet.said)
        : (_draft(i)['o'] as num?)?.toInt();
  }

  int _stakeAt(int i) {
    final Bet? bet = _bet(i);
    final int k = bet != null
        ? stakes.indexOf((bet.facts['stake'] as num?)?.toInt() ?? stakes.first)
        : ((_draft(i)['k'] as num?)?.toInt() ?? 0);
    return k.clamp(0, stakes.length - 1);
  }

  bool _pending(int i) => !settledAt(i) && _draft(i)['p'] == true;

  void _keep(int i, {int? option, int? stakeAt, bool pend = false}) =>
      BetsDay.instance.keepDraft(BetsDay.draftKey('stake', cards[i].pill.id), {
        'o': option ?? _picked(i),
        'k': stakeAt ?? _stakeAt(i),
        if (pend) 'p': true,
      });

  Future<void> _lay(BuildContext context, GameKit kit, int i, int? sure) async {
    await layStake(
      host,
      shelf,
      cards[i],
      option: _picked(i)!,
      stake: stakes[_stakeAt(i)],
      sure: sure,
    );
    if (context.mounted) {
      _told(kit, rightAt(i) == true, verdictAt(context, i) ?? '');
    }
  }

  @override
  Widget face(BuildContext context, GameKit kit, int i) {
    final l = context.l10n;
    final BetAnswer answer = cards[i];
    final bool laid = _bet(i) != null;
    final bool open = !settledAt(i) && !_pending(i);
    final int? picked = _picked(i);
    final int k = _stakeAt(i);
    final int wallet = BetsDay.instance.points;
    final List<String> options = answer.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: card(
            context,
            i,
            told: laid
                ? verdictAt(context, i)
                : elsewhereAt(i)
                ? l.betsAnsweredAlready
                : null,
          ),
        ),
        const SizedBox(height: 12),
        for (int j = 0; j < options.length; j++) ...[
          if (j > 0) const SizedBox(height: 8),
          GameButton(
            key: ValueKey('stake-${answer.pill.id}-o$j'),
            label: options[j],
            selected: j == picked,
            face: laid
                ? (j == answer.correct
                      ? kGameRight
                      : j == picked
                      ? kGameWrong
                      : kArtCream)
                : j == picked
                ? kArtInk
                : kArtCream,
            ink: !laid && j == picked ? kArtCream : kArtInk,
            height: 50,
            size: 16,
            radius: 14,
            fade: !laid && j != picked,
            onTap: open && j != picked
                ? () {
                    BetFeel.tick();
                    _keep(i, option: j);
                  }
                : null,
          ),
        ],
        const SizedBox(height: 14),
        if (_pending(i))
          GameSure(
            id: 'stake',
            ink: kit.ink,
            onPick: (s) => _lay(context, kit, i, s),
          )
        else if (!laid)
          Row(
            children: [
              Text(
                l.betsStakeLabel,
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.4),
                style: AppText.body(
                  size: 15,
                  weight: FontWeight.w800,
                  height: 1,
                  color: kit.ink,
                ),
              ),
              const SizedBox(width: 12),
              for (int j = 0; j < stakes.length; j++) ...[
                if (j > 0) const SizedBox(width: 8),
                Expanded(
                  child: GameButton(
                    key: ValueKey('stake-${answer.pill.id}-k$j'),
                    label: '${stakes[j]}',
                    selected: j == k,
                    face: j == k ? kArtInk : kArtCream,
                    ink: j == k ? kArtCream : kArtInk,
                    height: 48,
                    size: 17,
                    radius: 24,
                    fade: j != k,
                    onTap: open && stakes[j] <= wallet && j != k
                        ? () {
                            BetFeel.tick();
                            _keep(i, stakeAt: j);
                          }
                        : null,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  @override
  Widget? actions(BuildContext context, GameKit kit, int i) {
    if (_pending(i)) return null;
    final l = context.l10n;
    final int? picked = _picked(i);
    final int stake = stakes[_stakeAt(i)];
    final bool can = picked != null && stake <= BetsDay.instance.points;
    return GameButton(
      key: ValueKey('stake-bet-${cards[i].pill.id}'),
      label: can
          ? l.betsBetN(stake)
          : picked == null
          ? l.betsPickFirst
          : l.betsNotEnough,
      icon: can ? Icons.check_rounded : null,
      face: kArtInk,
      ink: kArtCream,
      height: 72,
      onTap: can
          ? () {
              BetFeel.lay();
              if (shelf.asksSure) {
                _keep(i, pend: true);
              } else {
                _lay(context, kit, i, null);
              }
            }
          : null,
    );
  }
}

// ── Your number ──────────────────────────────────────────────────────────

/// Your number: a number set with steppers, locked, and how far off it
/// was.
class NumberChallenge extends BetChallenge {
  NumberChallenge({
    required super.host,
    required super.shelf,
    required super.cards,
    required super.title,
  });

  @override
  String get game => 'bets-number';

  Bet? _bet(int i) => BetsDay.instance.betOn('number', cards[i].pill.id);

  @override
  bool elsewhereAt(int i) =>
      _bet(i) == null && host.app.answerFor(cards[i].pill.id) != null;

  @override
  bool settledAt(int i) => _bet(i) != null || elsewhereAt(i);

  @override
  bool? rightAt(int i) => _bet(i)?.right;

  Map _draft(int i) {
    final Object? d = BetsDay.instance.draft(
      BetsDay.draftKey('number', cards[i].pill.id),
    );
    return d is Map ? d : const {};
  }

  double _value(int i) {
    final StepScale scale = StepScale.around(cards[i])!;
    final Bet? bet = _bet(i);
    return bet != null
        ? double.tryParse(bet.said) ?? scale.start
        : (_draft(i)['v'] as num?)?.toDouble() ?? scale.start;
  }

  bool _pending(int i) => !settledAt(i) && _draft(i)['p'] == true;

  String _amount(BuildContext context, int i, double x) {
    final StepScale scale = StepScale.around(cards[i])!;
    final String said = numbers(context).plain(x, decimals: scale.decimals);
    final String unit = cards[i].unit;
    return unit.isEmpty ? said : '$said $unit';
  }

  @override
  String rules(AppLocalizations l) => l.betsNumberLine;

  @override
  String tagAt(BuildContext context, int i) =>
      _amount(context, i, cards[i].value);

  @override
  String? verdictAt(BuildContext context, int i) {
    final l = context.l10n;
    final Bet? bet = _bet(i);
    if (bet == null) return null;
    final double v = _value(i);
    final double off = (v - cards[i].value).abs();
    final String verdict = bet.right && off < 1e-9
        ? l.betsSpotOn
        : bet.right
        ? l.betsCloseEnough(_amount(context, i, off))
        : l.betsOffBy(_amount(context, i, off));
    final int? s = bet.confidence;
    return s == null ? verdict : '$verdict ${l.betsYouWereSure(s)}';
  }

  Future<void> _lay(BuildContext context, GameKit kit, int i, int? sure) async {
    await layNumber(host, shelf, cards[i], value: _value(i), sure: sure);
    if (context.mounted) {
      _told(kit, rightAt(i) == true, verdictAt(context, i) ?? '');
    }
  }

  @override
  Widget face(BuildContext context, GameKit kit, int i) {
    final l = context.l10n;
    final BetAnswer answer = cards[i];
    final StepScale scale = StepScale.around(answer)!;
    final BetNumbers n = numbers(context);
    final bool laid = _bet(i) != null;
    final bool open = !settledAt(i) && !_pending(i);
    final double v = _value(i);
    final String key = BetsDay.draftKey('number', answer.pill.id);
    final List<double> steps = [
      -scale.big,
      -scale.small,
      scale.small,
      scale.big,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: card(
            context,
            i,
            told: laid
                ? verdictAt(context, i)
                : elsewhereAt(i)
                ? l.betsAnsweredAlready
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          liveRegion: open,
          label: l.betsNumberTitle,
          value: _amount(context, i, v),
          excludeSemantics: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    n.plain(v, decimals: scale.decimals),
                    key: ValueKey('number-value-${answer.pill.id}'),
                    maxLines: 1,
                    textScaler: MediaQuery.textScalerOf(
                      context,
                    ).clamp(maxScaleFactor: 1.2),
                    style: AppText.display(
                      size: 56,
                      weight: FontWeight.w700,
                      height: 1,
                      spacing: -2,
                      color: kit.ink,
                    ),
                  ),
                ),
              ),
              if (answer.unit.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    answer.unit,
                    maxLines: 2,
                    style: AppText.body(
                      size: 16,
                      weight: FontWeight.w700,
                      height: 1.15,
                      color: kit.ink,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (laid) ...[
          const SizedBox(height: 10),
          _YouAndAnswer(you: v, answer: answer.value),
        ],
        const SizedBox(height: 12),
        if (_pending(i))
          GameSure(
            id: 'number',
            ink: kit.ink,
            onPick: (s) => _lay(context, kit, i, s),
          )
        else if (!laid)
          Row(
            children: [
              for (int j = 0; j < steps.length; j++) ...[
                if (j > 0) const SizedBox(width: 8),
                Expanded(
                  child: GameButton(
                    key: ValueKey('number-${answer.pill.id}-${steps[j]}'),
                    label:
                        '${steps[j] < 0 ? '−' : '+'}'
                        '${n.plain(steps[j].abs(), decimals: scale.decimals)}',
                    face: kArtCream,
                    ink: kArtInk,
                    height: 56,
                    size: 16,
                    radius: 16,
                    onTap: open && (steps[j] > 0 || v > 0)
                        ? () {
                            BetFeel.tick();
                            BetsDay.instance.keepDraft(key, {
                              'v': scale.move(_value(i), steps[j]),
                            });
                          }
                        : null,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  @override
  Widget? actions(BuildContext context, GameKit kit, int i) {
    if (_pending(i)) return null;
    final l = context.l10n;
    return GameButton(
      key: ValueKey('number-lock-${cards[i].pill.id}'),
      label: l.betsLock,
      icon: Icons.lock_rounded,
      face: kArtInk,
      ink: kArtCream,
      height: 72,
      onTap: () {
        BetFeel.lay();
        if (shelf.asksSure) {
          BetsDay.instance.keepDraft(
            BetsDay.draftKey('number', cards[i].pill.id),
            {'v': _value(i), 'p': true},
          );
        } else {
          _lay(context, kit, i, null);
        }
      },
    );
  }
}

/// The number set against the answer, on one scale from nought: where the
/// reader's stands, and where the card's does.
class _YouAndAnswer extends StatelessWidget {
  const _YouAndAnswer({required this.you, required this.answer});

  final double you;
  final double answer;

  @override
  Widget build(BuildContext context) {
    final double top = niceAbove(math.max(you, answer) / 0.8);
    return ExcludeSemantics(
      child: SizedBox(
        height: 30,
        child: CustomPaint(
          painter: _YouPainter(
            you: top == 0 ? 0 : you / top,
            answer: top == 0 ? 0 : answer / top,
          ),
        ),
      ),
    );
  }
}

class _YouPainter extends CustomPainter {
  const _YouPainter({required this.you, required this.answer});

  final double you;
  final double answer;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double mid = size.height / 2;
    final Paint line = Paint()
      ..color = kArtInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final RRect rail = RRect.fromLTRBR(
      0,
      mid - 6,
      w,
      mid + 6,
      const Radius.circular(6),
    );
    canvas.drawRRect(rail, Paint()..color = kArtCream);
    canvas.drawRRect(rail, line);
    for (final (double at, Color colour) in [
      (answer, kGameRight),
      (you, kArtInk),
    ]) {
      final double x = (w * at).clamp(5, w - 5);
      final RRect mark = RRect.fromLTRBR(
        x - 5,
        0,
        x + 5,
        size.height,
        const Radius.circular(5),
      );
      canvas.drawRRect(mark, Paint()..color = colour);
      canvas.drawRRect(mark, line..strokeWidth = 2.4);
    }
  }

  @override
  bool shouldRepaint(_YouPainter old) => old.you != you || old.answer != answer;
}

/// A few words in a game's head, beside its picture.
class _HeadWords extends StatelessWidget {
  const _HeadWords(this.text, {super.key, required this.kit});

  final String text;
  final GameKit kit;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
    style: AppText.display(
      size: 16,
      weight: FontWeight.w700,
      height: 1.12,
      spacing: -0.2,
      color: kit.ink,
    ),
  );
}
