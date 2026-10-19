/// Shelves by the feeling a card gives — the canvas's 138a.
///
/// SCOPO.md says what should happen to someone who reads Astute: the
/// "ah, that's why" of a mechanism understood, the start of recognising
/// yourself in something you do without noticing, the news that is about
/// your own body. Each is a shelf with a form of its own. What if it's
/// true? is in the app already, as core's shelf.
library;

import 'package:flutter/material.dart';

import '../../../data/explore_mix.dart' show minutesFor;
import '../../../data/themed_shelves.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/card_edge.dart';
import '../../../widgets/subject_icon.dart';
import '../../explore_block.dart';
import 'kit.dart';

// ── Ah, so that's why ────────────────────────────────────────────────────

/// 138a: mechanisms, each with THE WHY and how long it takes at its foot.
class WhyBlock extends ExploreBlock {
  const WhyBlock();

  @override
  String get name => 'purpose.why';

  /// The block's sizes; `m` is the canvas's.
  static const Map<String, TileSize> sizes = {
    's': TileSize(180, 240),
    'm': TileSize(206, 268),
    'l': TileSize(236, 296),
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
      fits: (p) => fitsTheme(ShelfTheme.howItWorks, p),
    );
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final String lang = host.language;
    final TileSize size = sizeOf(section, sizes);
    return host.watch(
      section,
      PurposeShelf(
        title: section.title(lang) ?? l.purposeWhy,
        line: section.subtitle(lang) ?? l.purposeWhyLine,
        child: SideRow(
          height: size.height + 4,
          count: cards.length,
          itemBuilder: (context, i) {
            final Pill p = cards[i];
            host.seen(section, p);
            return WhyTile(
              pill: p,
              size: size,
              read: host.isRead(p),
              onOpen: () => host.open(section, cards, p),
            );
          },
        ),
      ),
    );
  }
}

/// A mechanism, with a band across its foot in the card's darker tone: THE
/// WHY, how many minutes it takes, and an arrow into it.
class WhyTile extends StatelessWidget {
  const WhyTile({
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
      child: Container(
        width: size.width,
        height: size.height,
        decoration: cardFace(context, p.color, radius: 22),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(17, 17, 17, 12),
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
                          min: 11,
                          max: size.width < 200 ? 17 : 19,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 44,
              color: shade(p.color, 0.84),
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      upper(
                        context,
                        context.l10n.purposeWhyBand(minutesFor(p)),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label(
                        size: 9,
                        weight: FontWeight.w700,
                        spacing: 1.2,
                        height: 1,
                        color: p.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PurposeGlyph(Glyphs.arrow, size: 16, color: p.ink),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── That's me ────────────────────────────────────────────────────────────

/// What a That's me card is about: what people do without noticing — their
/// habits, their attention, their memory and moods, the way they decide —
/// as the genres of psychology and of life name it.
const Set<String> kAboutMeGenres = {
  'psychology.habits',
  'psychology.attention',
  'psychology.memory',
  'psychology.emotions',
  'psychology.bias',
  'psychology.motivation',
  'psychology.know_your_own_mind',
  'psychology.happiness_research',
  'psychology.think_under_pressure',
  'psychology.sleep_and_dreams',
  'life.habits',
  'life.time_and_attention',
  'life.decisions',
  'life.money_and_time',
  'life.handle_setbacks',
  'life.growth',
  'life.learn_anything',
  'technology.your_digital_life',
};

/// Whether [p] is a That's me card: about something people do, asked as
/// something to recognise. A story is about someone else, a debate is a
/// side to take and a sum is a sum, whatever their genre.
bool isAboutMe(Pill p) =>
    kAboutMeGenres.contains(p.genre) &&
    p.hook != 'story' &&
    p.hook != 'origin' &&
    p.challenge is! TakeASide &&
    p.challenge is! TypeNumber &&
    p.challenge is! Estimate;

/// 138a: things people do without noticing, each a wide row with That's me
/// to mark it, and under them how many the reader marked today.
class ThatsMeBlock extends ExploreBlock {
  const ThatsMeBlock();

  @override
  String get name => 'purpose.thats-me';

  /// The question's size on a row, by the section's size; `m` is the
  /// canvas's.
  static const Map<String, double> sizes = {'s': 15.5, 'm': 17, 'l': 19};

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> cards = cardsOf(host, section, limit: 3, fits: isAboutMe);
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final String lang = host.language;
    final double base = sizeOf(section, sizes);
    final String key = 'me:${section.id}';
    return host.watch(
      section,
      PurposeShelf(
        title: section.title(lang) ?? l.purposeMe,
        line: section.subtitle(lang) ?? l.purposeMeLine,
        child: PlayWatch<Set<String>>(
          select: () => PurposePlay.setOf(key),
          builder: (context, marked) {
            final int count = cards.where((p) => marked.contains(p.id)).length;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final Pill p in cards) ...[
                  Builder(
                    builder: (context) {
                      host.seen(section, p);
                      return MeRow(
                        pill: p,
                        base: base,
                        read: host.isRead(p),
                        marked: marked.contains(p.id),
                        onOpen: () => host.open(section, cards, p),
                        onMark: () {
                          final Set<String> now = PurposePlay.setOf(key);
                          final bool on = now.add(p.id);
                          if (!on) now.remove(p.id);
                          PurposePlay.writeSet(key, now);
                          host.note(section, 'thats me', {
                            'pill_id': p.id,
                            'on': on,
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 4),
                MeCount(
                  count: count,
                  text: count > 0
                      ? l.purposeMeMarked(count)
                      : wordsOf(section, 'footer', lang, l.purposeMeFooter),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A That's me card as a wide row: its head, its question, and That's me
/// to mark it, which says so once it is marked.
class MeRow extends StatelessWidget {
  const MeRow({
    super.key,
    required this.pill,
    required this.base,
    required this.read,
    required this.marked,
    required this.onOpen,
    required this.onMark,
  });

  final Pill pill;

  /// The question's size when it is of an ordinary length.
  final double base;
  final bool read;
  final bool marked;
  final VoidCallback onOpen;
  final VoidCallback onMark;

  @override
  Widget build(BuildContext context) {
    final Pill p = pill;
    final int length = p.question.length;
    // A row grows with its question, so the question is set by its length
    // the way the canvas sets it, a little smaller as it runs longer, and
    // never cut.
    final double size = base - (length > 110 ? 2 : (length > 90 ? 0.5 : 0));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: CardTap(
        pill: p,
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          decoration: cardFace(context, p.color, radius: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PurposeHead(
                pill: p,
                trailing: read ? ReadMark(pill: p) : null,
              ),
              const SizedBox(height: 11),
              Text(
                p.question,
                style: AppText.display(
                  size: size,
                  weight: FontWeight.w600,
                  height: 1.16,
                  spacing: -0.025 * size,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 5),
              _MarkButton(pill: p, marked: marked, onTap: onMark),
            ],
          ),
        ),
      ),
    );
  }
}

/// That's me, as a pill on the card: a plus to mark it, a tick once it is.
/// Drawn 32 high, as the canvas draws it, in a target 44 high.
class _MarkButton extends StatelessWidget {
  const _MarkButton({
    required this.pill,
    required this.marked,
    required this.onTap,
  });

  final Pill pill;
  final bool marked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Pill p = pill;
    final Color fore = marked ? p.color : p.ink;
    final String label = context.l10n.purposeMe;
    return Semantics(
      button: true,
      toggled: marked,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('me-${p.id}-${marked ? 'on' : 'off'}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            height: 32,
            padding: const EdgeInsets.fromLTRB(11, 0, 13, 0),
            decoration: BoxDecoration(
              color: marked ? p.ink : fillOn(p),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PurposeGlyph(
                  marked ? Glyphs.check : Glyphs.plus,
                  size: 13,
                  color: fore,
                  stroke: 2.6,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 11.5,
                      weight: FontWeight.w700,
                      height: 1,
                      color: fore,
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

/// How many cards were marked today, in a ring, and what that means.
class MeCount extends StatelessWidget {
  const MeCount({super.key, required this.count, required this.text});

  final int count;
  final String text;

  @override
  Widget build(BuildContext context) {
    final Palette pal = context.p;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: pal.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: pal.ink, shape: BoxShape.circle),
              child: Text(
                '$count',
                key: const ValueKey('me-count'),
                style: AppText.display(
                  size: 18,
                  weight: FontWeight.w600,
                  height: 1,
                  color: pal.surface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: AppText.body(
                size: 13,
                weight: FontWeight.w500,
                height: 1.4,
                color: pal.ink.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── News to me, and about me ─────────────────────────────────────────────

/// Genres outside the body's own subjects that are still about the
/// reader's body: what they eat, how they sleep.
const Set<String> kAboutYouGenres = {
  'food.eat_smarter',
  'food.food_claims',
  'psychology.sleep_and_dreams',
};

/// Whether [p] is about the reader's body, health or odds: a card of the
/// body or of medicine that is not its history, or of the genres above,
/// and not a story about somebody else.
bool isAboutYou(Pill p) {
  final String subject = subjectKey(p);
  final bool body =
      (subject == 'human_body' || subject == 'medicine') &&
      p.genre != 'medicine.medical_history';
  return (body || kAboutYouGenres.contains(p.genre)) &&
      p.hook != 'story' &&
      p.hook != 'origin';
}

/// 138a: the reader's body, health and odds, two by two, the subject's
/// mark drawn large behind each card.
class AboutYouBlock extends ExploreBlock {
  const AboutYouBlock();

  @override
  String get name => 'purpose.about-you';

  /// How high a tile stands, by size; `m` is the canvas's. They are as
  /// wide as half the shelf.
  static const Map<String, double> sizes = {'s': 164, 'm': 184, 'l': 204};

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> cards = cardsOf(host, section, limit: 4, fits: isAboutYou);
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final String lang = host.language;
    final double height = sizeOf(section, sizes);
    Widget tile(Pill p) {
      host.seen(section, p);
      return AboutTile(
        pill: p,
        height: height,
        read: host.isRead(p),
        onOpen: () => host.open(section, cards, p),
      );
    }

    return host.watch(
      section,
      PurposeShelf(
        title: section.title(lang) ?? l.purposeAboutYou,
        line: section.subtitle(lang) ?? l.purposeAboutYouLine,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < cards.length; i += 2) ...[
                if (i > 0) const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: tile(cards[i])),
                    const SizedBox(width: 10),
                    Expanded(
                      child: i + 1 < cards.length
                          ? tile(cards[i + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A card about you, its subject's mark drawn large in its darker tone,
/// half off its corner.
class AboutTile extends StatelessWidget {
  const AboutTile({
    super.key,
    required this.pill,
    required this.height,
    required this.read,
    required this.onOpen,
  });

  final Pill pill;
  final double height;
  final bool read;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final Pill p = pill;
    return CardTap(
      pill: p,
      onTap: onOpen,
      child: Container(
        height: height,
        decoration: cardFace(context, p.color, radius: 20),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -24,
              bottom: -24,
              child: ExcludeSemantics(
                child: SubjectIcon(
                  subject: p.topic,
                  size: 108,
                  ink: shade(p.color, 0.86),
                  stroke: 2.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Semantics(
                        label: context.l10n.subjectOf(p.topic),
                        child: SubjectIcon(
                          subject: p.topic,
                          size: 15,
                          ink: p.ink,
                          stroke: 2,
                        ),
                      ),
                      if (read) ...[
                        const SizedBox(width: 7),
                        ReadMark(pill: p),
                      ],
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: CardQuestion(
                        text: p.question,
                        color: p.ink,
                        min: 10.5,
                        max: height < 180 ? 15 : 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
