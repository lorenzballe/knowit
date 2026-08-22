import 'package:flutter/material.dart';

import '../models/pill.dart';
import '../theme.dart';
import '../widgets/ui.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Onboarding step three: what the 08:30 nudge actually looks like, rendered
/// as a lock screen so the ask is concrete.
///
/// Scheduling a real local notification needs a plugin this app does not carry
/// yet, so the choice is stored as a preference and nothing is scheduled.
class NotificationScreen extends StatelessWidget {
  final Pill previewPill;
  final String time;
  final VoidCallback onEnable;
  final VoidCallback onSkip;

  const NotificationScreen({
    super.key,
    required this.previewPill,
    required this.time,
    required this.onEnable,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLine =
        '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -0.84),
            radius: 1.2,
            colors: [Color(0xFF2B4BFF), Color(0xFF14142A), Color(0xFF0B0B10)],
            stops: [0.0, 0.46, 1.0],
          ),
        ),
        child: SafeArea(
          child: FlexPage(
            padding: const EdgeInsets.fromLTRB(18, 26, 18, 22),
            child: Column(
              children: [
                Text(
                  dateLine,
                  style: AppText.figtree(
                    size: 15,
                    weight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: AppText.outfit(
                    size: 74,
                    weight: FontWeight.w300,
                    height: 1,
                    spacing: -3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 34),
                _NotificationBubble(question: previewPill.question),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Text(
                        '2 more notifications',
                        style: AppText.figtree(
                          size: 12.5,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'One nudge a day, at $time.',
                  textAlign: TextAlign.center,
                  style: AppText.outfit(
                    size: 21,
                    weight: FontWeight.w600,
                    spacing: -0.6,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nothing else. No badges, no streak guilt at midnight.',
                  textAlign: TextAlign.center,
                  style: AppText.figtree(
                    size: 13.5,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Turn the nudge on',
                  background: Colors.white,
                  foreground: AppColors.ink,
                  onPressed: onEnable,
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSkip,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    child: Text(
                      'Not now',
                      style: AppText.figtree(
                        size: 13,
                        weight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBubble extends StatelessWidget {
  final String question;
  const _NotificationBubble({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              'K',
              style: AppText.outfit(
                size: 13,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Knowit',
                      style: AppText.figtree(
                        size: 13.5,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'now',
                      style: AppText.figtree(
                        size: 11.5,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Your 5 pills are ready',
                  style: AppText.figtree(
                    size: 14,
                    weight: FontWeight.w500,
                    height: 1.35,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  question,
                  style: AppText.figtree(
                    size: 13.5,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
