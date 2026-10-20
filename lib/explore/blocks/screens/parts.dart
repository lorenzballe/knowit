/// What the whole-screen blocks (docs/explore/screens.md) are built from:
/// how a section's size and style are read, the head every shelf has, the
/// chips a screen is steered by, and the card faces its cards are set on.
///
/// Every piece here is drawn the way the shelves of Explore are drawn
/// (lib/screens/explore_screen.dart, lib/widgets/explore/): the same
/// margins, the same Figtree head over a Fraunces question, the same
/// subject colours on the same faces. A screen built of these blocks has to
/// read as Explore on another day, never as another app.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/subject_icons.dart';
import '../../../data/topics.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/balanced_text.dart';
import '../../../widgets/card_edge.dart';
import '../../../widgets/explore/parts.dart';
import '../../../widgets/scaled_text.dart';
import '../../explore_block.dart';

// The pieces every shelf under Explore's first ones is drawn with, used
// here as they are: a card's head and question, its tick, the darker tone of
// its colour, the fills that show on it, capitals that know Turkish.
export '../../../widgets/explore/parts.dart'
    show
        CardHead,
        CardQuestion,
        CardTap,
        Kicker,
        ReadMark,
        fillOn,
        hairOn,
        shade,
        subOn,
        upper,
        winColor;

/// How much room a block takes, in the three steps every block of this
/// family understands. `xs` and `xl`, which other families use, are read as
/// the nearest of the three, so a document written for one family's sizes
/// never leaves a section of this one at nothing.
enum ScreenSize { s, m, l }

/// The size [section] asks for; medium when it asks for none, or for one
/// this build does not know.
ScreenSize screenSizeOf(ExploreSection section) => switch (section.size) {
  'xs' || 's' => ScreenSize.s,
  'l' || 'xl' => ScreenSize.l,
  _ => ScreenSize.m,
};

/// One of the three, by size.
T bySize<T>(ScreenSize size, {required T s, required T m, required T l}) =>
    switch (size) {
      ScreenSize.s => s,
      ScreenSize.m => m,
      ScreenSize.l => l,
    };

/// A switch in the section's `style`: whether a part of the block is drawn.
/// Anything but a boolean is the block's own default.
bool styleOn(ExploreSection section, String key, {bool fallback = true}) {
  final Object? raw = section.style[key];
  return raw is bool ? raw : fallback;
}

/// A list of words written per language — `{"en": ["a", "b"]}` — or one
/// list for every language: the reader's, English when theirs is missing,
/// empty when the section says nothing. Anything in it that is not words is
/// passed over.
List<String> sectionWords(
  ExploreSection section,
  String field,
  String language,
) {
  List<String> words(Object? raw) => [
    if (raw is List)
      for (final Object? w in raw)
        if (w is String && w.trim().isNotEmpty) w.trim(),
  ];
  final Object? raw = section.json[field];
  if (raw is List) return words(raw);
  if (raw is! Map) return const [];
  final List<String> own = words(raw[language]);
  return own.isNotEmpty ? own : words(raw['en']);
}

/// A text field of [map], written per language or once for all, as
/// [ExploreSection.text] reads a section's own: for the items inside a
/// section — an expert, a chain, a stop on the ruler — which carry their
/// words the same way.
String? itemText(Map<Object?, Object?> map, String field, String language) {
  final Object? raw = map[field];
  if (raw is String) return raw.trim().isEmpty ? null : raw;
  if (raw is! Map) return null;
  final Object? own = raw[language];
  if (own is String && own.trim().isNotEmpty) return own;
  final Object? english = raw['en'];
  return english is String && english.trim().isNotEmpty ? english : null;
}

/// The items of a list field of [section] that are objects, in order.
List<Map<Object?, Object?>> sectionItems(ExploreSection section, String key) {
  final Object? raw = section.json[key];
  return [
    if (raw is List)
      for (final Object? item in raw)
        if (item is Map) item,
  ];
}

/// The key a card's subject is filed under (`economics`), from the name the
/// card carries (`Economics`).
String? subjectKeyOf(Pill pill) => topicKeyForName(pill.topic);

/// The subject's style by its key, or null for a key this build does not
/// know.
TopicStyle? subjectStyleOf(String key) => kTopics[key];

/// A subject's name in the reader's language, by its key.
String subjectNameOf(BuildContext context, String key) =>
    context.l10n.subjectName(key);

/// How long a movement takes: none at all for a reader who asked for less
/// motion, who gets the end of every movement at once.
Duration paced(BuildContext context, int milliseconds) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: milliseconds);

/// The click a pick makes under the thumb: a chip, a stop on the ruler, a
/// place on a scale.
void tickPicked() => HapticFeedback.selectionClick();

/// The heavier one for a thing done that stays done: a line said, a stance
/// taken after the evidence.
void tickDone() => HapticFeedback.mediumImpact();

/// The light one for a page turned: the next why opening.
void tickLight() => HapticFeedback.lightImpact();

/// The marks a screen uses besides the subjects' own: a statistician has
/// no subject, and draws bars.
const Map<String, String> kScreenMarks = {
  'chart': 'M4 20V10 M10 20V4 M16 20v-7 M3 20h18',
};

/// The path a mark is drawn with: one of [kScreenMarks], a subject by its
/// key (`economics`) or by the name a card carries (`Economics`); null for
/// one this build does not know.
String? markPath(String mark) {
  final String? own = kScreenMarks[mark];
  if (own != null) return own;
  final String name = kTopics[mark]?.name ?? mark;
  return kSubjectIcons[name];
}

/// A mark, drawn at the subjects' one weight in whatever ink it sits on.
class ScreenMark extends StatelessWidget {
  const ScreenMark({
    super.key,
    required this.mark,
    required this.size,
    required this.ink,
    this.stroke = 1.9,
  });

  /// See [markPath].
  final String mark;
  final double size;
  final Color ink;

  /// The line's weight on the 24-unit grid.
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final String? path = markPath(mark);
    if (path == null) return SizedBox(width: size, height: size);
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
        '<path d="$path" fill="none" stroke="#ffffff" stroke-width="$stroke" '
        'stroke-linecap="round" stroke-linejoin="round"/></svg>',
        colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
      ),
    );
  }
}

/// A shelf of a whole screen: its name, the line under it, and what it
/// holds — the same head every shelf of Explore has, so a screen made of
/// these reads as Explore. [head] false leaves the name and line out, for
/// a part of a screen that is not a shelf of its own, like the columns of
/// the front page.
class ScreenShelf extends StatelessWidget {
  const ScreenShelf({
    super.key,
    required this.title,
    required this.line,
    required this.child,
    this.trailing,
    this.head = true,
    this.gap = 11,
  });

  final String title;
  final String line;
  final Widget child;

  /// What sits level with the name: a count, a meter.
  final Widget? trailing;
  final bool head;

  /// Between the head and what it holds.
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (!head) return child;
    final Color ink = context.p.ink;
    final Widget name = Text(
      title,
      style: AppText.body(
        size: 16,
        weight: FontWeight.w600,
        height: 1.1,
        spacing: -0.2,
        color: ink,
      ),
    );
    final Widget words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        name,
        if (line.isNotEmpty) ...[
          const SizedBox(height: 3),
          BalancedText(
            line,
            style: AppText.body(
              size: 12,
              height: 1.3,
              color: ink.withValues(alpha: 0.42),
            ),
          ),
        ],
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: trailing == null
              ? words
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: words),
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ),
        ),
        SizedBox(height: gap),
        child,
      ],
    );
  }
}

/// A chip that steers a screen — an expert, a subject — lit when chosen:
/// the subject row's chip, with a mark or a dot before its name. Drawn
/// [height] high inside a target 44 high, so the row reads as the canvas
/// drew it and a thumb still finds it.
class PickChip extends StatelessWidget {
  const PickChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.height = 36,
    this.radius = 12,
    this.padding = const EdgeInsets.fromLTRB(11, 0, 13, 0),
    this.size = 12.5,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Before the name: given the ink it sits in.
  final Widget Function(Color ink)? leading;
  final double height;
  final double radius;
  final EdgeInsets padding;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final Color ink = selected ? p.onInverse : p.ink.withValues(alpha: 0.62);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: AnimatedContainer(
              duration: paced(context, 220),
              curve: Curves.easeOutCubic,
              height: height,
              constraints: const BoxConstraints(minWidth: 44),
              padding: padding,
              decoration: BoxDecoration(
                color: selected ? p.inverse : p.ink.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    leading!(ink),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    maxLines: 1,
                    style: AppText.body(
                      size: size,
                      weight: FontWeight.w600,
                      height: 1,
                      color: ink,
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

/// A row of [PickChip]s that scrolls sideways at the shelves' margins.
class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.chips, this.height = 44});

  final List<Widget> chips;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Taller at a large text size: the chip grows with its word, and a row
    // fixed at the small size would cut it in half.
    final double scaled = MediaQuery.textScalerOf(context).scale(height);
    return SizedBox(
      height: scaled < height ? height : scaled,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, i) => chips[i],
      ),
    );
  }
}

/// A raised panel on the page: a sixteenth of ink, the round corners of
/// the shelves' own panels (Mood minutes, Sixty seconds).
class ScreenPanel extends StatelessWidget {
  const ScreenPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.margin = const EdgeInsets.symmetric(horizontal: 20),
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: context.p.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

/// A round button with one mark on it: back and forth along the ruler.
class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 38,
  });

  final IconData icon;

  /// What a screen reader says for it.
  final String label;

  /// Null greys it out: the end of the ruler.
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedOpacity(
              duration: paced(context, 200),
              opacity: onTap == null ? 0.3 : 1,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A rounded button with an optional mark: the canvas's flat one, sized to
/// its words and growing with them.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.onTap,
    this.icon,
    this.height = 40,
    this.size = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;
  final double size;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height < 44 ? 44 : height),
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: AnimatedContainer(
              duration: paced(context, 200),
              constraints: BoxConstraints(minHeight: height),
              padding: padding,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: size + 3, color: foreground),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        label,
                        style: AppText.body(
                          size: size,
                          weight: FontWeight.w700,
                          height: 1.1,
                          color: foreground,
                        ),
                      ),
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

/// The head of a card on its own face: the subject's mark and name in small
/// capitals, in the reader's language, and what follows the name — "· THE
/// LEAD", "· CLAIM".
class FaceHead extends StatelessWidget {
  const FaceHead({
    super.key,
    required this.pill,
    this.after,
    this.trailing,
    this.ink,
    this.markSize = 15,
  });

  final Pill pill;

  /// Said after the subject's name, with a dot between.
  final String? after;
  final Widget? trailing;

  /// The mark's and the name's colour, where the card is not its own.
  final Color? ink;
  final double markSize;

  @override
  Widget build(BuildContext context) {
    final String name = context.l10n.subjectOf(pill.topic);
    return CardHead(
      pill: pill,
      label: after == null ? name : '$name · $after',
      ink: ink,
      labelInk: ink?.withValues(alpha: 0.66),
      trailing: trailing,
    );
  }
}

/// A card set on its own colour: the head, the question as large as the
/// face allows, and whatever the block puts under it. Tapping it does what
/// the block says, which is opening the card nearly always.
class ColourTile extends StatelessWidget {
  const ColourTile({
    super.key,
    required this.pill,
    required this.onTap,
    required this.height,
    this.width,
    this.read = false,
    this.head = true,
    this.after,
    this.text,
    this.min = 11,
    this.max = 17,
    this.radius = 20,
    this.padding = 15,
    this.foot,
    this.colour,
    this.badge,
  });

  final Pill pill;
  final VoidCallback onTap;
  final double height;
  final double? width;

  /// At the far end of the head: the year a card names, on the ruler.
  final Widget? badge;

  /// Read already: the shelves' tick beside the head.
  final bool read;

  /// The subject's name beside the mark; false leaves the mark alone, as on
  /// the smaller tiles of a row.
  final bool head;
  final String? after;

  /// What the face says instead of the card's question: a claim, a line.
  final String? text;
  final double min;
  final double max;
  final double radius;
  final double padding;

  /// Under the question.
  final Widget? foot;

  /// The face's colour, where it is not the card's own (the other subject
  /// of a meeting).
  final Color? colour;

  @override
  Widget build(BuildContext context) {
    final Color face = colour ?? pill.color;
    final Color ink = colour == null ? pill.ink : inkOn(face);
    final Widget tick = ReadMark(pill: pill, color: ink, size: 14);
    return CardTap(
      pill: pill,
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: EdgeInsets.all(padding),
        decoration: cardFace(context, face, radius: radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (head && badge == null)
              FaceHead(
                pill: pill,
                after: after,
                ink: colour == null ? null : ink,
                trailing: read ? tick : null,
              )
            else
              Row(
                children: [
                  ScreenMark(mark: pill.topic, size: 15, ink: ink),
                  if (head) ...[
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        upper(context, context.l10n.subjectOf(pill.topic)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(
                          size: 9,
                          weight: FontWeight.w700,
                          spacing: 1.2,
                          color: ink.withValues(alpha: 0.66),
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (badge != null) ...[const SizedBox(width: 6), badge!],
                  if (read) ...[const SizedBox(width: 6), tick],
                ],
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  top: max > 19 ? 12 : 10,
                  bottom: foot == null ? 0 : 8,
                ),
                child: ScaledText(
                  text: text ?? pill.question,
                  min: min,
                  max: max,
                  alignment: Alignment.topLeft,
                  styleFor: (size) => AppText.display(
                    size: size,
                    weight: FontWeight.w600,
                    height: max > 19 ? 1.12 : 1.15,
                    spacing: (max > 19 ? -0.032 : -0.027) * size,
                    color: ink,
                  ),
                ),
              ),
            ),
            ?foot,
          ],
        ),
      ),
    );
  }
}
