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
/// On the profile the pick is one row; a tap opens the six in a sheet, one
/// under another rather than in a row that turns sideways: the six lines
/// are what a reader chooses by, and a sideways row would show one and a
/// half of them, the one picked perhaps out of sight.
///
/// Each area has a colour of its own, its subject's (goalTone): on its mark,
/// a glyph in a thin ring of the colour, and on the row picked, washed in
/// it, edged in it and ticked in it. The rest is the page's own ink, so the
/// six read as colour at a glance and never as six filled tiles: the
/// subjects' chips above them, at a lower voice.
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
import 'ui.dart' show Eyebrow;

/// The profile's section: the question, and one row with the reader's pick
/// (or, before there is one, the way to make it). A tap on the row opens
/// the six in a sheet that rises from the foot, and a pick there closes it:
/// the owner wanted the choice behind a tap, never the six laid out down
/// the page.
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
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (sheet) => AimSheet(
      app: app,
      onPick: (g) async {
        await _pick(g);
        if (sheet.mounted) Navigator.of(sheet).pop();
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

/// The row on the profile: the reader's pick, its mark in its ring and its
/// line, and the turn that says a tap opens the six; before a pick, the
/// invitation to make one.
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
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(13.5, 12, 10, 12),
            decoration: BoxDecoration(
              color: g == null
                  ? Colors.transparent
                  : tone.withValues(alpha: p.isDark ? 0.08 : 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: g == null ? p.line : tone.withValues(alpha: 0.55),
                width: g == null ? 1 : 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: tone, width: 1.2),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    g == null ? Icons.add_rounded : goalIcon(g),
                    size: 18,
                    color: tone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Down from the six's own sizes until each word fits
                      // a line of its own: "Alltagsentscheidungen" on the
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

/// The sheet the row opens: the question, what a pick does, and the six.
class AimSheet extends StatelessWidget {
  const AimSheet({super.key, required this.app, required this.onPick});

  final AppState app;
  final ValueChanged<Goal> onPick;

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
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
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
              Semantics(
                header: true,
                child: Text(
                  l.aimTitle,
                  style: AppText.display(
                    size: 24,
                    weight: FontWeight.w600,
                    height: 1.15,
                    color: p.ink,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.aimLine,
                style: AppText.body(size: 13.5, height: 1.4, color: p.inkMuted),
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: app,
                builder: (context, _) => AimRows(
                  picked: Goal.of(app.goal),
                  keyPrefix: 'profile-aim-',
                  onPick: onPick,
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
