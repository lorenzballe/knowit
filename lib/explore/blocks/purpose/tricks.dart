/// Where the trick hides — the canvas's 138b.
///
/// The same few moves catch a trick wherever it is set: in a headline, in
/// a number, in an offer, in an argument. Each is a shelf in the shape of
/// the place — a paper's rules, a figure that wants its denominator, a
/// price tag, a speech bubble — and under them, what to keep: the
/// questions that catch most of them.
library;

import 'package:flutter/material.dart';

import '../../../data/topics.dart' show TopicStyle, kTopics;
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/card_edge.dart';
import '../../../widgets/fit_text.dart';
import '../../../widgets/subject_icon.dart';
import '../../explore_block.dart';
import 'kit.dart';
import 'move.dart' show moveNamed;

/// A shelf of the tricks: the form's name and line unless the section
/// gives its own, and its cards in a row [height] high.
Widget _trickShelf({
  required ExploreHost host,
  required ExploreSection section,
  required String title,
  required String line,
  required List<Pill> cards,
  required double height,
  double gap = 10,
  required Widget Function(Pill pill) tile,
}) {
  final String lang = host.language;
  return host.watch(
    section,
    PurposeShelf(
      title: section.title(lang) ?? title,
      line: section.subtitle(lang) ?? line,
      child: SideRow(
        height: height,
        count: cards.length,
        gap: gap,
        itemBuilder: (context, i) {
          host.seen(section, cards[i]);
          return tile(cards[i]);
        },
      ),
    ),
  );
}

// ── In a headline ────────────────────────────────────────────────────────

/// Genres that are about reading a claim: a study, a health claim, the
/// money news, what is true online.
const Set<String> kClaimGenres = {
  'science.read_a_study',
  'science.spot_bad_science',
  'science.how_science_knows',
  'human_body.health_claims',
  'food.food_claims',
  'medicine.judge_a_treatment',
  'medicine.medical_myths',
  'economics.read_money_news',
  'technology.truth_online',
  'pop_culture.behind_the_hype',
};

/// Words that make a question a claim reported: a study, a survey, a
/// trial, what researchers reported.
final RegExp _claimWords = RegExp(
  r'\b(study|studies|research|researchers|survey|surveyed|trial|trials|'
  r'reported|report|experiment|data)\b',
  caseSensitive: false,
);

/// Whether [p] is a claim to read the way a paper prints it: from a genre
/// about claims, or a reported finding with a trick in it.
bool isClaim(Pill p) =>
    kClaimGenres.contains(p.genre) ||
    (kTraps.contains(p.principle) && _claimWords.hasMatch(p.question));

/// 138b: claims as a paper prints them, under a double rule.
class HeadlineBlock extends ExploreBlock {
  const HeadlineBlock();

  @override
  String get name => 'purpose.headline';

  /// The block's sizes; `m` is the canvas's.
  static const Map<String, TileSize> sizes = {
    's': TileSize(210, 212),
    'm': TileSize(240, 236),
    'l': TileSize(270, 262),
  };

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> cards = cardsOf(host, section, limit: 8, fits: isClaim);
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final TileSize size = sizeOf(section, sizes);
    return _trickShelf(
      host: host,
      section: section,
      title: l.purposeHeadline,
      line: l.purposeHeadlineLine,
      cards: cards,
      height: size.height + 4,
      tile: (p) => HeadlineTile(
        pill: p,
        size: size,
        read: host.isRead(p),
        onOpen: () => host.open(section, cards, p),
      ),
    );
  }
}

/// A claim under a paper's rules: THE CLAIM and the subject between them,
/// and the question set like a headline.
class HeadlineTile extends StatelessWidget {
  const HeadlineTile({
    super.key,
    required this.pill,
    required this.size,
    required this.read,
    required this.onOpen,
  });

  final Pill pill;
  final TileSize size;
  final bool read;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final Pill p = pill;
    final TextStyle label = AppText.label(
      size: 9,
      weight: FontWeight.w700,
      spacing: 1.2,
      height: 1,
      color: p.ink,
    );
    return CardTap(
      pill: p,
      onTap: onOpen,
      child: Container(
        width: size.width,
        height: size.height,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: cardFace(context, p.color, radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(height: 2, color: p.ink),
                  const SizedBox(height: 3),
                  Container(height: 1, color: p.ink),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: hairOn(p))),
              ),
              child: Row(
                children: [
                  Text(
                    upper(context, context.l10n.purposeTheClaim),
                    style: label,
                  ),
                  if (read) ...[
                    const SizedBox(width: 6),
                    ReadMark(pill: p, size: 11),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      upper(context, context.l10n.subjectOf(p.topic)),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: label.copyWith(color: subOn(p)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: CardQuestion(
                  text: p.question,
                  color: p.ink,
                  min: 11,
                  max: size.width < 230 ? 17 : 19,
                  height: 1.14,
                  tracking: -0.03,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── In a number ──────────────────────────────────────────────────────────

final RegExp _share = RegExp(
  r'(\d+(?:\.\d+)?)\s?(?:%|per ?cent\b)|\b(\d[\d,]*)\s+in\s+(\d[\d,]*)\b',
  caseSensitive: false,
);

/// The share or the odds [p]'s question rests on, as the question puts
/// them — `99%`, `1 in 100` — or null when it states none.
String? shareFigure(Pill p) {
  final RegExpMatch? m = _share.firstMatch(p.question);
  if (m == null) return null;
  return m.group(1) != null
      ? '${m.group(1)}%'
      : '${m.group(2)} in ${m.group(3)}';
}

/// 138b: a share or the odds set large, and the question to ask of it:
/// out of what?
class OutOfWhatBlock extends ExploreBlock {
  const OutOfWhatBlock();

  @override
  String get name => 'purpose.out-of-what';

  /// The block's sizes; `m` is the canvas's.
  static const Map<String, TileSize> sizes = {
    's': TileSize(172, 208),
    'm': TileSize(194, 228),
    'l': TileSize(220, 252),
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
      canDraw: (p) => shareFigure(p) != null,
      fits: (p) => kTraps.contains(p.principle),
    );
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final TileSize size = sizeOf(section, sizes);
    return _trickShelf(
      host: host,
      section: section,
      title: l.purposeNumber,
      line: l.purposeNumberLine,
      cards: cards,
      height: size.height + 4,
      tile: (p) => FigureTile(
        pill: p,
        size: size,
        read: host.isRead(p),
        onOpen: () => host.open(section, cards, p),
      ),
    );
  }
}

/// The figure large, OUT OF WHAT? under it, and the question at the foot.
class FigureTile extends StatelessWidget {
  const FigureTile({
    super.key,
    required this.pill,
    required this.size,
    required this.read,
    required this.onOpen,
  });

  final Pill pill;
  final TileSize size;
  final bool read;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final Pill p = pill;
    final double large = size.width < 185 ? 44 : (size.width < 210 ? 50 : 56);
    return CardTap(
      pill: p,
      onTap: onOpen,
      child: Container(
        width: size.width,
        height: size.height,
        padding: const EdgeInsets.all(16),
        decoration: cardFace(context, p.color, radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  // One line, as large as the width allows: "1 in 100"
                  // sets smaller than "9%", as the canvas sets it.
                  child: FitText(
                    shareFigure(p)!,
                    maxLines: 1,
                    minSize: 22,
                    style: AppText.display(
                      size: large,
                      weight: FontWeight.w600,
                      height: 0.98,
                      spacing: -0.04 * large,
                      color: p.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (read) ...[
                        ReadMark(pill: p),
                        const SizedBox(width: 5),
                      ],
                      Semantics(
                        label: context.l10n.subjectOf(p.topic),
                        child: SubjectIcon(
                          subject: p.topic,
                          size: 15,
                          ink: p.ink,
                          stroke: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Text(
                upper(context, context.l10n.purposeOutOfWhat),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label(
                  size: 9,
                  weight: FontWeight.w700,
                  spacing: 1.2,
                  height: 1,
                  color: subOn(p),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: CardQuestion(
                  text: p.question,
                  color: p.ink,
                  min: 10.5,
                  max: size.width < 185 ? 13.5 : 14.5,
                  height: 1.18,
                  tracking: -0.022,
                  alignment: Alignment.bottomLeft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── In an offer ──────────────────────────────────────────────────────────

/// Genres about prices, deals and who pays.
const Set<String> kOfferGenres = {
  'economics.pricing_tricks',
  'economics.spot_a_bad_deal',
  'economics.everyday_costs',
  'economics.your_money_decisions',
  'economics.think_in_incentives',
  'economics.markets_and_hype',
  'art.what_makes_it_valuable',
  'music.the_music_business',
};

/// 138b: offers, each as a price tag.
class PriceTagBlock extends ExploreBlock {
  const PriceTagBlock();

  @override
  String get name => 'purpose.price-tag';

  /// The block's sizes; `m` is the canvas's.
  static const Map<String, TileSize> sizes = {
    's': TileSize(240, 146),
    'm': TileSize(270, 160),
    'l': TileSize(300, 178),
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
      fits: (p) => kOfferGenres.contains(p.genre),
    );
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final TileSize size = sizeOf(section, sizes);
    return _trickShelf(
      host: host,
      section: section,
      title: l.purposeOffer,
      line: l.purposeOfferLine,
      cards: cards,
      height: size.height + 4,
      tile: (p) => TagTile(
        pill: p,
        size: size,
        read: host.isRead(p),
        onOpen: () => host.open(section, cards, p),
      ),
    );
  }
}

/// The outline of a price tag [size] big: a point at the left, the hole
/// punched through it, the other corners rounded.
Path tagPath(Size size) {
  const double point = 26;
  const double r = 20;
  final double w = size.width, h = size.height;
  final Path tag = Path()
    ..moveTo(point, 0)
    ..lineTo(w - r, 0)
    ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
    ..lineTo(w, h - r)
    ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
    ..lineTo(point, h)
    ..lineTo(0, h / 2)
    ..close();
  final Path hole = Path()
    ..addOval(Rect.fromCircle(center: Offset(21, h / 2), radius: 7));
  return Path.combine(PathOperation.difference, tag, hole);
}

/// An offer as a price tag: the point, the hole, the line it tears along.
class TagTile extends StatelessWidget {
  const TagTile({
    super.key,
    required this.pill,
    required this.size,
    required this.read,
    required this.onOpen,
  });

  final Pill pill;
  final TileSize size;
  final bool read;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final Pill p = pill;
    return CardTap(
      pill: p,
      onTap: onOpen,
      child: CustomPaint(
        painter: ShapedFace(
          shape: tagPath,
          colour: p.color,
          ground: context.p.surface,
        ),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              Positioned(
                left: 36,
                top: 12,
                bottom: 12,
                child: ExcludeSemantics(
                  child: CustomPaint(
                    size: const Size(1.5, double.infinity),
                    painter: _Dashes(hairOn(p)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(46, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PurposeHead(
                      pill: p,
                      trailing: read ? ReadMark(pill: p) : null,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: CardQuestion(
                          text: p.question,
                          color: p.ink,
                          min: 10.5,
                          max: size.height < 155 ? 15.5 : 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A dashed line down the space it is given.
class _Dashes extends CustomPainter {
  _Dashes(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pen = Paint()
      ..color = colour
      ..strokeWidth = 1.5;
    for (double y = 0; y < size.height; y += 7) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + 3.5).clamp(0, size.height)),
        pen,
      );
    }
  }

  @override
  bool shouldRepaint(_Dashes old) => old.colour != colour;
}

// ── In an argument ───────────────────────────────────────────────────────

/// Genres about arguing, persuading and changing your mind.
const Set<String> kArgumentGenres = {
  'philosophy.arguments',
  'psychology.resist_persuasion',
  'psychology.change_your_mind',
  'language.words_that_persuade',
  'life.clear_thinking',
  'life.ask_better_questions',
  'cinema.how_films_persuade',
  'history.propaganda',
};

/// 138b: arguments, each as a speech bubble.
class ArgumentBlock extends ExploreBlock {
  const ArgumentBlock();

  @override
  String get name => 'purpose.argument';

  /// The block's sizes, the bubble without its tail; `m` is the canvas's.
  static const Map<String, TileSize> sizes = {
    's': TileSize(228, 152),
    'm': TileSize(258, 168),
    'l': TileSize(288, 186),
  };

  /// How far the tail reaches below the bubble.
  static const double tail = 10;

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
      fits: (p) => kArgumentGenres.contains(p.genre),
    );
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final TileSize size = sizeOf(section, sizes);
    return _trickShelf(
      host: host,
      section: section,
      title: l.purposeArgument,
      line: l.purposeArgumentLine,
      cards: cards,
      height: size.height + tail + 4,
      gap: 12,
      tile: (p) => BubbleTile(
        pill: p,
        size: size,
        read: host.isRead(p),
        onOpen: () => host.open(section, cards, p),
      ),
    );
  }
}

/// The outline of a speech bubble whose body is [body] big, its tail
/// reaching [ArgumentBlock.tail] below its lower left corner.
Path bubblePath(Size body) {
  final RRect box = RRect.fromRectAndCorners(
    Offset.zero & body,
    topLeft: const Radius.circular(22),
    topRight: const Radius.circular(22),
    bottomRight: const Radius.circular(22),
    bottomLeft: const Radius.circular(6),
  );
  final Path tail = Path()
    ..moveTo(0, body.height - 2)
    ..lineTo(22, body.height - 2)
    ..lineTo(0, body.height + ArgumentBlock.tail)
    ..close();
  return Path.combine(PathOperation.union, Path()..addRRect(box), tail);
}

/// An argument as a speech bubble, its tail at the foot.
class BubbleTile extends StatelessWidget {
  const BubbleTile({
    super.key,
    required this.pill,
    required this.size,
    required this.read,
    required this.onOpen,
  });

  final Pill pill;
  final TileSize size;
  final bool read;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final Pill p = pill;
    final Size body = Size(size.width, size.height);
    return CardTap(
      pill: p,
      onTap: onOpen,
      child: CustomPaint(
        painter: ShapedFace(
          shape: (_) => bubblePath(body),
          colour: p.color,
          ground: context.p.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: ArgumentBlock.tail),
          child: Container(
            width: size.width,
            height: size.height,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PurposeHead(
                  pill: p,
                  trailing: read ? ReadMark(pill: p) : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: CardQuestion(
                      text: p.question,
                      color: p.ink,
                      min: 10.5,
                      max: size.width < 240 ? 16 : 17.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── What to keep ─────────────────────────────────────────────────────────

/// The moves a box of what to keep names when its section names none: the
/// three the canvas keeps, which between them catch most of the tricks on
/// the shelves above it.
const List<Principle> kKeepMoves = [
  Principle.counterfactual,
  Principle.sampling,
  Principle.baseRate,
];

/// 138b: what to keep — the questions that catch most of these, each the
/// question a move asks and the line that says the move.
class KeepBlock extends ExploreBlock {
  const KeepBlock();

  @override
  String get name => 'purpose.keep';

  /// The most questions a box holds.
  static const int most = 5;

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final l = context.l10n;
    final String lang = host.language;
    final List<(String, String)> items = [];
    // The questions themselves, when the section writes them; otherwise
    // the moves it names, or the canvas's three, in the app's words.
    for (final Map<Object?, Object?> item in partsOf(section, 'items')) {
      final ExploreSection part = ExploreSection(
        id: section.id,
        block: section.block,
        json: {
          for (final MapEntry<Object?, Object?> e in item.entries)
            if (e.key is String) e.key! as String: e.value,
        },
      );
      final String? ask = part.text('ask', lang);
      if (ask == null || ask.trim().isEmpty) continue;
      items.add((ask, part.text('line', lang) ?? ''));
    }
    if (items.isEmpty) {
      // Moves this build does not know are passed over; a box whose every
      // move is unknown is left out rather than filled with other ones.
      final Object? named = section.json['moves'];
      final List<Principle> moves = named is List
          ? [for (final Object? m in named) ?moveNamed(m)]
          : kKeepMoves;
      for (final Principle m in moves.toSet()) {
        items.add((l.purposeMoveAsk(m.name), l.purposeMoveLine(m.name)));
      }
    }
    if (items.isEmpty) return null;
    final List<(String, String)> shown = items.take(most).toList();
    return host.watch(
      section,
      KeepBox(
        heading: wordsOf(
          section,
          'heading',
          lang,
          l.purposeKeepHeading('${shown.length}'),
        ),
        items: shown,
      ),
    );
  }
}

/// The box of what to keep: WHAT TO KEEP, how many questions, and each
/// numbered, the question large and the line that says why under it.
class KeepBox extends StatelessWidget {
  const KeepBox({super.key, required this.heading, required this.items});

  final String heading;
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    // The box is a Thinking card: the app's own voice, in its own white,
    // on either paper.
    final TopicStyle thinking = kTopics['thinking']!;
    final Color ink = thinking.ink;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: cardFace(context, thinking.color, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PurposeGlyph(Glyphs.bulb, size: 15, color: ink, stroke: 2),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  upper(context, context.l10n.barMoveCaps),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    size: 9,
                    weight: FontWeight.w700,
                    spacing: 1.2,
                    height: 1,
                    color: ink.withValues(alpha: 0.66),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            heading,
            style: AppText.display(
              size: 22,
              weight: FontWeight.w600,
              height: 1.14,
              spacing: -0.6,
              color: ink,
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < items.length; i++)
            Container(
              padding: EdgeInsets.only(
                top: 12,
                bottom: i == items.length - 1 ? 0 : 12,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: ink.withValues(alpha: 0.14)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ink,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: AppText.display(
                          size: 11,
                          weight: FontWeight.w600,
                          height: 1,
                          color: thinking.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].$1,
                          style: AppText.display(
                            size: 15.5,
                            weight: FontWeight.w600,
                            height: 1.2,
                            spacing: -0.2,
                            color: ink,
                          ),
                        ),
                        if (items[i].$2.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            items[i].$2,
                            style: AppText.body(
                              size: 12,
                              weight: FontWeight.w500,
                              height: 1.35,
                              color: ink.withValues(alpha: 0.64),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
