import 'package:flutter/material.dart';

import '../models/pill.dart';
import '../theme.dart';

/// Full-bleed, one-colour-per-topic card — the "card is the screen" look,
/// carrying a Bar move line and a source once flipped.
class PillCard extends StatelessWidget {
  final Pill pill;
  final String indexLabel;
  final bool flipped;

  /// Puzzle only: which option the reader committed to, and what to do when
  /// they pick one. Null while untouched.
  final int? chosenIndex;
  final ValueChanged<int>? onChoose;

  const PillCard({
    super.key,
    required this.pill,
    required this.indexLabel,
    required this.flipped,
    this.chosenIndex,
    this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: pill.color,
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 60,
            offset: Offset(0, 24),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pill.topic.toUpperCase(),
                style: AppText.label(
                  size: 11,
                  spacing: 1.4,
                  color: pill.ink.withValues(alpha: 0.72),
                ),
              ),
              Text(
                indexLabel,
                style: AppText.label(
                  size: 11,
                  color: pill.ink.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          Expanded(
            child: flipped
                ? _BackFace(pill: pill, chosenIndex: chosenIndex)
                : pill.isPuzzle
                ? _PuzzleFace(
                    pill: pill,
                    chosenIndex: chosenIndex,
                    onChoose: onChoose,
                  )
                : _FrontFace(pill: pill),
          ),
        ],
      ),
    );
  }
}

class _FrontFace extends StatelessWidget {
  final Pill pill;
  const _FrontFace({required this.pill});

  @override
  Widget build(BuildContext context) {
    // A long question on a narrow card wraps to many lines, so the type steps
    // down on short cards and the whole face scrolls rather than overflowing.
    return LayoutBuilder(
      builder: (context, constraints) {
        final tall = constraints.maxHeight;
        final size = tall < 260
            ? 24.0
            : tall < 340
            ? 28.0
            : tall < 460
            ? 34.0
            : 37.0;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: tall),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pill.question,
                  style: AppText.display(
                    size: size,
                    weight: FontWeight.w600,
                    height: 1.12,
                    spacing: -1.0,
                    color: pill.ink,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tap to reveal',
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w500,
                    color: pill.ink.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BackFace extends StatelessWidget {
  final Pill pill;
  final int? chosenIndex;
  const _BackFace({required this.pill, this.chosenIndex});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pill.isPuzzle && chosenIndex != null) ...[
                _Verdict(pill: pill, right: chosenIndex == pill.correctIndex),
                const SizedBox(height: 14),
              ],
              Text(
                pill.question,
                style: AppText.display(
                  size: pill.isPuzzle ? 18 : 20,
                  weight: FontWeight.w600,
                  height: 1.28,
                  spacing: -0.4,
                  color: pill.ink,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                pill.answer,
                style: AppText.body(
                  size: 16,
                  weight: FontWeight.w400,
                  height: 1.5,
                  color: pill.ink.withValues(alpha: 0.92),
                ),
              ),
              if (pill.isPuzzle && pill.trap.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'The trap: ${pill.trap}',
                  style: AppText.body(
                    size: 13.5,
                    weight: FontWeight.w500,
                    height: 1.45,
                    color: pill.ink.withValues(alpha: 0.75),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // The bar move is the reason to open the app at all, so it gets
              // its own panel rather than a line under a rule.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
                decoration: BoxDecoration(
                  color: pill.wash,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BAR MOVE',
                      style: AppText.label(
                        size: 10.5,
                        spacing: 1.2,
                        color: pill.ink.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      pill.barMove,
                      style: AppText.body(
                        size: 14.5,
                        weight: FontWeight.w500,
                        height: 1.4,
                        color: pill.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              Text(
                'Source · ${pill.source}',
                style: AppText.body(
                  size: 11.5,
                  weight: FontWeight.w400,
                  color: pill.ink.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Right or wrong, said plainly at the top of the reveal.
class _Verdict extends StatelessWidget {
  final Pill pill;
  final bool right;
  const _Verdict({required this.pill, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          right ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 18,
          color: pill.ink,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            right ? 'You got it' : 'Almost everyone gets this wrong',
            style: AppText.label(
              size: 11,
              spacing: 1.2,
              color: pill.ink.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }
}

/// A puzzle asks before it tells: the options are the front of the card, and
/// picking one is what turns it over.
class _PuzzleFace extends StatelessWidget {
  final Pill pill;
  final int? chosenIndex;
  final ValueChanged<int>? onChoose;

  const _PuzzleFace({
    required this.pill,
    required this.chosenIndex,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pill.question,
                style: AppText.display(
                  size: constraints.maxHeight < 420 ? 21 : 25,
                  weight: FontWeight.w600,
                  height: 1.2,
                  spacing: -0.7,
                  color: pill.ink,
                ),
              ),
              const SizedBox(height: 22),
              ...List.generate(pill.choices.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _ChoiceButton(
                    label: pill.choices[i],
                    ink: pill.ink,
                    fill: pill.wash,
                    edge: pill.washEdge,
                    onTap: onChoose == null ? null : () => onChoose!(i),
                  ),
                );
              }),
              const SizedBox(height: 4),
              Text(
                'Commit before you turn it over.',
                style: AppText.body(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: pill.ink.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final Color ink;
  final Color fill;
  final Color edge;
  final VoidCallback? onTap;

  const _ChoiceButton({
    required this.label,
    required this.ink,
    required this.fill,
    required this.edge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: edge),
          ),
          child: Text(
            label,
            style: AppText.body(
              size: 14.5,
              weight: FontWeight.w500,
              height: 1.35,
              color: ink,
            ),
          ),
        ),
      ),
    );
  }
}
