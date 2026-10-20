/// The front page — artboard 141f, in seven blocks.
///
/// The day laid out the way a paper lays out its front: the masthead
/// (`masthead`), the lead with its standfirst (`front-lead`), two columns
/// (`front-columns`), the figures (`front-numbers`), a correction
/// (`front-correction`), a puzzle (`front-puzzle`) and the line that says
/// the edition ends (`edition-end`). Each is a block of its own, so a day
/// can be a whole front page and another day can borrow its numbers or its
/// puzzle for an ordinary Explore.
///
/// With a source of its own a part shows the cards it is given, in order.
/// Without one it deals, by the day, from all the cards Explore has for it,
/// the kind of card the part is for — a story or a mechanism to lead with,
/// a side to pick and a thing to use in the columns, a figure, a myth, a
/// sum. Every card is for one part at most, so the parts of a page made
/// only of defaults never print the same card twice; and the deal is the
/// day's, not the reader's, so the page is the same for everyone who opens
/// it that day, read or not, as the masthead says.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../data/explore_mix.dart';
import '../../../data/themed_shelves.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/balanced_text.dart';
import '../../explore_block.dart';
import 'parts.dart';

/// How many of Explore's cards a part deals from when the section names
/// none: all of them, so that the day's deal can land on any card and does
/// not hang on the order Explore keeps them in.
const int kFrontPool = 10000;

/// Whether the section names its cards one by one, in which case they are
/// shown as named: the page's editor chose them.
bool handPicked(ExploreSection section) {
  final Object? source = section.source;
  return source is Map && source['ids'] is List;
}

/// The parts of the page a card can be for.
enum FrontPart { lead, column, figure, correction, puzzle }

/// The part [pill] is for when nobody named it, or null for a card no part
/// is for. A figure goes to In numbers, a myth to the corrections, a sum to
/// the puzzle, a side to pick or a thing to use to the columns, and a
/// story, paradox, mechanism or origin to the lead, in that order.
FrontPart? frontPartOf(Pill pill) {
  if (pill.hook == 'number') {
    // A number with no figure in its question has nothing to set large,
    // and is no puzzle either: its answer is the figure.
    return shelfFigure(pill) != null ? FrontPart.figure : null;
  }
  if (pill.hook == 'misconception') return FrontPart.correction;
  if (pill.challenge is TypeNumber ||
      pill.challenge is Estimate ||
      pill.hook == 'puzzle') {
    return FrontPart.puzzle;
  }
  if (pill.challenge is TakeASide || pill.hook == 'practical') {
    return FrontPart.column;
  }
  if (const {'story', 'paradox', 'mechanism', 'origin'}.contains(pill.hook)) {
    return FrontPart.lead;
  }
  return null;
}

/// A lead: something that happened, a paradox, a mechanism, an origin.
bool isLead(Pill p) => frontPartOf(p) == FrontPart.lead;

/// A figure for "In numbers": a card about a number whose question has one.
bool isFigure(Pill p) => frontPartOf(p) == FrontPart.figure;

/// A correction: what almost everyone believes.
bool isCorrection(Pill p) => frontPartOf(p) == FrontPart.correction;

/// A puzzle: a sum to work out, or a card that is one.
bool isPuzzle(Pill p) => frontPartOf(p) == FrontPart.puzzle;

/// The cards for [part]: those the section names, in order; or the day's
/// deal of [count] of its kind from all Explore has, one per subject while
/// there are subjects enough. [on] is the day, today unless a test says.
List<Pill> frontCards(
  ExploreHost host,
  ExploreSection section,
  FrontPart part, {
  required int count,
  DateTime? on,
}) {
  if (handPicked(section)) return host.cardsFor(section, limit: count);
  return dealCards(
    host
        .cardsFor(section, limit: kFrontPool)
        .where((p) => frontPartOf(p) == part),
    salt: 'front-${part.name}',
    day: themeDay(on ?? DateTime.now()),
    count: count,
    perTopic: 1,
  );
}

/// The two columns: a side to pick and a thing to use, dealt by the day;
/// short of either, another card for the columns, then a card no part is
/// for, so that the columns never take another part's card.
List<Pill> frontColumns(
  ExploreHost host,
  ExploreSection section, {
  DateTime? on,
}) {
  if (handPicked(section)) return host.cardsFor(section, limit: 2);
  final List<Pill> pool = host.cardsFor(section, limit: kFrontPool);
  final int day = themeDay(on ?? DateTime.now());
  List<Pill> deal(Iterable<Pill> fits, String salt, int count) =>
      dealCards(fits, salt: 'front-$salt', day: day, count: count, perTopic: 1);
  final List<Pill> columns = [
    for (final Pill p in pool)
      if (frontPartOf(p) == FrontPart.column) p,
  ];
  final List<Pill> out = [
    ...deal(columns.where((p) => p.challenge is TakeASide), 'side', 1),
    ...deal(columns.where((p) => p.challenge is! TakeASide), 'use', 1),
  ];
  for (final (Iterable<Pill> fits, String salt) in [
    (columns, 'column'),
    (pool.where((p) => frontPartOf(p) == null), 'other'),
  ]) {
    if (out.length >= 2) break;
    out.addAll(deal(fits.where((p) => !out.contains(p)), salt, 2 - out.length));
  }
  return out;
}

/// The day's date as a paper prints it, in the reader's language.
String frontDate(BuildContext context, DateTime on) {
  final String locale = Localizations.localeOf(context).toString();
  try {
    return intl.DateFormat.MMMMEEEEd(locale).format(on);
  } catch (_) {
    return intl.DateFormat.MMMMEEEEd('en').format(on);
  }
}

TextStyle _caps(Color colour) => AppText.label(
  size: 9.5,
  weight: FontWeight.w700,
  spacing: 1.3,
  height: 1.2,
  color: colour,
);

/// A subject's dot and name, the way a column is headed.
class _Dotted extends StatelessWidget {
  const _Dotted({required this.pill, this.label});

  final Pill pill;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: pill.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            upper(context, label ?? context.l10n.subjectOf(pill.topic)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(
              size: 9,
              weight: FontWeight.w700,
              spacing: 1.2,
              color: ink.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }
}

/// The paper's name across the top, under the day's date, between rules.
class MastheadBlock extends ExploreBlock {
  const MastheadBlock();

  @override
  String get name => 'masthead';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final l = context.l10n;
    final String language = host.language;
    final Palette p = context.p;
    final ScreenSize size = screenSizeOf(section);
    final String kicker =
        section.text('kicker', language) ?? frontDate(context, DateTime.now());
    final String left = section.text('left', language) ?? l.screensFrontEdition;
    final String right = section.text('right', language) ?? l.screensFrontSame;
    final TextStyle caps = _caps(p.ink.withValues(alpha: 0.5));
    return host.watch(
      section,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              upper(context, kicker),
              textAlign: TextAlign.center,
              style: caps,
            ),
            const SizedBox(height: 10),
            Text(
              section.title(language) ?? l.screensFrontName,
              key: const ValueKey('masthead-name'),
              textAlign: TextAlign.center,
              style: AppText.display(
                size: bySize(size, s: 34, m: 46, l: 54),
                weight: FontWeight.w600,
                height: 1,
                spacing: bySize(size, s: -1.2, m: -1.8, l: -2.2),
                color: p.ink,
              ),
            ),
            const SizedBox(height: 10),
            Container(height: 2, color: p.ink),
            const SizedBox(height: 3),
            Container(height: 1, color: p.ink),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(upper(context, left), style: caps)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    upper(context, right),
                    textAlign: TextAlign.end,
                    style: caps,
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

/// The lead: a banner in its subject's colour with the subject's mark drawn
/// large across it, the question as the headline, and a standfirst.
class FrontLeadBlock extends ExploreBlock {
  const FrontLeadBlock();

  @override
  String get name => 'front-lead';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> cards = frontCards(
      host,
      section,
      FrontPart.lead,
      count: 1,
    );
    if (cards.isEmpty) return null;
    final Pill lead = cards.first;
    host.seen(section, lead);
    final l = context.l10n;
    final Palette p = context.p;
    final ScreenSize size = screenSizeOf(section);
    final String headline =
        section.text('headline', host.language) ?? lead.question;
    // The standfirst never gives the answer away: the line to keep only
    // once the card is read, and before that what kind of card it is, in
    // the words its shelf would use.
    final String deck =
        section.text('deck', host.language) ??
        (host.isRead(lead) && lead.barMove.isNotEmpty
            ? lead.barMove
            : _kindLine(l, lead));
    return host.watch(
      section,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: CardTap(
          pill: lead,
          onTap: () => host.open(section, cards, lead),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (size != ScreenSize.s) ...[
                Container(
                  height: bySize(size, s: 0, m: 150, l: 190),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: lead.color,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -34,
                        bottom: -60,
                        child: ScreenMark(
                          mark: lead.topic,
                          size: bySize(size, s: 0, m: 230, l: 270),
                          stroke: 2.2,
                          ink: shade(lead.color, 0.84),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        top: 16,
                        right: 16,
                        child: FaceHead(
                          pill: lead,
                          after: l.screensFrontLead,
                          trailing: host.isRead(lead)
                              ? ReadMark(pill: lead)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                _Dotted(
                  pill: lead,
                  label: '${l.subjectOf(lead.topic)} · ${l.screensFrontLead}',
                ),
                const SizedBox(height: 8),
              ],
              Text(
                headline,
                style: AppText.display(
                  size: bySize(size, s: 22, m: _leadSize(headline), l: 30),
                  weight: FontWeight.w600,
                  height: 1.1,
                  spacing: -0.03 * bySize(size, s: 22, m: 26, l: 30),
                  color: p.ink,
                ),
              ),
              if (deck.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  deck,
                  style: AppText.body(
                    size: 13.5,
                    weight: FontWeight.w500,
                    height: 1.45,
                    color: p.ink.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The headline's size, from the canvas's own fit: large for a short
  /// question, smaller for a long one, never under the size a column's
  /// question is set at.
  static double _leadSize(String headline) {
    final int length = headline.length;
    if (length <= 60) return 28;
    if (length <= 100) return 25;
    if (length <= 140) return 22.5;
    return 20;
  }

  // The lines of the shelves of each kind, where the line is true of any
  // card of it. "How it works" and "Origins" speak of things seen and used
  // every day, which a lead on Augustine or a film's models is not: those
  // lead on the line that is true of every card.
  static String _kindLine(AppLocalizations l, Pill p) => switch (p.hook) {
    'story' => l.themeStoriesLine,
    'paradox' => l.themeParadoxesLine,
    'misconception' => l.themeMythsLine,
    'number' => l.themeNumbersLine,
    'puzzle' => l.themePuzzlesLine,
    'practical' => l.themePracticalLine,
    _ => l.themeCuriousLine,
  };
}

/// Two columns under a rule, with a rule between them: a side to pick and a
/// thing to use, unless the section names its own two.
class FrontColumnsBlock extends ExploreBlock {
  const FrontColumnsBlock();

  @override
  String get name => 'front-columns';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> cards = frontColumns(host, section);
    if (cards.length < 2) return null;
    final Palette p = context.p;
    final ScreenSize size = screenSizeOf(section);
    final double type = bySize(size, s: 15, m: 17, l: 19);
    for (final Pill pill in cards) {
      host.seen(section, pill);
    }
    Widget column(Pill pill) => CardTap(
      pill: pill,
      onTap: () => host.open(section, cards, pill),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _Dotted(pill: pill)),
              if (host.isRead(pill))
                ReadMark(pill: pill, color: p.ink, size: 12),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pill.question,
            style: AppText.display(
              size: type,
              weight: FontWeight.w600,
              height: 1.15,
              spacing: -0.025 * type,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
    return host.watch(
      section,
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.ink.withValues(alpha: 0.14))),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: column(cards[0])),
              const SizedBox(width: 14),
              Container(width: 1, color: p.ink.withValues(alpha: 0.14)),
              const SizedBox(width: 14),
              Expanded(child: column(cards[1])),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three figures, each over a rule in its subject's colour, with the
/// question it comes from under it.
class FrontNumbersBlock extends ExploreBlock {
  const FrontNumbersBlock();

  @override
  String get name => 'front-numbers';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final int count = (section.limit ?? 3).clamp(2, 4);
    final List<Pill> cards = [
      for (final Pill p in frontCards(
        host,
        section,
        FrontPart.figure,
        count: count,
      ))
        if (shelfFigure(p) != null) p,
    ];
    if (cards.length < 2) return null;
    final l = context.l10n;
    final Palette p = context.p;
    final ScreenSize size = screenSizeOf(section);
    for (final Pill pill in cards) {
      host.seen(section, pill);
    }
    return host.watch(
      section,
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.ink.withValues(alpha: 0.14))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              upper(
                context,
                section.title(host.language) ?? l.screensFrontNumbers,
              ),
              style: _caps(p.ink.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(
                    child: CardTap(
                      pill: cards[i],
                      onTap: () => host.open(section, cards, cards[i]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: cards[i].color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            shelfFigure(cards[i])!,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: AppText.display(
                              size: bySize(size, s: 20, m: 24, l: 28),
                              weight: FontWeight.w600,
                              height: 1,
                              spacing: -0.6,
                              color: p.ink,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            cards[i].question,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              size: 11,
                              weight: FontWeight.w500,
                              height: 1.35,
                              color: p.ink.withValues(alpha: 0.58),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A correction: a myth, boxed by a hairline, under the line that says what
/// a correction is here.
class FrontCorrectionBlock extends ExploreBlock {
  const FrontCorrectionBlock();

  @override
  String get name => 'front-correction';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> cards = frontCards(
      host,
      section,
      FrontPart.correction,
      count: 1,
    );
    if (cards.isEmpty) return null;
    final Pill fix = cards.first;
    host.seen(section, fix);
    final l = context.l10n;
    final Palette p = context.p;
    final ScreenSize size = screenSizeOf(section);
    final double type = bySize(size, s: 15.5, m: 17, l: 19);
    return host.watch(
      section,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: CardTap(
          pill: fix,
          onTap: () => host.open(section, cards, fix),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.ink.withValues(alpha: 0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: fix.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        upper(
                          context,
                          section.title(host.language) ??
                              l.screensFrontCorrections,
                        ),
                        style: _caps(p.ink.withValues(alpha: 0.55)),
                      ),
                    ),
                    if (host.isRead(fix))
                      ReadMark(pill: fix, color: p.ink, size: 13),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  section.subtitle(host.language) ?? l.themeMythsLine,
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w500,
                    height: 1.35,
                    color: p.ink.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fix.question,
                  style: AppText.display(
                    size: type,
                    weight: FontWeight.w600,
                    height: 1.22,
                    spacing: -0.3,
                    color: p.ink,
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

/// The puzzle of the day, reversed out of the page, with the button that
/// opens it to be worked out.
class FrontPuzzleBlock extends ExploreBlock {
  const FrontPuzzleBlock();

  @override
  String get name => 'front-puzzle';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> cards = frontCards(
      host,
      section,
      FrontPart.puzzle,
      count: 1,
    );
    if (cards.isEmpty) return null;
    final Pill puzzle = cards.first;
    host.seen(section, puzzle);
    final l = context.l10n;
    final Palette p = context.p;
    final ScreenSize size = screenSizeOf(section);
    final double type = bySize(size, s: 16, m: 18, l: 20);
    return host.watch(
      section,
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: p.inverse,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    upper(
                      context,
                      section.title(host.language) ?? l.screensFrontPuzzle,
                    ),
                    style: _caps(p.onInverse.withValues(alpha: 0.62)),
                  ),
                ),
                if (host.isRead(puzzle))
                  ReadMark(pill: puzzle, color: p.onInverse, size: 13),
              ],
            ),
            const SizedBox(height: 10),
            BalancedText(
              puzzle.question,
              style: AppText.display(
                size: type,
                weight: FontWeight.w600,
                height: 1.2,
                spacing: -0.4,
                color: p.onInverse,
              ),
            ),
            const SizedBox(height: 10),
            PillButton(
              key: ValueKey('front-puzzle-${puzzle.id}'),
              label: section.text('button', host.language) ?? l.themeWorkItOut,
              height: 36,
              size: 12.5,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              background: p.onInverse,
              foreground: p.inverse,
              onTap: () => host.open(section, cards, puzzle),
            ),
          ],
        ),
      ),
    );
  }
}

/// The last line of the edition, and when the next one is out.
class EditionEndBlock extends ExploreBlock {
  const EditionEndBlock();

  @override
  String get name => 'edition-end';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final l = context.l10n;
    final Palette p = context.p;
    final ScreenSize size = screenSizeOf(section);
    final String line =
        section.subtitle(host.language) ?? l.screensFrontTomorrow;
    return host.watch(
      section,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Text(
              section.title(host.language) ?? l.screensFrontEnd,
              textAlign: TextAlign.center,
              style: AppText.display(
                size: bySize(size, s: 15, m: 17, l: 19),
                weight: FontWeight.w600,
                height: 1.2,
                spacing: -0.3,
                color: p.ink,
              ),
            ),
            if (line.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                line,
                textAlign: TextAlign.center,
                style: AppText.body(
                  size: 12,
                  height: 1.3,
                  color: p.ink.withValues(alpha: 0.42),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
