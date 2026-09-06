import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/pill_card_stack.dart';
import '../widgets/share_sheet.dart';
import '../widgets/ui.dart';
import 'today_done_view.dart';

/// The card is the screen: dark chrome, and the deck filling everything
/// between the progress bars and the tab bar.
///
/// Two screens live here, and they are deliberately not the same one with a
/// different middle. While the five are unread this is the trainer — "Today"
/// at the top, the bars, the deck, and nothing else to do. Once they are
/// read it becomes the shelf from artboard 66a, which is a place to look
/// back rather than a place to work.
class TodayScreen extends StatefulWidget {
  final AppState app;

  /// Set when this is opened as its own screen off the path, so the way back
  /// sits in the header rather than stacked above it.
  final VoidCallback? onBack;

  /// True while a card is under the finger. The tab bar steps aside for the
  /// gesture: a card being thrown towards the bottom of the screen should
  /// not be thrown at a row of buttons.
  final ValueChanged<bool>? onCardMotion;

  /// Opens the Explore tab on today's best, from the finished day.
  final VoidCallback? onExplore;

  const TodayScreen({
    super.key,
    required this.app,
    this.onBack,
    this.onCardMotion,
    this.onExplore,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool _celebrated = false;

  /// Which of the finished day's cards is at the front of the shelf. Held
  /// here rather than in the shelf because the header's dot and the glow
  /// behind the whole tab take that card's colour.
  int _shelfAt = 0;
  List<Pill>? _shelfDeck;

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
    final bool done = app.todayCompleted;
    _markCompletion(done);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      child: done
          ? _shelf(context, key: const ValueKey('shelf'))
          : _reading(context, key: const ValueKey('deck')),
    );
  }

  /// The day, being read. Unchanged from the screen this app has always
  /// opened on: the word Today, the streak beside it, the bars, the deck.
  Widget _reading(BuildContext context, {required Key key}) {
    final app = widget.app;
    return Padding(
      key: key,
      // The sides come from the deck's own constant, so Today and the
      // re-read cannot drift apart again.
      padding: const EdgeInsets.fromLTRB(kDeckMargin, 10, kDeckMargin, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReadingHeader(
            streak: app.liveStreak,
            frozen: app.streakWasFrozen,
            onBack: widget.onBack,
          ),
          const SizedBox(height: 16),
          _ProgressBars(total: app.todaysDeck.length, index: app.todayIndex),
          const SizedBox(height: 16),
          // The deck takes every pixel that is left.
          Expanded(
            child: PillCardStack(
              deck: app.todaysDeck,
              index: app.todayIndex,
              onAdvance: () => app.advance(),
              isSaved: app.isSaved,
              onSave: (pill) => app.toggleSaved(pill.id),
              onShare: (pill) => showShareSheet(context, pill),
              onMotion: widget.onCardMotion,
              reviewIds: app.reviewIdsToday,
              answerFor: app.answerFor,
              onAnswer: (id, response, confidence, reason) => app.recordAnswer(
                id,
                response,
                confidence: confidence,
                reason: reason,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The day, done — artboard 66a, down to its margins.
  Widget _shelf(BuildContext context, {required Key key}) {
    final app = widget.app;
    final deck = app.todaysDeck;
    if (deck.isEmpty) return SizedBox.shrink(key: key);

    // A new deck — the next day, or the second set dealt — starts the shelf
    // from its first card.
    if (!identical(_shelfDeck, deck)) {
      _shelfDeck = deck;
      _shelfAt = 0;
    }
    final int at = _shelfAt.clamp(0, deck.length - 1);
    final Pill front = deck[at];

    return Stack(
      key: key,
      children: [
        Positioned.fill(child: _Glow(colour: front.color)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 15),
              child: _ShelfHeader(app: app, colour: front.color),
            ),
            Expanded(
              child: TodayDoneView(
                app: app,
                at: at,
                onPick: (k) => setState(() => _shelfAt = k),
                onExplore: widget.onExplore,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The header while the day is being read.
class _ReadingHeader extends StatelessWidget {
  final int streak;
  final bool frozen;
  final VoidCallback? onBack;
  const _ReadingHeader({
    required this.streak,
    this.frozen = false,
    this.onBack,
  });

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
          // A long date and a streak badge do not both fit on a narrow
          // handset. The date gives way by a point or two rather than being
          // clipped, or overflowing, which is what it did.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Today',
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

/// The header once the day is done: a dot in the front card's colour, which
/// day this was, and at the far end what was kept. One line, because the
/// screen under it is the subject and a header should say where you are
/// rather than take a third of the room saying it.
class _ShelfHeader extends StatelessWidget {
  const _ShelfHeader({required this.app, required this.colour});

  final AppState app;
  final Color colour;

  /// The freeze is said here and nowhere else, so it comes first on the day
  /// it was spent. Otherwise, what the day has produced.
  String get _aside {
    if (app.streakWasFrozen) return 'A freeze kept the streak';
    final int kept = app.keptToday;
    if (kept == 0) return 'Nothing kept yet';
    return kept == 1 ? '1 kept today' : '$kept kept today';
  }

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return Row(
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: still ? 0 : 500),
          curve: Curves.easeOut,
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        // The day's line eats the room, so the aside is pushed flush to the
        // far edge — the canvas's `flex:1` spacer between the two. Sharing
        // the room between them instead left the aside stranded in the
        // middle with the leftover piled up after it.
        Expanded(
          child: Text(
            'Day ${app.dayNumber} · '
            '${spellCount(app.todaysDeck.length).toLowerCase()} read',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              size: 15,
              weight: FontWeight.w600,
              spacing: -0.2,
              color: context.p.ink,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _aside,
          maxLines: 1,
          style: AppText.body(
            size: 12,
            weight: FontWeight.w500,
            color: context.p.ink.withValues(alpha: 0.38),
          ),
        ),
      ],
    );
  }
}

/// Two pools of the front card's colour thrown on the ground, one high
/// behind the card and a fainter one low behind the controls — the
/// artboard's two blurred circles, at its own positions and strengths. The
/// colour crosses over when the front card changes rather than snapping.
class _Glow extends StatelessWidget {
  const _Glow({required this.colour});

  final Color colour;

  /// Where the artboard puts them, less the 56 points of status bar its
  /// frame draws above the page.
  static const double _statusBar = 56;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    final duration = Duration(milliseconds: still ? 0 : 550);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final double w = box.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: w / 2 - 320,
                top: 150 - _statusBar,
                child: _Pool(
                  colour: colour,
                  strength: 0.30,
                  size: 640,
                  duration: duration,
                ),
              ),
              Positioned(
                left: w / 2 - 260,
                top: 420 - _statusBar,
                child: _Pool(
                  colour: colour,
                  strength: 0.16,
                  size: 520,
                  height: 420,
                  duration: duration,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Pool extends StatelessWidget {
  const _Pool({
    required this.colour,
    required this.strength,
    required this.size,
    required this.duration,
    this.height,
  });

  final Color colour;
  final double strength;
  final double size;
  final double? height;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      width: size,
      height: height ?? size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // The canvas draws a hard-edged circle and blurs it by 130. A blur
        // that wide is a Gaussian, so the same shape is cheaper as a
        // gradient: most of the colour in the middle third, and gone well
        // before the edge.
        gradient: RadialGradient(
          colors: [
            colour.withValues(alpha: strength),
            colour.withValues(alpha: strength * 0.72),
            colour.withValues(alpha: strength * 0.30),
            colour.withValues(alpha: strength * 0.08),
            colour.withValues(alpha: 0),
          ],
          stops: const [0, 0.28, 0.55, 0.78, 1],
        ),
      ),
    );
  }
}

class _ProgressBars extends StatelessWidget {
  final int total;
  final int index;
  const _ProgressBars({required this.total, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // The bars are the only thing that says where in the day you are, now
      // that the card has stopped repeating it. The key names what they
      // draw, so it can be read without a caption existing for its own sake.
      key: ValueKey('progress-${index + 1}-of-$total'),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: List.generate(total, (i) {
          final filled = i <= index;
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
