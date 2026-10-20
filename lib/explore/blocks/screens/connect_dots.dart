/// Connect the dots — artboard 140c.
///
/// Every card here sits where two subjects meet: a road that makes traffic
/// worse is economics and psychology at once, the lapis in a painter's blue
/// is art and money. Pick a subject and it stands in the middle, with the
/// subjects it meets around it and the cards between them underneath, each
/// in the colour of the subject it leads to.
///
/// The meetings are the bank's own: a card filed under one subject that is
/// genuinely about a strand of another says so in its tags (`also`), and
/// those are the cards this block shows. A section can add meetings by hand
/// — a card and the subject it meets — for a card whose tags have not
/// caught up with it.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/topics.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/card_edge.dart';
import '../../explore_block.dart';
import 'memory.dart';
import 'parts.dart';

/// How many cards the meetings are looked for among.
const int kDotsPool = 400;

/// The most subjects drawn round the one in the middle: past seven the
/// labels run into each other.
const int kDotsSpokes = 7;

/// A card between two subjects, seen from [hub]: it leads to [other].
@immutable
class DotMeeting {
  const DotMeeting(this.pill, this.hub, this.other);

  final Pill pill;
  final String hub;
  final String other;
}

/// Every meeting in [pool], by the subject in the middle: a card of one
/// subject tagged with a strand of another meets it from both sides. Then
/// the meetings [extra] adds by hand. Each card is once under a subject,
/// with the first other subject it meets.
Map<String, List<DotMeeting>> meetingsOf(
  Iterable<Pill> pool, {
  Iterable<(Pill, String)> extra = const [],
}) {
  final Map<String, List<DotMeeting>> out = {};
  void meet(Pill p, String a, String b) {
    if (a == b || !kTopics.containsKey(a) || !kTopics.containsKey(b)) return;
    final List<DotMeeting> at = out.putIfAbsent(a, () => []);
    if (at.any((m) => m.pill.id == p.id)) return;
    at.add(DotMeeting(p, a, b));
  }

  for (final Pill p in pool) {
    final String? own = subjectKeyOf(p);
    if (own == null) continue;
    for (final String strand in p.also) {
      final String other = strand.split('.').first;
      meet(p, own, other);
      meet(p, other, own);
    }
  }
  for (final (Pill p, String other) in extra) {
    final String? own = subjectKeyOf(p);
    if (own == null) continue;
    meet(p, own, other);
    meet(p, other, own);
  }
  return out;
}

/// The block.
class ConnectDotsBlock extends ExploreBlock {
  const ConnectDotsBlock();

  @override
  String get name => 'connect-dots';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> pool = host.cardsFor(section, limit: kDotsPool);
    // The meetings written into the section, fetched the way every card
    // is, so a card the reader cannot be dealt is never shown here either.
    final List<(String, String)> asked = [
      for (final Map<Object?, Object?> m in sectionItems(section, 'pairs'))
        if (m['card'] is String && m['with'] is String)
          (m['card'] as String, m['with'] as String),
    ];
    final List<(Pill, String)> extra = [];
    if (asked.isNotEmpty) {
      final List<Pill> named = host.cardsFor(
        ExploreSection(
          id: '${section.id}/pairs',
          block: name,
          json: {
            'id': '${section.id}/pairs',
            'block': name,
            'source': {
              'ids': [for (final (id, _) in asked) id],
            },
          },
        ),
        limit: asked.length,
      );
      for (final (String id, String other) in asked) {
        final Pill? p = named.where((p) => p.id == id).firstOrNull;
        if (p != null) extra.add((p, other));
      }
    }
    final Map<String, List<DotMeeting>> meetings = meetingsOf(
      pool,
      extra: extra,
    );
    final String? narrowed = host.subject == null
        ? null
        : topicKeyForName(host.subject!);
    final Object? wanted = section.json['subjects'];
    final List<String> order = narrowed != null
        ? [narrowed]
        : wanted is List && wanted.isNotEmpty
        ? [
            for (final Object? s in wanted)
              if (s is String) s,
          ]
        : kTopicOrder;
    final List<String> hubs = [
      for (final String s in order)
        if ((meetings[s]?.length ?? 0) >= 2) s,
    ];
    if (hubs.isEmpty) return null;
    return host.watch(
      section,
      _Dots(host: host, section: section, hubs: hubs, meetings: meetings),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.host,
    required this.section,
    required this.hubs,
    required this.meetings,
  });

  final ExploreHost host;
  final ExploreSection section;
  final List<String> hubs;
  final Map<String, List<DotMeeting>> meetings;

  @override
  Widget build(BuildContext context) {
    final ScreensMemory memory = ScreensMemory.instance..open();
    return ListenableBuilder(
      listenable: memory,
      builder: (context, _) {
        String hub = hubs.first;
        final String? kept = memory.pick(section.id);
        final Object? asked = section.json['subject'];
        if (kept != null && hubs.contains(kept)) {
          hub = kept;
        } else if (asked is String && hubs.contains(asked)) {
          hub = asked;
        }
        return _view(context, hub, memory);
      },
    );
  }

  void _pick(ScreensMemory memory, String hub) {
    tickPicked();
    memory.setPick(section.id, hub);
    host.note(section, 'subject picked', {'subject': hub});
  }

  Widget _view(BuildContext context, String hub, ScreensMemory memory) {
    final l = context.l10n;
    final Palette p = context.p;
    final ScreenSize size = screenSizeOf(section);
    final List<DotMeeting> all = meetings[hub]!;
    // The subjects it meets most go round it first: past seven the map has
    // no room, and the strongest links are the ones worth drawing.
    final Map<String, int> met = {};
    for (final DotMeeting m in all) {
      met[m.other] = (met[m.other] ?? 0) + 1;
    }
    final List<String> others = met.keys.toList()
      ..sort((a, b) => met[b]!.compareTo(met[a]!));
    // One card for each subject met before a second for any: five cards
    // of one pair would be one meeting told five times.
    final List<DotMeeting> listed = [];
    final int most = section.limit ?? 5;
    for (int round = 0; listed.length < most; round++) {
      bool any = false;
      for (final String other in others) {
        final List<DotMeeting> withIt = [
          for (final DotMeeting m in all)
            if (m.other == other) m,
        ];
        if (round < withIt.length && listed.length < most) {
          listed.add(withIt[round]);
          any = true;
        }
      }
      if (!any) break;
    }
    final List<Pill> shelf = [for (final m in listed) m.pill];
    for (final Pill pill in shelf) {
      host.seen(section, pill);
    }
    final bool map = size != ScreenSize.s && styleOn(section, 'map');

    return ScreenShelf(
      head: styleOn(section, 'head'),
      title: section.title(host.language) ?? l.screensDotsTitle,
      line: section.subtitle(host.language) ?? l.screensDotsLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hubs.length > 1) ...[
            ChipRow(
              chips: [
                for (final String s in hubs)
                  PickChip(
                    key: ValueKey('dots-$s-${s == hub ? 'on' : 'off'}'),
                    label: subjectNameOf(context, s),
                    selected: s == hub,
                    leading: (_) => Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: kTopics[s]!.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onTap: () {
                      if (s != hub) _pick(memory, s);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          AnimatedSwitcher(
            duration: paced(context, 240),
            child: Column(
              key: ValueKey('dots-at-$hub'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectNameOf(context, hub),
                        style: AppText.display(
                          size: bySize(size, s: 24, m: 28, l: 32),
                          weight: FontWeight.w600,
                          height: 1.05,
                          spacing: -0.8,
                          color: p.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.screensDotsMeets(others.length, all.length),
                        style: AppText.body(
                          size: 12.5,
                          weight: FontWeight.w500,
                          height: 1.3,
                          color: p.ink.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (map) ...[
                  const SizedBox(height: 18),
                  _Constellation(
                    hub: hub,
                    others: others.take(kDotsSpokes).toList(),
                    tall: size == ScreenSize.l,
                    onPick: (s) {
                      if (hubs.contains(s)) _pick(memory, s);
                    },
                    canPick: hubs.contains,
                  ),
                ],
                const SizedBox(height: 22),
                ScreenShelf(
                  title: l.screensDotsWhere,
                  line: l.screensDotsWhereLine,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 0; i < listed.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          _Meeting(
                            meeting: listed[i],
                            size: size,
                            read: host.isRead(listed[i].pill),
                            onTap: () =>
                                host.open(section, shelf, listed[i].pill),
                          ),
                        ],
                      ],
                    ),
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

/// The subject in the middle and the subjects it meets round it, joined by
/// dotted lines — a tap on one of those makes it the middle.
class _Constellation extends StatelessWidget {
  const _Constellation({
    required this.hub,
    required this.others,
    required this.tall,
    required this.onPick,
    required this.canPick,
  });

  final String hub;
  final List<String> others;
  final bool tall;
  final ValueChanged<String> onPick;
  final bool Function(String) canPick;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final double height = tall ? 260 : 236;
    final double radius = tall ? 100 : 88;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, box) {
          final double width = box.maxWidth;
          final Offset centre = Offset(width / 2, height / 2 - 6);
          final List<Offset> at = [
            for (int i = 0; i < others.length; i++)
              centre +
                  Offset.fromDirection(
                    -math.pi / 2 + i * 2 * math.pi / others.length,
                    radius,
                  ),
          ];
          final double label = scaler.scale(10.5) * 1.1;
          return SizedBox(
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _Spokes(
                      centre: centre,
                      ends: at,
                      ink: p.ink.withValues(alpha: 0.26),
                    ),
                  ),
                ),
                Positioned(
                  left: centre.dx - 27,
                  top: centre.dy - 27,
                  child: Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kTopics[hub]!.color,
                      shape: BoxShape.circle,
                      border: cardHairline(kTopics[hub]!.color, p.surface),
                      boxShadow: [
                        BoxShadow(
                          color: p.ink.withValues(alpha: 0.07),
                          spreadRadius: 7,
                        ),
                      ],
                    ),
                    child: ScreenMark(
                      mark: hub,
                      size: 22,
                      ink: kTopics[hub]!.ink,
                    ),
                  ),
                ),
                for (int i = 0; i < others.length; i++) ...[
                  Positioned(
                    left: at[i].dx - 22,
                    top: at[i].dy - 22,
                    child: Semantics(
                      button: canPick(others[i]),
                      label: subjectNameOf(context, others[i]),
                      child: GestureDetector(
                        key: ValueKey('dots-spoke-${others[i]}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: canPick(others[i])
                            ? () => onPick(others[i])
                            : null,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: kTopics[others[i]]!.color,
                                shape: BoxShape.circle,
                                border: cardHairline(
                                  kTopics[others[i]]!.color,
                                  p.surface,
                                ),
                              ),
                              child: ScreenMark(
                                mark: others[i],
                                size: 15,
                                ink: kTopics[others[i]]!.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (at[i].dx - 50).clamp(0, math.max(0, width - 100)),
                    top:
                        math.sin(
                              -math.pi / 2 + i * 2 * math.pi / others.length,
                            ) >
                            0.2
                        ? at[i].dy + 21
                        : at[i].dy - 21 - label - 4,
                    width: 100,
                    child: ExcludeSemantics(
                      child: Text(
                        subjectNameOf(context, others[i]),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          size: 10.5,
                          weight: FontWeight.w600,
                          height: 1.1,
                          color: p.ink.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Spokes extends CustomPainter {
  const _Spokes({required this.centre, required this.ends, required this.ink});

  final Offset centre;
  final List<Offset> ends;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..color = ink
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final Offset end in ends) {
      // Dashed, three on and four off, from the edge of the middle to the
      // edge of each circle round it.
      final Offset d = end - centre;
      final double length = d.distance;
      if (length <= 0) continue;
      final Offset unit = d / length;
      for (double t = 27; t < length - 17; t += 7) {
        final double stop = math.min(t + 3, length - 17);
        canvas.drawLine(centre + unit * t, centre + unit * stop, line);
      }
    }
  }

  @override
  bool shouldRepaint(_Spokes old) =>
      old.centre != centre || old.ink != ink || old.ends.length != ends.length;
}

/// One card where two subjects meet, in the colour of the one it leads to.
class _Meeting extends StatelessWidget {
  const _Meeting({
    required this.meeting,
    required this.size,
    required this.read,
    required this.onTap,
  });

  final DotMeeting meeting;
  final ScreenSize size;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TopicStyle other = kTopics[meeting.other]!;
    final TopicStyle hub = kTopics[meeting.hub]!;
    final Color ink = other.ink;
    final String pair = upper(
      context,
      '${subjectNameOf(context, meeting.hub)} × '
      '${subjectNameOf(context, meeting.other)}',
    );
    return CardTap(
      pill: meeting.pill,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: cardFace(context, other.color, radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: hub.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: ink, width: 2),
                  ),
                ),
                const SizedBox(width: 8),
                ScreenMark(mark: meeting.other, size: 14, ink: ink),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pair,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(
                      size: 9,
                      weight: FontWeight.w700,
                      spacing: 1.2,
                      color: ink,
                    ),
                  ),
                ),
                if (read) ...[
                  const SizedBox(width: 6),
                  ReadMark(pill: meeting.pill, color: ink, size: 14),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              meeting.pill.question,
              style: AppText.display(
                size: bySize(size, s: 15.5, m: 17, l: 19),
                weight: FontWeight.w600,
                height: 1.16,
                spacing: -0.025 * bySize(size, s: 15.5, m: 17, l: 19),
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
