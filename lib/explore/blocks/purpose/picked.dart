/// Picked for you — the canvas's 133d.
///
/// The themed shelves are the same for everybody (themed_shelves.dart);
/// these are not. Each is picked from what the app already knows of the
/// reader: the level measured in each subject, what they have read, the
/// sides they took. Came back, the fourth of the design, is the reviews
/// waiting, which Explore already shows; it is core's.
library;

import 'package:flutter/material.dart';

import '../../../data/topics.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../explore_block.dart';
import 'commit.dart' show shortSide;
import 'kit.dart';

// ── A step above ─────────────────────────────────────────────────────────

/// The difficulty a step above a measured [level]: 0 curious reads medium,
/// 1 some reads hard, and 2 solid reads hard, there being nothing harder.
Difficulty stepAbove(int level) =>
    level <= 0 ? Difficulty.medium : Difficulty.hard;

/// How many of a difficulty's four bars are lit.
int barsOf(Difficulty d) => switch (d) {
  Difficulty.easy => 2,
  Difficulty.medium => 3,
  Difficulty.hard => 4,
};

/// 133d: cards a step past the reader's measured level in their subject,
/// dark, ringed in the subject's colour, the difficulty drawn in bars.
class StepAboveBlock extends ExploreBlock {
  const StepAboveBlock();

  @override
  String get name => 'purpose.step-above';

  /// The block's sizes; `m` is the canvas's.
  static const Map<String, TileSize> sizes = {
    's': TileSize(180, 204),
    'm': TileSize(204, 226),
    'l': TileSize(232, 252),
  };

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final Map<String, int> levels = host.app.measuredLevels;
    final List<Pill> cards = cardsOf(
      host,
      section,
      limit: 8,
      // A card read is not a step anywhere.
      canDraw: (p) => !host.isRead(p),
      fits: (p) => p.difficulty == stepAbove(levels[subjectKey(p)] ?? 1),
    );
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final String lang = host.language;
    final TileSize size = sizeOf(section, sizes);
    return host.watch(
      section,
      PurposeShelf(
        title: section.title(lang) ?? l.purposeStepAbove,
        line: section.subtitle(lang) ?? l.purposeStepAboveLine,
        child: SideRow(
          height: size.height + 4,
          count: cards.length,
          itemBuilder: (context, i) {
            final Pill p = cards[i];
            host.seen(section, p);
            return StepTile(
              pill: p,
              size: size,
              onOpen: () => host.open(section, cards, p),
            );
          },
        ),
      ),
    );
  }
}

/// A card a step above: the colour held back to its edge and its marks, as
/// For the sharpest holds it, and the difficulty in four bars at its foot.
class StepTile extends StatelessWidget {
  const StepTile({
    super.key,
    required this.pill,
    required this.size,
    required this.onOpen,
  });

  final Pill pill;
  final TileSize size;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final Pill p = pill;
    final bool dark = context.p.isDark;
    // On paper a pale colour cannot carry text: take its darker tone.
    final Color accent = !dark && p.color.computeLuminance() > 0.45
        ? shade(p.color, 0.62)
        : p.color;
    final Color ground = dark
        ? const Color(0xFF0B0B0D)
        : context.p.surfaceRaised;
    final int lit = barsOf(p.difficulty);
    return CardTap(
      pill: p,
      onTap: onOpen,
      child: Container(
        width: size.width,
        height: size.height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PurposeHead(pill: p, ink: accent, labelInk: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: CardQuestion(
                  text: p.question,
                  color: context.p.ink,
                  min: 11,
                  max: size.width < 200 ? 15.5 : 17,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int k = 0; k < 4; k++) ...[
                  if (k > 0) const SizedBox(width: 3),
                  Container(
                    width: 6,
                    height: const [6.0, 9.0, 12.0, 16.0][k],
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: k < lit ? 1 : 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    upper(
                      context,
                      context.l10n.difficultyLabel(p.difficulty.name),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(
                      size: 9,
                      weight: FontWeight.w700,
                      spacing: 1.2,
                      height: 1,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Thin for you ─────────────────────────────────────────────────────────

/// How many cards the reader has to have read before one subject can be
/// called thinner than the rest: before that, every subject is as thin as
/// the next, and naming one would be a guess dressed as a finding.
const int kThinFloor = 12;

/// A subject's share of its cards here that the reader has read.
@immutable
class SubjectShare {
  const SubjectShare(this.key, this.read, this.total);

  final String key;
  final int read;
  final int total;

  double get share => total == 0 ? 0 : read / total;

  /// In whole per cent, never 0 for a subject with something read.
  int get percent {
    final int p = (share * 100).round();
    return read > 0 && p == 0 ? 1 : p;
  }
}

/// The subject among [pool]'s that the reader has read the least of, by
/// share, among the subjects they read and that have cards left to read;
/// null before the reader has read [kThinFloor] cards.
SubjectShare? thinnestOf(
  List<Pill> pool, {
  required bool Function(Pill) isRead,
  required Set<String> picked,
  required int readInAll,
  String? only,
}) {
  if (readInAll < kThinFloor) return null;
  final Map<String, int> read = {};
  final Map<String, int> total = {};
  final Map<String, int> left = {};
  for (final Pill p in pool) {
    final String key = subjectKey(p);
    if (key.isEmpty) continue;
    total[key] = (total[key] ?? 0) + 1;
    if (isRead(p)) {
      read[key] = (read[key] ?? 0) + 1;
    } else {
      left[key] = (left[key] ?? 0) + 1;
    }
  }
  final List<SubjectShare> shares = [
    for (final String key in kTopicOrder)
      if ((only == null || key == only) &&
          (only != null || picked.contains(key)) &&
          (left[key] ?? 0) >= 3)
        SubjectShare(key, read[key] ?? 0, total[key]!),
  ];
  if (shares.isEmpty) return null;
  // The least read by share; the subjects' own order breaks a tie, so the
  // shelf is the same one every time the page is built.
  SubjectShare least = shares.first;
  for (final SubjectShare s in shares.skip(1)) {
    if (s.share < least.share) least = s;
  }
  return least;
}

/// 133d: the subject the reader has read least of, how much, and its
/// cards not read yet.
class ThinSubjectBlock extends ExploreBlock {
  const ThinSubjectBlock();

  @override
  String get name => 'purpose.thin-subject';

  /// The block's sizes; `m` is the canvas's.
  static const Map<String, TileSize> sizes = {
    's': TileSize(176, 188),
    'm': TileSize(200, 208),
    'l': TileSize(228, 232),
  };

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> pool = host.cardsFor(section, limit: kPurposePool);
    final Object? asked = section.json['subject'];
    final SubjectShare? thin = thinnestOf(
      pool,
      isRead: host.isRead,
      picked: host.app.pickedTopics,
      readInAll: host.app.seenIds.length,
      only: asked is String && kTopics.containsKey(asked) ? asked : null,
    );
    if (thin == null) return null;
    final List<Pill> cards = [
      for (final Pill p in pool)
        if (subjectKey(p) == thin.key && !host.isRead(p)) p,
    ].take(limitOf(section, 8)).toList();
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final String lang = host.language;
    final String subject = l.subjectName(thin.key);
    final Color colour = kTopics[thin.key]!.color;
    final TileSize size = sizeOf(section, sizes);
    return host.watch(
      section,
      PurposeShelf(
        title: section.title(lang) ?? l.purposeThinTitle(subject),
        line:
            section.subtitle(lang) ?? l.purposeThinLine(thin.percent, subject),
        under: _ShareBar(share: thin.share, colour: colour),
        child: SideRow(
          height: size.height + 4,
          count: cards.length,
          itemBuilder: (context, i) {
            final Pill p = cards[i];
            host.seen(section, p);
            return PlainTile(
              pill: p,
              size: size,
              onOpen: () => host.open(section, cards, p),
            );
          },
        ),
      ),
    );
  }
}

/// How much of a subject is read, as a thin bar in its colour.
class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.share, required this.colour});

  final double share;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: 5,
        decoration: BoxDecoration(
          color: context.p.ink.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          // Never less than a dot: a share of nothing still shows where the
          // bar starts.
          widthFactor: share.clamp(0.012, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colour,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
      ),
    );
  }
}

// ── The other side ───────────────────────────────────────────────────────

/// The side the reader took on a debate, from the answer it was given, or
/// null when they took none.
int? sideTaken(Pill p, Answer? answer) {
  if (p.challenge is! TakeASide || answer == null) return null;
  final int? side = int.tryParse(answer.response);
  return side == 0 || side == 1 ? side : null;
}

/// 133d: the debates the reader took a side on, each the way to the best
/// case against it, which is the card.
class OtherSideBlock extends ExploreBlock {
  const OtherSideBlock();

  @override
  String get name => 'purpose.other-side';

  /// The block's sizes; `m` is the canvas's.
  static const Map<String, TileSize> sizes = {
    's': TileSize(256, 184),
    'm': TileSize(290, 204),
    'l': TileSize(320, 224),
  };

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> cards = cardsOf(
      host,
      section,
      limit: 8,
      canDraw: (p) => sideTaken(p, host.app.answerFor(p.id)) != null,
    );
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final String lang = host.language;
    final TileSize size = sizeOf(section, sizes);
    return host.watch(
      section,
      PurposeShelf(
        title: section.title(lang) ?? l.purposeOtherSide,
        line: section.subtitle(lang) ?? l.purposeOtherSideLine,
        child: SideRow(
          height: size.height + 4,
          count: cards.length,
          itemBuilder: (context, i) {
            final Pill p = cards[i];
            host.seen(section, p);
            return OtherSideTile(
              pill: p,
              side: sideTaken(p, host.app.answerFor(p.id))!,
              size: size,
              onOpen: () => host.open(section, cards, p),
            );
          },
        ),
      ),
    );
  }
}

/// A debate the reader took a side on: in two tones, as Pick a side draws
/// one, the side they took in a badge, and the button to the other's case.
class OtherSideTile extends StatelessWidget {
  const OtherSideTile({
    super.key,
    required this.pill,
    required this.side,
    required this.size,
    required this.onOpen,
  });

  final Pill pill;

  /// The side taken: 0 or 1.
  final int side;
  final TileSize size;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final Pill p = pill;
    final l = context.l10n;
    final List<String> positions = (p.challenge as TakeASide).positions;
    final String mine = shortSide(positions[side]);
    final String theirs = shortSide(positions[1 - side]);
    return CardTap(
      pill: p,
      onTap: onOpen,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  p.color,
                  p.color,
                  shade(p.color, 0.84),
                  shade(p.color, 0.84),
                ],
                stops: const [0, 0.5, 0.5, 1],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PurposeHead(
                    pill: p,
                    trailingAtEnd: true,
                    trailing: Container(
                      key: ValueKey('you-said-${p.id}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: p.ink.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        upper(context, l.purposeYouSaid(mine)),
                        maxLines: 1,
                        style: AppText.label(
                          size: 9,
                          weight: FontWeight.w700,
                          spacing: 1,
                          height: 1,
                          color: p.ink,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: CardQuestion(
                        text: p.question,
                        color: p.ink,
                        min: 12,
                        max: size.width < 280 ? 17 : 19,
                        height: 1.14,
                        tracking: -0.03,
                      ),
                    ),
                  ),
                  Container(
                    key: ValueKey('case-for-${p.id}'),
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: p.ink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.purposeCaseFor(theirs),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              size: 13,
                              weight: FontWeight.w700,
                              height: 1,
                              color: p.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PurposeGlyph(Glyphs.arrow, size: 16, color: p.color),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
