import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/pills_repository.dart';
import '../data/profile_marks.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../theme.dart';
import 'subject_icon.dart';
import 'ui.dart';

export '../data/profile_marks.dart';

// The foot of the profile: the reader's two shelves as hands of their own
// cards, then everything else as rows in raised boxes — a mark, a label, and
// what is behind the row before it is opened.

/// How much a mark beside text grows with the reader's text size: with it,
/// but never past 1.4×, so a large setting does not turn marks into tiles.
double profileMarkScale(BuildContext context) =>
    math.min(MediaQuery.textScalerOf(context).scale(15) / 15, 1.4);

/// How wide [text] sets on one line, in [style] as a [Text] here would set
/// it: over the inherited style, at the reader's text size.
double _lineWidth(BuildContext context, String text, TextStyle style) {
  final TextPainter painter = TextPainter(
    text: TextSpan(
      text: text,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    maxLines: 1,
  )..layout();
  final double width = painter.width;
  painter.dispose();
  return width;
}

/// One of [ProfileMarks], at [size], in [color].
class ProfileMark extends StatelessWidget {
  const ProfileMark(
    this.path, {
    super.key,
    required this.size,
    required this.color,
  });

  final String path;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(
        profileMarkSvg(path),
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}

/// Google's own G, as the intro's button carries it: the mark from its
/// plate, not a drawing of it, which never quite becomes a G this small.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/google-g.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// A section's name over its box, in the profile's small capitals.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader(this.text, {super.key, this.top = 26, this.bottom = 11});

  final String text;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: Semantics(header: true, child: Eyebrow(text)),
    );
  }
}

/// Rows in one raised box, with a hairline between two of them that starts
/// under the labels, where the reader's eye runs down the list.
class ProfileBox extends StatelessWidget {
  const ProfileBox({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final double indent =
        ProfileRow.inset +
        ProfileRow.lead * profileMarkScale(context) +
        ProfileRow.gap;
    return PaperCard(
      padding: EdgeInsets.zero,
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              Padding(
                padding: EdgeInsetsDirectional.only(start: indent),
                child: Container(height: 1, color: p.line),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// One row of a box: a mark, the label, and a quiet value at the end — the
/// city, the plan, how far back the archive goes — then the way in.
///
/// Label and value share the line while they fit on it. When they do not,
/// in a longer language or at a larger text size, the value moves under the
/// label rather than either of them being cut. The whole row is the button,
/// and never less than a finger's height.
class ProfileRow extends StatelessWidget {
  const ProfileRow({
    super.key,
    required this.label,
    this.mark,
    this.leading,
    this.value,
    this.onTap,
    this.chevron = true,
    this.color,
    this.trailing,
    this.toggled,
  }) : assert((mark == null) != (leading == null));

  /// The space the mark sits in, the gap after it, and the row's own inset
  /// from the box's edge, at the reader's text size of 1.
  static const double lead = 22;
  static const double gap = 16;
  static const double inset = 16;

  final String label;

  /// One of [ProfileMarks]; or [leading], for a mark that is not a line —
  /// Apple's and Google's, on the rows that sign in with them.
  final String? mark;
  final Widget Function(double size)? leading;

  final String? value;
  final VoidCallback? onTap;

  /// Whether the row says it leads somewhere. Rows that do a thing there
  /// and then — sign out, delete — do not.
  final bool chevron;

  /// The label's and the mark's ink, where it is not the page's own.
  final Color? color;

  /// A control at the end in place of the chevron: the usage switch, whose
  /// state is [toggled].
  final Widget? trailing;
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final Color ink = color ?? p.ink;
    final TextStyle labelStyle = AppText.body(
      size: 15,
      weight: FontWeight.w500,
      height: 1.25,
      color: ink,
    );
    final TextStyle valueStyle = AppText.body(
      size: 14,
      height: 1.25,
      color: p.inkMuted,
    );
    final double k = profileMarkScale(context);
    final double side = lead * k;
    final bool showChevron = chevron && trailing == null;
    final Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: inset, vertical: 9),
        child: LayoutBuilder(
          builder: (context, box) {
            final double room =
                box.maxWidth -
                side -
                gap -
                (showChevron ? 22 : 0) -
                (trailing != null ? 62 : 0);
            final bool beside =
                value == null ||
                _lineWidth(context, label, labelStyle) +
                        12 +
                        _lineWidth(context, value!, valueStyle) <=
                    room;
            return Row(
              children: [
                SizedBox(
                  width: side,
                  height: side,
                  child: Center(
                    child: mark != null
                        ? ProfileMark(mark!, size: side, color: ink)
                        : leading!(side),
                  ),
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: beside
                      ? Text(label, style: labelStyle)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: labelStyle),
                            const SizedBox(height: 2),
                            Text(value!, style: valueStyle),
                          ],
                        ),
                ),
                if (value != null && beside) ...[
                  const SizedBox(width: 12),
                  Text(value!, textAlign: TextAlign.end, style: valueStyle),
                ],
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
                if (showChevron) ...[
                  const SizedBox(width: 6),
                  ProfileMark(
                    ProfileMarks.chevron,
                    size: 16,
                    color: p.inkFaint,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
    return Semantics(
      container: true,
      button: toggled == null && onTap != null,
      toggled: toggled,
      label: label,
      value: value,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: row,
      ),
    );
  }
}

/// A line under a row, starting where the row's label starts: what the
/// usage switch measures, under the switch.
class ProfileRowNote extends StatelessWidget {
  const ProfileRowNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final double start =
        ProfileRow.inset +
        ProfileRow.lead * profileMarkScale(context) +
        ProfileRow.gap;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        start,
        0,
        ProfileRow.inset + 6,
        14,
      ),
      child: Text(
        text,
        style: AppText.body(size: 12, height: 1.45, color: context.p.inkMuted),
      ),
    );
  }
}

/// One of the reader's shelves, Saved or Liked, as a hand of its own cards:
/// the name, how many it holds, and the newest few fanned out in their
/// colours, the newest on top with its subject's mark.
///
/// The hand sits beside the words while the words fit on their lines, and
/// under them at a text size where they would not. An empty shelf still
/// looks meant: one faint outline where the cards will go, and "Nothing
/// yet".
class ShelfRow extends StatelessWidget {
  const ShelfRow({
    super.key,
    required this.mark,
    required this.title,
    required this.ids,
    required this.onTap,
  });

  /// One of [ProfileMarks], beside the count.
  final String mark;
  final String title;

  /// The shelf, newest first, as AppState keeps it.
  final List<String> ids;
  final VoidCallback onTap;

  /// The width the hand is drawn in, and its height.
  static const double artWidth = 118;
  static const double artHeight = 100;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final String count = ids.isEmpty
        ? context.l10n.nothingYet
        : context.l10n.nCards(ids.length);
    // A few more ids than the hand holds, so a card this build no longer
    // knows leaves no gap in it.
    final List<Pill> hand = pillsByIds(ids.take(8).toList()).take(4).toList();
    final TextStyle titleStyle = AppText.display(
      size: 22,
      weight: FontWeight.w600,
      height: 1.1,
      spacing: -0.6,
      color: p.ink,
    );
    final TextStyle countStyle = AppText.body(
      size: 13,
      height: 1.2,
      color: p.inkMuted,
    );
    final double k = profileMarkScale(context);
    final Widget words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: titleStyle),
        const SizedBox(height: 6),
        Row(
          children: [
            ProfileMark(mark, size: 15 * k, color: p.inkMuted),
            const SizedBox(width: 6),
            Flexible(child: Text(count, style: countStyle)),
          ],
        ),
      ],
    );
    final Widget art = hand.isEmpty ? const _EmptyHand() : CardFan(hand);
    final Widget chevron = ProfileMark(
      ProfileMarks.chevron,
      size: 16,
      color: p.inkFaint,
    );
    return Semantics(
      container: true,
      button: true,
      label: title,
      value: count,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: artHeight),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: p.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, box) {
              // The hand beside the words while the words fit on their
              // lines; under them at a text size where they would not.
              final double room = box.maxWidth - 18 - artWidth - 16 - 14;
              final bool beside =
                  _lineWidth(context, title, titleStyle) <= room &&
                  15 * k + 6 + _lineWidth(context, count, countStyle) <= room;
              if (!beside) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        18,
                        16,
                        14,
                        0,
                      ),
                      child: Row(
                        children: [
                          Expanded(child: words),
                          chevron,
                        ],
                      ),
                    ),
                    SizedBox(height: artHeight, child: art),
                  ],
                );
              }
              return Row(
                children: [
                  const SizedBox(width: 18),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: words,
                    ),
                  ),
                  SizedBox(width: artWidth, height: artHeight, child: art),
                  chevron,
                  const SizedBox(width: 14),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Up to four cards fanned out to the right from a point below them, the
/// first upright on top and each one behind it turned a little further —
/// the fan behind the A in the app's mark.
class CardFan extends StatelessWidget {
  const CardFan(this.cards, {super.key});

  /// Newest first; the first is the one on top.
  final List<Pill> cards;

  static const double cardWidth = 42;
  static const double cardHeight = 56;

  /// How far below the cards the fan turns, as a fraction of their height.
  static const double below = 1.15;

  /// The turn between one card and the next, in degrees.
  static const double step = 9;

  /// Where the top card of a fan sits in a box of [size]: the hand spreads
  /// about two card widths to the right of it.
  static Offset topCardAt(Size size) => Offset(
    (size.width - cardWidth * 2.05) / 2,
    (size.height - cardHeight) / 2 + 3,
  );

  /// The turn every card is given about, below the hand.
  static const Alignment pivot = Alignment(-0.7, 1 + 2 * below);

  @override
  Widget build(BuildContext context) {
    final List<Pill> hand = cards.take(4).toList();
    return LayoutBuilder(
      builder: (context, box) {
        final Offset at = topCardAt(box.biggest);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (int i = hand.length - 1; i >= 0; i--)
              Positioned(
                left: at.dx,
                top: at.dy,
                child: Transform.rotate(
                  angle: (-3 + step * i) * math.pi / 180,
                  alignment: pivot,
                  child: _MiniCard(hand[i], marked: i == 0),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A card's face, small: its colour, and on the top card its subject's mark.
class _MiniCard extends StatelessWidget {
  const _MiniCard(this.pill, {required this.marked});

  final Pill pill;
  final bool marked;

  @override
  Widget build(BuildContext context) {
    final bool dark = context.p.isDark;
    return Container(
      key: ValueKey('fan-card-${pill.id}'),
      width: CardFan.cardWidth,
      height: CardFan.cardHeight,
      padding: const EdgeInsets.all(CardFan.cardWidth * 0.11),
      alignment: AlignmentDirectional.topStart,
      decoration: BoxDecoration(
        color: pill.color,
        borderRadius: BorderRadius.circular(9),
        // On black a card glows in its own colour; on paper it sits, with
        // a shadow under it.
        boxShadow: dark
            ? [
                BoxShadow(
                  color: pill.color.withValues(alpha: 0.32),
                  blurRadius: 18,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: marked
          ? SubjectIcon(subject: pill.topic, size: 15, ink: pill.ink)
          : null,
    );
  }
}

/// Where the hand will be, on a shelf with nothing on it yet: one card's
/// outline, faint, where the top card of a hand sits.
class _EmptyHand extends StatelessWidget {
  const _EmptyHand();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final Offset at = CardFan.topCardAt(box.biggest);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: at.dx,
              top: at.dy,
              child: Transform.rotate(
                angle: -3 * math.pi / 180,
                alignment: CardFan.pivot,
                child: Container(
                  key: const ValueKey('fan-empty'),
                  width: CardFan.cardWidth,
                  height: CardFan.cardHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: context.p.lineStrong, width: 1.3),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
