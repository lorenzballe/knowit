import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/pill_card_stack.dart';
import '../widgets/share_sheet.dart';
import 'recap_view.dart';

/// The card is the screen: dark chrome, and the deck filling everything
/// between the progress bars and the action row.
class TodayScreen extends StatefulWidget {
  final AppState app;
  const TodayScreen({super.key, required this.app});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool _celebrated = false;

  /// Finishing the day is the one moment worth marking. Fired after the frame
  /// so the feedback is a side effect of the state, not of painting.
  void _markCompletion(bool completed) {
    if (completed == _celebrated) return;
    _celebrated = completed;
    if (!completed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.heavyImpact();
    });
  }

  Pill? get _currentPill {
    final app = widget.app;
    if (app.todayIndex >= app.todaysDeck.length) return null;
    return app.todaysDeck[app.todayIndex];
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    _markCompletion(app.todayCompleted);

    final deck = app.todaysDeck;
    final index = app.todayIndex;
    final pill = _currentPill;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(streak: app.liveStreak),
          const SizedBox(height: 16),
          _ProgressBars(
            total: deck.length,
            index: index,
            done: app.todayCompleted,
          ),
          const SizedBox(height: 16),

          // The deck takes every pixel that is left.
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              child: app.todayCompleted
                  ? RecapView(key: const ValueKey('recap'), app: app)
                  : PillCardStack(
                      key: const ValueKey('deck'),
                      deck: deck,
                      index: index,
                      onAdvance: () => app.advance(),
                    ),
            ),
          ),

          if (pill != null) ...[
            const SizedBox(height: 14),
            _ActionRow(
              saved: app.isSaved(pill.id),
              onSave: () => app.toggleSaved(pill.id),
              onShare: () => showShareSheet(context, pill),
              onNext: () => app.advance(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int streak;
  const _Header({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Knowit',
            style: AppText.display(
              size: 20,
              weight: FontWeight.w600,
              spacing: -0.4,
              color: Colors.white,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.lime,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  streak == 1 ? '1 day' : '$streak days',
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.82),
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

class _ProgressBars extends StatelessWidget {
  final int total;
  final int index;
  final bool done;
  const _ProgressBars({
    required this.total,
    required this.index,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: List.generate(total, (i) {
          final filled = done || i <= index;
          return Expanded(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 260 + i * 40),
              curve: Curves.easeOut,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 5),
              height: 3,
              decoration: BoxDecoration(
                color: filled
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Heart, next, share — the three things you do to a card, always in reach.
class _ActionRow extends StatelessWidget {
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onNext;

  const _ActionRow({
    required this.saved,
    required this.onSave,
    required this.onShare,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
      child: Row(
        children: [
          _RoundButton(
            label: saved ? 'Remove from saved' : 'Save this pill',
            icon: saved
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: saved ? const Color(0xFFFF8B73) : Colors.white,
            onTap: () {
              HapticFeedback.mediumImpact();
              onSave();
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onNext();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.dark,
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
                        style: AppText.body(
                          size: 15,
                          weight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 17,
                        color: AppColors.dark.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _RoundButton(
            label: 'Share this pill',
            icon: Icons.ios_share_rounded,
            color: Colors.white.withValues(alpha: 0.8),
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String label;

  const _RoundButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.09),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 19, color: color),
        ),
      ),
    );
  }
}
