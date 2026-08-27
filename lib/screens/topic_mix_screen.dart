import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/topics.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// Every subject except Thinking, which is not on offer: the puzzles are the
/// training and they come whatever the reader picks, so putting them here
/// would be asking a question with only one answer.
final List<String> kMixableTopics = [
  for (final key in kTopicOrder)
    if (key != 'thinking') key,
];

/// Pick the mix by sliding along each subject.
///
/// A row of checkboxes can only say in or out. These say how much: the chip
/// is the control, and running a finger along it fills it. The number on it
/// is the share of the deck that subject would take, so pulling one up nudges
/// the others down — which is the thing a list of switches can never show,
/// that this is one deck being divided rather than twelve separate yes/nos.
class TopicMixScreen extends StatefulWidget {
  /// Weights by topic key, each 0..1. Subjects at zero are left out.
  final void Function(Map<String, double> weights) onDone;

  const TopicMixScreen({super.key, required this.onDone});

  @override
  State<TopicMixScreen> createState() => _TopicMixScreenState();
}

class _TopicMixScreenState extends State<TopicMixScreen> {
  /// Everything starts half-way, so the screen opens as a working mix rather
  /// than as twelve empty bars somebody has to fill in from nothing.
  late final Map<String, double> _weights = {
    for (final key in kMixableTopics) key: 0.5,
  };

  /// Below this a subject is out of the deck entirely.
  static const double _minKept = 0.04;

  int get _kept => _weights.values.where((v) => v >= _minKept).length;

  void _set(String key, double value) {
    final clamped = value.clamp(0.0, 1.0);
    if ((_weights[key]! - clamped).abs() < 0.005) return;
    // A tick as a subject crosses in or out of the deck, so the boundary can
    // be felt rather than only read.
    final wasIn = _weights[key]! >= _minKept;
    final isIn = clamped >= _minKept;
    if (wasIn != isIn) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    setState(() => _weights[key] = clamped);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.p.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What should we talk about?',
                    style: AppText.display(
                      size: 29,
                      weight: FontWeight.w700,
                      height: 1.08,
                      spacing: -1.2,
                      color: context.p.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Slide along a subject to take more or less of it. The '
                    'puzzles come whatever you pick — this is the reading.',
                    style: AppText.body(
                      size: 14,
                      height: 1.45,
                      color: context.p.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, outer) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                  // Centred rather than pinned to the top: twelve chips leave
                  // a lot of screen under them on a tall phone, and a block
                  // floating above a void reads as unfinished.
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: outer.maxHeight),
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const gap = 10.0;
                          final width = (constraints.maxWidth - gap) / 2;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final key in kMixableTopics)
                                SizedBox(
                                  width: width,
                                  child: _TopicSlider(
                                    topicKey: key,
                                    value: _weights[key]!,
                                    onChanged: (v) => _set(key, v),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
              child: Column(
                children: [
                  Text(
                    _kept == 0
                        ? 'Slide at least one subject up.'
                        : '$_kept of ${kMixableTopics.length} subjects in '
                              'the mix',
                    style: AppText.body(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: _kept == 0 ? context.p.alert : context.p.inkFaint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'START WITH MY FIRST CARDS',
                    background: AppColors.lime,
                    foreground: AppColors.limeInk,
                    onPressed: _kept == 0
                        ? null
                        : () => widget.onDone({
                            for (final e in _weights.entries)
                              if (e.value >= _minKept) e.key: e.value,
                          }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One subject: the topic chip from the topics screen, filled part-way.
///
/// It has to be that chip and not a near-miss of it — same pill, same check,
/// same weight of type — or the app has two kinds of topic chip and the
/// newer one looks like a copy somebody made in a hurry. The only thing
/// added is that the colour stops part of the way across, and the label is
/// drawn twice so the half over the fill takes the ink that belongs on it.
class _TopicSlider extends StatelessWidget {
  final String topicKey;
  final double value;
  final ValueChanged<double> onChanged;

  const _TopicSlider({
    required this.topicKey,
    required this.value,
    required this.onChanged,
  });

  static const double _off = 0.04;

  @override
  Widget build(BuildContext context) {
    final style = kTopics[topicKey]!;
    final on = value >= _off;

    Widget label(Color ink, double opacity) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Row(
        children: [
          Opacity(
            opacity: opacity,
            child: Icon(Icons.check_rounded, size: 13, color: ink),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              style.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                size: 14,
                weight: FontWeight.w500,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      slider: true,
      label: style.name,
      // The share is worth saying to a screen reader even though the chip
      // shows it as a length rather than a number.
      value: on ? 'in the mix' : 'out of the mix',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _fromLocal(context, d.localPosition),
        onHorizontalDragStart: (d) => _fromLocal(context, d.localPosition),
        onHorizontalDragUpdate: (d) => _fromLocal(context, d.localPosition),
        child: Container(
          decoration: BoxDecoration(
            color: context.p.surfaceRaised,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: context.p.line),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                label(context.p.inkMuted, on ? 1 : 0),
                ClipRect(
                  // Off means no colour at all: a sliver left at the edge
                  // reads as a rendering fault rather than as a setting.
                  clipper: _LeftFraction(on ? value.clamp(0.0, 1.0) : 0),
                  child: ColoredBox(
                    color: style.color,
                    child: label(style.ink, on ? 1 : 0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _fromLocal(BuildContext context, Offset local) {
    final box = context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 0;
    if (width <= 0) return;
    onChanged(local.dx / width);
  }
}

/// Clips a full-width layer to the left [fraction] of itself, so the text
/// underneath keeps its own layout rather than being squashed.
class _LeftFraction extends CustomClipper<Rect> {
  final double fraction;
  const _LeftFraction(this.fraction);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_LeftFraction old) => old.fraction != fraction;
}
