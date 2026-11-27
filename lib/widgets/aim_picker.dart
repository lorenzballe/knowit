/// Where the reader wants to see more clearly ("Dove vuoi vederci più
/// chiaro?"), on the profile, for every reader: the six areas of a life the
/// cards name on their backs (lib/data/goals.dart), each a row with its
/// mark, its name and a line on what it covers, as the question the
/// developer tools first tried had them (lib/widgets/learn_looks.dart, B),
/// and one of them to pick.
///
/// The pick is the reader's goal (AppState.setGoals), which everything that
/// leans to a goal already reads, so each follows the moment it changes:
/// the cards dealt for the reader lean to its subjects and say so under
/// their heads, Explore has a shelf of it every day after Today's five
/// (withAimShelf), the coach writes towards it, and the paywall opens on it.
///
/// On the profile the pick is one row; a tap opens a sheet: the goal as a
/// card of its own colour, the way the app's cards are drawn, with what the
/// week did for it and the way to its page, then the six to change it, two
/// to a row where their words fit, each line whole: the lines are what a
/// reader chooses by.
///
/// Each area has a colour of its own, its subject's (goalTone): its glyph
/// on a disc of it, its tile edged in it, and the tile picked edged in it
/// whole, lit by it and ticked. The tiles stay the page's own ink, so the
/// six read as colour at a glance and never as six filled tiles: the one
/// card filled with colour is the goal's.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../analytics.dart';
import '../data/goals.dart';
import '../data/topics.dart' show inkOn;
import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'area_marks.dart';
import 'fit_text.dart';
import 'learn_looks.dart' show aimTally, openAimPage;
import 'premium.dart' show requirePlus;
import 'ui.dart' show Eyebrow;

/// The profile's section: the question, and one row with the reader's pick
/// (or, before there is one, the way to make it). A tap on the row opens
/// the sheet: the goal as a card of its own colour, what the week did for
/// it and the way to all of it, then the six to change it; a pick there
/// closes it. The owner wanted the choice behind a tap, never the six laid
/// out down the page, and inside it the goal's own card as before.
class ProfileAim extends StatelessWidget {
  const ProfileAim({super.key, required this.app});

  final AppState app;

  /// Keeps [g] as the reader's goal, the only one, as the question asks
  /// for one; a tap on the one already picked changes nothing.
  Future<void> _pick(Goal g) async {
    final Goal? before = Goal.of(app.goal);
    if (g == before) return;
    HapticFeedback.selectionClick();
    Analytics.capture('goal set', {
      'goal': g.key,
      'before': before?.key,
      'from': 'profile',
    });
    await app.setGoals([g.key]);
  }

  Future<void> _open(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (sheet) => AimSheet(
      app: app,
      onPick: (g) async {
        await _pick(g);
        if (sheet.mounted) Navigator.of(sheet).pop();
      },
      onOpenPage: (g) {
        Navigator.of(sheet).pop();
        openAimPage(context, app, g);
      },
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) {
      final l = context.l10n;
      return Column(
        key: const ValueKey('profile-aim-section'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Eyebrow(l.aimTitle)),
          const SizedBox(height: 10),
          AimSummary(goal: Goal.of(app.goal), onTap: () => _open(context)),
        ],
      );
    },
  );
}

/// The row on the profile: the reader's pick, its glyph on a disc of its
/// colour, its name and its line, edged in the colour, and the turn that
/// says a tap opens the sheet; before a pick, the invitation to make one.
class AimSummary extends StatelessWidget {
  const AimSummary({super.key, required this.goal, required this.onTap});

  final Goal? goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final Goal? g = goal;
    final Color tone = g == null ? p.inkMuted : goalTone(g, p);
    final String name = g == null ? l.aimPick : goalName(l, g);
    final String line = g == null ? l.aimNone : goalLine(l, g);
    return Semantics(
      button: true,
      label: '${l.aimTitle} $name',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('profile-aim-open'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(13, 13, 10, 13),
            decoration: BoxDecoration(
              color: p.surfaceRaised,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: g == null
                    ? p.line
                    : tone.withValues(alpha: p.isDark ? 0.5 : 0.55),
                width: g == null ? 1 : 1.2,
              ),
            ),
            child: Row(
              children: [
                g == null
                    ? Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: p.lineStrong, width: 1.2),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.add_rounded, size: 19, color: p.ink),
                      )
                    : AimDisc(goal: g, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Down from the six's own sizes until each word fits
                      // a line of its own: a long German name on the
                      // narrowest phone at large text never breaks in two.
                      FitText(
                        name,
                        style: AimRow.nameStyle(AimRow.largestName)
                            .copyWith(color: p.ink),
                        minSize: 9,
                        wholeWords: true,
                      ),
                      const SizedBox(height: 2),
                      FitText(
                        line,
                        style: AimRow.lineStyle(AimRow.largestLine)
                            .copyWith(color: p.inkMuted),
                        maxLines: 3,
                        minSize: 8,
                        wholeWords: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.expand_more_rounded, size: 22, color: p.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An area's glyph on a disc of its colour, the glyph in the ink that reads
/// on it: the mark the row, the tiles and the card share.
class AimDisc extends StatelessWidget {
  const AimDisc({super.key, required this.goal, this.size = 36});

  final Goal goal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color tone = goalTone(goal, context.p);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: tone),
      alignment: Alignment.center,
      child: Icon(goalIcon(goal), size: size * 0.5, color: inkOn(tone)),
    );
  }
}

/// The sheet the row opens. With a goal: the goal as a card of its colour,
/// what the week did for it and the way to all of it, Astute+'s line on the
/// free plan, then the question again and the six to change it. Before a
/// goal: the question, what a pick does, and the six.
class AimSheet extends StatelessWidget {
  const AimSheet({
    super.key,
    required this.app,
    required this.onPick,
    this.onOpenPage,
  });

  final AppState app;
  final ValueChanged<Goal> onPick;

  /// Opens the goal's own page, its paths and more of it.
  final ValueChanged<Goal>? onOpenPage;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    return Container(
      key: const ValueKey('profile-aim-sheet'),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        MediaQuery.paddingOf(context).bottom + 18,
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          child: ListenableBuilder(
            listenable: app,
            builder: (context, _) {
              final Goal? g = Goal.of(app.goal);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: p.inkMuted.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (g != null) ...[
                    AimHero(
                      app: app,
                      goal: g,
                      onOpen: onOpenPage == null ? null : () => onOpenPage!(g),
                    ),
                    if (!app.isPlus) ...[
                      const SizedBox(height: 12),
                      AimPlusLine(
                        app: app,
                        onOpen: onOpenPage == null
                            ? null
                            : () => onOpenPage!(g),
                      ),
                    ],
                    const SizedBox(height: 28),
                  ],
                  Semantics(
                    header: true,
                    child: Text(
                      l.aimTitle,
                      style: AppText.display(
                        size: g == null ? 25 : 21,
                        weight: FontWeight.w600,
                        height: 1.15,
                        color: p.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.aimLine,
                    style: AppText.body(
                      size: 13.5,
                      height: 1.4,
                      color: p.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AimTiles(
                    picked: g,
                    keyPrefix: 'profile-aim-',
                    onPick: onPick,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The reader's goal as a card of its own colour, the way the app's cards
/// are drawn: its glyph and the words "your goal", its name in the display
/// face, its line, what the last seven days did for it, and the way to its
/// page, a pill in the card's ink.
class AimHero extends StatelessWidget {
  const AimHero({
    super.key,
    required this.app,
    required this.goal,
    this.onOpen,
  });

  final AppState app;
  final Goal goal;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final Color hue = goalHue(goal);
    final Color on = inkOn(hue);
    final ({int cards, int answers, int right}) tally = aimTally(app, goal);
    return Container(
      key: const ValueKey('profile-aim-hero'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(hue, Colors.white, 0.12)!,
            hue,
            Color.lerp(hue, Colors.black, 0.14)!,
          ],
          stops: const [0, 0.55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: hue.withValues(alpha: p.isDark ? 0.26 : 0.24),
            blurRadius: 32,
            spreadRadius: -6,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(goalIcon(goal), size: 19, color: on),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.whyGoalRow.toUpperCase(),
                  style: AppText.label(
                    size: 11,
                    weight: FontWeight.w700,
                    spacing: 1.3,
                    color: on.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FitText(
            goalName(l, goal),
            style: AppText.display(
              size: 27,
              weight: FontWeight.w600,
              height: 1.08,
              spacing: -0.4,
              color: on,
            ),
            minSize: 12,
            wholeWords: true,
          ),
          const SizedBox(height: 6),
          Text(
            goalLine(l, goal),
            style: AppText.body(
              size: 14,
              height: 1.38,
              color: on.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: on.withValues(alpha: 0.16)),
          const SizedBox(height: 12),
          Text(
            l.aimWeek(tally.cards),
            key: const ValueKey('profile-aim-week'),
            style: AppText.body(
              size: 14,
              weight: FontWeight.w700,
              height: 1.35,
              color: on,
            ),
          ),
          if (tally.answers > 0) ...[
            const SizedBox(height: 2),
            Text(
              l.answersRightOf(tally.right, tally.answers),
              style: AppText.body(
                size: 13,
                height: 1.35,
                color: on.withValues(alpha: 0.72),
              ),
            ),
          ],
          if (onOpen != null) ...[
            const SizedBox(height: 16),
            Material(
              color: on,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                key: const ValueKey('profile-aim-page'),
                onTap: onOpen,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.aimOpen,
                          style: AppText.body(
                            size: 14.5,
                            weight: FontWeight.w700,
                            color: hue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18, color: hue),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// On the free plan, under the goal's card: what Astute+ does for it, the
/// door to the plans by its paths.
class AimPlusLine extends StatelessWidget {
  const AimPlusLine({super.key, required this.app, this.onOpen});

  final AppState app;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    return Semantics(
      button: true,
      child: GestureDetector(
        key: const ValueKey('profile-aim-sheet-plus'),
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            requirePlus(context, app, () => onOpen?.call(), source: 'paths'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: p.link.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l.plusName,
                    style: AppText.label(
                      size: 9.5,
                      weight: FontWeight.w700,
                      spacing: 0.6,
                      color: p.link,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  l.aimPlus,
                  style: AppText.body(
                    size: 13,
                    height: 1.38,
                    color: p.ink.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The six areas, one row under another, their names at one size and their
/// lines at one: the largest, down from the row's own, at which every word
/// of the six fits the row on a line of its own, so a long German word
/// ("Alltagsentscheidungen") never breaks in two and no row reads louder
/// than the one beside it. Where the words would have to go below four
/// fifths of their size beside the mark and the ring — the narrowest phone
/// at a large text size — they go under them instead, the row's whole
/// width theirs: a reader who asked for large text keeps it large. The
/// profile's section and the first run's question (AimScreen) both draw
/// them, so the question is one picker wherever it is asked.
class AimRows extends StatelessWidget {
  const AimRows({
    super.key,
    required this.picked,
    required this.onPick,
    required this.keyPrefix,
    this.gap = 8,
  });

  /// The area picked, or null for none yet.
  final Goal? picked;

  final ValueChanged<Goal> onPick;

  /// Each row's key: this, then the area's.
  final String keyPrefix;

  /// The room between two rows.
  final double gap;

  /// How the six are laid out, by language, room and text size: a profile
  /// is built again at every change of the reader's state, and the six do
  /// not change with it.
  static final Map<String, ({bool stacked, double name, double line})>
  _layouts = {};

  /// The size [texts] are all set at in [width]: the largest, from [from]
  /// down by half points to [least], at which each of their words fits a
  /// line alone; null where none does.
  static double? _oneSize(
    List<String> texts,
    TextStyle Function(double size) style,
    double width, {
    required double from,
    required double least,
    required TextScaler scaler,
    required TextDirection direction,
  }) {
    for (double size = from; size >= least; size -= 0.5) {
      if (texts.every(
        (t) => FitText.wordsFit(t, style(size), scaler, direction, width),
      )) {
        return size;
      }
    }
    return null;
  }

  static ({bool stacked, double name, double line}) _layout(
    AppLocalizations l,
    double width,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final List<String> names = [
      for (final Goal g in Goal.values) goalName(l, g),
    ];
    final List<String> lines = [
      for (final Goal g in Goal.values) goalLine(l, g),
    ];
    double? name(double room, double least) => _oneSize(
      names,
      AimRow.nameStyle,
      room,
      from: AimRow.largestName,
      least: least,
      scaler: scaler,
      direction: direction,
    );
    double? line(double room, double least) => _oneSize(
      lines,
      AimRow.lineStyle,
      room,
      from: AimRow.largestLine,
      least: least,
      scaler: scaler,
      direction: direction,
    );
    final double beside = width - AimRow.around;
    final double? besideName = name(beside, AimRow.largestName * 0.8);
    final double? besideLine = line(beside, AimRow.largestLine * 0.8);
    if (besideName != null && besideLine != null) {
      return (stacked: false, name: besideName, line: besideLine);
    }
    final double under = width - AimRow.aroundStacked;
    return (
      stacked: true,
      name: name(under, 8) ?? 8,
      line: line(under, 7) ?? 7,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final TextScaler scaler = MediaQuery.textScalerOf(context);
      final TextDirection direction = Directionality.of(context);
      final ({bool stacked, double name, double line}) layout = _layouts
          .putIfAbsent(
            '${Localizations.localeOf(context)} ${box.maxWidth.round()} '
            '${scaler.scale(100).round()}',
            () => _layout(context.l10n, box.maxWidth, scaler, direction),
          );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (int i, Goal g) in Goal.values.indexed) ...[
            if (i > 0) SizedBox(height: gap),
            AimRow(
              key: ValueKey('$keyPrefix${g.key}'),
              goal: g,
              on: picked == g,
              onTap: () => onPick(g),
              nameSize: layout.name,
              lineSize: layout.line,
              stacked: layout.stacked,
            ),
          ],
        ],
      );
    },
  );
}

/// One area to pick: its mark in its colour, its name in the display face,
/// its line, and a ring that fills with the colour when it is the one.
class AimRow extends StatelessWidget {
  const AimRow({
    super.key,
    required this.goal,
    required this.on,
    required this.onTap,
    this.nameSize = largestName,
    this.lineSize = largestLine,
    this.stacked = false,
  });

  final Goal goal;
  final bool on;
  final VoidCallback onTap;

  /// The sizes of the name and the line, as [AimRows] sets the six.
  final double nameSize;
  final double lineSize;

  /// The words under the mark and the ring rather than between them, as
  /// [AimRows] lays the six out where there is no room beside.
  final bool stacked;

  /// The largest the name and the line are set at: their size wherever
  /// nothing takes them down.
  static const double largestName = 17.5;
  static const double largestLine = 13;

  static TextStyle nameStyle(double size) =>
      AppText.display(size: size, weight: FontWeight.w600, height: 1.15);

  static TextStyle lineStyle(double size) =>
      AppText.body(size: size, height: 1.33);

  /// The room a row keeps around its words, across: its edge and inset on
  /// both sides, the mark and the gap after it, the gap before the ring and
  /// the ring.
  static const double around = 2 * _inset + _mark + 12 + 10 + _ring;

  /// The same, with the words under the mark and the ring: the edge and
  /// the inset alone.
  static const double aroundStacked = 2 * _inset;

  /// The edge and the room inside it, the same whether the edge is the
  /// hairline or the picked one's: picked, the words do not move.
  static const double _inset = 13.5;
  static const double _mark = 36;
  static const double _ring = 24;

  static const Duration _turn = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final String name = goalName(l, goal);
    final String line = goalLine(l, goal);
    final Color tone = goalTone(goal, p);
    final double edge = on ? 1.5 : 1;
    // The mark: the glyph in the area's colour, in a thin ring of it, drawn
    // whole on the row picked. A ring rather than a disc of the colour: six
    // discs down the page were six coloured tiles again, and a yellow laid
    // faint on the night is olive.
    final Widget mark = AnimatedContainer(
      duration: _turn,
      width: _mark,
      height: _mark,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: on ? tone : tone.withValues(alpha: p.isDark ? 0.6 : 0.5),
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(goalIcon(goal), size: 18, color: tone),
    );
    final Widget words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: nameStyle(nameSize).copyWith(color: p.ink)),
        const SizedBox(height: 3),
        Text(
          line,
          style: lineStyle(lineSize)
              .copyWith(color: p.ink.withValues(alpha: 0.6)),
        ),
      ],
    );
    // The ring that fills with the colour, and the tick in it, when it is
    // the one.
    final Widget ring = AnimatedContainer(
      duration: _turn,
      width: _ring,
      height: _ring,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? tone : Colors.transparent,
        border: Border.all(color: on ? tone : p.lineStrong, width: 1.5),
      ),
      child: on
          ? Icon(Icons.check_rounded, size: 16, color: inkOn(tone))
          : null,
    );
    return Semantics(
      button: true,
      selected: on,
      inMutuallyExclusiveGroup: true,
      label: '$name. $line',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: _turn,
          padding: EdgeInsets.all(_inset - edge),
          decoration: BoxDecoration(
            // Picked, the row takes a wash of its colour, faint enough for
            // the words on it to stay the page's own.
            color: on
                ? Color.alphaBlend(
                    tone.withValues(alpha: p.isDark ? 0.13 : 0.08),
                    p.surfaceRaised,
                  )
                : p.surfaceRaised,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: on ? tone.withValues(alpha: 0.85) : p.line,
              width: edge,
            ),
          ),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [mark, const Spacer(), ring]),
                    const SizedBox(height: 10),
                    words,
                  ],
                )
              : Row(
                  children: [
                    mark,
                    const SizedBox(width: 12),
                    Expanded(child: words),
                    const SizedBox(width: 10),
                    ring,
                  ],
                ),
        ),
      ),
    );
  }
}

/// The six in the sheet, two to a row where their words fit there: each a
/// tile with its glyph on a disc of its colour, its name, its line, and a
/// ring that fills with the colour on the one picked. The names at one size
/// and the lines at one, the largest at which every word of the six fits a
/// line of its own; where two to a row would take them below four fifths
/// of that, one to a row, the whole width theirs.
class AimTiles extends StatelessWidget {
  const AimTiles({
    super.key,
    required this.picked,
    required this.onPick,
    required this.keyPrefix,
  });

  final Goal? picked;
  final ValueChanged<Goal> onPick;

  /// Each tile's key: this, then the area's.
  final String keyPrefix;

  static const double gap = 10;

  static final Map<String, ({int columns, double name, double line})> _layouts =
      {};

  static ({int columns, double name, double line}) _layout(
    AppLocalizations l,
    double width,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final List<String> names = [
      for (final Goal g in Goal.values) goalName(l, g),
    ];
    final List<String> lines = [
      for (final Goal g in Goal.values) goalLine(l, g),
    ];
    double? name(double room, double least) => AimRows._oneSize(
      names,
      AimTile.nameStyle,
      room,
      from: AimTile.largestName,
      least: least,
      scaler: scaler,
      direction: direction,
    );
    double? line(double room, double least) => AimRows._oneSize(
      lines,
      AimTile.lineStyle,
      room,
      from: AimTile.largestLine,
      least: least,
      scaler: scaler,
      direction: direction,
    );
    final double half = (width - gap) / 2 - 2 * AimTile.inset;
    final double? halfName = name(half, AimTile.largestName * 0.8);
    final double? halfLine = line(half, AimTile.largestLine * 0.8);
    if (halfName != null && halfLine != null) {
      return (columns: 2, name: halfName, line: halfLine);
    }
    final double whole = width - 2 * AimTile.inset;
    return (columns: 1, name: name(whole, 8) ?? 8, line: line(whole, 7) ?? 7);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final TextScaler scaler = MediaQuery.textScalerOf(context);
      final TextDirection direction = Directionality.of(context);
      final ({int columns, double name, double line}) layout = _layouts
          .putIfAbsent(
            '${Localizations.localeOf(context)} ${box.maxWidth.round()} '
            '${scaler.scale(100).round()}',
            () => _layout(context.l10n, box.maxWidth, scaler, direction),
          );
      Widget tile(Goal g) => AimTile(
        key: ValueKey('$keyPrefix${g.key}'),
        goal: g,
        on: picked == g,
        onTap: () => onPick(g),
        nameSize: layout.name,
        lineSize: layout.line,
      );
      const List<Goal> six = Goal.values;
      if (layout.columns == 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (int i, Goal g) in six.indexed) ...[
              if (i > 0) const SizedBox(height: gap),
              tile(g),
            ],
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < six.length; i += 2) ...[
            if (i > 0) const SizedBox(height: gap),
            // Two of a row as tall as the taller.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tile(six[i])),
                  const SizedBox(width: gap),
                  Expanded(
                    child: i + 1 < six.length
                        ? tile(six[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}

/// One area in the sheet: its glyph on a disc of its colour and the ring
/// over the corner, its name in the display face, its line. Edged in its
/// colour; picked, edged in it whole, lit by it from under, and ticked.
class AimTile extends StatelessWidget {
  const AimTile({
    super.key,
    required this.goal,
    required this.on,
    required this.onTap,
    this.nameSize = largestName,
    this.lineSize = largestLine,
  });

  final Goal goal;
  final bool on;
  final VoidCallback onTap;
  final double nameSize;
  final double lineSize;

  static const double largestName = 17;
  static const double largestLine = 12.5;

  /// The edge and the room inside it, the same whether the edge is the
  /// hairline or the picked one's: picked, the words do not move.
  static const double inset = 14;

  static TextStyle nameStyle(double size) =>
      AppText.display(size: size, weight: FontWeight.w600, height: 1.14);

  static TextStyle lineStyle(double size) =>
      AppText.body(size: size, height: 1.32);

  static const Duration _turn = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final String name = goalName(l, goal);
    final String line = goalLine(l, goal);
    final Color tone = goalTone(goal, p);
    final double edge = on ? 1.6 : 1;
    final Widget ring = AnimatedContainer(
      duration: _turn,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? tone : Colors.transparent,
        border: Border.all(color: on ? tone : p.lineStrong, width: 1.5),
      ),
      child: on
          ? Icon(Icons.check_rounded, size: 15, color: inkOn(tone))
          : null,
    );
    return Semantics(
      button: true,
      selected: on,
      inMutuallyExclusiveGroup: true,
      label: '$name. $line',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: _turn,
          padding: EdgeInsets.all(inset - edge),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: on ? tone : tone.withValues(alpha: p.isDark ? 0.34 : 0.4),
              width: edge,
            ),
            // Lit from under in its colour rather than washed in it: a
            // yellow laid faint on the night is olive, a glow of it is
            // still yellow.
            boxShadow: [
              BoxShadow(
                color: tone.withValues(
                  alpha: on ? (p.isDark ? 0.34 : 0.26) : 0,
                ),
                blurRadius: 20,
                spreadRadius: -3,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AimDisc(goal: goal, size: 34),
                  const Spacer(),
                  ring,
                ],
              ),
              const SizedBox(height: 12),
              Text(name, style: nameStyle(nameSize).copyWith(color: p.ink)),
              const SizedBox(height: 4),
              Text(
                line,
                style: lineStyle(lineSize)
                    .copyWith(color: p.ink.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
