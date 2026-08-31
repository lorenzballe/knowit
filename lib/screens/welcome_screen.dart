import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/brand_mark.dart';
import '../widgets/ui.dart';

/// First run — the fanned card hero and the two ways in.
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onSignIn;

  const WelcomeScreen({
    super.key,
    required this.onStart,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.p.surface,
      body: SafeArea(
        child: FlexPage(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const BrandMark(size: 26),
                  const SizedBox(width: 9),
                  Text(
                    'Astuto',
                    style: AppText.display(
                      size: 20,
                      weight: FontWeight.w700,
                      spacing: -0.6,
                      color: context.p.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const _FannedCards(),
              const SizedBox(height: 26),
              Text(
                'Most people are more sure than they are right.',
                style: AppText.display(
                  size: 34,
                  weight: FontWeight.w700,
                  height: 1.06,
                  spacing: -1.4,
                  color: context.p.ink,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                'Five cards a day. You commit to an answer and say how '
                'sure you are before you turn it over — so after a few weeks '
                'you have the one thing almost nobody has: a measurement of '
                'your own judgement.',
                style: AppText.body(
                  size: 15,
                  height: 1.5,
                  color: context.p.inkMuted,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'SHOW ME THE FIRST 5 CARDS',
                onPressed: onStart,
              ),
              const SizedBox(height: 4),
              QuietButton(
                label: 'I already have an account',
                onPressed: onSignIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three cards fanned out behind each other, the blue one on top.
class _FannedCards extends StatelessWidget {
  const _FannedCards();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 254,
      child: Stack(
        children: [
          Positioned(
            left: 22,
            right: 22,
            top: 26,
            child: Transform.rotate(
              angle: -7 * math.pi / 180,
              child: Container(
                height: 224,
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            top: 14,
            child: Transform.rotate(
              angle: 4 * math.pi / 180,
              child: Container(
                height: 234,
                decoration: BoxDecoration(
                  color: context.p.alert,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 246,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.p.link,
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 44,
                    offset: Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SPACE',
                    style: AppText.label(
                      size: 10.5,
                      spacing: 1.4,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                  Text(
                    'Why do we only ever see one face of the Moon?',
                    style: AppText.display(
                      size: 26,
                      weight: FontWeight.w600,
                      height: 1.14,
                      spacing: -0.9,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'tap to reveal',
                    style: AppText.body(
                      size: 12.5,
                      weight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
