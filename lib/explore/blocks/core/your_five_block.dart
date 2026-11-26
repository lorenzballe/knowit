/// Your five from today: once the day's five are read, a small row near the
/// top of Explore — the five in small, in their colours, the name, their
/// subjects — and a tap opens them again at full size, the way they first
/// came, from the first: a drawn card to be played again, a card in words to
/// be turned over.
///
/// Explore is where a reader goes once the day is read, so a way back to
/// the cards themselves is here (the owner: "maybe it's better to put your
/// five of today somewhere in Explore"). Today has its own again, "See
/// again" over the shelf: both open the five the same way ([openTodaysFive]).
///
/// The reader's own five, never the day's challenge that is the same for
/// everyone and opens Explore above it: the name says whose they are, and
/// what the row shows is their cards. Not drawn before the five are read —
/// until then they are Today's, a tab away — nor while Explore is narrowed
/// to a subject.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../analytics.dart';
import '../../../data/pills_repository.dart' show kPillsPerDay;
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../screens/deck_viewer_screen.dart';
import '../../../state/app_state.dart';
import '../../../theme.dart';
import '../../explore_block.dart';
import 'layout.dart';

/// The block: see the library's own words.
class YourFiveBlock extends ExploreBlock with SectionLayout {
  const YourFiveBlock();

  @override
  String get name => 'your-five';

  @override
  bool get onSubjectPages => false;

  /// Close under the day's challenge, which has room of its own at its foot.
  @override
  double get gap => 12;

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final AppState app = host.app;
    if (host.subject != null) return null;
    if (!app.dayClosed && !app.todayCompleted) return null;
    // A second set dealt after the five does not make the day longer: the
    // row is the five.
    final List<Pill> five = app.todaysDeck.take(kPillsPerDay).toList();
    if (five.isEmpty) return null;
    return Padding(
      // Room at its foot of its own, as Continue has: the cover after it
      // sits close to what is above it.
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: YourFiveRow(
        five: five,
        title: section.title(host.language) ?? context.l10n.yourFiveFromToday,
        line: section.subtitle(host.language),
        onTap: () => openTodaysFive(context, app, from: 'explore'),
      ),
    );
  }
}

/// Opens the reader's own five again at full size, in the viewer, the way
/// they first came, from the first card, always: not the card at the front
/// of Today's shelf, nor the one the last time stopped on (the owner's
/// rule). The five read again are read as they came. The one way both doors
/// to them open them, this row in Explore ([from] `explore`) and "See
/// again" over Today's shelf (`today`).
void openTodaysFive(
  BuildContext context,
  AppState app, {
  required String from,
}) {
  // A second set dealt after the five does not make the day longer.
  final List<Pill> five = app.todaysDeck.take(kPillsPerDay).toList();
  if (five.isEmpty) return;
  final String title = context.l10n.tabToday;
  HapticFeedback.selectionClick();
  Analytics.capture('today seen again', {'from': from});
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DeckViewerScreen(
        app: app,
        deck: five,
        title: title,
        initialIndex: 0,
        source: 'today again',
      ),
    ),
  );
}

/// The row itself, given what it shows: the five in small, the name, the
/// subjects (or the section's own line), and the way in.
class YourFiveRow extends StatelessWidget {
  const YourFiveRow({
    super.key,
    required this.five,
    required this.title,
    required this.onTap,
    this.line,
  });

  final List<Pill> five;
  final String title;

  /// The line under the name; the five's subjects when not given.
  final String? line;
  final VoidCallback onTap;

  /// As many of [names] as fit [width] whole, and how many more there are:
  /// "Human body · Space · Psychology +2". A name cut off in its middle
  /// reads as a fault.
  static String _fitted(
    BuildContext context,
    List<String> names,
    TextStyle style,
    double width,
  ) {
    final TextStyle base = DefaultTextStyle.of(context).style.merge(style);
    for (int k = names.length; k > 1; k--) {
      final String text = [
        names.take(k).join(' · '),
        if (k < names.length) '+${names.length - k}',
      ].join('  ');
      final TextPainter painter = TextPainter(
        text: TextSpan(text: text, style: base),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final bool fits = painter.width <= width;
      painter.dispose();
      if (fits) return text;
    }
    return names.length > 1
        ? '${names.first}  +${names.length - 1}'
        : names.first;
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final List<String> subjects = [
      ...{for (final Pill pill in five) context.l10n.subjectOf(pill.topic)},
    ];
    final String? own = line;
    final TextStyle quiet = AppText.body(
      size: 12.5,
      height: 1.3,
      color: p.inkMuted,
    );
    return Semantics(
      button: true,
      label: '$title. ${own ?? subjects.join(', ')}',
      hint: context.l10n.todaySeeAgainHint,
      excludeSemantics: true,
      child: Material(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: const ValueKey('your-five'),
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                _Five(five: five, edge: p.surfaceRaised),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          size: 15,
                          weight: FontWeight.w700,
                          height: 1.25,
                          color: p.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      LayoutBuilder(
                        builder: (context, box) => Text(
                          own ??
                              _fitted(context, subjects, quiet, box.maxWidth),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: quiet,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: p.ink.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The five in small: each a card in its own colour, at a card's
/// proportion, spread a little from the first, which lies on top, as five
/// cards held in a hand.
class _Five extends StatelessWidget {
  const _Five({required this.five, required this.edge});

  final List<Pill> five;

  /// What separates one card from the next: the row's own ground.
  final Color edge;

  static const double _width = 16;
  static const double _height = 22;
  static const double _step = 12;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: _width + _step * (five.length - 1),
        height: _height,
        child: Stack(
          children: [
            for (int k = five.length - 1; k >= 0; k--)
              Positioned(
                left: _step * k,
                top: 0,
                child: Container(
                  width: _width,
                  height: _height,
                  decoration: BoxDecoration(
                    color: five[k].color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: edge, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
