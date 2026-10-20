/// Change your mind — artboard 141d.
///
/// A claim, and before a word of the card is read, where the reader stands
/// on it: five places from strongly disagree to strongly agree. Then what
/// we know, and the same question again. The two answers side by side are
/// a change of mind that can be counted, which is the one thing a card is
/// for and the one thing nothing else in the app measures.
///
/// The claims are the bank's true-or-false cards, read as statements, the
/// myths first; what we know is the first lines of the card's own answer,
/// so the evidence is the card's and its sources are the card's. Showing it
/// is reading the card, which the day then never deals again.
///
/// Where the reader stood is kept on the phone, once each: a stance taken
/// after the evidence was seen is not a stance before it.
library;

import 'package:flutter/material.dart';

import '../../../data/explore_mix.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/card_edge.dart';
import '../../explore_block.dart';
import 'memory.dart';
import 'parts.dart';

/// How many cards the claims are looked for among.
const int kMindPool = 240;

/// The place on the scale where the evidence on [pill] stands: strongly
/// agree for a claim that is true, strongly disagree for one that is not.
int evidencePlace(Pill pill) => trueOrFalseAnswer(pill) ? 4 : 0;

/// What the card's answer says, without the "True." or "False." it starts
/// with: the scale has just asked exactly that.
String evidenceOf(Pill pill) => firstLines(
  pill.answer.replaceFirst(
    RegExp(r'^(true|false)[.!,:]?\s*', caseSensitive: false),
    '',
  ),
  max: 220,
);

/// The block.
class ChangeYourMindBlock extends ExploreBlock {
  const ChangeYourMindBlock();

  @override
  String get name => 'change-your-mind';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> claims = [
      for (final Pill p in host.cardsFor(section, limit: kMindPool))
        if (isTrueOrFalse(p)) p,
    ];
    // The myths first: a claim almost everybody holds is the one most
    // worth a second answer.
    final List<Pill> ordered = [
      ...claims.where((p) => p.hook == 'misconception'),
      ...claims.where((p) => p.hook != 'misconception'),
    ].take(section.limit ?? 3).toList();
    if (ordered.isEmpty) return null;
    return host.watch(
      section,
      _Mind(host: host, section: section, claims: ordered),
    );
  }
}

class _Mind extends StatelessWidget {
  const _Mind({
    required this.host,
    required this.section,
    required this.claims,
  });

  final ExploreHost host;
  final ExploreSection section;
  final List<Pill> claims;

  @override
  Widget build(BuildContext context) {
    final ScreensMemory memory = ScreensMemory.instance..open();
    return ListenableBuilder(
      listenable: memory,
      builder: (context, _) => _view(context, memory),
    );
  }

  void _before(ScreensMemory memory, Pill pill, int place) {
    tickPicked();
    memory.setBefore(pill.id, place, on: screensDayKey(DateTime.now()));
    host.note(section, 'stance', {
      'pill_id': pill.id,
      'when': 'before',
      'level': place,
    });
    // The evidence is on the shelf now: the card has been read.
    host.app.markReadElsewhere(pill.id);
  }

  void _after(ScreensMemory memory, Pill pill, int before, int place) {
    tickDone();
    memory.setAfter(pill.id, place);
    final int target = evidencePlace(pill);
    host.note(section, 'stance', {
      'pill_id': pill.id,
      'when': 'after',
      'level': place,
      'before': before,
      'moved': (before - target).abs() - (place - target).abs(),
    });
  }

  Widget _view(BuildContext context, ScreensMemory memory) {
    final l = context.l10n;
    final Palette p = context.p;
    final ScreenSize size = screenSizeOf(section);
    int answered = 0;
    int changed = 0;
    for (final Pill pill in claims) {
      host.seen(section, pill);
      final Stance s = memory.stance(pill.id);
      if (s.after != null) {
        answered++;
        if (s.after != s.before) changed++;
      }
    }
    return ScreenShelf(
      head: styleOn(section, 'head'),
      title: section.title(host.language) ?? l.screensMindTitle,
      line: section.subtitle(host.language) ?? l.screensMindLine,
      gap: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < claims.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _Claim(
                    key: ValueKey('mind-${claims[i].id}'),
                    pill: claims[i],
                    stance: memory.stance(claims[i].id),
                    size: size,
                    onOpen: () => host.open(section, claims, claims[i]),
                    onBefore: (place) => _before(memory, claims[i], place),
                    onAfter: (before, place) =>
                        _after(memory, claims[i], before, place),
                  ),
                ],
              ],
            ),
          ),
          if (styleOn(section, 'summary')) ...[
            const SizedBox(height: 12),
            ScreenPanel(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              radius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    answered == 0
                        ? l.screensMindFirst
                        : l.screensMindChanged(changed, answered),
                    key: const ValueKey('mind-summary'),
                    style: AppText.display(
                      size: 17,
                      weight: FontWeight.w600,
                      height: 1.25,
                      spacing: -0.3,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.screensMindFoot,
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
        ],
      ),
    );
  }
}

/// One claim, its two scales, the evidence between them, and what the two
/// answers come to.
class _Claim extends StatelessWidget {
  const _Claim({
    super.key,
    required this.pill,
    required this.stance,
    required this.size,
    required this.onOpen,
    required this.onBefore,
    required this.onAfter,
  });

  final Pill pill;
  final Stance stance;
  final ScreenSize size;
  final VoidCallback onOpen;
  final ValueChanged<int> onBefore;
  final void Function(int before, int place) onAfter;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = pill.ink;
    final Color sub = subOn(pill);
    final int? before = stance.before;
    final int? after = stance.after;
    final double type = bySize(size, s: 19, m: 23, l: 26);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardFace(context, pill.color, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTap(
            pill: pill,
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FaceHead(pill: pill, after: l.screensMindClaim),
                const SizedBox(height: 14),
                Text(
                  claimOf(pill),
                  style: AppText.display(
                    size: type,
                    weight: FontWeight.w600,
                    height: 1.12,
                    spacing: -0.03 * type,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Scale(
            keyName: 'mind-before-${pill.id}',
            pill: pill,
            title: l.screensMindBefore,
            said: before == null
                ? l.screensMindTap
                : l.screensMindLevel('$before'),
            chosen: before,
            onPick: before == null ? onBefore : null,
          ),
          if (before != null) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: hairOn(pill)),
            const SizedBox(height: 14),
            Text(
              upper(context, l.screensMindKnow),
              style: AppText.label(
                size: 9,
                weight: FontWeight.w700,
                spacing: 1.2,
                color: sub,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              evidenceOf(pill),
              style: AppText.body(
                size: 13.5,
                weight: FontWeight.w500,
                height: 1.45,
                color: ink,
              ),
            ),
            const SizedBox(height: 14),
            _Scale(
              keyName: 'mind-after-${pill.id}',
              pill: pill,
              title: l.screensMindNow,
              said: after == null
                  ? l.screensMindAgain
                  : l.screensMindLevel('$after'),
              chosen: after,
              was: before,
              onPick: after == null ? (place) => onAfter(before, place) : null,
            ),
            if (after != null) ...[
              const SizedBox(height: 14),
              Text(
                _result(l, before, after),
                key: ValueKey('mind-result-${pill.id}'),
                style: AppText.body(
                  size: 13.5,
                  weight: FontWeight.w700,
                  height: 1.35,
                  color: ink,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _result(AppLocalizations l, int before, int after) {
    final int target = evidencePlace(pill);
    final int was = (before - target).abs();
    final int now = (after - target).abs();
    if (now < was) return l.screensMindToward(was - now);
    if (now > was) return l.screensMindAway;
    return was == 0 ? l.screensMindAlready : l.screensMindSame;
  }
}

/// Five places from disagree to agree, on a line: the one chosen filled,
/// the one chosen before (on the second scale) drawn dashed.
class _Scale extends StatelessWidget {
  const _Scale({
    required this.keyName,
    required this.pill,
    required this.title,
    required this.said,
    required this.chosen,
    required this.onPick,
    this.was,
  });

  final String keyName;
  final Pill pill;
  final String title;

  /// Beside the title: what was chosen, or what to do.
  final String said;
  final int? chosen;
  final int? was;

  /// Null once chosen: a stance is taken once.
  final ValueChanged<int>? onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color ink = pill.ink;
    final Color sub = subOn(pill);
    final bool dark = ink.computeLuminance() < 0.5;
    final Color ring = dark
        ? ink.withValues(alpha: 0.5)
        : ink.withValues(alpha: 0.7);
    final TextStyle ends = AppText.body(
      size: 10,
      weight: FontWeight.w600,
      height: 1.2,
      color: sub,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          // What was chosen sits flush right and takes the room it needs,
          // up to most of the row; the title has the rest, and wraps
          // before either is cut.
          builder: (context, box) => Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  upper(context, title),
                  style: AppText.label(
                    size: 9,
                    weight: FontWeight.w700,
                    spacing: 1.2,
                    height: 1.2,
                    color: sub,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: box.maxWidth * 0.6),
                child: Text(
                  said,
                  textAlign: TextAlign.end,
                  style: AppText.body(
                    size: 11,
                    weight: FontWeight.w700,
                    height: 1.2,
                    color: ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: LayoutBuilder(
            builder: (context, box) {
              final double step = (box.maxWidth - 26) / (Stance.places - 1);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 13,
                    right: 13,
                    top: 21,
                    child: Container(height: 2, color: hairOn(pill)),
                  ),
                  for (int i = 0; i < Stance.places; i++)
                    Positioned(
                      left: i * step + 13 - 22,
                      top: 0,
                      child: Semantics(
                        key: ValueKey('$keyName-$i'),
                        button: onPick != null,
                        selected: chosen == i,
                        label: l.screensMindLevel('$i'),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onPick == null ? null : () => onPick!(i),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: _Dot(
                                fill: chosen == i ? ink : pill.color,
                                edge: chosen == i ? ink : ring,
                                dashed: chosen != i && was == i,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        ExcludeSemantics(
          child: Row(
            children: [
              Expanded(child: Text(l.screensMindLevel('1'), style: ends)),
              Expanded(
                child: Text(
                  l.screensMindLevel('3'),
                  textAlign: TextAlign.end,
                  style: ends,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A place on the scale: a ring 26 across, filled when chosen, dashed where
/// the reader stood before.
class _Dot extends StatelessWidget {
  const _Dot({required this.fill, required this.edge, required this.dashed});

  final Color fill;
  final Color edge;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    if (dashed) {
      return CustomPaint(
        size: const Size(26, 26),
        painter: _DashedRing(colour: fill, edge: edge),
      );
    }
    return AnimatedContainer(
      duration: paced(context, 180),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: edge, width: 2),
      ),
    );
  }
}

class _DashedRing extends CustomPainter {
  const _DashedRing({required this.colour, required this.edge});

  final Color colour;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.width / 2 - 1;
    canvas.drawCircle(c, r, Paint()..color = colour);
    final Paint dash = Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const int dashes = 10;
    const double sweep = 2 * 3.141592653589793 / dashes;
    for (int i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        i * sweep,
        sweep * 0.55,
        false,
        dash,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRing old) =>
      old.colour != colour || old.edge != edge;
}
