import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/pill_card_stack.dart';
import 'recap_view.dart';

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class TodayScreen extends StatelessWidget {
  final AppState app;
  const TodayScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final deck = app.todaysDeck;
    final index = app.todayIndex;
    final weekday = _weekdayNames[app.today.weekday - 1];

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$weekday · ${deck.length} pills',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.mono(
                          size: 11,
                          spacing: 1.3,
                          color: Colors.black.withValues(alpha: 0.42),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Today',
                        style: AppText.outfit(
                          size: 33,
                          weight: FontWeight.w700,
                          height: 1.05,
                          spacing: -1.3,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.12),
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${app.liveStreak}',
                        style: AppText.figtree(
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'day streak',
                        style: AppText.figtree(
                          size: 11,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(deck.length, (i) {
                final done = i <= index - 1 || (app.todayCompleted);
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: i == deck.length - 1 ? 0 : 5,
                    ),
                    height: 3,
                    decoration: BoxDecoration(
                      color: done
                          ? AppColors.ink
                          : Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: app.todayCompleted
                  ? RecapView(app: app)
                  : PillCardStack(
                      deck: deck,
                      index: index,
                      onAdvance: () => app.advance(),
                      isSaved: app.isSaved,
                      onToggleSaved: (id) => app.toggleSaved(id),
                    ),
            ),
            if (!app.todayCompleted) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(deck.length, (i) {
                  final active = i == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3.5),
                    height: 6,
                    width: active ? 22 : 6,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.ink
                          : Colors.black.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(9),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => app.advance(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next pill',
                        style: AppText.figtree(
                          size: 15,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 17,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}
