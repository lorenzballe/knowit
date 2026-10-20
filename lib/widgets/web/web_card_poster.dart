import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/topics.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import '../balanced_text.dart';
import '../subject_icon.dart';
import 'web_card_page.dart';

/// A free card before its page has drawn, and in the page's place where it
/// cannot be drawn: the card's head as the kit sets it in the app — the
/// ground, the subject's mark and name, the question at the size the page
/// sets it — so when the page comes up it only adds what is under them.
///
/// The measures are the kit's own (`.kit-app` in astute-card.css): the
/// padding a native card has, the head at eleven points, the question at
/// 3.4% of the card's height and never under eighteen, a gap of 2.1%
/// between them. Kept in step by eye on the cameras (tool/web_card_shots.dart).
///
/// Where the page will not come — a later kit, a platform with no WebView,
/// a page that failed — [fallback] says "tap to reveal" at its foot, and
/// the card is read like any card that only tells: turned over, its answer
/// on the back.
class WebCardPoster extends StatelessWidget {
  const WebCardPoster({
    super.key,
    required this.pill,
    this.fallback = false,
    this.chip,
    this.note,
  });

  final Pill pill;
  final bool fallback;

  /// The chip beside the subject (`AGAIN`, `FOR YOU`) and the line under
  /// the head, as the page draws them.
  final String? chip;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final Color ground = groundOf(pill);
    final Color ink = pill.web?.ground == null ? pill.ink : inkOn(ground);
    return ColoredBox(
      color: ground,
      child: LayoutBuilder(
        builder: (context, box) {
          final double h = box.maxHeight.isFinite ? box.maxHeight : 600;
          final double size = math.max(h * 0.034, 18);
          return Padding(
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SubjectIcon(subject: pill.topic, size: 16, ink: ink),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        context.l10n.subjectOf(pill.topic).toUpperCase(),
                        maxLines: 1,
                        style: AppText.label(
                          size: 11,
                          spacing: 1.4,
                          height: 1,
                          color: ink.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                    if (chip case final String chip) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: ink.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          chip,
                          style: AppText.label(
                            size: 9.5,
                            spacing: 1,
                            height: 1,
                            color: ink.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (note case final String note) ...[
                  SizedBox(height: h * 0.011),
                  Text(
                    note,
                    style: AppText.body(
                      size: 12.5,
                      weight: FontWeight.w500,
                      height: 1.25,
                      color: ink.withValues(alpha: 0.66),
                    ),
                  ),
                ],
                SizedBox(height: h * 0.021),
                BalancedText(
                  pill.question,
                  style: AppText.display(
                    size: size,
                    weight: FontWeight.w800,
                    height: 1.13,
                    spacing: -0.012 * size,
                    color: ink,
                  ),
                ),
                const Spacer(),
                if (fallback)
                  Text(
                    context.l10n.tapToReveal,
                    style: AppText.body(
                      size: 13,
                      weight: FontWeight.w500,
                      color: ink.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
