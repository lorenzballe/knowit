import 'package:flutter/material.dart';

import '../models/pill.dart';
import '../theme.dart';

/// Full-bleed, one-colour-per-topic card — the "card is the screen" look,
/// carrying a Bar move line and a source once flipped.
class PillCard extends StatelessWidget {
  final Pill pill;
  final String indexLabel;
  final bool flipped;

  const PillCard({
    super.key,
    required this.pill,
    required this.indexLabel,
    required this.flipped,
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
            child: flipped ? _BackFace(pill: pill) : _FrontFace(pill: pill),
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
  const _BackFace({required this.pill});

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
                  size: 20,
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
              const SizedBox(height: 20),
              // The bar move is the reason to open the app at all, so it gets
              // its own panel rather than a line under a rule.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
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
