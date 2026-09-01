import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/pill_card_stack.dart';
import '../widgets/share_sheet.dart';
import '../widgets/ui.dart';
import 'recap_view.dart';

/// The card is the screen: dark chrome, and the deck filling everything
/// between the progress bars and the action row.
class TodayScreen extends StatefulWidget {
  final AppState app;

  /// Set when this is opened as its own screen off the path, so the way back
  /// sits in the header rather than stacked above it.
  final VoidCallback? onBack;

  /// True while a card is under the finger. The tab bar steps aside for the
  /// gesture: a card being thrown towards the bottom of the screen should
  /// not be thrown at a row of buttons.
  final ValueChanged<bool>? onCardMotion;

  const TodayScreen({
    super.key,
    required this.app,
    this.onBack,
    this.onCardMotion,
  });

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

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    _markCompletion(app.todayCompleted);

    final deck = app.todaysDeck;
    final index = app.todayIndex;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            streak: app.liveStreak,
            freezes: app.freezes,
            frozen: app.streakWasFrozen,
            onBack: widget.onBack,
          ),
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
                      isSaved: app.isSaved,
                      onSave: (pill) => app.toggleSaved(pill.id),
                      onShare: (pill) => showShareSheet(context, pill),
                      onMotion: widget.onCardMotion,
                      reviewIds: app.reviewIdsToday,
                      answerFor: app.answerFor,
                      onAnswer: (id, response, confidence, reason) =>
                          app.recordAnswer(
                            id,
                            response,
                            confidence: confidence,
                            reason: reason,
                          ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int streak;
  final int freezes;
  final bool frozen;
  final VoidCallback? onBack;
  const _Header({
    required this.streak,
    this.freezes = 0,
    this.frozen = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (onBack != null) ...[
            BackCircle(onPressed: onBack!),
            const SizedBox(width: 12),
          ],
          Text(
            'Astuto',
            style: AppText.display(
              size: 20,
              weight: FontWeight.w600,
              spacing: -0.4,
              color: context.p.ink,
            ),
          ),
          if (freezes > 0) ...[
            Semantics(
              label: freezes == 1
                  ? 'One streak freeze in hand'
                  : '$freezes streak freezes in hand',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: context.p.line,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.ac_unit_rounded,
                      size: 13,
                      color: context.p.link,
                    ),
                    if (freezes > 1) ...[
                      const SizedBox(width: 4),
                      Text(
                        '$freezes',
                        style: AppText.body(
                          size: 12,
                          weight: FontWeight.w700,
                          color: context.p.ink,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: frozen
                  ? context.p.link.withValues(alpha: 0.22)
                  : context.p.line,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: frozen ? context.p.link : context.p.inverse,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  streak == 1 ? '1 day' : '$streak days',
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: context.p.ink,
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
                color: filled ? context.p.ink : context.p.line,
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
