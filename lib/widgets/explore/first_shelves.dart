/// The shelves Explore has had from the start, as they were drawn on its
/// screen: the frame every shelf stands in, the rows of a question from every
/// subject, and the readers' top list with its window. They moved out of the
/// screen when Explore became a list of sections, so that the blocks drawing
/// those shelves (lib/explore/blocks/core/) draw them exactly as before, and
/// any other block can stand in the same frame.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import '../balanced_text.dart';
import '../card_edge.dart';
import '../scaled_text.dart';
import '../subject_icon.dart';

/// A shelf: what it holds, why it exists, and the cards — and, where the
/// shelf can be turned, the control that turns it, level with its name, or
/// what it keeps count of: the points left, a move met so many times.
class ShelfFrame extends StatelessWidget {
  const ShelfFrame({
    super.key,
    required this.title,
    required this.line,
    required this.child,
    this.trailing,
  });

  /// The shelf's name.
  final String title;

  /// Why it is a shelf, under the name.
  final String line;

  /// The cards, at the shelf's full width: a row keeps the page's margins
  /// itself, so it can run to the edges of the screen as it scrolls.
  final Widget child;

  /// The control level with the name, or what the shelf keeps count of.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Widget name = Text(
      title,
      style: AppText.body(
        size: 16,
        weight: FontWeight.w600,
        height: 1,
        spacing: -0.2,
        color: context.p.ink,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The control sits level with the name, and the line runs
              // under both, so a long one in any language keeps to a line.
              if (trailing == null)
                name
              else
                Row(
                  children: [
                    Expanded(child: name),
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ),
              SizedBox(height: trailing == null ? 3 : 4),
              BalancedText(
                line,
                style: AppText.body(
                  size: 12,
                  height: 1.3,
                  color: context.p.ink.withValues(alpha: 0.42),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        child,
      ],
    );
  }
}

/// The middle shelf: rows, with the subject's colour carrying its mark.
class RowList extends StatelessWidget {
  const RowList({
    super.key,
    required this.pills,
    required this.isRead,
    required this.onOpen,
    this.onShown,
  });

  /// The cards, one row each, in order.
  final List<Pill> pills;

  /// Whether the reader has read a card: a tick by its subject.
  final bool Function(Pill) isRead;

  /// A row tapped: the card, with the rest of the list a swipe away.
  final void Function(List<Pill>, Pill) onOpen;

  /// Each card the list puts on screen, as it builds it.
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    // A column shows all of its rows at once.
    for (final pill in pills) {
      onShown?.call(pill);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (final pill in pills)
            Padding(
              padding: EdgeInsets.only(bottom: pill == pills.last ? 0 : 7),
              child: CardRow(
                pill: pill,
                read: isRead(pill),
                onTap: () => onOpen(pills, pill),
              ),
            ),
        ],
      ),
    );
  }
}

/// One card as a row: a block of its colour with its mark on it, and the
/// question beside it.
class CardRow extends StatelessWidget {
  const CardRow({
    super.key,
    required this.pill,
    required this.onTap,
    this.read = false,
  });

  /// The card.
  final Pill pill;

  /// The row tapped.
  final VoidCallback onTap;

  /// Read already: a tick after the subject's name.
  final bool read;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('explore-${pill.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: ColoredBox(
          color: context.p.ink.withValues(alpha: 0.05),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 44,
                  color: pill.color,
                  alignment: Alignment.center,
                  child: SubjectIcon(
                    subject: pill.topic,
                    size: 16,
                    ink: pill.ink,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          pill.question,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                            size: 13.5,
                            weight: FontWeight.w600,
                            height: 1.26,
                            color: context.p.ink.withValues(alpha: 0.93),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                pill.topic,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body(
                                  size: 10.5,
                                  weight: FontWeight.w500,
                                  height: 1,
                                  spacing: 0.3,
                                  color: context.p.ink.withValues(alpha: 0.36),
                                ),
                              ),
                            ),
                            if (read) ...[
                              const SizedBox(width: 5),
                              ReadTick(
                                pill: pill,
                                color: context.p.ink.withValues(alpha: 0.5),
                                size: 12,
                              ),
                            ],
                          ],
                        ),
                      ],
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

/// A card read already, where it sits on a shelf: the tick the top list
/// marks one with, so a card read from a shelf can stay on it without
/// being taken for one still to find.
class ReadTick extends StatelessWidget {
  const ReadTick({
    super.key,
    required this.pill,
    required this.color,
    this.size = 14,
  });

  /// The card it marks, which keys it.
  final Pill pill;

  /// The ink it is drawn in, a little faded.
  final Color color;

  /// How big it is drawn.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.readMark,
      child: Icon(
        Icons.check_circle_rounded,
        key: ValueKey('explore-read-${pill.id}'),
        size: size,
        color: color.withValues(alpha: 0.8),
      ),
    );
  }
}

/// This week or this month, for the top list: two words, one lit — the
/// subject row's chip, made into a pair.
class WindowSwitch extends StatelessWidget {
  const WindowSwitch({super.key, required this.month, required this.onPick});

  /// Whether the month is the one lit.
  final bool month;

  /// The other one tapped: true for the month.
  final ValueChanged<bool> onPick;

  @override
  Widget build(BuildContext context) {
    Widget side(String label, bool isMonth) {
      final bool on = month == isMonth;
      return Semantics(
        key: ValueKey('top-${isMonth ? 'month' : 'week'}-${on ? 'on' : 'off'}'),
        button: true,
        selected: on,
        // A 24-point word in a target 44 high: the pair is small, the
        // place a finger lands on it is not.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: on ? null : () => onPick(isMonth),
          child: SizedBox(
            height: 44,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 24,
                constraints: const BoxConstraints(minWidth: 44),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on
                      ? context.p.inverse
                      : context.p.inverse.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: AppText.body(
                    size: 11.5,
                    weight: FontWeight.w600,
                    height: 1,
                    color: on
                        ? context.p.onInverse
                        : context.p.ink.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // The pair's ground is drawn 29 high behind two targets 44 high.
    return Stack(
      children: [
        Positioned.fill(
          top: 7.5,
          bottom: 7.5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.p.ink.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              side(context.l10n.topWeek, false),
              side(context.l10n.topMonth, true),
            ],
          ),
        ),
      ],
    );
  }
}

/// The top list: each card standing on its place, the number behind it.
class TopRow extends StatelessWidget {
  const TopRow({
    super.key,
    required this.ranked,
    required this.onOpen,
    required this.isRead,
    this.onShown,
  });

  /// The cards in their places, each with how many readers kept it.
  final List<(Pill, int)> ranked;

  /// A place tapped, by its index from 0.
  final ValueChanged<int> onOpen;

  /// Each card the list puts on screen, as it builds it.
  final ValueChanged<Pill>? onShown;

  /// Whether the reader has read a card already. The list is the same for
  /// everybody, so a card read stays on its place, marked.
  final bool Function(Pill) isRead;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
        itemCount: ranked.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, i) {
          onShown?.call(ranked[i].$1);
          return TopPlaced(
            rank: i + 1,
            pill: ranked[i].$1,
            readers: ranked[i].$2,
            read: isRead(ranked[i].$1),
            onTap: () => onOpen(i),
          );
        },
      ),
    );
  }
}

/// One place on the list: the number, and what stands in front of it,
/// over the number's last edge — so the card is still the thing, and the
/// number is what it stands on. A ring of the page's own colour runs round
/// the card where it meets the number, the way a magazine cuts a picture
/// out of the type behind it.
class TopPlace extends StatelessWidget {
  const TopPlace({
    super.key,
    required this.rank,
    required this.card,
    this.faint = false,
  });

  /// The place, from 1.
  final int rank;

  /// What stands on it.
  final Widget card;

  /// An empty place: the number there, but barely.
  final bool faint;

  static const double _card = 146;
  static const double _ring = 3;

  /// Room round the numeral for the mask: a serif reaches past the box its
  /// line gives it, and what the mask does not cover is painted in full ink.
  static const double _bleed = 16;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    final TextStyle numeral = AppText.display(
      size: 124,
      weight: FontWeight.w700,
      height: 1,
      spacing: -6,
      color: ink,
    );
    // Measured, because a 1 is half the width of a 2: a fixed gap would
    // leave the one adrift and bury the other.
    final TextPainter painter = TextPainter(
      text: TextSpan(text: '$rank', style: numeral),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    final double width = painter.width;
    painter.dispose();
    final double cardLeft = width - math.max(8, width * 0.14);
    final List<Color> fade = faint
        ? [ink.withValues(alpha: 0.24), ink.withValues(alpha: 0.06)]
        : [ink, ink.withValues(alpha: 0.42)];

    return SizedBox(
      width: cardLeft + _card + _ring * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -_bleed,
            bottom: -13 - _bleed,
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: fade,
              ).createShader(rect.deflate(_bleed)),
              child: Padding(
                padding: const EdgeInsets.all(_bleed),
                child: Text(
                  '$rank',
                  textScaler: TextScaler.noScaling,
                  style: numeral,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: cardLeft,
            width: _card + _ring * 2,
            child: Container(
              padding: const EdgeInsets.all(_ring),
              decoration: BoxDecoration(
                color: context.p.surface,
                borderRadius: BorderRadius.circular(19 + _ring),
              ),
              child: card,
            ),
          ),
        ],
      ),
    );
  }
}

/// A card on the list: its subject, its question, and how many readers
/// kept it.
class TopPlaced extends StatelessWidget {
  const TopPlaced({
    super.key,
    required this.rank,
    required this.pill,
    required this.readers,
    required this.onTap,
    this.read = false,
  });

  /// The place, from 1.
  final int rank;

  /// The card on it.
  final Pill pill;

  /// How many readers kept it, which orders the list and is not printed.
  final int readers;

  /// The card tapped.
  final VoidCallback onTap;

  /// Read already: a tick by the subject, and the word under the count.
  final bool read;

  @override
  Widget build(BuildContext context) {
    final Color sub = pill.ink.withValues(alpha: 0.66);
    return GestureDetector(
      key: ValueKey('top-${pill.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: TopPlace(
        rank: rank,
        card: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
          decoration: cardFace(context, pill.color, radius: 19),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SubjectIcon(subject: pill.topic, size: 14, ink: pill.ink),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      context.l10n.subjectOf(pill.topic).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label(
                        size: 8.5,
                        weight: FontWeight.w700,
                        spacing: 1.1,
                        color: sub,
                      ),
                    ),
                  ),
                  if (read) ...[
                    const SizedBox(width: 6),
                    Semantics(
                      label: context.l10n.readMark,
                      child: Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('top-read-${pill.id}'),
                        size: 14,
                        color: pill.ink.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 8),
                  child: ScaledText(
                    text: pill.question,
                    min: 10.5,
                    max: 15,
                    alignment: Alignment.topLeft,
                    styleFor: (size) => AppText.display(
                      size: size,
                      weight: FontWeight.w600,
                      height: 1.15,
                      spacing: -0.4 * size / 15,
                      color: pill.ink,
                    ),
                  ),
                ),
              ),
              // No count on the card. Until real readers outnumber it, most
              // of a number here is the launch crowd (TopSeed), and a
              // made-up "1,204 readers" is the one thing an app about not
              // being fooled cannot print. The order stays; the number waits
              // until it is real.
              Text(
                read ? context.l10n.readMark : '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 11,
                  weight: FontWeight.w600,
                  height: 1,
                  color: pill.ink.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The list with nothing on it yet: the first three places, numbered and
/// empty, and on the first of them what puts a card there. The same
/// height as the list, so nothing jumps when the cards arrive.
class TopGhost extends StatelessWidget {
  const TopGhost({super.key});

  @override
  Widget build(BuildContext context) {
    Widget slot({Widget? child}) => Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: context.p.ink.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: context.p.ink.withValues(alpha: 0.10)),
      ),
      child: child,
    );

    return SizedBox(
      key: const ValueKey('top-empty'),
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, i) => TopPlace(
          rank: i + 1,
          faint: true,
          card: slot(
            // Set to the space, like the cards: some languages take twice
            // the words to say it.
            child: i == 0
                ? ScaledText(
                    text: context.l10n.topEmpty,
                    min: 9.5,
                    max: 12,
                    alignment: Alignment.bottomLeft,
                    styleFor: (size) => AppText.body(
                      size: size,
                      weight: FontWeight.w500,
                      height: 1.4,
                      color: context.p.inkMuted,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
