/// Say it tonight — artboard 141e.
///
/// Cards as lines to say at dinner: one large, tonight's, set as something
/// said — a speech bubble with its tail — and the reason it is true under
/// it, then a row of more. "I said it" is the said that Top of the week
/// already counts (AppState.markSaid feeds the readers' tallies), so a line
/// that left the phone climbs the list like a card saved. Said is said: it
/// cannot be taken back, by the app's own rule, and the button says so by
/// staying said.
///
/// The lines are the bank's true-or-false cards whose claim is true, read
/// as statements: a surprising thing that is so, and the card that shows
/// why. The count under them is the reader's week, kept on the phone with
/// the day each line was said.
library;

import 'package:flutter/material.dart';

import '../../../data/explore_mix.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/card_edge.dart';
import '../../../widgets/scaled_text.dart';
import '../../../widgets/share_sheet.dart';
import '../../explore_block.dart';
import 'memory.dart';
import 'parts.dart';

/// How many cards the lines are looked for among.
const int kSayPool = 240;

/// Whether [pill] makes a line to say: a true-or-false card whose claim is
/// true.
bool makesALine(Pill pill) => isTrueOrFalse(pill) && trueOrFalseAnswer(pill);

/// Why the line is so: the first lines of the card's answer, without the
/// "True." it starts with.
String reasonOf(Pill pill) => firstLines(
  pill.answer.replaceFirst(
    RegExp(r'^true[.!,:]?\s*', caseSensitive: false),
    '',
  ),
  max: 170,
);

/// How many of the days in [said] fall in the week of [now], Monday first.
int saidThisWeek(Map<String, String> said, DateTime now) {
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime monday = today.subtract(Duration(days: today.weekday - 1));
  final String from = screensDayKey(monday);
  final String to = screensDayKey(monday.add(const Duration(days: 6)));
  return said.values
      .where((d) => d.compareTo(from) >= 0 && d.compareTo(to) <= 0)
      .length;
}

/// The block.
class SayItTonightBlock extends ExploreBlock {
  const SayItTonightBlock();

  @override
  String get name => 'say-it-tonight';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> lines = [
      for (final Pill p in host.cardsFor(section, limit: kSayPool))
        if (makesALine(p)) p,
    ].take(section.limit ?? 5).toList();
    if (lines.isEmpty) return null;
    return host.watch(
      section,
      _Say(host: host, section: section, lines: lines),
    );
  }
}

class _Say extends StatelessWidget {
  const _Say({required this.host, required this.section, required this.lines});

  final ExploreHost host;
  final ExploreSection section;
  final List<Pill> lines;

  @override
  Widget build(BuildContext context) {
    final ScreensMemory memory = ScreensMemory.instance..open();
    return ListenableBuilder(
      listenable: Listenable.merge([memory, host.app]),
      builder: (context, _) => _view(context, memory),
    );
  }

  void _said(ScreensMemory memory, Pill pill) {
    if (host.app.hasSaid(pill.id)) return;
    tickDone();
    memory.markSaid(pill.id, on: screensDayKey(DateTime.now()));
    host.app.markSaid(pill.id);
    host.note(section, 'said', {'pill_id': pill.id});
  }

  Widget _view(BuildContext context, ScreensMemory memory) {
    final l = context.l10n;
    final Palette p = context.p;
    final ScreenSize size = screenSizeOf(section);
    final bool hero = size != ScreenSize.s;
    final Pill? first = hero ? lines.first : null;
    final List<Pill> row = hero ? lines.skip(1).toList() : lines;
    if (first != null) host.seen(section, first);
    final int week = saidThisWeek(memory.said, DateTime.now());

    return ScreenShelf(
      head: styleOn(section, 'head'),
      title: section.title(host.language) ?? l.screensSayTitle,
      line: section.subtitle(host.language) ?? l.screensSayLine,
      gap: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (first != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _Tonight(
                pill: first,
                size: size,
                said: host.app.hasSaid(first.id),
                onOpen: () => host.open(section, lines, first),
                onSaid: () => _said(memory, first),
                onShare: () => showShareSheet(context, first),
              ),
            ),
          if (row.isNotEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 212 + 11 + 8 + _grow(context),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
                itemCount: row.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  host.seen(section, row[i]);
                  return _Line(
                    pill: row[i],
                    height: 212 + _grow(context),
                    said: host.app.hasSaid(row[i].id),
                    onOpen: () => host.open(section, lines, row[i]),
                    onSaid: () => _said(memory, row[i]),
                  );
                },
              ),
            ),
          ],
          if (styleOn(section, 'counter')) ...[
            const SizedBox(height: 4),
            ScreenPanel(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              radius: 20,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.inverse,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$week',
                      key: const ValueKey('say-count'),
                      textScaler: TextScaler.noScaling,
                      style: AppText.display(
                        size: 19,
                        weight: FontWeight.w600,
                        height: 1,
                        color: p.onInverse,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.screensSayWeek(week),
                          style: AppText.body(
                            size: 14,
                            weight: FontWeight.w600,
                            height: 1.3,
                            color: p.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.screensSayCounts,
                          style: AppText.body(
                            size: 12,
                            weight: FontWeight.w500,
                            height: 1.4,
                            color: p.ink.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// How much taller the row's bubbles are at a large text size, so the
  /// button under the line still has its room.
  static double _grow(BuildContext context) {
    final double extra = MediaQuery.textScalerOf(context).scale(12) - 12;
    return extra <= 0 ? 0 : extra * 3;
  }
}

/// The button a line is said with: a cross until it is said, a tick after,
/// and the card's own ink filled in.
class _SaidButton extends StatelessWidget {
  const _SaidButton({
    required this.pill,
    required this.said,
    required this.onTap,
    required this.small,
  });

  final Pill pill;
  final bool said;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PillButton(
      key: ValueKey('say-${pill.id}-${said ? 'said' : 'not'}'),
      label: said ? l.screensSayDone : l.screensSaySaid,
      icon: said ? Icons.check_rounded : Icons.add_rounded,
      height: small ? 34 : 40,
      size: small ? 12 : 13,
      padding: small
          ? const EdgeInsets.fromLTRB(10, 0, 13, 0)
          : const EdgeInsets.fromLTRB(12, 0, 16, 0),
      background: said ? pill.ink : fillOn(pill),
      foreground: said ? pill.color : pill.ink,
      onTap: said ? null : onTap,
    );
  }
}

/// A speech bubble's tail: a corner of the bubble's colour under its left
/// edge, the way the canvas cuts it.
class _Tail extends StatelessWidget {
  const _Tail({required this.colour, this.width = 22, this.height = 12});

  final Color colour;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    // A bubble pale enough to need a hairline on the page needs one round
    // its tail too, or the tail melts into the paper the bubble stands on.
    final bool edged = cardHairline(colour, context.p.surface) != null;
    return CustomPaint(
      size: Size(width, height),
      painter: _TailPainter(
        colour,
        edge: edged ? cardEdgeColour(colour) : null,
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter(this.colour, {this.edge});

  final Color colour;
  final Color? edge;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, -1)
        ..lineTo(size.width, -1)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = colour,
    );
    if (edge == null) return;
    final Paint line = Paint()
      ..color = edge!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(0.5, size.height - 0.5)
        ..lineTo(0.5, 0),
      line,
    );
  }

  @override
  bool shouldRepaint(_TailPainter old) =>
      old.colour != colour || old.edge != edge;
}

/// Tonight's line, large: the quotation mark behind it, the reason under
/// it, the two buttons.
class _Tonight extends StatelessWidget {
  const _Tonight({
    required this.pill,
    required this.size,
    required this.said,
    required this.onOpen,
    required this.onSaid,
    required this.onShare,
  });

  final Pill pill;
  final ScreenSize size;
  final bool said;
  final VoidCallback onOpen;
  final VoidCallback onSaid;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final double type = bySize(size, s: 22, m: 26, l: 30);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: cardFace(context, pill.color, radius: 24).copyWith(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 14,
                top: -40,
                child: ExcludeSemantics(
                  child: Text(
                    '”',
                    textScaler: TextScaler.noScaling,
                    style: AppText.display(
                      size: 210,
                      weight: FontWeight.w600,
                      height: 1,
                      color: shade(pill.color, 0.84),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CardTap(
                      pill: pill,
                      onTap: onOpen,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CardHead(
                            pill: pill,
                            label:
                                '${l.screensSayTonight} · '
                                '${l.subjectOf(pill.topic)}',
                          ),
                          const SizedBox(height: 14),
                          Text(
                            claimOf(pill),
                            style: AppText.display(
                              size: type,
                              weight: FontWeight.w600,
                              height: 1.12,
                              spacing: -0.032 * type,
                              color: pill.ink,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            reasonOf(pill),
                            style: AppText.body(
                              size: 12.5,
                              weight: FontWeight.w500,
                              height: 1.45,
                              color: pill.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _SaidButton(
                          pill: pill,
                          said: said,
                          onTap: onSaid,
                          small: false,
                        ),
                        PillButton(
                          key: ValueKey('say-share-${pill.id}'),
                          label: l.share,
                          icon: Icons.ios_share_rounded,
                          height: 40,
                          size: 13,
                          padding: const EdgeInsets.fromLTRB(13, 0, 16, 0),
                          background: fillOn(pill),
                          foreground: pill.ink,
                          onTap: onShare,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _Tail(colour: pill.color),
      ],
    );
  }
}

/// One more line, in the row: a smaller bubble with its own button.
class _Line extends StatelessWidget {
  const _Line({
    required this.pill,
    required this.height,
    required this.said,
    required this.onOpen,
    required this.onSaid,
  });

  final Pill pill;
  final double height;
  final bool said;
  final VoidCallback onOpen;
  final VoidCallback onSaid;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 268,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: height,
            padding: const EdgeInsets.all(16),
            decoration: cardFace(context, pill.color, radius: 22).copyWith(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CardTap(
                    pill: pill,
                    onTap: onOpen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FaceHead(pill: pill),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ScaledText(
                            text: claimOf(pill),
                            min: 12,
                            max: 19,
                            alignment: Alignment.topLeft,
                            styleFor: (s) => AppText.display(
                              size: s,
                              weight: FontWeight.w600,
                              height: 1.14,
                              spacing: -0.028 * s,
                              color: pill.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _SaidButton(pill: pill, said: said, onTap: onSaid, small: true),
              ],
            ),
          ),
          _Tail(colour: pill.color, width: 20, height: 11),
        ],
      ),
    );
  }
}
