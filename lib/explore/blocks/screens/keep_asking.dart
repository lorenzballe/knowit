/// Keep asking why — artboard 141a.
///
/// One answer at a time, until it clicks: the first question and its
/// answer, and under it a button that asks why of that answer. Each why
/// opens the next step a shade deeper in the subject's colour, joined to
/// the one before by a dotted line, until the bottom of the chain, where it
/// says so and offers to start again. The other chains of the section wait
/// underneath as more rabbit holes.
///
/// A chain is the section's own words, not a card's: every step of it is
/// written per language, English first, and every chain names where its
/// answers come from, which the checker refuses a chain without and the
/// bottom of the chain shows. A chain can end on bank cards that go further
/// than it does.
library;

import 'package:flutter/material.dart';

import '../../../data/topics.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/card_edge.dart';
import '../../explore_block.dart';
import 'memory.dart';
import 'parts.dart';

/// The most steps a chain shows; the checker holds a chain to it.
const int kMostWhys = 8;

/// One chain of whys, in the reader's language.
@immutable
class WhyChain {
  const WhyChain({
    required this.id,
    required this.subject,
    required this.steps,
    required this.source,
    this.cards = const [],
  });

  final String id;

  /// The subject whose colour and mark the steps carry, by key.
  final String subject;

  /// Each question with its answer, the first question first.
  final List<(String, String)> steps;

  /// Where the answers come from.
  final String source;

  /// Cards that go further, by id.
  final List<String> cards;
}

/// The chains [section] gives, each in [language] (English where a step
/// has none of its own). A chain without a subject the build knows, a
/// source, or two steps it can read is passed over.
List<WhyChain> chainsOf(ExploreSection section, String language) {
  final List<WhyChain> out = [];
  for (final Map<Object?, Object?> c in sectionItems(section, 'chains')) {
    final Object? id = c['id'];
    final Object? subject = c['subject'];
    final Object? source = c['source'];
    if (id is! String || id.isEmpty || out.any((x) => x.id == id)) continue;
    if (subject is! String || !kTopics.containsKey(subject)) continue;
    if (source is! String || source.trim().isEmpty) continue;
    final List<(String, String)> steps = [];
    final Object? raw = c['steps'];
    for (final Object? step in raw is List ? raw : const []) {
      if (step is! Map) continue;
      final String? q = itemText(step, 'q', language);
      final String? a = itemText(step, 'a', language);
      if (q == null || a == null) continue;
      steps.add((q, a));
    }
    if (steps.length < 2) continue;
    final Object? cards = c['cards'];
    out.add(
      WhyChain(
        id: id,
        subject: subject,
        steps: steps.take(kMostWhys).toList(),
        source: source.trim(),
        cards: [
          if (cards is List)
            for (final Object? card in cards)
              if (card is String) card,
        ],
      ),
    );
  }
  return out;
}

/// The block.
class KeepAskingBlock extends ExploreBlock {
  const KeepAskingBlock();

  @override
  String get name => 'keep-asking';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<WhyChain> chains = chainsOf(section, host.language);
    if (chains.isEmpty) return null;
    return host.watch(
      section,
      _Whys(
        key: ValueKey('whys-${section.id}'),
        host: host,
        section: section,
        chains: chains,
      ),
    );
  }
}

class _Whys extends StatefulWidget {
  const _Whys({
    super.key,
    required this.host,
    required this.section,
    required this.chains,
  });

  final ExploreHost host;
  final ExploreSection section;
  final List<WhyChain> chains;

  @override
  State<_Whys> createState() => _WhysState();
}

class _WhysState extends State<_Whys> {
  /// Where the chain starts, to bring it back into sight when another
  /// rabbit hole is picked from under it.
  final GlobalKey _top = GlobalKey();

  ScreensMemory get _memory => ScreensMemory.instance;

  WhyChain _chain() {
    final String? kept = _memory.pick(widget.section.id);
    final Object? asked = widget.section.json['chain'];
    return widget.chains.where((c) => c.id == kept).firstOrNull ??
        widget.chains.where((c) => c.id == asked).firstOrNull ??
        widget.chains.first;
  }

  void _deeper(WhyChain chain, int depth) {
    tickLight();
    final int next = depth + 1;
    _memory.setDepth(widget.section.id, chain.id, next);
    widget.host.note(widget.section, 'why', {
      'chain': chain.id,
      'depth': next + 1,
      'of': chain.steps.length,
    });
  }

  void _again(WhyChain chain) {
    tickPicked();
    _memory.setDepth(widget.section.id, chain.id, 0);
    widget.host.note(widget.section, 'why again', {'chain': chain.id});
  }

  void _start(WhyChain chain) {
    tickPicked();
    _memory.setPick(widget.section.id, chain.id);
    widget.host.note(widget.section, 'chain picked', {'chain': chain.id});
    final BuildContext? top = _top.currentContext;
    if (top != null) {
      Scrollable.ensureVisible(
        top,
        duration: paced(context, 320),
        curve: Curves.easeOutCubic,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _memory.open();
    return ListenableBuilder(
      listenable: _memory,
      builder: (context, _) => _view(context),
    );
  }

  Widget _view(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final ExploreSection section = widget.section;
    final ScreenSize size = screenSizeOf(section);
    final WhyChain chain = _chain();
    final int depth = _memory
        .depth(section.id, chain.id)
        .clamp(0, chain.steps.length - 1);
    final bool bottom = depth >= chain.steps.length - 1;
    final TopicStyle colour = kTopics[chain.subject]!;
    final List<WhyChain> holes = [
      for (final WhyChain c in widget.chains)
        if (c.id != chain.id) c,
    ];
    final List<Pill> deeper = bottom && chain.cards.isNotEmpty
        ? widget.host.cardsFor(
            ExploreSection(
              id: '${section.id}/${chain.id}',
              block: section.block,
              json: {
                'id': '${section.id}/${chain.id}',
                'block': section.block,
                'source': {'ids': chain.cards},
              },
            ),
            limit: 6,
          )
        : const [];
    for (final Pill pill in deeper) {
      widget.host.seen(section, pill);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenShelf(
          key: _top,
          head: styleOn(section, 'head'),
          title: section.title(widget.host.language) ?? l.screensWhyTitle,
          line: section.subtitle(widget.host.language) ?? l.screensWhyLine,
          gap: 14,
          trailing: styleOn(section, 'meter')
              ? _Meter(steps: chain.steps.length, open: depth + 1)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i <= depth; i++) ...[
                  if (i > 0) _Join(label: l.screensWhyAsk),
                  _Step(
                    key: ValueKey('why-${chain.id}-$i'),
                    subject: chain.subject,
                    question: chain.steps[i].$1,
                    answer: chain.steps[i].$2,
                    face: shade(colour.color, 1 - i * 0.07),
                    ink: colour.ink,
                    size: size,
                    arriving: i == depth && i > 0,
                  ),
                ],
                const SizedBox(height: 14),
                if (!bottom)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PillButton(
                      key: ValueKey('why-ask-${chain.id}'),
                      label: l.screensWhyAsk,
                      icon: Icons.arrow_downward_rounded,
                      height: 46,
                      size: 15,
                      padding: const EdgeInsets.fromLTRB(18, 0, 22, 0),
                      background: p.inverse,
                      foreground: p.onInverse,
                      onTap: () => _deeper(chain, depth),
                    ),
                  )
                else
                  _Bottom(
                    steps: chain.steps.length,
                    source: chain.source,
                    onAgain: () => _again(chain),
                    againKey: ValueKey('why-again-${chain.id}'),
                  ),
              ],
            ),
          ),
        ),
        if (deeper.isNotEmpty) ...[
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Kicker(l.screensWhyDeeper),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              itemCount: deeper.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => ColourTile(
                pill: deeper[i],
                width: 158,
                height: 156,
                head: false,
                radius: 19,
                padding: 14,
                min: 10.5,
                max: 15,
                read: widget.host.isRead(deeper[i]),
                onTap: () => widget.host.open(section, deeper, deeper[i]),
              ),
            ),
          ),
        ],
        if (holes.isNotEmpty && styleOn(section, 'holes')) ...[
          const SizedBox(height: 24),
          ScreenShelf(
            title: l.screensWhyHoles,
            line: l.screensWhyHolesLine,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  for (int i = 0; i < holes.length; i++) ...[
                    if (i > 0) const SizedBox(height: 7),
                    _Hole(
                      key: ValueKey('why-hole-${holes[i].id}'),
                      chain: holes[i],
                      onTap: () => _start(holes[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// How deep the chain is open: a bar for every step, each taller than the
/// one before, lit up to where the reader is.
class _Meter extends StatelessWidget {
  const _Meter({required this.steps, required this.open});

  final int steps;
  final int open;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return Semantics(
      label: context.l10n.screensWhyDepth(open, steps),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < steps; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                AnimatedContainer(
                  duration: paced(context, 300),
                  width: 7,
                  height: 10 + i * (steps <= 4 ? 4.0 : 12 / (steps - 1)),
                  decoration: BoxDecoration(
                    color: i < open ? ink : ink.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(4),
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

/// The dotted line between two steps, with the why that joins them.
class _Join extends StatelessWidget {
  const _Join({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const SizedBox(width: 24),
          CustomPaint(
            size: const Size(2, 44),
            painter: _Dashes(ink.withValues(alpha: 0.3)),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ink.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              label,
              style: AppText.body(
                size: 11,
                weight: FontWeight.w700,
                height: 1,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dashes extends CustomPainter {
  const _Dashes(this.ink);

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..color = ink
      ..strokeWidth = 2;
    for (double y = 0; y < size.height; y += 7) {
      canvas.drawLine(
        Offset(1, y),
        Offset(1, (y + 4).clamp(0, size.height)),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_Dashes old) => old.ink != ink;
}

/// One step: the subject's head, the question large, its answer under it.
class _Step extends StatelessWidget {
  const _Step({
    super.key,
    required this.subject,
    required this.question,
    required this.answer,
    required this.face,
    required this.ink,
    required this.size,
    required this.arriving,
  });

  final String subject;
  final String question;
  final String answer;
  final Color face;
  final Color ink;
  final ScreenSize size;

  /// The step just opened, which rises into place.
  final bool arriving;

  @override
  Widget build(BuildContext context) {
    final double type = bySize(size, s: 20, m: 24, l: 27);
    final Widget step = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: face,
        borderRadius: BorderRadius.circular(22),
        border: cardHairline(face, context.p.surface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ScreenMark(mark: subject, size: 15, ink: ink),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  upper(context, subjectNameOf(context, subject)),
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
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question,
            style: AppText.display(
              size: type,
              weight: FontWeight.w600,
              height: 1.12,
              spacing: -0.03 * type,
              color: ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            answer,
            style: AppText.body(
              size: bySize(size, s: 13.5, m: 14, l: 15),
              weight: FontWeight.w500,
              height: 1.45,
              color: ink,
            ),
          ),
        ],
      ),
    );
    if (!arriving || MediaQuery.disableAnimationsOf(context)) return step;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
      child: step,
    );
  }
}

/// The bottom of the chain: how deep it went, where its answers come from,
/// and the way back to the top.
class _Bottom extends StatelessWidget {
  const _Bottom({
    required this.steps,
    required this.source,
    required this.onAgain,
    required this.againKey,
  });

  final int steps;
  final String source;
  final VoidCallback onAgain;
  final Key againKey;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        color: p.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.screensWhyBottom(steps),
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w500,
                    height: 1.4,
                    color: p.ink.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.screensWhySource(source),
                  style: AppText.body(
                    size: 11,
                    weight: FontWeight.w500,
                    height: 1.35,
                    color: p.ink.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PillButton(
            key: againKey,
            label: l.screensWhyAgain,
            height: 36,
            size: 12.5,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            background: p.ink.withValues(alpha: 0.1),
            foreground: p.ink,
            onTap: onAgain,
          ),
        ],
      ),
    );
  }
}

/// Another chain, waiting: the subject's square, its first question, and
/// how many whys deep it goes.
class _Hole extends StatelessWidget {
  const _Hole({super.key, required this.chain, required this.onTap});

  final WhyChain chain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final TopicStyle colour = kTopics[chain.subject]!;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          decoration: BoxDecoration(
            color: p.ink.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colour.color,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: ScreenMark(
                  mark: chain.subject,
                  size: 16,
                  ink: colour.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  chain.steps.first.$1,
                  style: AppText.body(
                    size: 13.5,
                    weight: FontWeight.w600,
                    height: 1.25,
                    color: p.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                context.l10n.screensWhyCount(chain.steps.length),
                style: AppText.body(
                  size: 11,
                  weight: FontWeight.w600,
                  height: 1,
                  color: p.ink.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
