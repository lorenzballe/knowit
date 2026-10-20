/// Blocks that are not cards: words set as a headline, a paragraph or a
/// quote; a count of the days to something; a strip of subjects; the offer
/// of Astute+; a space, a rule; and a free section whose inside is a page
/// made with the card kit.
library;

import 'package:flutter/material.dart';

import '../../../data/pills_repository.dart' show daysBetween;
import '../../../data/topics.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../screens/mix_screen.dart' show kMixSubjects;
import '../../../theme.dart';
import '../../../widgets/explore/card_tiles.dart';
import '../../../widgets/explore/parts.dart' show FlatButton, Kicker, upper;
import '../../../widgets/fit_text.dart';
import '../../../widgets/subject_icon.dart';
import '../../../widgets/web/web_surface.dart' show WebSurfaces;
import '../../../widgets/web/web_surface_view.dart' show webSurface;
import '../../explore_block.dart';
import 'layout.dart';

/// The blocks that are not cards, in the order docs/explore/core.md lists
/// them.
const List<ExploreBlock> otherBlocks = [
  TextBlock(),
  CountdownBlock(),
  SubjectsBlock(),
  PromoBlock(),
  SpacerBlock(),
  DividerBlock(),
  WebBlock(),
];

/// The section's own words for [field], in the reader's language.
String? _said(ExploreSection section, ExploreHost host, String field) =>
    section.text(field, host.language);

/// The colour a section asks for by a subject's key, or null.
Color? _subjectColour(ExploreSection section) {
  final Object? key = section.json['subject'];
  return key is String ? kTopics[key]?.color : null;
}

// ── text ────────────────────────────────────────────────────────────────

/// Words of the section's own, as a `headline`, a `paragraph` (the
/// default) or a `quote`, with who said it (`by`) under a quote. `align`
/// `start` or `center`; `subject` colours the mark of a quote and the rule
/// beside a headline.
class TextBlock extends ExploreBlock with SectionLayout {
  const TextBlock();

  @override
  String get name => 'text';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final String? text = _said(section, host, 'text');
    if (text == null) return null;
    final bool centred = section.style['align'] == 'center';
    final TextAlign align = centred ? TextAlign.center : TextAlign.start;
    final CrossAxisAlignment cross = centred
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final Color accent = _subjectColour(section) ?? context.p.ink;
    final Widget body = switch (section.json['kind']) {
      'headline' => FitText(
        text,
        maxLines: 3,
        minSize: 22,
        textAlign: align,
        style: AppText.display(
          size: 30,
          weight: FontWeight.w600,
          height: 1.08,
          spacing: -0.8,
          color: context.p.ink,
        ),
      ),
      'quote' => Column(
        crossAxisAlignment: cross,
        children: [
          ExcludeSemantics(
            child: Text(
              '“',
              style: AppText.display(
                size: 64,
                weight: FontWeight.w700,
                height: 0.8,
                color: accent,
              ),
            ),
          ),
          Text(
            text,
            textAlign: align,
            style: AppText.display(
              size: 21,
              weight: FontWeight.w500,
              height: 1.28,
              spacing: -0.3,
              color: context.p.ink,
            ),
          ),
          if (_said(section, host, 'by') case final String by) ...[
            const SizedBox(height: 12),
            Kicker(by, color: context.p.inkMuted),
          ],
        ],
      ),
      _ => Text(
        text,
        textAlign: align,
        style: AppText.body(
          size: 15,
          height: 1.45,
          color: context.p.ink.withValues(alpha: 0.86),
        ),
      ),
    };
    return SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        // A headline stands against a rule of its subject's colour, as
        // tall as the headline is, whatever it wraps to.
        child: section.json['kind'] == 'headline' && !centred
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 14),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: accent, width: 4)),
                ),
                child: body,
              )
            : SizedBox(width: double.infinity, child: body),
      ),
    );
  }
}

// ── countdown ───────────────────────────────────────────────────────────

/// The days to a date — `to`, `2026-10-21`, on the phone's own calendar —
/// set large, with what they are the days to (`label`: "to the eclipse").
/// On the day itself it says today, with `today` if the section gives it;
/// after it, `after`, or nothing at all. `subject` gives it a subject's
/// colour; a `source` puts a row of its cards under it, at `size` `xs`, `s`
/// (the default) or `m`.
class CountdownBlock extends ExploreBlock with SectionLayout {
  const CountdownBlock();

  @override
  String get name => 'countdown';

  /// The days from [now] to [to], on the calendar: 0 on the day, negative
  /// after it. Null for a date that is not one.
  static int? daysTo(String? to, DateTime now) {
    if (to == null) return null;
    final RegExpMatch? m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(to);
    if (m == null) return null;
    final DateTime day = DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
    if (day.month != int.parse(m.group(2)!)) return null;
    return daysBetween(DateTime(now.year, now.month, now.day), day);
  }

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final l = context.l10n;
    final int? days = daysTo(
      section.get<String>('to'),
      host.app.remoteContext(host.language).now,
    );
    final String? label = _said(section, host, 'label');
    if (days == null || label == null) return null;
    final String? after = _said(section, host, 'after');
    if (days < 0 && after == null) return null;
    final Color? colour = _subjectColour(section);
    final Color ground = colour ?? context.p.ink.withValues(alpha: 0.06);
    final Color ink = colour == null ? context.p.ink : inkOn(colour);
    final String? figure = days > 0
        ? '$days'
        : days == 0
        ? l.todayLabel
        : null;
    final String line = days == 0
        ? _said(section, host, 'today') ?? label
        : days < 0
        ? after!
        : label;

    final TileSize size = switch (TileSize.named(section.size)) {
      final TileSize named when named.index <= TileSize.m.index => named,
      _ => TileSize.s,
    };
    final List<Pill> cards = section.source == null
        ? const []
        : host.cardsFor(section, limit: section.limit ?? 8);

    return SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              key: ValueKey('countdown-${section.id}'),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: BoxDecoration(
                color: ground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (figure != null)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 10,
                      children: [
                        Text(
                          figure,
                          style: AppText.display(
                            size: days > 0 ? 64 : 44,
                            weight: FontWeight.w700,
                            height: 1,
                            spacing: days > 0 ? -2.4 : -1.2,
                            color: ink,
                          ),
                        ),
                        if (days > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: Text(
                              upper(context, l.dayWord(days)),
                              style: AppText.label(
                                size: 11,
                                weight: FontWeight.w700,
                                spacing: 1.4,
                                color: ink.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (figure != null) const SizedBox(height: 8),
                  Text(
                    line,
                    style: AppText.display(
                      size: 20,
                      weight: FontWeight.w600,
                      height: 1.2,
                      spacing: -0.3,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (cards.isNotEmpty) ...[
            const SizedBox(height: 12),
            TileRow(
              size: size,
              pills: cards,
              isRead: host.isRead,
              onOpen: (shelf, pill) => host.open(section, shelf, pill),
              onShown: (pill) => host.seen(section, pill),
            ),
          ],
        ],
      ),
    );
  }
}

// ── subjects ────────────────────────────────────────────────────────────

/// How big a subject's tile is, by `size`; `s` is the chip of the subject
/// row at the top.
const Map<String, Size> kSubjectTiles = {
  's': Size(0, 36),
  'm': Size(112, 76),
  'l': Size(140, 100),
};

/// A strip of subjects, each narrowing Explore to it as its chip at the top
/// does: `subjects`, by their keys (every subject of the row at the top
/// when it names none), and `size` `s` (chips), `m` (the default) or `l`.
class SubjectsBlock extends ExploreBlock with SectionLayout {
  const SubjectsBlock();

  @override
  String get name => 'subjects';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final Object? named = section.json['subjects'];
    final Set<String> offered = {for (final s in kMixSubjects) s.key};
    final List<String> keys = [
      for (final Object? key
          in named is List ? named : [for (final s in kMixSubjects) s.key])
        if (key is String && offered.contains(key)) key,
    ];
    if (keys.isEmpty) return null;
    final String size = kSubjectTiles.containsKey(section.size)
        ? section.size!
        : 'm';
    final double height = kSubjectTiles[size]!.height;
    return SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      child: SizedBox(
        height: height + 4,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          itemCount: keys.length,
          separatorBuilder: (_, _) => SizedBox(width: size == 's' ? 7 : 8),
          itemBuilder: (context, i) {
            final TopicStyle topic = kTopics[keys[i]]!;
            final bool on = host.subject == topic.name;
            return _SubjectTile(
              key: ValueKey('section-subject-${keys[i]}-${on ? 'on' : 'off'}'),
              topic: topic,
              name: context.l10n.subjectName(keys[i]),
              size: size,
              on: on,
              onTap: () => host.openSubject(topic.name),
            );
          },
        ),
      ),
    );
  }
}

/// One subject of the strip.
class _SubjectTile extends StatelessWidget {
  const _SubjectTile({
    super.key,
    required this.topic,
    required this.name,
    required this.size,
    required this.on,
    required this.onTap,
  });

  final TopicStyle topic;
  final String name;
  final String size;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget face;
    if (size == 's') {
      final Color ink = on ? topic.ink : context.p.ink;
      face = AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 36,
        constraints: const BoxConstraints(minWidth: 44),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: on ? topic.color : context.p.ink.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SubjectIcon(
              subject: topic.name,
              size: 14,
              ink: on ? ink : topic.color,
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: AppText.body(
                size: 12.5,
                weight: FontWeight.w600,
                color: on ? ink : context.p.ink.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      );
    } else {
      final Size box = kSubjectTiles[size]!;
      face = Container(
        width: box.width,
        height: box.height,
        padding: const EdgeInsets.fromLTRB(12, 11, 10, 10),
        decoration: BoxDecoration(
          color: topic.color,
          borderRadius: BorderRadius.circular(size == 'l' ? 20 : 17),
          border: on
              ? Border.all(color: context.p.ink, width: 2.5)
              : Border.all(color: topic.color, width: 0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SubjectIcon(
                  subject: topic.name,
                  size: size == 'l' ? 22 : 18,
                  ink: topic.ink,
                ),
                const Spacer(),
                if (on)
                  Icon(
                    Icons.check_circle_rounded,
                    size: size == 'l' ? 18 : 15,
                    color: topic.ink.withValues(alpha: 0.85),
                  ),
              ],
            ),
            FitText(
              name,
              maxLines: 2,
              minSize: 10.5,
              style: AppText.body(
                size: size == 'l' ? 15 : 13,
                weight: FontWeight.w700,
                height: 1.1,
                color: topic.ink,
              ),
            ),
          ],
        ),
      );
    }
    return Semantics(
      button: true,
      selected: on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: size == 's'
            ? Align(alignment: Alignment.topCenter, child: face)
            : face,
      ),
    );
  }
}

// ── promo ───────────────────────────────────────────────────────────────

/// The offer of Astute+, opening the plans: on the free plan only, unless
/// `plan` is `all`. Its words are the paywall's own unless the section
/// gives `kicker`, `headline`, `line` or `button`; `from` names the door in
/// the paywall's numbers (`explore` by default).
class PromoBlock extends ExploreBlock with SectionLayout {
  const PromoBlock();

  @override
  String get name => 'promo';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    if (host.app.isPlus && section.json['plan'] != 'all') return null;
    final l = context.l10n;
    final String from = section.get<String>('from') ?? 'explore';
    void open() => host.openPlans(from);
    final Color ground = context.p.inverse;
    final Color ink = context.p.onInverse;
    return SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          key: ValueKey('promo-${section.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: open,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            decoration: BoxDecoration(
              color: ground,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Kicker(
                  _said(section, host, 'kicker') ?? l.plusName,
                  color: ink.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 10),
                FitText(
                  _said(section, host, 'headline') ?? l.paywallOutcomeTitle,
                  maxLines: 3,
                  minSize: 19,
                  style: AppText.display(
                    size: 26,
                    weight: FontWeight.w600,
                    height: 1.1,
                    spacing: -0.6,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _said(section, host, 'line') ?? l.paywallOutcomeLine,
                  style: AppText.body(
                    size: 13.5,
                    height: 1.4,
                    color: ink.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 18),
                FlatButton(
                  label: _said(section, host, 'button') ?? l.getPlus,
                  background: ink,
                  foreground: ground,
                  height: 44,
                  size: 14,
                  expand: true,
                  onTap: open,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── spacer, divider ─────────────────────────────────────────────────────

/// Room, `height` points of it (24 unless it says), and nothing else.
class SpacerBlock extends ExploreBlock with SectionLayout {
  const SpacerBlock();

  @override
  String get name => 'spacer';

  @override
  double get gap => 0;

  @override
  bool get isShelf => false;

  @override
  Widget build(BuildContext context, ExploreHost host, ExploreSection section) {
    final Object? height = section.json['height'];
    return SizedBox(
      height: height is num && height >= 0 && height <= 240
          ? height.toDouble()
          : 24,
    );
  }
}

/// A rule across the page, between the margins, with a word in the middle
/// of it when the section gives one (`label`).
class DividerBlock extends ExploreBlock with SectionLayout {
  const DividerBlock();

  @override
  String get name => 'divider';

  @override
  bool get isShelf => false;

  @override
  Widget build(BuildContext context, ExploreHost host, ExploreSection section) {
    final Widget rule = Expanded(
      child: Container(height: 1, color: context.p.line),
    );
    final String? label = _said(section, host, 'label');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          rule,
          if (label != null) ...[
            const SizedBox(width: 12),
            Kicker(label, color: context.p.inkMuted),
            const SizedBox(width: 12),
            rule,
          ],
        ],
      ),
    );
  }
}

// ── web ─────────────────────────────────────────────────────────────────

/// A free section: a page made with the card kit (docs/cards/kit/), `html`
/// in one language or per language, shown `height` points tall (40 to
/// 1200) between the page's margins, in a card's corner.
///
/// It is drawn by the web surface, through [webSection]: the one a free
/// card's page is drawn on (lib/widgets/web/), with the kit, the reader's
/// theme and language inside it. Where the phone has no WebView to draw it
/// in, the section is passed over, as a block the build does not know
/// would be.
class WebBlock extends ExploreBlock with SectionLayout {
  const WebBlock();

  /// Draws a section's page, [height] points tall; null passes every web
  /// section over.
  static Widget Function(
    BuildContext context, {
    required String html,
    required double height,
  })?
  webSection = _drawn;

  static Widget _drawn(
    BuildContext context, {
    required String html,
    required double height,
  }) => webSurface(context, html: html, height: height);

  @override
  String get name => 'web';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final draw = webSection;
    if (draw == null || !WebSurfaces.available) return null;
    final String? html = _said(section, host, 'html');
    final Object? rawHeight = section.json['height'];
    if (html == null ||
        rawHeight is! num ||
        rawHeight < 40 ||
        rawHeight > 1200) {
      return null;
    }
    final double height = rawHeight.toDouble();
    return SectionFrame(
      title: section.title(host.language),
      line: section.subtitle(host.language),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            key: ValueKey('web-${section.id}'),
            height: height,
            width: double.infinity,
            child: draw(context, html: html, height: height),
          ),
        ),
      ),
    );
  }
}
