import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'paywall_screen.dart';

const _weekLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// The end-of-day state: the streak recap, then either the Knowit+ upsell on
/// the free plan or the second set of the day for subscribers.
class RecapView extends StatelessWidget {
  final AppState app;
  const RecapView({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final week = app.weekCompletion();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${app.todaysDeck.length} of ${app.todaysDeck.length} · done',
              style: AppText.label(
                size: 11,
                spacing: 1.4,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: AppText.display(
                  size: 34,
                  weight: FontWeight.w700,
                  height: 1.06,
                  spacing: -1.3,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(
                    text: '${app.streak} day${app.streak == 1 ? '' : 's'}\n',
                  ),
                  TextSpan(
                    text: 'in a row.',
                    style: const TextStyle(color: AppColors.lime),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: List.generate(7, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 34,
                          decoration: BoxDecoration(
                            color: week[i]
                                ? AppColors.lime
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _weekLetters[i],
                          style: AppText.label(
                            size: 10,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 22),
            Text(
              'YOU PICKED UP TODAY',
              style: AppText.label(
                size: 11,
                spacing: 1.3,
                color: Colors.white.withValues(alpha: 0.42),
              ),
            ),
            const SizedBox(height: 10),
            ...app.todaysDeck.map(
              (p) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.055),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: p.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        p.question,
                        style: AppText.body(
                          size: 13.5,
                          weight: FontWeight.w500,
                          height: 1.3,
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (app.canOpenExtraSet)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your second set is ready',
                      style: AppText.display(
                        size: 20,
                        weight: FontWeight.w600,
                        spacing: -0.6,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Five more pills, picked the same way. Knowit+ unlocks '
                      'them the moment you finish the first five.',
                      style: AppText.body(
                        size: 13.5,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => app.openExtraSet(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.ink,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          'Read 5 more',
                          style: AppText.body(
                            size: 14.5,
                            weight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (app.isPlus)
              Text(
                "That's all ten for today. New pills tomorrow morning.",
                style: AppText.body(
                  size: 13.5,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.lime, AppColors.limeDark],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Want 5 more?',
                      style: AppText.display(
                        size: 20,
                        weight: FontWeight.w600,
                        spacing: -0.6,
                        color: const Color(0xFF17200A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Knowit+ unlocks an extra set every day, plus the full archive of everything you've read.",
                      style: AppText.body(
                        size: 13.5,
                        height: 1.45,
                        color: const Color(0xFF17200A).withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PaywallScreen(app: app),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF17200A),
                          foregroundColor: const Color(0xFFE9FFC4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          'Unlock 5 extra pills',
                          style: AppText.body(
                            size: 14.5,
                            weight: FontWeight.w600,
                            color: const Color(0xFFE9FFC4),
                          ),
                        ),
                      ),
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
