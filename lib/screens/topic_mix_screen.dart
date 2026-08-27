import 'dart:math' as math;

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

  double get _total =>
      _weights.values.fold(0.0, (sum, v) => sum + math.max(0, v));

  int _percent(String key) {
    final total = _total;
    if (total <= 0) return 0;
    return (100 * math.max(0.0, _weights[key]!) / total).round();
  }

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
                                    percent: _percent(key),
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

/// One subject, as a pill that is also its own slider.
class _TopicSlider extends StatelessWidget {
  final String topicKey;
  final double value;
  final int percent;
  final ValueChanged<double> onChanged;

  const _TopicSlider({
    required this.topicKey,
    required this.value,
    required this.percent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final style = kTopics[topicKey]!;
    final out = value < 0.04;

    void setFrom(Offset local, double width) {
      if (width <= 0) return;
      onChanged(local.dx / width);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Semantics(
          slider: true,
          label: style.name,
          value: '$percent per cent',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => setFrom(d.localPosition, width),
            onHorizontalDragStart: (d) => setFrom(d.localPosition, width),
            onHorizontalDragUpdate: (d) => setFrom(d.localPosition, width),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: context.p.surfaceRaised,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: out ? context.p.line : style.color,
                  width: out ? 1.4 : 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  children: [
                    // The fill follows the finger; the number on top follows
                    // the deck.
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 90),
                      widthFactor: value.clamp(0.0, 1.0),
                      alignment: Alignment.centerLeft,
                      heightFactor: 1,
                      child: ColoredBox(
                        color: style.color.withValues(alpha: 0.55),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              style.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body(
                                size: 13.5,
                                weight: FontWeight.w700,
                                color: out ? context.p.inkFaint : context.p.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            out ? 'off' : '$percent%',
                            style: AppText.body(
                              size: 13,
                              weight: FontWeight.w700,
                              color: out ? context.p.inkFaint : context.p.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
