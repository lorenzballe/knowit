/// Sets you finish — the canvas's 138e.
///
/// A shelf can be a set to finish, where reading counts as much as
/// answering: how many of it are read, a bar in as many pieces as it has
/// cards, READ on each card read, and once all are, the set fanned out with
/// a tick. The same set can be stamps that fill as the reader reads; and
/// every set has a ring on Your sets.
///
/// A set does not turn with the day the way a theme's shelf does: its cards
/// are the theme's in an order of their own (themeSet), so the set a
/// reader is filling is the same set tomorrow.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/themed_shelves.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/card_edge.dart';
import '../../../widgets/subject_icon.dart';
import '../../explore_block.dart';
import 'kit.dart';

/// How many cards a set holds unless its section says otherwise.
const int kSetSize = 12;

/// A set: what it is called, the line under its name, its cards, and the
/// section its cards are opened from.
@immutable
class CardSet {
  const CardSet({
    required this.title,
    required this.line,
    required this.cards,
    required this.section,
  });

  final String title;
  final String line;
  final List<Pill> cards;
  final ExploreSection section;
}

/// The set [section] stands for, from its pool: the theme it names (`myths`,
/// `place-2`), its source's cards under its own title, or this week's theme
/// among [among]. Null for a theme this build does not know, for a source
/// with no title to call it by, and for a set with no cards.
CardSet? setFor(
  BuildContext context,
  ExploreHost host,
  ExploreSection section, {
  Iterable<ShelfTheme> among = kThemeCycle,
}) {
  final l = context.l10n;
  final String lang = host.language;
  final List<Pill> pool = host.cardsFor(section, limit: kPurposePool);
  final int size = limitOf(section, kSetSize);
  final Object? named = section.json['theme'];
  (ShelfTheme, int)? theme;
  if (named != null) {
    theme = themeNamed(named, day: today());
    if (theme == null) return null;
  } else if (section.source != null) {
    final String? title = section.title(lang);
    final List<Pill> cards = pool.take(size).toList();
    if (title == null || cards.isEmpty) return null;
    return CardSet(
      title: title,
      line: section.subtitle(lang) ?? '',
      cards: cards,
      section: section,
    );
  } else {
    theme =
        weekTheme(pool, day: today(), among: among) ??
        weekTheme(pool, day: today());
    if (theme == null) return null;
  }
  final (ShelfTheme t, int variant) = theme;
  final List<Pill> cards = themeSet(pool, t, variant, size: size);
  if (cards.isEmpty) return null;
  return CardSet(
    title: section.title(lang) ?? themeTitle(l, t, variant),
    line: section.subtitle(lang) ?? themeLine(l, t),
    cards: cards,
    section: section,
  );
}

// ── A set ────────────────────────────────────────────────────────────────

/// 138e: a shelf as a set to finish; once every card is read, the set
/// fanned out with a tick.
class SetBlock extends ExploreBlock {
  const SetBlock();

  @override
  String get name => 'purpose.set';

  /// The block's sizes; `m` is the canvas's.
  static const Map<String, TileSize> sizes = {
    's': TileSize(156, 180),
    'm': TileSize(180, 204),
    'l': TileSize(206, 232),
  };

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final CardSet? set = setFor(context, host, section);
    if (set == null) return null;
    final l = context.l10n;
    final List<Pill> cards = set.cards;
    final int read = cards.where(host.isRead).length;
    if (read == cards.length) {
      for (final Pill p in cards.take(4)) {
        host.seen(section, p);
      }
      return host.watch(
        section,
        FinishedSet(
          title: set.title,
          line: l.purposeSetDone(cards.length),
          cards: cards,
          onOpen: () => host.open(section, cards, cards.first),
        ),
      );
    }
    final TileSize size = sizeOf(section, sizes);
    return host.watch(
      section,
      PurposeShelf(
        title: set.title,
        line: set.line,
        trailing: ShelfCount(
          l.purposeSetRead(read, cards.length),
          key: ValueKey('set-count-${section.id}'),
          strong: true,
        ),
        trailingAtFoot: true,
        under: SetBar(read: read, of: cards.length),
        underGap: 10,
        gap: 12,
        child: SideRow(
          height: size.height + 4,
          count: cards.length,
          itemBuilder: (context, i) {
            final Pill p = cards[i];
            host.seen(section, p);
            return SetTile(
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

/// How far along a set is: a bar in as many pieces as the set has cards,
/// as many of them lit as are read.
class SetBar extends StatelessWidget {
  const SetBar({super.key, required this.read, required this.of});

  final int read;
  final int of;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (int i = 0; i < of; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i < read ? ink : ink.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A card of a set, with READ in its corner once it is read.
class SetTile extends StatelessWidget {
  const SetTile({
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
        decoration: cardFace(context, p.color, radius: 20),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(14, 14, 14, read ? 40 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PurposeHead(pill: p),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: CardQuestion(
                        text: p.question,
                        color: p.ink,
                        min: 10.5,
                        max: size.width < 170 ? 14.5 : 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (read)
              Positioned(
                right: 10,
                bottom: 10,
                child: ReadBadge(key: ValueKey('set-read-${p.id}')),
              ),
          ],
        ),
      ),
    );
  }
}

/// READ, with a tick, black on any card: what a card of a set says once it
/// is read.
class ReadBadge extends StatelessWidget {
  const ReadBadge({super.key});

  static const Color _ground = Color(0xFF000000);
  static const Color _ink = Color(0xFFF1EFEA);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.fromLTRB(7, 0, 9, 0),
      decoration: BoxDecoration(
        color: _ground,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PurposeGlyph(Glyphs.check, size: 11, color: _ink, stroke: 3),
          const SizedBox(width: 5),
          Text(
            upper(context, context.l10n.readMark),
            maxLines: 1,
            style: AppText.label(
              size: 9,
              weight: FontWeight.w700,
              spacing: 1,
              height: 1,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// A finished set: its cards fanned, its name with a tick, and the line
/// that says new ones join it when its shelf comes round.
class FinishedSet extends StatelessWidget {
  const FinishedSet({
    super.key,
    required this.title,
    required this.line,
    required this.cards,
    required this.onOpen,
  });

  final String title;
  final String line;
  final List<Pill> cards;
  final VoidCallback onOpen;

  static const List<double> _turns = [-8, -3, 2, 7];

  @override
  Widget build(BuildContext context) {
    final Palette pal = context.p;
    final List<Pill> fan = cards.take(4).toList();
    return Semantics(
      button: true,
      child: GestureDetector(
        key: const ValueKey('set-finished'),
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pal.ink.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  width: 96,
                  height: 80,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (int i = 0; i < fan.length; i++)
                        Positioned(
                          left: 15.0 * i,
                          top: 6,
                          child: Transform.rotate(
                            angle: _turns[i] * math.pi / 180,
                            child: Container(
                              width: 50,
                              height: 66,
                              padding: const EdgeInsets.all(8),
                              alignment: Alignment.topLeft,
                              decoration: BoxDecoration(
                                color: fan[i].color,
                                borderRadius: BorderRadius.circular(10),
                                border: cardHairline(fan[i].color, pal.surface),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x80000000),
                                    blurRadius: 10,
                                    offset: Offset(-4, 0),
                                  ),
                                ],
                              ),
                              child: SubjectIcon(
                                subject: fan[i].topic,
                                size: 12,
                                ink: fan[i].ink,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: AppText.body(
                              size: 16,
                              weight: FontWeight.w600,
                              height: 1.1,
                              spacing: -0.2,
                              color: pal.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Semantics(
                          label: context.l10n.purposeComplete,
                          child: Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: winColor(context),
                              shape: BoxShape.circle,
                            ),
                            child: PurposeGlyph(
                              Glyphs.check,
                              size: 11,
                              color: pal.surface,
                              stroke: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      line,
                      style: AppText.body(
                        size: 12,
                        weight: FontWeight.w500,
                        height: 1.4,
                        color: pal.ink.withValues(alpha: 0.6),
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

// ── Stamps ───────────────────────────────────────────────────────────────

/// 138e: a set as stamps, one for each card: in its colour once read,
/// dashed until then.
class StampsBlock extends ExploreBlock {
  const StampsBlock();

  @override
  String get name => 'purpose.stamps';

  /// Stamps to a row, by size; `m` is the canvas's.
  static const Map<String, int> sizes = {'s': 7, 'm': 6, 'l': 5};

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final CardSet? set = setFor(
      context,
      host,
      section,
      among: const [ShelfTheme.place],
    );
    if (set == null) return null;
    final l = context.l10n;
    final List<Pill> cards = set.cards;
    final int read = cards.where(host.isRead).length;
    final int across = sizeOf(section, sizes);
    final Object? labels = section.json['labels'];
    String? label(Pill p) {
      final Object? own = labels is Map ? labels[p.id] : null;
      if (own is String && own.trim().isNotEmpty) return own.trim();
      return p.place?.country;
    }

    return host.watch(
      section,
      PurposeShelf(
        title: set.title,
        line: set.line,
        trailing: ShelfCount(
          l.purposeOf(read, cards.length),
          key: ValueKey('stamps-count-${section.id}'),
          strong: true,
        ),
        trailingAtFoot: true,
        gap: 12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(
                builder: (context, box) {
                  const double gap = 8;
                  final double width =
                      (box.maxWidth - gap * (across - 1)) / across;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final Pill p in cards)
                        Builder(
                          builder: (context) {
                            host.seen(section, p);
                            return Stamp(
                              pill: p,
                              width: width,
                              label: label(p),
                              read: host.isRead(p),
                              onOpen: () => host.open(section, cards, p),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                wordsOf(
                  section,
                  'footer',
                  host.language,
                  l.purposeStampsFooter,
                ),
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w500,
                  height: 1.4,
                  color: context.p.ink.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The outline of a stamp [size] big: a box with its edge perforated, a
/// hole every eight points.
Path stampPath(Size size) {
  const double step = 8;
  const double r = 2.6;
  final Path holes = Path();
  void along(Offset from, Offset to) {
    final double length = (to - from).distance;
    final int n = math.max(1, (length / step).round());
    for (int i = 0; i <= n; i++) {
      final Offset at = Offset.lerp(from, to, i / n)!;
      holes.addOval(Rect.fromCircle(center: at, radius: r));
    }
  }

  final double w = size.width, h = size.height;
  along(Offset.zero, Offset(w, 0));
  along(Offset(0, h), Offset(w, h));
  along(Offset.zero, Offset(0, h));
  along(Offset(w, 0), Offset(w, h));
  return Path.combine(
    PathOperation.difference,
    Path()..addRect(Offset.zero & size),
    holes,
  );
}

/// One card as a stamp: perforated, in the card's colour with its label
/// (the country, or the subject's mark) once read; a faint dashed one
/// until then. A tap opens its card.
class Stamp extends StatelessWidget {
  const Stamp({
    super.key,
    required this.pill,
    required this.width,
    required this.label,
    required this.read,
    required this.onOpen,
  });

  final Pill pill;
  final double width;
  final String? label;
  final bool read;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final Pill p = pill;
    final Palette pal = context.p;
    final double height = width * 64 / 54;
    final Color ink = read ? p.ink : pal.ink.withValues(alpha: 0.4);
    final Widget mark = label == null
        ? SubjectIcon(subject: p.topic, size: 18, ink: ink)
        : Text(
            label!,
            maxLines: 1,
            style: AppText.display(
              size: 16,
              weight: FontWeight.w600,
              height: 1,
              color: ink,
            ),
          );
    return Semantics(
      button: true,
      label: read ? '${p.question} · ${context.l10n.readMark}' : p.question,
      excludeSemantics: true,
      child: CardTap(
        pill: p,
        onTap: onOpen,
        child: CustomPaint(
          painter: ShapedFace(
            shape: stampPath,
            colour: read ? p.color : pal.ink.withValues(alpha: 0.1),
            ground: pal.surface,
          ),
          child: SizedBox(
            width: width,
            height: height,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: CustomPaint(
                painter: ShapedFace(
                  shape: (s) => Path()
                    ..addRRect(
                      RRect.fromRectAndRadius(
                        Offset.zero & s,
                        const Radius.circular(2),
                      ),
                    ),
                  colour: read ? hairOn(p) : pal.ink.withValues(alpha: 0.22),
                  ground: pal.surface,
                  outline: true,
                  dashed: !read,
                ),
                child: Center(
                  child: FittedBox(fit: BoxFit.scaleDown, child: mark),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Your sets ────────────────────────────────────────────────────────────

/// 138e: every set, with a ring for how far along it is, green once
/// complete; a tap opens the first card of it not yet read.
class SetsBlock extends ExploreBlock {
  const SetsBlock();

  @override
  String get name => 'purpose.sets';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final l = context.l10n;
    final String lang = host.language;
    final List<CardSet> sets = [];
    final List<Map<Object?, Object?>> parts = partsOf(section, 'sets');
    if (parts.isNotEmpty) {
      for (final Map<Object?, Object?> part in parts) {
        final CardSet? set = setFor(context, host, partOf(section, part));
        if (set != null) sets.add(set);
      }
    } else {
      final List<Pill> pool = host.cardsFor(section, limit: kPurposePool);
      final int day = today();
      for (final ShelfTheme t in kThemeCycle) {
        final int variant = themeVariant(t, day);
        final List<Pill> cards = themeSet(pool, t, variant, size: kSetSize);
        if (cards.length < kThemeMinimum) continue;
        sets.add(
          CardSet(
            title: themeTitle(l, t, variant),
            line: themeLine(l, t),
            cards: cards,
            section: partOf(section, {'id': '${t.name}-$variant'}),
          ),
        );
      }
    }
    final List<CardSet> shown = sets.take(limitOf(section, 8)).toList();
    if (shown.isEmpty) return null;
    Widget tile(CardSet set) {
      final int read = set.cards.where(host.isRead).length;
      final Pill first = set.cards.firstWhere(
        (p) => !host.isRead(p),
        orElse: () => set.cards.first,
      );
      return SetRing(
        key: ValueKey('sets-${set.section.id}'),
        title: set.title,
        read: read,
        of: set.cards.length,
        onOpen: () => host.open(set.section, set.cards, first),
      );
    }

    return host.watch(
      section,
      PurposeShelf(
        title: section.title(lang) ?? l.purposeSets,
        line: section.subtitle(lang) ?? l.purposeSetsLine,
        gap: 12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < shown.length; i += 2) ...[
                if (i > 0) const SizedBox(height: 8),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: tile(shown[i])),
                      const SizedBox(width: 8),
                      Expanded(
                        child: i + 1 < shown.length
                            ? tile(shown[i + 1])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A set on Your sets: a ring for how much of it is read, its name, and n
/// of m, or Complete.
class SetRing extends StatelessWidget {
  const SetRing({
    super.key,
    required this.title,
    required this.read,
    required this.of,
    required this.onOpen,
  });

  final String title;
  final int read;
  final int of;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final Palette pal = context.p;
    final bool done = of > 0 && read >= of;
    final l = context.l10n;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: pal.ink.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: CustomPaint(
                  size: const Size(30, 30),
                  painter: _Ring(
                    share: of == 0 ? 0 : read / of,
                    lit: done ? winColor(context) : pal.ink,
                    track: pal.ink.withValues(alpha: 0.14),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.body(
                        size: 12.5,
                        weight: FontWeight.w600,
                        height: 1.2,
                        color: pal.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      done ? l.purposeComplete : l.purposeOf(read, of),
                      style: AppText.body(
                        size: 11,
                        weight: FontWeight.w600,
                        height: 1.1,
                        color: pal.ink.withValues(alpha: 0.45),
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

/// How far round a ring is lit, from the top, clockwise.
class _Ring extends CustomPainter {
  _Ring({required this.share, required this.lit, required this.track});

  final double share;
  final Color lit;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const double width = 4.5;
    final Rect box = (Offset.zero & size).deflate(width / 2);
    final Paint pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    canvas.drawArc(box, 0, 2 * math.pi, false, pen..color = track);
    if (share > 0) {
      canvas.drawArc(
        box,
        -math.pi / 2,
        2 * math.pi * share.clamp(0.0, 1.0),
        false,
        pen..color = lit,
      );
    }
  }

  @override
  bool shouldRepaint(_Ring old) =>
      old.share != share || old.lit != lit || old.track != track;
}
