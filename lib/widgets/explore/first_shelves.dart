/// The shelves Explore has had from the start, as they were drawn on its
/// screen: the frame every shelf stands in, the rows of a question from every
/// subject, and the readers' top list with its window — or Astute's picks in
/// its place, until readers make one. They moved out of the
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
        size: 19,
        weight: FontWeight.w700,
        height: 1.15,
        spacing: -0.45,
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
                  size: 13,
                  height: 1.3,
                  color: context.p.ink.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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

  /// How tall it stands level with the shelf's name: the height a finger
  /// needs. A head with no switch keeps this room, so a shelf is the same
  /// height with the switch or without it.
  static const double height = 44;

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
            height: height,
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

/// The top list: each card standing on its place, the number behind it —
/// or, [numbered] false, the same cards in the same row at the same height
/// with no number, for Astute's own picks in the list's place: a number
/// says which card readers put first, and on the picks no reader put any
/// card anywhere.
class TopRow extends StatelessWidget {
  const TopRow({
    super.key,
    required this.pills,
    required this.onOpen,
    required this.isRead,
    this.numbered = true,
    this.onShown,
  });

  /// The cards in their places, first first.
  final List<Pill> pills;

  /// Whether each card stands on its number: the readers' list.
  final bool numbered;

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
        itemCount: pills.length,
        // With no number between them the cards keep the gap of every other
        // row of cards: this and the ring on each side make ten.
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, i) {
          onShown?.call(pills[i]);
          return TopPlaced(
            rank: numbered ? i + 1 : null,
            pill: pills[i],
            read: isRead(pills[i]),
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
/// out of the type behind it. With no [rank], the card alone, as wide as on
/// the list.
class TopPlace extends StatelessWidget {
  const TopPlace({super.key, required this.rank, required this.card});

  /// The place, from 1, or null for a card on no place.
  final int? rank;

  /// What stands on it.
  final Widget card;

  static const double _card = 146;
  static const double _ring = 3;

  /// Room round the numeral for the mask: a serif reaches past the box its
  /// line gives it, and what the mask does not cover is painted in full ink.
  static const double _bleed = 16;

  @override
  Widget build(BuildContext context) {
    final int? rank = this.rank;
    final Widget ringed = Container(
      padding: const EdgeInsets.all(_ring),
      decoration: BoxDecoration(
        color: context.p.surface,
        borderRadius: BorderRadius.circular(19 + _ring),
      ),
      child: card,
    );
    if (rank == null) return SizedBox(width: _card + _ring * 2, child: ringed);
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
                colors: [ink, ink.withValues(alpha: 0.42)],
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
            child: ringed,
          ),
        ],
      ),
    );
  }
}

/// A card on the list, or on Astute's picks in its place: its subject and
/// its question.
class TopPlaced extends StatelessWidget {
  const TopPlaced({
    super.key,
    required this.rank,
    required this.pill,
    required this.onTap,
    this.read = false,
  });

  /// The place, from 1; null for one of Astute's picks, which stand on no
  /// place.
  final int? rank;

  /// The card on it.
  final Pill pill;

  /// The card tapped.
  final VoidCallback onTap;

  /// Read already: a tick by the subject, and the word at the foot.
  final bool read;

  @override
  Widget build(BuildContext context) {
    final Color sub = pill.ink.withValues(alpha: 0.66);
    // Keyed apart, so the readers' list and Astute's picks are never taken
    // for each other, by a test or by anything else.
    final String kind = rank == null ? 'picks' : 'top';
    return GestureDetector(
      key: ValueKey('$kind-${pill.id}'),
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
                  CardMark(pill: pill, size: 14, ink: pill.ink),
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
                        key: ValueKey('$kind-read-${pill.id}'),
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
              // No count on the card. The list had a launch crowd under it
              // once, and a made-up "1,204 readers" is the one thing an app
              // about not being fooled cannot print; every count is a real
              // reader's now, and the list keeps the look it had: the order
              // says which card readers kept most.
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
