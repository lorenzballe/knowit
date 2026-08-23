import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/ui.dart';

const _steps = [
  (
    n: '01',
    title: 'A topic comes up',
    sub:
        'Rotated from the twelve you picked, weighted so you never get the '
        'same one twice in a day.',
  ),
  (
    n: '02',
    title: 'The model drafts a pill',
    sub:
        'One question, one answer under 60 words, one reason it is worth '
        'saying out loud.',
  ),
  (
    n: '03',
    title: 'It gets checked against a source',
    sub: 'Every claim is matched to a public reference. No match, no pill.',
  ),
  (
    n: '04',
    title: 'You get five at 08:30',
    sub: 'Written the same morning. Nothing recycled from yesterday.',
  ),
];

/// The disclosure screen — says up front that the pills are model-written and
/// lays out the pipeline.
class HowScreen extends StatelessWidget {
  const HowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: BackCircle(onPressed: () => Navigator.of(context).pop()),
            ),
            const SizedBox(height: 22),
            Text(
              'Every pill here is written by a model.',
              style: AppText.display(
                size: 31,
                weight: FontWeight.w700,
                height: 1.07,
                spacing: -1.2,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "We'd rather say it up front than have you find out. "
              'Here is the whole pipeline.',
              style: AppText.body(
                size: 14.5,
                height: 1.5,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 22),
            ..._steps.map(
              (s) => Container(
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.black.withValues(alpha: 0.09),
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.n,
                      style: AppText.label(
                        size: 11,
                        height: 1.5,
                        color: AppColors.blue,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            style: AppText.body(
                              size: 15,
                              weight: FontWeight.w600,
                              height: 1.3,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            s.sub,
                            style: AppText.body(
                              size: 13,
                              height: 1.5,
                              color: Colors.black.withValues(alpha: 0.52),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(19),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Found something wrong?',
                    style: AppText.body(
                      size: 15,
                      weight: FontWeight.w600,
                      height: 1.3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Report any pill and it gets pulled from rotation until '
                    'a human checks it.',
                    style: AppText.body(
                      size: 13,
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Model and source list updated monthly.',
              textAlign: TextAlign.center,
              style: AppText.body(
                size: 11.5,
                height: 1.5,
                color: Colors.black.withValues(alpha: 0.38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
