import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pill.dart';
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
      // The sides come from the deck's own constant, so Today and the
      // re-read cannot drift apart again.
      padding: const EdgeInsets.fromLTRB(kDeckMargin, 10, kDeckMargin, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            streak: app.liveStreak,
            frozen: app.streakWasFrozen,
            onBack: widget.onBack,
          ),
          const SizedBox(height: 16),
          // Only while there is a day left to run. Once it is finished the
          // screen says so in words, and a full row of colour under that is
          // decoration on a screen whose whole job is to be quiet.
          if (!app.todayCompleted) ...[
            _ProgressBars(deck: deck, index: index, done: false),
            const SizedBox(height: 16),
          ],

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
  final bool frozen;
  final VoidCallback? onBack;
  const _Header({required this.streak, this.frozen = false, this.onBack});

  /// Monday 1 September. Built here rather than pulling in a localisation
  /// package for one line.
  static String _today() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
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
    final now = DateTime.now();
    return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          if (onBack != null) ...[
            BackCircle(onPressed: onBack!),
            const SizedBox(width: 12),
          ],
          // The day, not the app's name. Every app knows what it is called;
          // what a reader opening a daily app twice needs to know is which
          // day's five these are.
          // A long date and a streak badge do not both fit on a narrow
          // handset. The date gives way by a point or two rather than being
          // clipped, or overflowing, which is what it did.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _today(),
                maxLines: 1,
                style: AppText.display(
                  size: 20,
                  weight: FontWeight.w600,
                  spacing: -0.4,
                  color: context.p.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Nothing until there is something. A badge reading "0 days" on the
          // morning somebody installs the app is a worse first impression
          // than no badge at all.
          if (streak > 0)
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
  final List<Pill> deck;
  final int index;
  final bool done;
  const _ProgressBars({
    required this.deck,
    required this.index,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final total = deck.length;
    return Padding(
      // The bars are the only thing that says where in the day you are, now
      // that the card has stopped repeating it. The key names what they
      // draw, so it can be read without a caption existing for its own sake.
      key: ValueKey('progress-${done ? total : index + 1}-of-$total'),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: List.generate(total, (i) {
          final read = done || i < index;
          final here = !done && i == index;
          // Each bar is its own card, in that card's colour. Five identical
          // grey dashes said only how far along you were; these say what the
          // day is made of before you have read any of it, and the one under
          // the thumb is the one lit.
          final colour = deck[i].color;
          return Expanded(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 260 + i * 40),
              curve: Curves.easeOut,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 5),
              height: here ? 5 : 3,
              decoration: BoxDecoration(
                color: read || here ? colour : colour.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(9),
                boxShadow: here
                    ? [
                        BoxShadow(
                          color: colour.withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Heart, next, share — the three things you do to a card, always in reach.
