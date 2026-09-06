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
/// between the progress bars and the tab bar. Once the five are done the
/// same tab becomes the shelf from artboard 66a, under the same one-line
/// header, so finishing the day changes what the tab holds and not what it
/// looks like.
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

    final deck = app.todaysDeck;
    final index = app.todayIndex;

    // A new deck — the next day, or the second set dealt — starts the shelf
    // from its first card.
    if (!identical(_shelfDeck, deck)) {
      _shelfDeck = deck;
      _shelfAt = 0;
    }
    final int at = deck.isEmpty ? 0 : _shelfAt.clamp(0, deck.length - 1);

    // The card the screen is about: the one being read, or the one at the
    // front of the shelf. Its colour is the only colour the chrome takes.
    final Pill? front = deck.isEmpty
        ? null
        : deck[done ? at : index.clamp(0, deck.length - 1)];

    return Stack(
      children: [
        if (done && front != null)
          Positioned.fill(child: _Glow(colour: front.color)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: _Header(
                app: app,
                colour: front?.color ?? context.p.inkFaint,
                onBack: widget.onBack,
              ),
            ),
            // Only while there is a day left to run. Once it is finished the
            // screen says so in words, and a full row of colour under that
            // is decoration on a screen whose whole job is to be quiet.
            if (!done) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _ProgressBars(total: deck.length, index: index),
              ),
            ],
            const SizedBox(height: 16),

            // The deck takes every pixel that is left.
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: Curves.easeOutCubic,
                child: done
                    ? TodayDoneView(
                        key: const ValueKey('shelf'),
                        app: app,
                        at: at,
                        onPick: (k) => setState(() => _shelfAt = k),
                        onExplore: widget.onExplore,
                      )
                    : Padding(
                        key: const ValueKey('deck'),
                        // The sides come from the deck's own constant, so
                        // Today and the re-read cannot drift apart again.
                        padding: const EdgeInsets.fromLTRB(
                          kDeckMargin,
                          0,
                          kDeckMargin,
                          8,
                        ),
                        child: PillCardStack(
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
            ),
          ],
        ),
      ],
    );
  }
}

/// One line: a dot in the day's colour, which day this is and where it has
/// got to, and at the far end what has been kept.
///
/// The header used to be the word "Today" with a streak badge beside it,
/// which said the name of the tab you were already on and nothing about
/// the day. "Day 6 · five read" says both, in the same width.
class _Header extends StatelessWidget {
  const _Header({required this.app, required this.colour, this.onBack});

  final AppState app;
  final Color colour;
  final VoidCallback? onBack;

  String get _state {
    final int total = app.todaysDeck.length;
    final int read = app.todayIndex.clamp(0, total);
    if (total == 0) return 'nothing to read';
    if (read >= total) return '${spellCount(total).toLowerCase()} read';
    if (read == 0) return '${spellCount(total).toLowerCase()} to read';
    return '$read of $total read';
  }

  /// The freeze is said here and nowhere else, so it comes first on the day
  /// it was spent. Otherwise, what the day has produced so far.
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
        if (onBack != null) ...[
          BackCircle(onPressed: onBack!),
          const SizedBox(width: 12),
        ],
        AnimatedContainer(
          duration: Duration(milliseconds: still ? 0 : 500),
          curve: Curves.easeOut,
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        // The day's line takes what it needs and the aside sits at the far
        // end; when the two cannot both fit, the aside gives way first.
        Flexible(
          flex: 3,
          child: Text(
            'Day ${app.dayNumber} · $_state',
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
        Expanded(
          flex: 2,
          child: Text(
            _aside,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppText.body(
              size: 12,
              weight: FontWeight.w500,
              color: context.p.ink.withValues(alpha: 0.38),
            ),
          ),
        ),
      ],
    );
  }
}

/// Two pools of the front card's colour thrown on the ground, one high
/// behind the card and a fainter one low behind the controls. The colour
/// crosses over when the front card changes rather than snapping.
class _Glow extends StatelessWidget {
  const _Glow({required this.colour});

  final Color colour;

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
                top: 94,
                child: _Pool(
                  colour: colour,
                  strength: 0.30,
                  width: 640,
                  height: 640,
                  duration: duration,
                ),
              ),
              Positioned(
                left: w / 2 - 260,
                top: 364,
                child: _Pool(
                  colour: colour,
                  strength: 0.16,
                  width: 520,
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
    required this.width,
    required this.height,
    required this.duration,
  });

  final Color colour;
  final double strength;
  final double width;
  final double height;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // A soft pool rather than a hard-edged disc: most of the colour is
        // in the middle third and it is gone well before the edge.
        gradient: RadialGradient(
          colors: [
            colour.withValues(alpha: strength),
            colour.withValues(alpha: strength * 0.55),
            colour.withValues(alpha: strength * 0.18),
            colour.withValues(alpha: 0),
          ],
          stops: const [0, 0.3, 0.6, 1],
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
    return Row(
      // The bars are the only thing that says where in the day you are, now
      // that the card has stopped repeating it. The key names what they
      // draw, so it can be read without a caption existing for its own sake.
      key: ValueKey('progress-${index + 1}-of-$total'),
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
    );
  }
}
