/// True or false on a screen of its own (challenge_screen.dart): the day's
/// claims of its shelf on a deck, one at a time, False and True under it,
/// large; each answer told at once, on the card and in the hand, with the
/// first lines of why; then the next. No clock: there is time to think,
/// and to read why.
///
/// It is the shelf's own row, kept and counted as there: an answer is the
/// card's own answer, recorded as the card records one, and a card already
/// answered — here, on its shelf, or on the card — is not asked again.
/// Opened again the same day, the screen opens where the reader left off,
/// or on how it went.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/explore_mix.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import '../../utils/share_link.dart';
import '../scaled_text.dart';
import 'challenge_kit.dart';
import 'challenge_screen.dart';
import 'parts.dart' show upper;
import 'sixty_game.dart' show ClaimCard, DeckCard;

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
  (IconData, String)? note(AppLocalizations l) =>
      (Icons.today_rounded, l.gameCardsToday(pills.length));

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
    if (right) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    final l = context.l10n;
    widget.kit.say(
      '${right ? l.gameRight : l.gameWrong}. '
      '${trueOrFalseAnswer(_game.pills[_at]) ? l.sayTrue : l.sayFalse}.',
    );
    setState(() => _told = true);
  }

  void _next() {
    final int? next = _game.next;
    if (next == null) {
      widget.kit.finish();
      return;
    }
    HapticFeedback.selectionClick();
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
    final int left = [
      for (int i = _at + 1; i < n; i++) _game.saidAt(i) == null,
    ].where((x) => x).length;
    return GamePlayFrame(
      kit: kit,
      count: l.nOfM(_at + 1, n),
      marks: _game.marks,
      at: _at,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int depth = left.clamp(0, 2); depth >= 1; depth--)
            DeckCard(
              index: _at + depth,
              depth: depth.toDouble(),
              child: const ClaimCard(pill: null),
            ),
          DeckCard(
            index: _at,
            depth: 0,
            child: AnimatedSwitcher(
              duration: kit.motion(260),
              child: _told
                  ? _Told(
                      key: ValueKey('tf-told-${p.id}'),
                      pill: p,
                      right: _game.rightAt(_at) ?? false,
                    )
                  : ClaimCard(key: ValueKey('tf-claim-${p.id}'), pill: p),
            ),
          ),
        ],
      ),
      actions: _told
          ? GameButton(
              key: const ValueKey('tf-next'),
              label: _game.next == null ? l.gameSeeResult : l.gameNextCard,
              icon: Icons.arrow_forward_rounded,
              face: kArtInk,
              ink: kArtCream,
              height: 84,
              onTap: _next,
            )
          : Row(
              children: [
                Expanded(
                  child: GameButton(
                    key: const ValueKey('tf-false'),
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
                    key: const ValueKey('tf-true'),
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
}

/// A claim answered: right or wrong, what it is, and the first lines of
/// why, on its card.
class _Told extends StatelessWidget {
  const _Told({super.key, required this.pill, required this.right});

  final Pill pill;
  final bool right;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bool truth = trueOrFalseAnswer(pill);
    return Container(
      decoration: BoxDecoration(
        color: kArtCream,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kArtInk, width: 3),
      ),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GameStamp(right: right, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  right ? l.gameRight : l.gameWrong,
                  style: AppText.display(
                    size: 28,
                    weight: FontWeight.w700,
                    height: 1.05,
                    spacing: -0.6,
                    color: kArtInk,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: truth ? kArtInk : kArtCream,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kArtInk, width: 2.2),
                ),
                child: Text(
                  upper(context, truth ? l.sayTrue : l.sayFalse),
                  style: AppText.label(
                    size: 12,
                    weight: FontWeight.w800,
                    spacing: 0.9,
                    height: 1,
                    color: truth ? kArtCream : kArtInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            claimOf(pill),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppText.display(
              size: 18,
              weight: FontWeight.w600,
              height: 1.18,
              spacing: -0.3,
              color: kArtInk.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: ScaledText(
                text: firstLines(pill.answer, max: 240),
                min: 14,
                max: 21,
                alignment: Alignment.topLeft,
                styleFor: (size) => AppText.body(
                  size: size,
                  weight: FontWeight.w600,
                  height: 1.34,
                  color: kArtInk,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
