import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/goals.dart';
import '../measure/card_read.dart';
import '../measure/screens.dart' show seenOf;
import '../models/pill.dart';
import '../sync/reports.dart';
import '../theme.dart';
import 'area_marks.dart' show goalIcon, goalName;
import 'deeper_sheet.dart';
import 'diagram_view.dart';
import 'motion.dart';
import 'report_sheet.dart';
import 'source_foot.dart';
import '../l10n/app_localizations.dart';

/// Everything a card says once it is turned over: the reasoning, the trap,
/// the plain-words retelling and the other side of a debate.
///
/// This lives on its own because it is needed twice — on the back of a card
/// and on the detail screen reached from the archive — and the two drifted
/// apart. The detail screen was showing only `pill.answer`, which on a worked
/// problem is the last line of the solution and on a debate is one side of it.
class RevealBody extends StatefulWidget {
  final Pill pill;

  /// Text colour on whatever this is sitting on: the card's ink on a card,
  /// the app's ink on paper.
  final Color ink;

  /// Panel fill and edge to match.
  final Color wash;
  final Color washEdge;

  /// A worked solution one step at a time, the first time it is turned
  /// over; whole, when it is looked at again from the archive.
  final bool stepByStep;

  const RevealBody({
    super.key,
    required this.pill,
    required this.ink,
    required this.wash,
    required this.washEdge,
    this.stepByStep = false,
  });

  /// The version that sits on the page rather than on a card, so it takes
  /// its colours from the palette in force.
  factory RevealBody.onPage(Pill pill, Palette palette, {Key? key}) =>
      RevealBody(
        key: key,
        pill: pill,
        ink: palette.ink,
        wash: palette.line,
        washEdge: palette.lineStrong,
      );

  @override
  State<RevealBody> createState() => _RevealBodyState();
}

class _RevealBodyState extends State<RevealBody> {
  bool _simplyOpen = false;
  bool _counterOpen = false;

  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pill.hasSteps)
          _Steps(
            pill: pill,
            ink: widget.ink,
            stepByStep: widget.stepByStep,
            style: _Type.step(widget.ink, 15),
            gap: 14,
          )
        else
          Text(
            pill.answer,
            style: AppText.body(
              size: 16,
              height: 1.5,
              color: widget.ink.withValues(alpha: 0.92),
            ),
          ),
        // The picture comes right after the words it illustrates, and is
        // drawn while they are being read.
        if (pill.diagram != null) ...[
          const SizedBox(height: 18),
          DiagramView(diagram: pill.diagram!, ink: widget.ink),
        ],
        if (pill.hasSimply) ...[
          const SizedBox(height: 14),
          if (_simplyOpen)
            _Panel(
              label: context.l10n.putSimplyCaps,
              body: pill.simply,
              ink: widget.ink,
              wash: widget.wash,
            )
          else
            _TextAction(
              ink: widget.ink,
              icon: Icons.child_care_rounded,
              label: context.l10n.explainLikeImThree,
              onTap: () => setState(() => _simplyOpen = true),
            ),
        ],
        if (pill.hasCounterpoint) ...[
          const SizedBox(height: 14),
          if (_counterOpen)
            _Panel(
              label: context.l10n.whatTheOtherSideSaysCaps,
              body: pill.counterpoint,
              ink: widget.ink,
              wash: widget.wash,
            )
          else
            _TextAction(
              ink: widget.ink,
              icon: Icons.swap_horiz_rounded,
              label: context.l10n.whatTheOtherSideSays,
              onTap: () => setState(() => _counterOpen = true),
            ),
        ],
        if (pill.asksSomething && pill.trap.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            context.l10n.theTrap(pill.trap),
            style: AppText.body(
              size: 13.5,
              weight: FontWeight.w500,
              height: 1.45,
              color: widget.ink.withValues(alpha: 0.75),
            ),
          ),
        ],
        // One box to end on: what to keep, or the question to ask yourself
        // when the card has nothing to keep — both only on a card that asks
        // for both. Two panels of take-aways read as homework.
        if (pill.showsMove) ...[
          const SizedBox(height: 20),
          _Panel(
            label: context.l10n.barMoveCaps,
            body: pill.barMove,
            ink: widget.ink,
            wash: widget.wash,
          ),
        ],
        if (pill.showsAsk) ...[
          SizedBox(height: pill.showsMove ? 10 : 20),
          _Panel(
            label: context.l10n.askYourselfCaps,
            body: pill.ask,
            ink: widget.ink,
            wash: widget.wash,
          ),
        ],
        const SizedBox(height: 13),
        _SourceTap(
          pill: pill,
          child: Text(
            context.l10n.sourceLabel(pill.sourceShort),
            style:
                AppText.body(
                  size: 11.5,
                  color: widget.ink.withValues(alpha: 0.6),
                ).copyWith(
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                  decorationColor: widget.ink.withValues(alpha: 0.35),
                ),
          ),
        ),
        const SizedBox(height: 16),
        _ReportLine(pill: pill, ink: widget.ink),
      ],
    );
  }
}

/// The type of the reveal, in one place, so what is measured to fit the
/// card is exactly what is then set on it.
abstract final class _Type {
  static TextStyle answer(Color ink, double size) => AppText.body(
    size: size,
    height: 1.48,
    color: ink.withValues(alpha: 0.92),
  );

  static TextStyle step(Color ink, double size) => AppText.body(
    size: size,
    height: 1.45,
    color: ink.withValues(alpha: 0.92),
  );

  static TextStyle question(Color ink, double size) => AppText.display(
    size: size,
    weight: FontWeight.w600,
    height: 1.16,
    spacing: -0.3 - size * 0.018,
    color: ink,
  );

  static TextStyle trap(Color ink, double size) => AppText.body(
    size: size,
    weight: FontWeight.w500,
    height: 1.45,
    color: ink.withValues(alpha: 0.75),
  );

  static TextStyle action(Color ink, double size) => AppText.body(
    size: size,
    weight: FontWeight.w500,
    color: ink.withValues(alpha: 0.65),
  );

  static TextStyle panelLabel(Color ink) => AppText.label(
    size: 10.5,
    spacing: 1.2,
    color: ink.withValues(alpha: 0.6),
  );

  static TextStyle panelBody(Color ink, double size) => AppText.body(
    size: size,
    height: 1.45,
    color: ink.withValues(alpha: 0.92),
  );

  /// The line to keep is the one thing on the back set bold: it is what the
  /// card is for, and it should read as the conclusion, not as more text.
  static TextStyle keep(Color ink, double size) => AppText.body(
    size: size,
    weight: FontWeight.w600,
    height: 1.36,
    color: ink,
  );

  /// Where a card pays off: the source's size, a voice firmer than it.
  static TextStyle useful(Color ink, double size) => AppText.body(
    size: size,
    height: 1.35,
    weight: FontWeight.w700,
    color: ink.withValues(alpha: 0.78),
  );

  static TextStyle nextStep(Color ground) =>
      AppText.body(size: 13.5, weight: FontWeight.w700, color: ground);

  static TextStyle showAll(Color ink) => AppText.body(
    size: 13.5,
    weight: FontWeight.w600,
    color: ink.withValues(alpha: 0.7),
  );
}

/// How a foot that carries Why this card is set, as the back has room for
/// it ([_Fit.foot]).
enum _FootForm {
  /// Go deeper and the source with the card's whole width, Why this card on
  /// the row beside the save and share under them.
  rows,

  /// Short of room: no row for Why this card alone. It follows the source
  /// on Go deeper's line, and the whole foot keeps to the side of the save
  /// and share, as a foot without it does.
  line,

  /// The last the foot gives before the back would scroll: its two doors
  /// alone beside the save and share. The source is what Go deeper opens
  /// on, one tap away.
  doors,
}

/// The foot a card's back ends on: Go deeper, and where the card's facts
/// come from after it, set the way [sourceFoot] says (source_foot.dart); and,
/// on a card of the day, the way to Why this card beside it (why_sheet.dart).
///
/// Go deeper's part opens it, the room above its words included, so it is a
/// target a thumb finds without the foot taking a line more for it. Where
/// the foot carries Why this card too, its last row is the one the save and
/// share stand in, tall enough to reach past them: what goes above that row
/// has the card's whole width. On a back short of room that row goes first
/// ([_FootForm]).
class _Foot extends StatelessWidget {
  const _Foot({
    super.key,
    required this.pill,
    required this.origin,
    required this.size,
    required this.above,
    required this.corner,
    required this.onTap,
    this.onWhy,
    this.tight = false,
    this.form = _FootForm.rows,
  });

  final Pill pill;

  /// Where the facts come from: the source as the card says it, after its
  /// kind where the card names one ("Study · Johnson, Science, 2019").
  final String origin;

  /// The source's size on this back ([_Fit.source]); the lead's is set
  /// from it.
  final double size;

  /// The room above the words, which is the foot's to be pressed.
  final double above;

  /// The room the save and share take at the foot's right.
  final double corner;
  final VoidCallback onTap;

  /// Opens Why this card; null where there is none to open, on a card that
  /// is not one of the day's.
  final VoidCallback? onWhy;

  /// Whether the back is short of room ([_Fit.tight]): Go deeper's name is
  /// then set at the source's own size, firmer only in weight, so the foot
  /// takes no more lines than the source alone did.
  final bool tight;

  /// How the foot is set where it carries Why this card.
  final _FootForm form;

  /// The way this back sets the foot: the one being tried, but for the
  /// pill, which gives way to the words as a line sets them on a back short
  /// of room ([tight]), a pill taking the room of a line and a half.
  static SourceFoot wayOn({required bool tight}) =>
      tight && sourceFoot == SourceFoot.pill ? SourceFoot.line : sourceFoot;

  /// Whether a foot given [onWhy] carries the way to Why this card: not
  /// where the way being tried says why on the card's front instead
  /// ([SourceFoot.stack]).
  static bool carries(VoidCallback? onWhy) =>
      onWhy != null && sourceFoot != SourceFoot.stack;

  /// The row beside the save and share: as tall as reaches past them (their
  /// marks stand 21 points into the face, the room kept round them 9 more),
  /// its words lifted onto the line their marks sit on.
  static const double row = 32;
  static const double rowLift = 3;
  static double rowFor(double words) =>
      words + rowLift > row ? words + rowLift : row;

  /// Between the lead and the source under it.
  static const double stackGap = 2;

  /// Between the pill and what is beside it, or under it.
  static const double pillGap = 8;
  static const double pillRunGap = 4;

  /// Between the two doors, where they stand alone.
  static const double doorsGap = 10;

  /// Round the words inside a pill.
  static const EdgeInsets pillPad = EdgeInsets.fromLTRB(10, 4, 9, 4.5);

  /// Go deeper's name, a little firmer than the source: the same size on a
  /// line, a size up on a line of its own, and inside the pill.
  static TextStyle lead(Color ink, double size, {bool tight = false}) =>
      AppText.body(
        size: switch (sourceFoot) {
          SourceFoot.line || SourceFoot.pill => tight ? size : size + 1,
          SourceFoot.stack => tight ? size + 1.5 : size + 2.5,
        },
        weight: FontWeight.w700,
        height: 1.3,
        color: ink.withValues(alpha: 0.94),
      );

  /// Why this card's name: a door as Go deeper is, a step quieter; on a
  /// back short of room, at Go deeper's size.
  static TextStyle why(Color ink, double size, {bool tight = false}) =>
      AppText.body(
        size: tight ? size : size + 1,
        weight: FontWeight.w600,
        height: 1.3,
        color: ink.withValues(alpha: 0.8),
      );

  /// The source after it, as quiet as the source always was.
  static TextStyle from(Color ink, double size) => AppText.body(
    size: size,
    weight: FontWeight.w500,
    height: 1.35,
    color: ink.withValues(alpha: 0.6),
  );

  /// [name] with its chevron, which is kept on its line.
  static InlineSpan door(String name, TextStyle style) => TextSpan(
    children: [
      TextSpan(text: name, style: style),
      TextSpan(
        text: '\u00a0\u203a',
        style: style.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  );

  static InlineSpan leadSpan(
    AppLocalizations l,
    Color ink,
    double size, {
    bool tight = false,
  }) => door(l.deeperTitle, lead(ink, size, tight: tight));

  static InlineSpan whySpan(
    AppLocalizations l,
    Color ink,
    double size, {
    bool tight = false,
  }) => door(l.whyTitle, why(ink, size, tight: tight));

  /// The lead and the source run together, on a line.
  static InlineSpan lineSpan(
    AppLocalizations l,
    Color ink,
    double size,
    String origin, {
    bool tight = false,
  }) => TextSpan(
    children: [
      leadSpan(l, ink, size, tight: tight),
      TextSpan(text: '  $origin', style: from(ink, size)),
    ],
  );

  /// Go deeper, the source and Why this card in one paragraph, as a back
  /// short of room sets them ([_FootForm.line]): each door one piece, its
  /// chevron with it and Why this card's words never parted, so a line
  /// breaks only between them. Given [deeperTap] and [whyTap], each door
  /// opens what it names, read out as [deeperLabel] and Why this card.
  static InlineSpan oneLine(
    AppLocalizations l,
    Color ink,
    double size,
    String origin, {
    bool tight = false,
    GestureRecognizer? deeperTap,
    GestureRecognizer? whyTap,
    String? deeperLabel,
  }) {
    const String keep = '\u00a0';
    final TextStyle go = lead(ink, size, tight: tight);
    final TextStyle answer = why(ink, size, tight: tight);
    return TextSpan(
      children: [
        TextSpan(
          text: '${l.deeperTitle}$keep\u203a',
          style: go,
          recognizer: deeperTap,
          semanticsLabel: deeperLabel,
        ),
        // The source is Go deeper's too: a tap on it is taken by the foot
        // round it, and it is read out with Go deeper's name. A year that
        // ends it stays on the line of the word before it.
        TextSpan(
          text:
              '  ${origin.replaceFirstMapped(RegExp(r',\s+(\d{4})$'), (y) => ',$keep${y[1]}')}',
          style: from(ink, size),
          semanticsLabel: deeperLabel == null ? null : '',
        ),
        TextSpan(text: '   ', style: from(ink, size)),
        TextSpan(
          text: '${l.whyTitle.replaceAll(' ', keep)}$keep\u203a',
          style: answer,
          recognizer: whyTap,
          semanticsLabel: deeperLabel == null ? null : l.whyTitle,
        ),
      ],
    );
  }

  /// Where things set side by side as a [Wrap] sets them come to: how tall
  /// the runs they take in [width] are.
  static double wrapHeight(
    List<Size> items,
    double width,
    double spacing,
    double runSpacing,
  ) {
    double line = 0, height = 0, total = 0;
    var first = true;
    for (final Size s in items) {
      if (!first && line + spacing + s.width > width) {
        total += height + runSpacing;
        line = s.width;
        height = s.height;
      } else {
        line += (first ? 0 : spacing) + s.width;
        height = s.height > height ? s.height : height;
      }
      first = false;
    }
    return total + height;
  }

  /// A pill's size round [words].
  static Size pillSize(_Measure m, InlineSpan words) {
    final Size s = m.spanSize(words);
    return Size(s.width + pillPad.horizontal, s.height + pillPad.vertical);
  }

  /// The size words come to in a [Wrap] [width] wide: their own on a line,
  /// the width's where they run onto more.
  static Size wrapped(_Measure m, String words, TextStyle style, double width) {
    final Size one = m.size(words, style);
    return one.width <= width
        ? one
        : Size(width, m.height(words, style, width));
  }

  /// Two pills, side by side where they fit and one over the other where
  /// they do not, as a [Wrap] sets them.
  static double pillsHeight(_Measure m, List<InlineSpan> spans, double width) =>
      wrapHeight(
        [for (final InlineSpan s in spans) pillSize(m, s)],
        width,
        pillGap,
        pillRunGap,
      );

  /// The room the foot takes on a back [width] wide, the room [above] its
  /// words included.
  static double heightFor(
    _Measure m,
    Color ink,
    double size,
    String origin,
    double width,
    double corner,
    double above, {
    required bool why,
    bool tight = false,
    _FootForm form = _FootForm.rows,
  }) {
    final AppLocalizations l = m.l10n;
    final double room = width - corner;
    final SourceFoot way = wayOn(tight: tight);
    if (why && form != _FootForm.rows && way != SourceFoot.stack) {
      final InlineSpan go = leadSpan(l, ink, size, tight: tight);
      final InlineSpan answer = whySpan(l, ink, size, tight: tight);
      return above +
          switch ((way, form)) {
            (SourceFoot.pill, _FootForm.doors) => pillsHeight(m, [
              go,
              answer,
            ], room),
            (SourceFoot.pill, _) => wrapHeight(
              [
                pillSize(m, go),
                pillSize(m, answer),
                wrapped(m, origin, from(ink, size), room),
              ],
              room,
              pillGap,
              pillRunGap,
            ),
            (_, _FootForm.doors) => wrapHeight(
              [m.spanSize(go), m.spanSize(answer)],
              room,
              doorsGap,
              0,
            ),
            _ => m.spanHeight(
              oneLine(l, ink, size, origin, tight: tight),
              room,
            ),
          };
    }
    if (why && way == SourceFoot.line) {
      return above +
          m.spanHeight(lineSpan(l, ink, size, origin, tight: tight), width) +
          rowFor(m.spanHeight(whySpan(l, ink, size), room));
    }
    if (why && way == SourceFoot.pill) {
      return above +
          pillsHeight(m, [
            leadSpan(l, ink, size, tight: tight),
            whySpan(l, ink, size),
          ], width) +
          rowFor(m.height(origin, from(ink, size), room));
    }
    final double words = switch (way) {
      SourceFoot.line => m.spanHeight(
        lineSpan(l, ink, size, origin, tight: tight),
        room,
      ),
      SourceFoot.stack =>
        m.spanHeight(leadSpan(l, ink, size, tight: tight), room) +
            stackGap +
            m.height(origin, from(ink, size), room),
      SourceFoot.pill => () {
        final Size pill = m.spanSize(leadSpan(l, ink, size, tight: tight));
        final double pillW = pill.width + pillPad.horizontal;
        final double pillH = pill.height + pillPad.vertical;
        final Size one = m.size(origin, from(ink, size));
        // Beside the pill where it fits whole, under it where it does not.
        return pillW + pillGap + one.width <= room
            ? (pillH > one.height ? pillH : one.height)
            : pillH + pillRunGap + m.height(origin, from(ink, size), room);
      }(),
    };
    return above + words;
  }

  /// A part of the foot that opens something, read out as [label], and
  /// opened by a reader who cannot see it as by one who can.
  static Widget _press(String label, VoidCallback onTap, Widget child) =>
      Semantics(
        button: true,
        label: label,
        onTap: onTap,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: child,
        ),
      );

  /// The row beside the save and share, [words] on the line their marks
  /// sit on; the whole row, short of the corner, is pressed.
  Widget _row(Widget words, {required VoidCallback onTap, String? label}) {
    final Widget box = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: row),
        child: Align(
          alignment: AlignmentDirectional.bottomStart,
          child: Padding(
            padding: const EdgeInsets.only(bottom: rowLift),
            child: words,
          ),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsetsDirectional.only(end: corner),
      child: label == null
          ? ExcludeSemantics(child: box)
          : Semantics(
              button: true,
              label: label,
              onTap: onTap,
              excludeSemantics: true,
              child: box,
            ),
    );
  }

  /// A pill: filled with the card's wash for Go deeper, outlined for Why
  /// this card. The outline is drawn over the pill, so it takes no room and
  /// the pill is the size [heightFor] counts.
  Widget _pill(InlineSpan words, {required bool filled}) {
    final Color ink = pill.ink;
    final BorderRadius round = BorderRadius.circular(99);
    return Container(
      padding: pillPad,
      decoration: filled
          ? BoxDecoration(
              color: ink.withValues(alpha: 0.11),
              borderRadius: round,
            )
          : null,
      foregroundDecoration: filled
          ? null
          : BoxDecoration(
              border: Border.all(color: ink.withValues(alpha: 0.3)),
              borderRadius: round,
            ),
      child: Text.rich(words),
    );
  }

  /// The foot beside the save and share, the room above its words
  /// included; a tap anywhere on it that is not a door of its own is Go
  /// deeper's. Each door is read out on its own, so the foot round them is
  /// not.
  Widget _beside(Widget words) => Padding(
    padding: EdgeInsetsDirectional.only(end: corner),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      excludeFromSemantics: true,
      child: Padding(
        padding: EdgeInsets.only(top: above),
        child: Align(alignment: AlignmentDirectional.centerStart, child: words),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = context.l10n;
    final Color ink = pill.ink;
    // Read out as what it does and then what it names: the word Source,
    // gone from the card, is said to a reader who cannot see the type.
    final String deeper = l.deeperFootLabel(origin);
    final VoidCallback? onWhy = carries(this.onWhy) ? this.onWhy : null;
    final Key whyKey = ValueKey('card-why-${pill.id}');
    final SourceFoot way = wayOn(tight: tight);

    if (onWhy != null && form != _FootForm.rows) {
      final InlineSpan go = leadSpan(l, ink, size, tight: tight);
      final InlineSpan answer = whySpan(l, ink, size, tight: tight);
      final bool pills = way == SourceFoot.pill;
      if (form == _FootForm.doors) {
        return _beside(
          Wrap(
            spacing: pills ? pillGap : doorsGap,
            runSpacing: pills ? pillRunGap : 0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _press(
                deeper,
                onTap,
                pills ? _pill(go, filled: true) : Text.rich(go),
              ),
              _press(
                l.whyTitle,
                onWhy,
                KeyedSubtree(
                  key: whyKey,
                  child: pills
                      ? _pill(answer, filled: false)
                      : Text.rich(answer),
                ),
              ),
            ],
          ),
        );
      }
      if (pills) {
        return _beside(
          Wrap(
            spacing: pillGap,
            runSpacing: pillRunGap,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _press(deeper, onTap, _pill(go, filled: true)),
              _press(
                l.whyTitle,
                onWhy,
                KeyedSubtree(key: whyKey, child: _pill(answer, filled: false)),
              ),
              ExcludeSemantics(child: Text(origin, style: from(ink, size))),
            ],
          ),
        );
      }
      return _beside(
        _OneLine(
          key: ValueKey('card-foot-line-${pill.id}'),
          span: (deeperTap, whyTap) => oneLine(
            l,
            ink,
            size,
            origin,
            tight: tight,
            deeperTap: deeperTap,
            whyTap: whyTap,
            deeperLabel: deeper,
          ),
          onDeeper: onTap,
          onWhy: onWhy,
        ),
      );
    }

    if (onWhy != null && way == SourceFoot.line) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _press(
            deeper,
            onTap,
            Padding(
              padding: EdgeInsets.only(top: above),
              child: Text.rich(lineSpan(l, ink, size, origin, tight: tight)),
            ),
          ),
          _row(
            Text.rich(key: whyKey, whySpan(l, ink, size)),
            onTap: onWhy,
            label: l.whyTitle,
          ),
        ],
      );
    }
    if (onWhy != null && way == SourceFoot.pill) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(top: above),
            child: Wrap(
              spacing: pillGap,
              runSpacing: pillRunGap,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _press(
                  deeper,
                  onTap,
                  _pill(leadSpan(l, ink, size, tight: tight), filled: true),
                ),
                _press(
                  l.whyTitle,
                  onWhy,
                  KeyedSubtree(
                    key: whyKey,
                    child: _pill(whySpan(l, ink, size), filled: false),
                  ),
                ),
              ],
            ),
          ),
          // The source under them is Go deeper's too, and read out with it.
          _row(Text(origin, style: from(ink, size)), onTap: onTap),
        ],
      );
    }
    final Widget words = switch (way) {
      SourceFoot.line => Text.rich(
        lineSpan(l, ink, size, origin, tight: tight),
      ),
      SourceFoot.stack => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(leadSpan(l, ink, size, tight: tight)),
          const SizedBox(height: stackGap),
          Text(origin, style: from(ink, size)),
        ],
      ),
      SourceFoot.pill => Wrap(
        spacing: pillGap,
        runSpacing: pillRunGap,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _pill(leadSpan(l, ink, size, tight: tight), filled: true),
          Text(origin, style: from(ink, size)),
        ],
      ),
    };
    return Padding(
      padding: EdgeInsetsDirectional.only(end: corner),
      child: _press(
        deeper,
        onTap,
        Padding(
          padding: EdgeInsets.only(top: above),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: words,
          ),
        ),
      ),
    );
  }
}

/// The foot's one paragraph on a back short of room ([_FootForm.line]),
/// which keeps the taps its two doors take for as long as it is shown.
class _OneLine extends StatefulWidget {
  const _OneLine({
    super.key,
    required this.span,
    required this.onDeeper,
    required this.onWhy,
  });

  final InlineSpan Function(
    GestureRecognizer deeperTap,
    GestureRecognizer whyTap,
  )
  span;
  final VoidCallback onDeeper;
  final VoidCallback onWhy;

  @override
  State<_OneLine> createState() => _OneLineState();
}

class _OneLineState extends State<_OneLine> {
  late final TapGestureRecognizer _deeper = TapGestureRecognizer()
    ..onTap = () => widget.onDeeper();
  late final TapGestureRecognizer _why = TapGestureRecognizer()
    ..onTap = () => widget.onWhy();

  @override
  void dispose() {
    _deeper.dispose();
    _why.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text.rich(widget.span(_deeper, _why));
}

/// "Report a problem", under the source it would be checked against; once
/// this phone has reported the card, a quiet line saying so instead.
class _ReportLine extends StatefulWidget {
  final Pill pill;
  final Color ink;
  const _ReportLine({required this.pill, required this.ink});

  @override
  State<_ReportLine> createState() => _ReportLineState();
}

class _ReportLineState extends State<_ReportLine> {
  @override
  void initState() {
    super.initState();
    Reports.instance.load();
  }

  Future<void> _open() async {
    final bool? sent = await showReportSheet(context, widget.pill);
    if (sent != true || !mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(context.l10n.reportSentToast),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String id = widget.pill.id;
    return ListenableBuilder(
      listenable: Reports.instance,
      builder: (context, _) {
        if (!Reports.instance.has(id)) {
          return _TextAction(
            key: ValueKey('report-$id'),
            ink: widget.ink,
            icon: Icons.outlined_flag_rounded,
            label: context.l10n.reportProblem,
            onTap: _open,
          );
        }
        return Row(
          key: ValueKey('reported-$id'),
          children: [
            Icon(
              Icons.check_rounded,
              size: 16,
              color: widget.ink.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                context.l10n.reportedThanks,
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w500,
                  color: widget.ink.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The solution, one move at a time: the first step is shown, and each tap
/// brings the next one in under it, joined by a line, so a derivation is
/// followed rather than skimmed. "Show all" is there for the reader who
/// would rather see it whole.
class _Steps extends StatefulWidget {
  final Pill pill;
  final Color ink;
  final bool stepByStep;

  /// How each step is set, and the room between one step and the next.
  final TextStyle style;
  final double gap;

  const _Steps({
    super.key,
    required this.pill,
    required this.ink,
    required this.stepByStep,
    required this.style,
    required this.gap,
  });

  /// The room the steps take at [width] with the first [shown] of them out,
  /// and the buttons under them while some are still to come.
  static double heightFor({
    required List<String> steps,
    required int shown,
    required TextStyle style,
    required double gap,
    required double width,
    required _Measure m,
  }) {
    var h = 0.0;
    for (var i = 0; i < shown && i < steps.length; i++) {
      final text = m.height(steps[i], style, width - 38);
      final pad = 1 + (i == shown - 1 ? 0 : gap);
      h += text + pad > 22 ? text + pad : 22;
    }
    if (shown < steps.length) {
      final next = m.size(
        '${m.l10n.nextStep}  ${steps.length}/${steps.length}',
        _Type.nextStep(const Color(0xFF000000)),
      );
      final all = m.size(
        m.l10n.showAllSteps,
        _Type.showAll(const Color(0xFF000000)),
      );
      final pill = Size(next.width + 32, next.height + 20);
      h += 14;
      h += pill.width + 14 + all.width <= width
          ? (pill.height > all.height ? pill.height : all.height)
          : pill.height + 8 + all.height;
    }
    return h;
  }

  @override
  State<_Steps> createState() => _StepsState();
}

class _StepsState extends State<_Steps> {
  late int _shown = widget.stepByStep ? 1 : widget.pill.steps.length;

  @override
  Widget build(BuildContext context) {
    final steps = widget.pill.steps;
    final ink = widget.ink;
    final all = _shown >= steps.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _shown && i < steps.length; i++)
          RiseIn(
            key: ValueKey('step-$i'),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 30,
                    child: Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i == _shown - 1 && !all
                                ? ink
                                : ink.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: AppText.label(
                              size: 10.5,
                              spacing: 0,
                              color: i == _shown - 1 && !all
                                  ? widget.pill.color
                                  : ink.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                        if (i < _shown - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              color: ink.withValues(alpha: 0.2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 1,
                        bottom: i == _shown - 1 ? 0 : widget.gap,
                      ),
                      child: Text(steps[i], style: widget.style),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!all) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                button: true,
                child: GestureDetector(
                  key: const ValueKey('next-step'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _shown++),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${context.l10n.nextStep}  ${_shown + 1}/${steps.length}',
                      style: _Type.nextStep(widget.pill.color),
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                child: GestureDetector(
                  key: const ValueKey('all-steps'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _shown = steps.length),
                  child: Text(
                    context.l10n.showAllSteps,
                    style: _Type.showAll(ink),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A labelled panel — the shape the bar move, a retelling and a counterpoint
/// all take.
class _Panel extends StatelessWidget {
  final String label;
  final String body;
  final Color ink;
  final Color wash;

  /// How the body is set; the page's regular 14 when not given.
  final TextStyle? style;

  /// Drawn a little closer around its words, on a card short of room.
  final bool tight;

  const _Panel({
    required this.label,
    required this.body,
    required this.ink,
    required this.wash,
    this.style,
    this.tight = false,
  });

  static EdgeInsets _padding(bool tight) => tight
      ? const EdgeInsets.fromLTRB(14, 10, 14, 11)
      : const EdgeInsets.fromLTRB(15, 12, 15, 13);
  static double _gap(bool tight) => tight ? 4 : 6;

  static double heightFor(
    String label,
    String body,
    TextStyle style,
    double width,
    _Measure m, {
    bool tight = false,
  }) {
    final pad = _padding(tight);
    return pad.vertical +
        m.height(
          label,
          _Type.panelLabel(const Color(0xFF000000)),
          width - pad.horizontal,
        ) +
        _gap(tight) +
        m.height(body, style, width - pad.horizontal);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: _padding(tight),
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _Type.panelLabel(ink)),
          SizedBox(height: _gap(tight)),
          Text(body, style: style ?? _Type.panelBody(ink, 14)),
        ],
      ),
    );
  }
}

/// The closed state of one of those panels: an icon and a line to tap.
class _TextAction extends StatelessWidget {
  final Color ink;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;

  const _TextAction({
    super.key,
    required this.ink,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 13,
  });

  /// Padded above and below so the line is a target a thumb can find, not
  /// just the height of its letters.
  static const double _pad = 7;

  static double heightFor(String label, double size, double width, _Measure m) {
    final text = m.height(
      label,
      _Type.action(const Color(0xFF000000), size),
      width - 23,
    );
    return 2 * _pad + (text > 16 ? text : 16);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _pad),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(icon, size: 16, color: ink.withValues(alpha: 0.65)),
              ),
              const SizedBox(width: 7),
              Flexible(child: Text(label, style: _Type.action(ink, size))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Text measured the way it will be set: same styles, same width, and the
/// reader's own text size.
class _Measure {
  _Measure(BuildContext context)
    : scaler = MediaQuery.textScalerOf(context),
      l10n = context.l10n,
      _base = DefaultTextStyle.of(context),
      _direction = Directionality.of(context);
  final TextScaler scaler;
  final AppLocalizations l10n;

  /// What a [Text] merges its own style onto, which carries the theme's
  /// tracking: measured without it, a line breaks a word later than it is
  /// set and the plan comes up a line short.
  final DefaultTextStyle _base;
  final TextDirection _direction;

  TextPainter _lay(String text, TextStyle style, double width) => TextPainter(
    text: TextSpan(text: text, style: _base.style.merge(style)),
    textDirection: _direction,
    textScaler: scaler,
    textHeightBehavior: _base.textHeightBehavior,
  )..layout(maxWidth: width);

  double height(String text, TextStyle style, double width) {
    final p = _lay(text, style, width);
    final h = p.height;
    p.dispose();
    return h;
  }

  double spanHeight(InlineSpan span, double width) {
    final p = TextPainter(
      text: TextSpan(style: _base.style, children: [span]),
      textDirection: _direction,
      textScaler: scaler,
      textHeightBehavior: _base.textHeightBehavior,
    )..layout(maxWidth: width);
    final h = p.height;
    p.dispose();
    return h;
  }

  Size size(String text, TextStyle style) {
    final p = _lay(text, style, double.infinity);
    final s = p.size;
    p.dispose();
    return s;
  }

  /// How wide and tall [span] sets on one line.
  Size spanSize(InlineSpan span) {
    final p = TextPainter(
      text: TextSpan(style: _base.style, children: [span]),
      textDirection: _direction,
      textScaler: scaler,
      textHeightBehavior: _base.textHeightBehavior,
    )..layout();
    final s = p.size;
    p.dispose();
    return s;
  }
}

/// The sizes one back of a card is set at.
class _Fit {
  const _Fit({
    required this.question,
    required this.questionSize,
    required this.body,
    required this.gap,
    required this.scene,
    this.tucked = false,
    this.tuckSteps = false,
    this.pictureScale = 1,
    this.shortLead = false,
    this.leastLead = false,
    this.scrolls = false,
    this.foot = _FootForm.rows,
  });

  /// Whether the question is printed again above the answer. It is the
  /// first thing to go: the reader turned the card over a second ago and
  /// the question was the whole of the front.
  final bool question;
  final double questionSize;

  /// The answer's size; everything smaller follows from it.
  final double body;

  /// The room between blocks, as a share of the full spacing.
  final double gap;

  /// The scene's band, on a card that asked before it played.
  final double scene;

  /// True when the picture — a diagram, a scene — does not fit beside the
  /// words and waits behind a line to tap, taking the answer's place when
  /// it is opened rather than pushing the card's foot off the screen.
  final bool tucked;

  /// True when a worked solution does not fit under the verdict: the
  /// answer's last line is shown, and the working waits behind a line to
  /// tap, the way the picture does.
  final bool tuckSteps;

  /// The diagram drawn a little smaller, kept whole and upright, when even
  /// on its own it is taller than the card can give it. Only ever a step
  /// or two below full size.
  final double pictureScale;

  /// The reader's own line said in one paragraph rather than three.
  final bool shortLead;

  /// The lead said in as few words as it has: a verdict alone.
  final bool leastLead;

  /// True when even the tightest setting does not fit — only at a large
  /// text size — and the back scrolls rather than shrink the reader's type.
  final bool scrolls;

  /// How the foot is set where it carries Why this card: on its own row,
  /// or, short of room, without one ([_FootForm]).
  final _FootForm foot;

  bool get tight => gap < 1;
  bool get tightest => gap < 0.7;
  double get step => body - 0.5;
  double get small => (body * 0.84).clamp(12.5, 15.5);
  double get keep => tightest ? 13 : (body * 0.9).clamp(13.5, 17);
  double get source => tight ? 10.5 : 11.5;

  _Fit copyWith({
    double? questionSize,
    double? scene,
    bool? scrolls,
    _FootForm? foot,
  }) => _Fit(
    question: question,
    questionSize: questionSize ?? this.questionSize,
    body: body,
    gap: gap,
    scene: scene ?? this.scene,
    tucked: tucked,
    tuckSteps: tuckSteps,
    pictureScale: pictureScale,
    shortLead: shortLead,
    leastLead: leastLead,
    scrolls: scrolls ?? this.scrolls,
    foot: foot ?? this.foot,
  );
}

/// One piece of the back: what it is, and the room it takes. A null child
/// is the give — the space between the reading and the box at the foot.
class _Block {
  const _Block(this.height, [this.child]);
  final double height;
  final Widget? child;
}

/// Everything a card says once it is turned over, set to fit the card.
///
/// The back is one screen, like the front (docs/cards/STILE.md: "Niente
/// scroll"). So rather than a column in a scroll view it is planned: every
/// block is measured at the width it will have, with the reader's text
/// size, and the sizes are chosen to fill the card without running off it.
/// In order of what gives first: the question repeated from the front is
/// dropped, the type steps down within a band that stays comfortable to
/// read, the spacing tightens, and a picture that still does not fit
/// waits behind a line to tap. Whatever room is left goes to the scene,
/// then to the question, then sits between the reading and the box at the
/// foot, which is always at the bottom of the card. Only when none of that
/// fits — a very large text size — does the back scroll, at full size,
/// because shrinking type the reader asked to be large is not fitting it.
class CardReveal extends StatefulWidget {
  final Pill pill;

  /// What the reader committed to, set above everything else, and the room
  /// it takes at a width.
  final Widget? lead;
  final double Function(double width, TextScaler scaler)? leadHeight;

  /// The same, said in fewer lines, for a back that is short of room.
  final Widget? shortLead;
  final double Function(double width, TextScaler scaler)? shortLeadHeight;

  /// Fewer still, for a back too short of room even for that.
  final Widget? leastLead;
  final double Function(double width, TextScaler scaler)? leastLeadHeight;

  /// Keeps the source's lines clear of the save and share buttons in the
  /// bottom corner.
  final double cornerRoom;

  /// The scene, on a card that asked first and plays it with the answer.
  final Widget Function(double height)? scene;

  /// Opens Why this card (why_sheet.dart), from the foot beside Go deeper;
  /// null on a card that is not one of the day's, which has none.
  final VoidCallback? onWhy;

  const CardReveal({
    super.key,
    required this.pill,
    this.lead,
    this.leadHeight,
    this.shortLead,
    this.shortLeadHeight,
    this.leastLead,
    this.leastLeadHeight,
    this.cornerRoom = 0,
    this.scene,
    this.onWhy,
  });

  /// The answer's band. At most a fifteenth of the measure — about forty
  /// characters to the line, as large as body text reads well — between
  /// eighteen on a small phone and twenty-one on a large one; fourteen is as
  /// small as it should go for a reader at an ordinary text size.
  static double maxBody(double width) => (width / 15).clamp(18, 21);
  static const double minBody = 14;

  /// The question comes back only if the answer can still be set at this.
  static const double minBodyWithQuestion = 15.5;

  /// The scene's band beside the words, and on its own once opened. Below
  /// the least of it a scene's own controls no longer have room.
  static const double sceneMin = 250;
  static const double sceneMax = 270;
  static const double sceneOpenMax = 330;

  @override
  State<CardReveal> createState() => _CardRevealState();
}

/// What the back can show in the answer's place, one at a time.
enum _Aside { none, scene, picture, working, simply, counter }

class _CardRevealState extends State<CardReveal> {
  /// A tap on the foot: Go deeper (deeper_sheet.dart).
  void _deeper() {
    CardRead.of(context)?.opened('deeper');
    GoDeeper.open?.call(context, widget.pill);
  }

  /// What is open in the answer's place. A retelling or the other side's
  /// case is read instead of the answer, not under it: under it, a card
  /// that fitted would run off the screen the moment it was opened.
  _Aside _aside = _Aside.none;

  bool get _hasPicture => widget.scene != null || widget.pill.diagram != null;

  /// Every state the reader can reach on this card.
  List<_Aside> _asides(_Fit f) => [
    _Aside.none,
    if (f.tucked && widget.scene != null) _Aside.scene,
    if (f.tucked && widget.pill.diagram != null) _Aside.picture,
    if (f.tuckSteps) _Aside.working,
    if (widget.pill.hasSimply) _Aside.simply,
    if (widget.pill.hasCounterpoint) _Aside.counter,
  ];

  void _open(_Aside aside) {
    // Went further than the answer: what was opened is how deep the back
    // was read.
    if (aside != _Aside.none) CardRead.of(context)?.opened(aside.name);
    setState(() => _aside = aside);
  }

  List<_Block> _blocks(
    _Fit f,
    double width,
    _Measure m, {
    required _Aside aside,
  }) {
    final pill = widget.pill;
    final l10n = m.l10n;
    final ink = pill.ink;
    final g = f.gap;
    final out = <_Block>[_Block(8 * g, SizedBox(height: 8 * g))];
    void gap(double h) => out.add(_Block(h * g, SizedBox(height: h * g)));

    // A picture opened in the answer's place has the card to itself; the
    // verdict above it was read on the way in.
    // The working, too: the verdict and its ruler were read on the way
    // in, and the steps need the card.
    final visual =
        aside == _Aside.scene ||
        aside == _Aside.picture ||
        aside == _Aside.working;
    if (widget.lead != null && !visual) {
      final least = f.leastLead && widget.leastLead != null;
      final short = !least && f.shortLead && widget.shortLead != null;
      out.add(
        _Block(
          least
              ? widget.leastLeadHeight!(width, m.scaler)
              : short
              ? widget.shortLeadHeight!(width, m.scaler)
              : widget.leadHeight!(width, m.scaler),
          KeyedSubtree(
            key: const ValueKey('lead'),
            child: least
                ? widget.leastLead!
                : short
                ? widget.shortLead!
                : widget.lead!,
          ),
        ),
      );
      gap(14);
    }
    if (f.question) {
      final style = _Type.question(ink, f.questionSize);
      out.add(
        _Block(
          m.height(pill.question, style, width),
          Text(pill.question, style: style),
        ),
      );
      gap(14);
    }

    _Block action(
      String label,
      IconData icon,
      VoidCallback onTap, {
      Key? key,
    }) => _Block(
      _TextAction.heightFor(label, f.small, width, m),
      _TextAction(
        key: key,
        ink: ink,
        icon: icon,
        label: label,
        size: f.small,
        onTap: onTap,
      ),
    );

    final words = aside == _Aside.none;
    final inline = words && !f.tucked;

    if (widget.scene != null && (inline || aside == _Aside.scene)) {
      out.add(
        _Block(
          f.scene,
          KeyedSubtree(
            key: const ValueKey('scene'),
            child: widget.scene!(f.scene),
          ),
        ),
      );
      if (words) gap(16);
    }
    _Block steps() {
      final style = _Type.step(ink, f.step);
      double at(int shown) => _Steps.heightFor(
        steps: pill.steps,
        shown: shown,
        style: style,
        gap: 12 * g,
        width: width,
        m: m,
      );
      final first = at(1);
      final whole = at(pill.steps.length);
      return _Block(
        first > whole ? first : whole,
        _Steps(
          key: const ValueKey('steps'),
          pill: pill,
          ink: ink,
          stepByStep: true,
          style: style,
          gap: 12 * g,
        ),
      );
    }

    if (words) {
      if (pill.hasSteps && !f.tuckSteps) {
        out.add(steps());
      } else {
        final style = _Type.answer(ink, f.body);
        out.add(
          _Block(
            m.height(pill.answer, style, width),
            Text(pill.answer, style: style),
          ),
        );
      }
    }
    if (aside == _Aside.working) out.add(steps());
    if (pill.diagram != null && (inline || aside == _Aside.picture)) {
      if (words) gap(16);
      out.add(
        _Block(
          DiagramView.heightFor(
            pill.diagram!,
            width,
            m.scaler,
            ink: ink,
            base: m._base.style,
          ),
          DiagramView(
            key: const ValueKey('diagram'),
            diagram: pill.diagram!,
            ink: ink,
          ),
        ),
      );
      if (f.pictureScale < 1) {
        // Drawn at its full size and set down smaller as a whole, so its
        // words shrink with it and stay where the drawing put them.
        final full = out.removeLast();
        out.add(
          _Block(
            full.height * f.pictureScale,
            SizedBox(
              height: full.height * f.pictureScale,
              child: FittedBox(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  height: full.height,
                  child: full.child,
                ),
              ),
            ),
          ),
        );
      }
    }
    // A retelling or the other side's case, in the answer's place and set
    // like it: the same size, under a label saying whose words they are.
    if (aside == _Aside.simply || aside == _Aside.counter) {
      final caps = aside == _Aside.simply
          ? l10n.putSimplyCaps
          : l10n.whatTheOtherSideSaysCaps;
      final body = aside == _Aside.simply ? pill.simply : pill.counterpoint;
      // The label runs in ahead of the words, as a speaker's name does in
      // a script: it says whose case this is without a line of its own.
      final span = TextSpan(
        children: [
          TextSpan(text: '$caps  ', style: _Type.panelLabel(ink)),
          TextSpan(text: body, style: _Type.answer(ink, f.body)),
        ],
      );
      out.add(
        _Block(
          m.spanHeight(span, width),
          Text.rich(span, key: ValueKey(aside)),
        ),
      );
    }
    if (words) {
      // The trap belongs to the explanation, so it follows it straight
      // away, before anything the reader can choose to open.
      if (pill.asksSomething && pill.trap.isNotEmpty) {
        gap(12);
        final text = l10n.theTrap(pill.trap);
        final style = _Type.trap(ink, f.small);
        out.add(_Block(m.height(text, style, width), Text(text, style: style)));
      }
      if (f.tucked && widget.scene != null) {
        gap(6);
        out.add(
          action(
            l10n.revealPlayScene,
            Icons.play_circle_outline_rounded,
            () => _open(_Aside.scene),
            key: const ValueKey('scene-toggle'),
          ),
        );
      }
      if (f.tuckSteps) {
        gap(6);
        out.add(
          action(
            l10n.revealShowWorking,
            Icons.format_list_numbered_rounded,
            () => _open(_Aside.working),
            key: const ValueKey('working-toggle'),
          ),
        );
      }
      if (f.tucked && pill.diagram != null) {
        gap(6);
        out.add(
          action(
            l10n.revealSeePicture,
            Icons.insert_chart_outlined_rounded,
            () => _open(_Aside.picture),
            key: const ValueKey('picture-toggle'),
          ),
        );
      }
      if (pill.hasSimply) {
        gap(6);
        out.add(
          action(
            l10n.explainLikeImThree,
            Icons.child_care_rounded,
            () => _open(_Aside.simply),
          ),
        );
      }
      if (pill.hasCounterpoint) {
        gap(6);
        out.add(
          action(
            l10n.whatTheOtherSideSays,
            Icons.swap_horiz_rounded,
            () => _open(_Aside.counter),
          ),
        );
      }
    } else {
      gap(visual ? 10 : 6);
      out.add(
        action(
          l10n.revealBackToAnswer,
          Icons.notes_rounded,
          () => _open(_Aside.none),
          key: const ValueKey('back-to-answer'),
        ),
      );
    }

    // The give, then the box the card ends on, pinned to the foot.
    out.add(_Block(16 * g));
    // Where in a life the card pays off, when it is one of an area's own
    // (data/goals.dart): "Useful for: Money and shopping", over the box to
    // keep, so the thing to keep has its place to be used. With the answer
    // only, and the first thing to give on a card short of room.
    final Goal? area = aside == _Aside.none && !f.tight
        ? Goal.bestFor(pill)
        : null;
    if (area != null) {
      final String use = l10n.goalShelf(goalName(l10n, area));
      final TextStyle style = _Type.useful(ink, f.source);
      final double mark = f.source + 2;
      out.add(
        _Block(
          m.height(use, style, width - mark - 6),
          Row(
            key: const ValueKey('card-useful'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  goalIcon(area),
                  size: mark,
                  color: ink.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(use, style: style)),
            ],
          ),
        ),
      );
      gap(8);
    }
    final keep = _Type.keep(ink, f.keep);
    if (pill.showsMove) {
      out.add(
        _Block(
          _Panel.heightFor(
            l10n.barMoveCaps,
            pill.barMove,
            keep,
            width,
            m,
            tight: f.tight,
          ),
          _Panel(
            label: l10n.barMoveCaps,
            body: pill.barMove,
            ink: ink,
            wash: pill.wash,
            style: keep,
            tight: f.tight,
          ),
        ),
      );
    }
    if (pill.showsAsk) {
      if (pill.showsMove) gap(8);
      // Beside a box to keep, the question is the second voice, so it is
      // set as the panel body rather than in bold.
      final style = pill.showsMove ? _Type.panelBody(ink, f.small) : keep;
      out.add(
        _Block(
          _Panel.heightFor(
            l10n.askYourselfCaps,
            pill.ask,
            style,
            width,
            m,
            tight: f.tight,
          ),
          _Panel(
            label: l10n.askYourselfCaps,
            body: pill.ask,
            ink: ink,
            wash: pill.wash,
            style: style,
            tight: f.tight,
          ),
        ),
      );
    }
    // The foot: Go deeper, and where the facts come from after it, with no
    // word Source before them (source_foot.dart). What kind of source it is
    // stays, where the card says: a study, a book, an institution, the data
    // itself. A reader weighs "Study · Nature" and "Book · Kahneman"
    // differently, and should be able to. The flag that reported the card
    // used to ride at the end of this line; it is off the card's face now,
    // in Go deeper or the share sheet, which a drawn card reaches too. On a
    // card of the day, Why this card is beside Go deeper here.
    // At the tightest, the kind gives way, so Go deeper's name costs the
    // back no line the source alone did not take.
    final String? kind = f.tightest
        ? null
        : sourceKindName(l10n, pill.sourceKind);
    final String origin = kind == null
        ? pill.sourceShort
        : l10n.sourceLabelKind(kind, pill.sourceShort);
    out.add(
      _Block(
        _Foot.heightFor(
          m,
          ink,
          f.source,
          origin,
          width,
          widget.cornerRoom,
          10 * g,
          why: _Foot.carries(widget.onWhy),
          tight: f.tight,
          form: f.foot,
        ),
        _Foot(
          key: ValueKey('card-foot-${pill.id}'),
          pill: pill,
          origin: origin,
          size: f.source,
          above: 10 * g,
          corner: widget.cornerRoom,
          onTap: _deeper,
          onWhy: widget.onWhy,
          tight: f.tight,
          form: f.foot,
        ),
      ),
    );
    return out;
  }

  double _total(List<_Block> blocks) =>
      blocks.fold(0.0, (sum, b) => sum + b.height);

  /// The sizes for the state the back is in. Each state is planned on its
  /// own: opening the other side's case re-sets the card for what is now on
  /// it, rather than every state being set as small as the longest needs.
  _Fit _choose(double width, double height, _Measure m, _Aside aside) {
    final hasScene = widget.scene != null;
    // A point spare, so a rounding in layout never tips a fit over.
    final room = height - 1;
    double need(_Fit f) => _total(_blocks(f, width, m, aside: aside));
    bool fits(_Fit f) => need(f) <= room;

    _Fit grow(_Fit f) {
      if (hasScene) {
        final scene = (f.scene + room - need(f)).clamp(
          CardReveal.sceneMin,
          f.tucked ? CardReveal.sceneOpenMax : CardReveal.sceneMax,
        );
        f = f.copyWith(scene: scene);
      }
      // A short answer leaves room the question can use: it grows toward
      // the size it had on the front, so the back is not a field of colour.
      final maxQuestion = (width / 12).clamp(22.0, 28.0);
      while (f.question && f.questionSize + 1 <= maxQuestion) {
        final bigger = f.copyWith(questionSize: f.questionSize + 1);
        if (!fits(bigger)) break;
        f = bigger;
      }
      return f;
    }

    _Fit at(
      double body, {
      required bool question,
      double gap = 1,
      bool tucked = false,
      bool tuckSteps = false,
      double pictureScale = 1,
      bool shortLead = false,
      bool leastLead = false,
    }) => _Fit(
      question: question,
      questionSize: 17,
      body: body,
      gap: gap,
      scene: CardReveal.sceneMin,
      tucked: tucked,
      tuckSteps: tuckSteps,
      pictureScale: pictureScale,
      shortLead: shortLead,
      leastLead: leastLead,
    );

    Iterable<double> band(double from, double to) sync* {
      for (var b = from; b >= to - 0.01; b -= 0.5) {
        yield b;
      }
    }

    final visual = aside == _Aside.picture || aside == _Aside.scene;
    final tucks = visual ? const [true] : [false, if (_hasPicture) true];
    final stepsTucks = aside == _Aside.working
        ? const [true]
        : [false, if (widget.pill.hasSteps) true];

    // Every size, from the largest down, for one way of setting the back.
    Iterable<_Fit> sizes({
      required bool tuckSteps,
      bool shortLead = false,
    }) sync* {
      for (final tucked in tucks) {
        for (final b in band(
          CardReveal.maxBody(width),
          CardReveal.minBodyWithQuestion,
        )) {
          yield at(
            b,
            question: true,
            tucked: tucked,
            tuckSteps: tuckSteps,
            shortLead: shortLead,
          );
        }
        for (final b in band(
          CardReveal.maxBody(width),
          CardReveal.minBody + 0.5,
        )) {
          yield at(
            b,
            question: false,
            tucked: tucked,
            tuckSteps: tuckSteps,
            shortLead: shortLead,
          );
        }
        for (final b in band(15, CardReveal.minBody)) {
          yield at(
            b,
            question: false,
            gap: 0.75,
            tucked: tucked,
            tuckSteps: tuckSteps,
            shortLead: shortLead,
          );
        }
        // The last half point, with the spacing at its closest: still a
        // comfortable size on a phone, and better than a card that
        // scrolls.
        for (final gap in [0.75, 0.6]) {
          yield at(
            CardReveal.minBody - 0.5,
            question: false,
            gap: gap,
            tucked: tucked,
            tuckSteps: tuckSteps,
            shortLead: shortLead,
          );
        }
      }
    }

    // Everything in its place first; then the working, then the picture,
    // behind a line to tap — each only when the words would otherwise go
    // below a comfortable size.
    Iterable<_Fit> plans() sync* {
      for (final tuckSteps in stepsTucks) {
        yield* sizes(tuckSteps: tuckSteps);
        // A card with working to show gives up the lead's extra lines
        // before it gives up the working: the verdict, still as large, and
        // the steps in view, rather than the steps behind a line to tap so
        // that what the reader typed a moment ago can be said back to them.
        if (!tuckSteps && stepsTucks.length > 1 && widget.shortLead != null) {
          yield* sizes(tuckSteps: false, shortLead: true);
        }
      }
      // The longest cards in the bank, at thirteen: a footnote's size, and
      // still read without effort at a phone's distance.
      yield at(
        13,
        question: false,
        gap: 0.6,
        tucked: tucks.last,
        tuckSteps: stepsTucks.last,
      );
      // Then the reader's line, run together into one paragraph.
      if (widget.shortLead != null) {
        // The other side's case on the longest debates may go half a point
        // further: it is read once, and the reader's own line has to stay
        // in view beside it — that is the whole point of having asked.
        final least = aside == _Aside.counter ? 12.5 : 13.0;
        for (final b in band(15, least)) {
          yield at(
            b,
            question: false,
            gap: b > 14 ? 0.75 : 0.6,
            tucked: tucks.last,
            tuckSteps: stepsTucks.last,
            shortLead: true,
          );
        }
      }
      // Then the lead in as few words as it has.
      if (widget.leastLead != null) {
        for (final b in band(15, 13)) {
          yield at(
            b,
            question: false,
            gap: b > 14 ? 0.75 : 0.6,
            tucked: tucks.last,
            tuckSteps: stepsTucks.last,
            leastLead: true,
          );
        }
      }
      if (aside == _Aside.picture) {
        for (final scale in [0.92, 0.85, 0.8]) {
          yield at(
            13,
            question: false,
            gap: 0.6,
            tucked: true,
            pictureScale: scale,
          );
        }
      }
    }

    // Why this card's row is the first thing the foot gives, and only once
    // the back is short of room: at each setting from there, the foot is
    // tried with it and then without it.
    final bool why = _Foot.carries(widget.onWhy);
    for (final f in plans()) {
      if (fits(f)) return grow(f);
      if (why && f.tight) {
        final line = f.copyWith(foot: _FootForm.line);
        if (fits(line)) return grow(line);
      }
    }
    // The last thing it gives, before the back would scroll: the source's
    // words, so the two doors stand alone. Go deeper opens on the source.
    if (why) {
      for (final f in plans()) {
        if (!f.tightest) continue;
        final doors = f.copyWith(foot: _FootForm.doors);
        if (fits(doors)) return grow(doors);
      }
    }
    return at(
      CardReveal.minBody,
      question: false,
      tucked: tucks.last,
      tuckSteps: stepsTucks.last,
    ).copyWith(scrolls: true);
  }

  @override
  Widget build(BuildContext context) {
    final m = _Measure(context);
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        var aside = _aside;
        var fit = _choose(width, box.maxHeight, m, aside);
        if (!_asides(fit).contains(aside)) {
          aside = _Aside.none;
          fit = _choose(width, box.maxHeight, m, aside);
        }
        final blocks = _blocks(fit, width, m, aside: aside);
        final children = [
          for (final b in blocks)
            if (b.child != null)
              b.child!
            else if (fit.scrolls)
              SizedBox(height: b.height)
            else
              Expanded(child: SizedBox(height: b.height)),
        ];
        // How much of the back has been in sight: all of it, on a back
        // that fits, as nearly every one does.
        CardRead.of(context)?.backLaidOut(scrolls: fit.scrolls);
        if (!fit.scrolls) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          );
        }
        void seen(ScrollMetrics metrics) {
          final double? share = seenOf(metrics);
          if (share != null) CardRead.of(context)?.backSeen(share);
        }

        return NotificationListener<ScrollMetricsNotification>(
          onNotification: (note) {
            seen(note.metrics);
            return false;
          },
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: (note) {
              seen(note.metrics);
              return false;
            },
            child: SingleChildScrollView(
              child: Padding(
                // Room to scroll the last line clear of the buttons in the
                // corner.
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A tap on a card's source: Go deeper (deeper_sheet.dart), where the app
/// has said where that goes.
class _SourceTap extends StatelessWidget {
  const _SourceTap({required this.pill, required this.child});

  final Pill pill;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: ValueKey('card-source-${pill.id}'),
    behavior: HitTestBehavior.opaque,
    onTap: () => GoDeeper.open?.call(context, pill),
    child: child,
  );
}

/// The kind of a card's source as the reader reads it, or null when the
/// card does not say or says what this build does not know.
String? sourceKindName(AppLocalizations l, String kind) => switch (kind) {
  'paper' => l.sourceKindPaper,
  'book' => l.sourceKindBook,
  'institution' => l.sourceKindInstitution,
  'primary_document' => l.sourceKindDocument,
  'statistics' => l.sourceKindData,
  'reference_work' => l.sourceKindReference,
  'news_archive' => l.sourceKindNews,
  'company' => l.sourceKindCompany,
  'standard' => l.sourceKindStandard,
  'arithmetic' => l.sourceKindArithmetic,
  _ => null,
};
