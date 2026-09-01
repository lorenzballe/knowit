import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/share_sheet.dart';
import 'deck_viewer_screen.dart';

/// The end of the day, from artboard 55.
///
/// The old version treated finishing as an inventory: a tick, three tiles, a
/// list. This treats it as the payoff. The day's five come back as the deck
/// itself, fanned — tap one and it comes to the front with the line you can
/// use underneath, so the last thing on screen is what you can now say
/// rather than a receipt of what you read.
class RecapView extends StatefulWidget {
  final AppState app;
  const RecapView({super.key, required this.app});

  @override
  State<RecapView> createState() => _RecapViewState();
}

class _RecapViewState extends State<RecapView> {
  /// Which of the five is at the front. The middle one, so the fan opens
  /// both ways.
  late int _at = widget.app.todaysDeck.length ~/ 2;

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final deck = app.todaysDeck;
    if (deck.isEmpty) return const SizedBox.shrink();
    final Pill front = deck[_at.clamp(0, deck.length - 1)];

    return Stack(
      children: [
        // The light behind takes the colour of whichever card is at the
        // front, so choosing one changes the room it is standing in.
        Positioned(
          left: -60,
          right: -60,
          top: 40,
          height: 420,
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    front.color.withValues(alpha: 0.30),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.66],
                ),
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            _AllRead(count: deck.length),
            // The fan and its dots are one object, centred together in the
            // room that is left. With the fan alone filling the middle, the
            // dots sat a long way under it and the two read as unrelated.
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Held to the fan's own height. Left loose, the fan's
                  // centring box took the whole middle and the dots ended up
                  // at the bottom of it, a long way under the cards.
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 318),
                      child: _Fan(
                        deck: deck,
                        at: _at,
                        onPick: (i) => setState(() => _at = i),
                        onOpen: (i) => openDeckViewer(
                          context,
                          app,
                          deck,
                          "Today's five",
                          initialIndex: i,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Dots(
                    count: deck.length,
                    at: _at,
                    colour: front.color,
                    onPick: (i) => setState(() => _at = i),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _Actions(app: app, deck: deck, front: front),
            const SizedBox(height: 12),
            _NextFive(),
            const SizedBox(height: 4),
          ],
        ),
      ],
    );
  }
}

/// The streak as a ring closing on the week.
/// The tick, kept from the version before this one: it says at a glance that
/// the day has been seen, which is the first thing this screen owes.
class _AllRead extends StatelessWidget {
  const _AllRead({required this.count});

  final int count;

  static const _numbers = [
    'none',
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'ten',
  ];

  static String _spelt(int n) =>
      n < _numbers.length ? _numbers[n].toUpperCase() : '$n';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PopIn(
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: context.p.inverse,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              size: 16,
              color: context.p.onInverse,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          "TODAY'S ${_spelt(count)} · ALL READ",
          style: AppText.label(
            size: 10.5,
            spacing: 1.6,
            color: context.p.ink.withValues(alpha: 0.38),
          ),
        ),
      ],
    );
  }
}

/// The day's cards as the deck itself, fanned.
class _Fan extends StatelessWidget {
  const _Fan({
    required this.deck,
    required this.at,
    required this.onPick,
    required this.onOpen,
  });

  final List<Pill> deck;
  final int at;
  final ValueChanged<int> onPick;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, box) {
          // The artboard draws the fan at 240 by 310. On a shorter phone it
          // takes what is there rather than being cropped.
          final double height = math.min(box.maxHeight - 8, 310);
          final double width = math.min(box.maxWidth - 80, height * 240 / 310);
          // Painted furthest-from-the-front first, which is what the
          // artboard's z-index says. Walking the deck in index order left
          // card one on top of whichever card was chosen, so three questions
          // showed through each other.
          final order = List<int>.generate(deck.length, (k) => k)
            ..sort((a, b) => (b - at).abs().compareTo((a - at).abs()));
          final layers = <Widget>[];
          for (final k in order) {
            final int off = k - at;
            final int reach = math.min(off.abs(), 2);
            final int side = off.sign;
            final bool front = off == 0;
            final double opacity = switch (off.abs()) {
              0 => 1,
              1 => 0.6,
              2 => 0.28,
              _ => 0,
            };
            layers.add(
              IgnorePointer(
                ignoring: opacity == 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  opacity: opacity,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.identity()
                      ..translateByDouble(
                        side * reach * 34.0,
                        reach * 11.0,
                        0,
                        1,
                      )
                      ..rotateZ(side * reach * 5 * math.pi / 180)
                      ..scaleByDouble(front ? 1 : 0.9, front ? 1 : 0.9, 1, 1),
                    transformAlignment: Alignment.center,
                    child: _FanCard(
                      pill: deck[k],
                      index: k,
                      total: deck.length,
                      onTap: () => front ? onOpen(k) : onPick(k),
                    ),
                  ),
                ),
              ),
            );
          }
          // A swipe walks the fan, the way a thumb goes through a deck.
          // Tapping the card behind still brings it forward, but nobody
          // who has just swiped through five cards expects to stop now.
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v.abs() < 120) return;
              final next = v < 0 ? at + 1 : at - 1;
              if (next >= 0 && next < deck.length) onPick(next);
            },
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(alignment: Alignment.center, children: layers),
            ),
          );
        },
      ),
    );
  }
}

class _FanCard extends StatelessWidget {
  const _FanCard({
    required this.pill,
    required this.index,
    required this.total,
    required this.onTap,
  });

  final Pill pill;
  final int index;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color ink = pill.ink;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: pill.color,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x9E000000),
              blurRadius: 48,
              offset: Offset(0, 22),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    pill.topic.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(
                      size: 9.5,
                      spacing: 1.4,
                      color: ink.withValues(alpha: 0.62),
                    ),
                  ),
                ),
                Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: AppText.label(
                    size: 9.5,
                    color: ink.withValues(alpha: 0.42),
                  ),
                ),
              ],
            ),
            Flexible(
              child: Text(
                pill.question,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 20,
                  weight: FontWeight.w600,
                  height: 1.16,
                  spacing: -0.6,
                  color: ink,
                ),
              ),
            ),
            Text(
              'READ',
              style: AppText.label(
                size: 10,
                spacing: 1.2,
                color: ink.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.at,
    required this.colour,
    required this.onPick,
  });

  final int count;
  final int at;
  final Color colour;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onPick(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 6,
                width: i == at ? 20 : 6,
                decoration: BoxDecoration(
                  color: i == at
                      ? colour
                      : context.p.ink.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.app, required this.deck, required this.front});

  final AppState app;
  final List<Pill> deck;

  /// The card at the front of the fan — the one the share button sends.
  final Pill front;

  @override
  Widget build(BuildContext context) {
    final bool more = app.canOpenExtraSet;
    return Row(
      children: [
        Expanded(
          child: _Action(
            // Short enough to fit half the row at fifteen points: the
            // longer wording came out clipped mid-word.
            label: deck.length == 5
                ? "Today's five again"
                : 'All ${deck.length} again',
            fill: context.p.inverse,
            ink: context.p.onInverse,
            onTap: () => openDeckViewer(context, app, deck, "Today's five"),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _Action(
            // "Share streak" shared a record card, which nobody sends
            // anyone. What gets sent is the card — the surprising thing,
            // the line you can use — and it is the one channel this kind of
            // app has that costs nothing. So the button shares whichever
            // card is at the front of the fan.
            label: more ? 'Five more' : 'Share this card',
            fill: context.p.ink.withValues(alpha: 0.07),
            ink: context.p.ink,
            onTap: () async {
              if (more) {
                await app.openExtraSet();
              } else if (context.mounted) {
                await showShareSheet(context, front);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.fill,
    required this.ink,
    required this.onTap,
  });

  final String label;
  final Color fill;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(size: 15, weight: FontWeight.w700, color: ink),
          ),
        ),
      ),
    );
  }
}

class _NextFive extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final left = tomorrow.difference(now);
    final hours = left.inHours;
    final minutes = left.inMinutes % 60;
    return Text(
      hours >= 1
          ? 'Next five in ${hours}h ${minutes}m'
          : 'Next five in ${minutes}m',
      textAlign: TextAlign.center,
      style: AppText.body(
        size: 11.5,
        weight: FontWeight.w500,
        color: context.p.ink.withValues(alpha: 0.3),
      ),
    );
  }
}
