import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import '../scaled_text.dart';
import '../subject_icon.dart';

/// The pieces every shelf under the ones that were always there is built
/// from: the head of a card, its question, the darker tones its signature is
/// drawn in, the fills that show up on it whatever its colour.

/// The colour with each channel scaled by [k] — the canvas's own `mix`, the
/// darker tone of the card that every signature is drawn in, so a graphic
/// never fights the text on top of it.
Color shade(Color c, double k) => Color.fromARGB(
  255,
  (c.r * 255 * k).round().clamp(0, 255),
  (c.g * 255 * k).round().clamp(0, 255),
  (c.b * 255 * k).round().clamp(0, 255),
);

bool _darkInk(Color ink) => ink.computeLuminance() < 0.5;

/// A button's fill on the card: a tenth of dark ink, or a sixth of white.
Color fillOn(Pill p) => p.ink.withValues(alpha: _darkInk(p.ink) ? 0.1 : 0.18);

/// A hairline on the card.
Color hairOn(Pill p) => p.ink.withValues(alpha: _darkInk(p.ink) ? 0.28 : 0.42);

/// The card's ink, quieter: labels, counts, the line under a question.
Color subOn(Pill p) => p.ink.withValues(alpha: 0.66);

/// Capitals, with Turkish's dotted capital I.
String upper(BuildContext context, String text) =>
    Localizations.localeOf(context).languageCode == 'tr'
    ? text.replaceAll('i', 'İ').toUpperCase()
    : text.toUpperCase();

/// The green a win is told in, light enough on the night paper and dark
/// enough on the day one.
Color winColor(BuildContext context) =>
    context.p.isDark ? const Color(0xFF3BE07A) : const Color(0xFF128A43);

/// The subject's mark and its name, small caps: the head of every card.
class CardHead extends StatelessWidget {
  const CardHead({
    super.key,
    required this.pill,
    this.label,
    this.trailing,
    this.ink,
    this.labelInk,
  });

  final Pill pill;

  /// What the head says instead of the subject's name.
  final String? label;
  final Widget? trailing;

  /// The mark's colour and the label's, where the card is not its colour.
  final Color? ink;
  final Color? labelInk;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SubjectIcon(subject: pill.topic, size: 15, ink: ink ?? pill.ink),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            upper(context, label ?? pill.topic),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(
              size: 9,
              weight: FontWeight.w700,
              spacing: 1.2,
              color: labelInk ?? subOn(pill),
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 6), trailing!],
      ],
    );
  }
}

/// A question set to the space it has, in the app's own voice.
class CardQuestion extends StatelessWidget {
  const CardQuestion({
    super.key,
    required this.text,
    required this.color,
    this.min = 11,
    this.max = 17,
    this.height = 1.15,
    this.tracking = -0.027,
    this.alignment = Alignment.topLeft,
  });

  final String text;
  final Color color;
  final double min;
  final double max;
  final double height;

  /// Letter spacing, in ems.
  final double tracking;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return ScaledText(
      text: text,
      min: min,
      max: max,
      alignment: alignment,
      styleFor: (size) => AppText.display(
        size: size,
        weight: FontWeight.w600,
        height: height,
        spacing: tracking * size,
        color: color,
      ),
    );
  }
}

/// A card read already: the tick the shelves above mark one with.
class ReadMark extends StatelessWidget {
  const ReadMark({super.key, required this.pill, this.color, this.size = 14});

  final Pill pill;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.readMark,
      child: Icon(
        Icons.check_circle_rounded,
        key: ValueKey('explore-read-${pill.id}'),
        size: size,
        color: (color ?? pill.ink).withValues(alpha: 0.8),
      ),
    );
  }
}

/// A row of cards that scrolls sideways, at the margins every shelf keeps.
class SideRow extends StatelessWidget {
  const SideRow({
    super.key,
    required this.height,
    required this.count,
    required this.itemBuilder,
    this.gap = 10,
  });

  final double height;
  final int count;
  final IndexedWidgetBuilder itemBuilder;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        itemCount: count,
        separatorBuilder: (_, _) => SizedBox(width: gap),
        itemBuilder: itemBuilder,
      ),
    );
  }
}

/// A rounded button, filled: the canvas's flat one rather than the app's
/// chunky one, because a shelf is not a commitment screen.
class FlatButton extends StatelessWidget {
  const FlatButton({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.onTap,
    this.icon,
    this.height = 36,
    this.radius = 99,
    this.size = 12.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.expand = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  final Widget? icon;
  final double height;
  final double radius;
  final double size;
  final EdgeInsets padding;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: AppText.body(
        size: size,
        weight: FontWeight.w700,
        height: 1,
        color: foreground,
      ),
    );
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // No alignment: a container with one stretches to every width it is
        // offered, and a button that is not told to expand keeps to its
        // words. The fixed height already centres the row in it.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 7)],
              // Flexible either way: a button that keeps to its words still
              // gives way, with an ellipsis, when its words are wider than
              // the room it was given (a long label in a narrow card).
              Flexible(child: text),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two to four words, one lit: the subject row's chip made into a set.
class Segments extends StatelessWidget {
  const Segments({
    super.key,
    required this.labels,
    required this.selected,
    required this.onPick,
    this.keyPrefix,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onPick;

  /// Keys each segment as `$keyPrefix-$i-on` or `-off`, for tests.
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.p.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                key: keyPrefix == null
                    ? null
                    : ValueKey('$keyPrefix-$i-${i == selected ? 'on' : 'off'}'),
                button: true,
                selected: i == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onPick(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected
                          ? context.p.inverse
                          : context.p.inverse.withValues(alpha: 0),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 12.5,
                        weight: FontWeight.w600,
                        height: 1,
                        color: i == selected
                            ? context.p.onInverse
                            : context.p.ink.withValues(alpha: 0.62),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small caps over a part of a shelf: TONE, TIME YOU HAVE, IN NUMBERS.
class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      upper(context, text),
      style: AppText.label(
        size: 9.5,
        weight: FontWeight.w700,
        spacing: 1.3,
        color: color ?? context.p.ink.withValues(alpha: 0.45),
      ),
    );
  }
}

/// A card's face, tappable, keyed the way every card on Explore is so the
/// card can be found from outside the shelf.
class CardTap extends StatelessWidget {
  const CardTap({
    super.key,
    required this.pill,
    required this.onTap,
    required this.child,
  });

  final Pill pill;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('explore-${pill.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}
