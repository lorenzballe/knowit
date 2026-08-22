import 'package:flutter/material.dart';

import '../models/pill.dart';
import '../theme.dart';

/// Full-bleed, one-colour-per-topic card — the "card is the screen" look,
/// carrying a Bar move line and a source once flipped.
class PillCard extends StatelessWidget {
  final Pill pill;
  final String indexLabel;
  final bool flipped;
  final bool saved;
  final VoidCallback? onToggleSaved;

  const PillCard({
    super.key,
    required this.pill,
    required this.indexLabel,
    required this.flipped,
    required this.saved,
    this.onToggleSaved,
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
                style: AppText.mono(
                  size: 11,
                  spacing: 1.4,
                  color: pill.ink.withValues(alpha: 0.72),
                ),
              ),
              Row(
                children: [
                  Text(
                    indexLabel,
                    style: AppText.mono(
                      size: 11,
                      color: pill.ink.withValues(alpha: 0.55),
                    ),
                  ),
                  if (onToggleSaved != null) ...[
                    const SizedBox(width: 10),
                    _SaveButton(
                      saved: saved,
                      ink: pill.ink,
                      onTap: onToggleSaved!,
                    ),
                  ],
                ],
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pill.question,
          style: AppText.outfit(
            size: 34,
            weight: FontWeight.w600,
            height: 1.12,
            spacing: -1.0,
            color: pill.ink,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Tap to reveal',
          style: AppText.figtree(
            size: 13,
            weight: FontWeight.w500,
            color: pill.ink.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _BackFace extends StatelessWidget {
  final Pill pill;
  const _BackFace({required this.pill});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Text(
            pill.question,
            style: AppText.outfit(
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
            style: AppText.figtree(
              size: 16,
              weight: FontWeight.w400,
              height: 1.5,
              color: pill.ink.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: pill.ink.withValues(alpha: 0.22)),
          const SizedBox(height: 16),
          Text(
            'BAR MOVE',
            style: AppText.mono(
              size: 10.5,
              spacing: 1.2,
              color: pill.ink.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pill.barMove,
            style: AppText.figtree(
              size: 15,
              weight: FontWeight.w500,
              height: 1.35,
              color: pill.ink,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Source · ${pill.source}',
            style: AppText.figtree(
              size: 12,
              weight: FontWeight.w400,
              color: pill.ink.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool saved;
  final Color ink;
  final VoidCallback onTap;
  const _SaveButton({
    required this.saved,
    required this.ink,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Icon(
        saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: 18,
        color: saved ? ink : ink.withValues(alpha: 0.65),
      ),
    );
  }
}
