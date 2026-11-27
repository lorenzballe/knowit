/// True or false on a screen of its own (challenge_screen.dart): the day's
/// claims of its shelf on a deck, one at a time, each on its subject's
/// card as the app's cards are everywhere, False and True under it; each
/// answer told at once, on the card and in the hand, with why; then the
/// next. No clock: there is time to think, and to read why.
///
/// It is the shelf's own row, kept and counted as there: an answer is the
/// card's own answer, recorded as the card records one, and a card already
/// answered — here, on its shelf, or on the card — is not asked again.
/// Opened again the same day, the screen opens where the reader left off,
/// or on how it went.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/explore_mix.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../utils/share_link.dart';
import 'challenge_kit.dart';
import 'challenge_screen.dart';
import 'game_feel.dart';

/// True or false, as its screen plays it.
class TrueFalseChallenge extends ChallengeGame {
  TrueFalseChallenge({
    required this.pills,
    required this.title,
    required this.answerOf,
    required this.onCommit,
    required this.onOpen,
    this.onShown,
  });

  /// The shelf's claims today.
  final List<Pill> pills;

  /// The game's name, for the score sent on.
  final String title;

  /// A card's answer as the card keeps it, if it has one.
  final String? Function(Pill) answerOf;

  /// An answer, recorded as the card's own.
  final Future<void> Function(Pill, String) onCommit;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  /// What was said on this screen, by card: true for "True".
  final Map<String, bool> _said = {};

  @override
  String get id => 'tf';

  /// What was said of the claim at [i], here or before; null while not.
  bool? saidAt(int i) {
    final Pill p = pills[i];
    final bool? here = _said[p.id];
    if (here != null) return here;
    final int? given = int.tryParse(answerOf(p) ?? '');
    final Challenge c = p.challenge;
    if (given == null || c is! PickOne) return null;
    if (given < 0 || given >= c.options.length) return null;
    return c.options[given].toLowerCase() == 'true';
  }

  /// Whether the claim at [i] was answered before this screen.
  bool before(int i) => !_said.containsKey(pills[i].id) && saidAt(i) != null;

  bool? rightAt(int i) {
    final bool? s = saidAt(i);
    return s == null ? null : s == trueOrFalseAnswer(pills[i]);
  }

  List<bool?> get marks => [for (int i = 0; i < pills.length; i++) rightAt(i)];

  int get right => marks.where((m) => m == true).length;

  /// The first claim not answered, or null when every one is.
  int? get next {
    for (int i = 0; i < pills.length; i++) {
      if (saidAt(i) == null) return i;
    }
    return null;
  }

  @override
  bool get over => next == null;

  @override
  String rules(AppLocalizations l) => l.tfRules;

  @override
  List<List<Pill>> get today => [
    for (final Pill p in pills) [p],
  ];

  @override
  List<bool?> get todayMarks => marks;

  @override
  String playLabel(AppLocalizations l) =>
      marks.any((m) => m != null) ? l.gameContinue : l.gamePlay;

  @override
  void start() {}

  /// [sayTrue] said of the claim at [i]: recorded as the card's answer.
  bool say(int i, bool sayTrue) {
    final Pill p = pills[i];
    _said[p.id] = sayTrue;
    onCommit(p, '${trueOrFalseIndex(p, sayTrue)}');
    notifyListeners();
    return sayTrue == trueOrFalseAnswer(p);
  }

  void shown(int i) => onShown?.call(pills[i]);

  @override
  Widget play(BuildContext context, GameKit kit) =>
      _TrueFalsePlay(game: this, kit: kit);

  @override
  GameOutcome outcome(BuildContext context, GameKit kit) {
    final l = context.l10n;
    final int n = pills.length;
    return GameOutcome(
      score: '$right',
      of: '$n',
      label: l.nOfM(right, n),
      line: right == n ? l.gameAllRight : l.betsScoreSentence(right, n),
      board: GameSquares(marks: marks),
      review: [
        for (int i = 0; i < n; i++)
          () {
            final Pill p = pills[i];
            final bool truth = trueOrFalseAnswer(p);
            final String said = truth ? l.sayTrue : l.sayFalse;
            final bool? r = rightAt(i);
            return GameReviewItem(
              key: ValueKey('tf-row-${p.id}'),
              text: claimOf(p),
              tag: said,
              tagDark: truth,
              mark: r,
              detail: before(i) ? l.betsAnsweredAlready : null,
              semantics:
                  '${claimOf(p)} $said. '
                  '${switch (r) {
                    true => l.gameRight,
                    false => l.gameWrong,
                    null => l.gameUnanswered,
                  }}.',
              onTap: () => onOpen(pills, p),
            );
          }(),
      ],
    );
  }

  @override
  Future<void> share(BuildContext context) {
    final l = context.l10n;
    return shareGame(
      context,
      text: [
        l.gameShareHead(title, gameDate(context)),
        l.gameShareScore(right, pills.length),
        gameSquares(marks),
        ShareRef.challenges.link,
      ].join('\n'),
      event: 'explore true-false shared',
      facts: {'right': right},
    );
  }
}

class _TrueFalsePlay extends StatefulWidget {
  const _TrueFalsePlay({required this.game, required this.kit});

  final TrueFalseChallenge game;
  final GameKit kit;

  @override
  State<_TrueFalsePlay> createState() => _TrueFalsePlayState();
}

class _TrueFalsePlayState extends State<_TrueFalsePlay> {
  TrueFalseChallenge get _game => widget.game;

  /// The claim in front, and whether it has been answered here.
  late int _at = _game.next ?? 0;
  bool _told = false;

  @override
  void initState() {
    super.initState();
    _game.shown(_at);
  }

  void _say(bool sayTrue) {
    if (_told) return;
    final bool right = _game.say(_at, sayTrue);
    GameFeel.verdict(right);
    final l = context.l10n;
    final String side = '${trueOrFalseAnswer(_game.pills[_at])}';
    widget.kit.say(right ? l.tfRightIs(side) : l.tfWrongIs(side));
    setState(() => _told = true);
  }

  void _next() {
    final int? next = _game.next;
    if (next == null) {
      widget.kit.finish();
      return;
    }
    GameFeel.tick();
    setState(() {
      _at = next;
      _told = false;
    });
    _game.shown(_at);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final GameKit kit = widget.kit;
    final List<Pill> pills = _game.pills;
    final int n = pills.length;
    final Pill p = pills[_at];
    // The cards still to come, each its subject's colour under the one in
    // front, as the day's deck is.
    final List<Pill> coming = [
      for (int i = _at + 1; i < n; i++)
        if (_game.saidAt(i) == null) pills[i],
    ];
    return GamePlayFrame(
      kit: kit,
      count: l.nOfM(_at + 1, n),
      marks: _game.marks,
      at: _at,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int depth = math.min(coming.length, 2); depth >= 1; depth--)
            _DeckCard(
              depth: depth.toDouble(),
              child: SubjectCard(pill: coming[depth - 1]),
            ),
          _DeckCard(
            depth: 0,
            child: AnimatedSwitcher(
              duration: kit.motion(260),
              child: _told
                  ? _Told(
                      key: ValueKey('tf-told-${p.id}'),
                      pill: p,
                      right: _game.rightAt(_at) ?? false,
                    )
                  : SubjectCard(
                      key: ValueKey('tf-claim-${p.id}'),
                      pill: p,
                      child: Semantics(
                        liveRegion: true,
                        child: SubjectWords(text: claimOf(p), ink: p.ink),
                      ),
                    ),
            ),
          ),
        ],
      ),
      actions: _told
          ? GameButton.primary(
              key: const ValueKey('tf-next'),
              label: _game.next == null ? l.gameSeeResult : l.gameNextCard,
              onTap: _next,
            )
          : Row(
              children: [
                Expanded(
                  child: GameButton.plain(
                    key: const ValueKey('tf-false'),
                    label: l.sayFalse,
                    height: 64,
                    size: 17,
                    onTap: () => _say(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GameButton.plain(
                    key: const ValueKey('tf-true'),
                    label: l.sayTrue,
                    height: 64,
                    size: 17,
                    onTap: () => _say(true),
                  ),
                ),
              ],
            ),
    );
  }
}

/// A card of the deck, [depth] cards down: one deeper shows under the one
/// above it, a little lower and a little narrower, as the day's deck does.
class _DeckCard extends StatelessWidget {
  const _DeckCard({required this.depth, required this.child});

  final double depth;
  final Widget child;

  static const double peek = 8;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    top: 0,
    bottom: peek * 2,
    child: Transform.translate(
      offset: Offset(0, peek * depth),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(1 - 0.045 * depth, 1, 1),
        child: child,
      ),
    ),
  );
}

/// A claim answered, on its card: the claim, smaller; whether the answer
/// was right and what the claim is; and why, as much as the card holds.
class _Told extends StatelessWidget {
  const _Told({super.key, required this.pill, required this.right});

  final Pill pill;
  final bool right;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bool truth = trueOrFalseAnswer(pill);
    return SubjectCard(
      pill: pill,
      trailing: SubjectTag(pill: pill, text: truth ? l.sayTrue : l.sayFalse),
      child: SubjectTold(
        pill: pill,
        question: claimOf(pill),
        verdict: right ? l.tfRightIs('$truth') : l.tfWrongIs('$truth'),
        why: SubjectTold.withoutVerdict(context, pill.answer),
      ),
    );
  }
}
