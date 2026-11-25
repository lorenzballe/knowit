/// Spot the false one on a screen of its own (challenge_screen.dart): the
/// four claims one under another, each as large as its card takes; a tap
/// picks one, a large button says it is meant; then every claim says what
/// it is, true or false, the pick stamped right or wrong.
///
/// It is the day's game of its shelf, kept and counted as there
/// ([pickSpot]): one pick a day, recorded as that card's answer, the other
/// three counted read. Opened again the same day, the screen opens on how
/// it went.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/explore_mix.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../state/explore_play.dart';
import '../../theme.dart';
import '../../utils/share_link.dart';
import '../scaled_text.dart';
import 'challenge_kit.dart';
import 'challenge_screen.dart';
import 'parts.dart' show upper;
import 'spot_the_false.dart';

/// Spot the false one, as its screen plays it.
class SpotChallenge extends ChallengeGame {
  SpotChallenge({
    required this.spot,
    required this.title,
    required this.onCommit,
    required this.onOpen,
    this.onShown,
  }) {
    ExplorePlay.instance.addListener(notifyListeners);
  }

  /// The day's four claims.
  final SpotTheFalse spot;

  /// The game's name, for the score sent on.
  final String title;

  /// A pick, recorded as the card's own answer.
  final void Function(Pill, String) onCommit;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  String get id => 'spot';

  /// The claim picked today, or null.
  Pill? get picked => switch (spotPicked(spot)) {
    final String id => spot.cards.firstWhere((p) => p.id == id),
    null => null,
  };

  bool get right => picked?.id == spot.falseOne.id;

  @override
  bool get over => picked != null;

  @override
  String rules(AppLocalizations l) => l.spotLine;

  @override
  (IconData, String)? note(AppLocalizations l) =>
      (Icons.today_rounded, l.spotOnce);

  @override
  void start() {
    for (final Pill p in spot.cards) {
      onShown?.call(p);
    }
  }

  /// [pill] said to be the false one.
  void pick(Pill pill) => pickSpot(spot, pill, onCommit);

  @override
  void dispose() {
    ExplorePlay.instance.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  Widget play(BuildContext context, GameKit kit) =>
      _SpotPlay(game: this, kit: kit);

  @override
  GameOutcome outcome(BuildContext context, GameKit kit) {
    final l = context.l10n;
    final Pill? mine = picked;
    return GameOutcome(
      score: right ? '1' : '0',
      of: '1',
      label: l.nOfM(right ? 1 : 0, 1),
      line: right ? l.spotGotIt : l.spotMissedIt,
      review: [
        for (final Pill p in spot.cards)
          () {
            final bool truth = trueOrFalseAnswer(p);
            final String said = truth ? l.sayTrue : l.sayFalse;
            final bool yours = p.id == mine?.id;
            return GameReviewItem(
              key: ValueKey('spot-row-${p.id}'),
              text: claimOf(p),
              tag: said,
              tagDark: truth,
              mark: yours ? right : null,
              detail: yours ? l.spotYours : null,
              semantics: [
                claimOf(p),
                '$said.',
                if (yours) '${l.spotYours}.',
              ].join(' '),
              onTap: () => onOpen(spot.cards, p),
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
        l.gameShareScore(right ? 1 : 0, 1),
        gameSquares([right]),
        ShareRef.challenges.link,
      ].join('\n'),
      event: 'explore spot shared',
      facts: {'right': right ? 1 : 0},
    );
  }
}

class _SpotPlay extends StatefulWidget {
  const _SpotPlay({required this.game, required this.kit});

  final SpotChallenge game;
  final GameKit kit;

  @override
  State<_SpotPlay> createState() => _SpotPlayState();
}

class _SpotPlayState extends State<_SpotPlay>
    with SingleTickerProviderStateMixin {
  SpotChallenge get _game => widget.game;

  /// The claim tapped, not yet said to be meant.
  String? _chosen;

  /// The claims telling what they are, one after another.
  late final AnimationController _tell = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _tell.dispose();
    super.dispose();
  }

  void _choose(Pill p) {
    if (_game.over) return;
    HapticFeedback.selectionClick();
    setState(() => _chosen = _chosen == p.id ? null : p.id);
  }

  void _confirm() {
    final String? id = _chosen;
    if (id == null || _game.over) return;
    final Pill pill = _game.spot.cards.firstWhere((p) => p.id == id);
    _game.pick(pill);
    final bool right = _game.right;
    if (right) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    final l = context.l10n;
    widget.kit.say(right ? l.spotGotIt : l.spotMissedIt);
    if (widget.kit.calm) {
      _tell.value = 1;
    } else {
      _tell.forward(from: 0);
    }
    widget.kit.finish(after: const Duration(milliseconds: 1700));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final GameKit kit = widget.kit;
    final List<Pill> cards = _game.spot.cards;
    final Pill? mine = _game.picked;
    final bool told = mine != null;
    return GamePlayFrame(
      kit: kit,
      status: Text(
        told ? (_game.right ? l.spotGotIt : l.spotMissedIt) : l.spotPrompt,
        key: const ValueKey('spot-prompt'),
        maxLines: 3,
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
        style: AppText.display(
          size: 17,
          weight: FontWeight.w700,
          height: 1.12,
          spacing: -0.2,
          color: kit.ink,
        ),
      ),
      body: AnimatedBuilder(
        animation: _tell,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              Expanded(
                child: _Claim(
                  key: ValueKey('spot-claim-${cards[i].id}'),
                  pill: cards[i],
                  chosen: !told && _chosen == cards[i].id,
                  // Each claim tells what it is a beat after the one
                  // above it.
                  tell: told
                      ? ((_tell.value * 1.6 - i * 0.2).clamp(0.0, 1.0))
                      : 0,
                  mine: mine?.id == cards[i].id,
                  onTap: () => _choose(cards[i]),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: GameButton(
        key: const ValueKey('spot-confirm'),
        label: l.spotConfirm,
        icon: Icons.close_rounded,
        face: kArtInk,
        ink: kArtCream,
        height: 72,
        onTap: _chosen != null && !told ? _confirm : null,
      ),
    );
  }
}

/// One claim of the four, on its card: picked, it turns to ink; told, it
/// says what it is, and the pick is stamped.
class _Claim extends StatelessWidget {
  const _Claim({
    super.key,
    required this.pill,
    required this.chosen,
    required this.tell,
    required this.mine,
    required this.onTap,
  });

  final Pill pill;
  final bool chosen;

  /// How far it has told what it is, 0 to 1.
  final double tell;
  final bool mine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bool truth = trueOrFalseAnswer(pill);
    final bool told = tell > 0;
    final Color face = chosen ? kArtInk : gameFace(context);
    final Color ink = chosen ? kArtCream : kArtInk;
    final double fade = told && truth && !mine ? 0.72 : 1;
    return Semantics(
      button: !told,
      selected: chosen,
      label: [
        claimOf(pill),
        if (told) '${truth ? l.sayTrue : l.sayFalse}.',
        if (mine) '${l.spotYours}.',
      ].join(' '),
      excludeSemantics: true,
      onTap: told ? null : onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: fade,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  decoration: BoxDecoration(
                    color: face,
                    borderRadius: BorderRadius.circular(22),
                    border: gameBorder(context),
                  ),
                  child: ScaledText(
                    text: claimOf(pill),
                    min: 13,
                    max: 22,
                    alignment: Alignment.centerLeft,
                    styleFor: (size) => AppText.display(
                      size: size,
                      weight: FontWeight.w600,
                      height: 1.14,
                      spacing: -0.02 * size,
                      color: ink,
                    ).copyWith(
                      decoration: told && !truth
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: kGameWrong,
                      decorationThickness: 2.4,
                    ),
                  ),
                ),
              ),
            ),
            if (told)
              Positioned(
                right: 10,
                bottom: -8,
                child: Transform.scale(
                  scale: Curves.easeOutBack.transform(tell),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: truth ? kArtInk : kGameWrong,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kArtInk, width: 2.2),
                    ),
                    child: Text(
                      upper(context, truth ? l.sayTrue : l.sayFalse),
                      style: AppText.label(
                        size: 11,
                        weight: FontWeight.w800,
                        spacing: 0.9,
                        height: 1,
                        color: kArtCream,
                      ),
                    ),
                  ),
                ),
              ),
            if (told && mine)
              Positioned(
                right: -6,
                top: -10,
                child: GameStamp(
                  right: !truth,
                  size: 46,
                  scale: Curves.easeOutBack.transform(tell),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
