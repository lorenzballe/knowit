import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../analytics.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../theme.dart';
import 'parts.dart';
import '../card_edge.dart';

/// Charts that mislead — artboard 138d, drawn from the bank's own charts.
///
/// Every chart here is drawn the way charts like it run, headline and all,
/// and tells the truth in its numbers and a lie in its drawing: an axis cut
/// off, a window cropped out of a longer run, totals where a rate was fair,
/// a scale turned upside down. One button turns it into its honest self from
/// the same numbers, the bars sliding to their real lengths, and the card
/// says the trick. The card behind it plays the full version, where the
/// reader finds the trick on their own.
///
/// The shelf has three looks, picked by its section's `look`:
///
/// - `before-after`, the one shown when the section names none: the card
///   asks "This chart misleads. Can you see how?" over the chart, set as a
///   clipping, and its button shows the trick without naming it first.
///   Then the question gives way to the trick said plainly, with the
///   chart's own numbers, in the reader's language, and the chart as it
///   ran moves up to make room for the same numbers drawn fairly under it,
///   each named: Original, Corrected. Before and after, read at a glance.
/// - `in-place`: the same question and button; the chart turns fair where
///   it stands, under its honest headline, with a switch between Original
///   and Corrected under it.
/// - `current`: the first version, under "Unmask the chart" — the chart and
///   a button named for its fix, which gave the trick away before the
///   reader had looked, and named it only in the card's English.
enum UnmaskLook {
  current('current'),
  inPlace('in-place'),
  beforeAfter('before-after');

  const UnmaskLook(this.id);

  /// What a section calls it.
  final String id;

  /// The look a section that names none gets.
  static const UnmaskLook recommended = UnmaskLook.beforeAfter;

  /// The look named [id], or the recommended one.
  static UnmaskLook named(String? id) =>
      values.firstWhere((look) => look.id == id, orElse: () => recommended);
}

/// [v] as the shelf says it in [locale]: no more decimals than it needs, up
/// to [decimals] (exactly [decimals] when not [trim]med, as a bar's own
/// number), the language's own decimal mark, a minus sign rather than a
/// hyphen, and [unit] where it goes — so the trick said over a chart
/// quotes the number on its axis, as the reader writes numbers.
String unmaskFigure(
  double v,
  int decimals,
  String unit, {
  String locale = 'en',
  bool trim = true,
}) {
  String n = _numbers(locale, trim ? 0 : decimals, decimals).format(v.abs());
  if (v < 0 && RegExp('[1-9]').hasMatch(n)) n = '−$n';
  if (unit.isEmpty) return n;
  if (const {'€', r'$', '£', '¥'}.contains(unit)) {
    return n.startsWith('−') ? '−$unit${n.substring(1)}' : '$unit$n';
  }
  if (unit == '%' || unit.startsWith('°')) return '$n$unit';
  return '$n $unit';
}

/// The formats [unmaskFigure] writes with, made once each: a chart is
/// drawn again on every frame of its turn.
final Map<String, NumberFormat> _formats = {};

NumberFormat _numbers(String locale, int least, int most) =>
    _formats.putIfAbsent('$locale $least $most', () {
      NumberFormat f;
      try {
        f = NumberFormat.decimalPattern(locale);
      } catch (_) {
        f = NumberFormat.decimalPattern('en');
      }
      return f
        ..minimumFractionDigits = least
        ..maximumFractionDigits = most;
    });

/// The trick [s] plays, said plainly in the reader's language, with the
/// chart's own numbers in it: where the cut axis starts, how far the
/// stretched one runs, which years the window kept.
String unmaskTrickSaid(AppLocalizations l, TrickScene s) {
  String n(double v) =>
      unmaskFigure(v, s.decimals, s.unit, locale: l.localeName);
  final String said;
  switch (s.trick) {
    case TrickSceneKind.truncated:
      said = l.unmaskTrickTruncated(n(s.shown.lo));
    case TrickSceneKind.stretched:
      // Squeezed round the data, a step fills the chart; spread far past
      // it, a real change lies flat.
      final bool zoomed = s.shown.hi - s.shown.lo < s.fair.hi - s.fair.lo;
      said = zoomed
          ? l.unmaskTrickZoomed(n(s.shown.lo), n(s.shown.hi))
          : l.unmaskTrickWide(n(s.shown.lo), n(s.shown.hi));
    case TrickSceneKind.window:
      said = l.unmaskTrickWindow(
        '${s.columns[s.first]}–${s.columns[s.last]}',
        '${s.columns.first}–${s.columns.last}',
      );
    case TrickSceneKind.flipped:
      said = s.values.last >= s.values.first
          ? l.unmaskTrickFlippedRise
          : l.unmaskTrickFlippedFall;
    case _:
      said = l.unmaskTrickTotals;
  }
  return _unbroken(said);
}

/// [text] with its last two words held together, so a line never ends the
/// sentence on one short word alone ("…non da / zero.").
String _unbroken(String text) {
  final int at = text.lastIndexOf(' ');
  if (at <= 0 || text.length - at > 12) return text;
  return '${text.substring(0, at)}\u00A0${text.substring(at + 1)}';
}

class UnmaskRow extends StatelessWidget {
  const UnmaskRow({
    super.key,
    required this.pills,
    required this.onOpen,
    this.onShown,
    this.look = UnmaskLook.recommended,
  });

  final List<Pill> pills;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;
  final UnmaskLook look;

  @override
  Widget build(BuildContext context) {
    final bool first = look == UnmaskLook.current;
    return SideRow(
      height: first ? 424 : _kAskHeight + 4,
      count: pills.length,
      itemBuilder: (context, i) {
        final Pill p = pills[i];
        onShown?.call(p);
        void open() => onOpen(pills, p);
        return first
            ? _ChartCard(pill: p, onOpen: open)
            : _AskCard(pill: p, look: look, onOpen: open);
      },
    );
  }
}

/// How tall a card of the two clearer looks stands.
const double _kAskHeight = 436;

/// The type of the two charts before and after, against a full one's.
const double _kSmall = 0.92;

class _ChartCard extends StatefulWidget {
  const _ChartCard({required this.pill, required this.onOpen});

  final Pill pill;
  final VoidCallback onOpen;

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  void _toggle() {
    final TrickScene s = widget.pill.scene as TrickScene;
    if (_t.value < 0.5) {
      Analytics.capture('explore chart unmasked', {
        'pill_id': widget.pill.id,
        'trick': s.trick.name,
      });
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _t.value = _t.value < 0.5 ? 1 : 0;
      setState(() {});
      return;
    }
    _t.value < 0.5 ? _t.forward() : _t.reverse();
    setState(() {});
  }

  String _button(BuildContext context, TrickScene s) {
    final l = context.l10n;
    return switch (s.trick) {
      TrickSceneKind.truncated => l.unmaskTruncated,
      TrickSceneKind.stretched => l.unmaskStretched,
      TrickSceneKind.window => l.unmaskWindow,
      TrickSceneKind.flipped => l.unmaskFlipped,
      _ => l.unmaskTotals,
    };
  }

  @override
  Widget build(BuildContext context) {
    final Pill p = widget.pill;
    final TrickScene s = p.scene as TrickScene;
    final l = context.l10n;
    return CardTap(
      pill: p,
      onTap: widget.onOpen,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(18),
        decoration: cardFace(context, p.color, radius: 22),
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final bool honest = _t.value >= 0.5;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardHead(
                  pill: p,
                  label: s.outlet.isEmpty
                      ? null
                      : '${context.l10n.subjectOf(p.topic)} · ${s.outlet}',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topLeft,
                      children: [...previous, ?current],
                    ),
                    child: Align(
                      key: ValueKey(honest),
                      alignment: Alignment.topLeft,
                      child: CardQuestion(
                        text: honest ? s.honest : s.headline,
                        color: p.ink,
                        min: 13,
                        max: 20,
                        height: 1.12,
                        tracking: -0.03,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  honest && s.honestLabel.isNotEmpty ? s.honestLabel : s.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    size: 11.5,
                    weight: FontWeight.w600,
                    height: 1.2,
                    color: subOn(p),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _ChartPainter(
                      scene: s,
                      t: Curves.easeInOutCubic.transform(_t.value),
                      ink: p.ink,
                      faint: hairOn(p),
                      tone: shade(p.color, 0.82),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 70,
                  child: honest
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: p.ink,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                upper(context, s.name),
                                style: AppText.label(
                                  size: 9,
                                  weight: FontWeight.w700,
                                  spacing: 1,
                                  height: 1,
                                  color: p.color,
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Expanded(
                              child: Text(
                                s.lesson,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body(
                                  size: 12,
                                  weight: FontWeight.w500,
                                  height: 1.3,
                                  color: p.ink,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          l.lookFirst,
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w500,
                            height: 1.35,
                            color: p.ink,
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                FlatButton(
                  key: ValueKey('unmask-${p.id}'),
                  label: honest ? l.unmaskBack : _button(context, s),
                  background: p.ink,
                  foreground: p.color,
                  height: 36,
                  size: 12.5,
                  onTap: _toggle,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A chart card of the clearer looks: the question over the chart, the
/// chart as a clipping, and the button that shows the trick; then the trick
/// said where the question was, and the chart drawn fairly — under the
/// original, each named, or in place, with a switch back to the original
/// under it.
class _AskCard extends StatefulWidget {
  const _AskCard({
    required this.pill,
    required this.look,
    required this.onOpen,
  });

  final Pill pill;
  final UnmaskLook look;
  final VoidCallback onOpen;

  @override
  State<_AskCard> createState() => _AskCardState();
}

class _AskCardState extends State<_AskCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  /// Whether the trick has been said. In place it stays said once it is,
  /// whichever chart the switch shows; before and after, going back to the
  /// original asks the question again.
  bool _told = false;

  /// Whether the chart is drawn fairly, or on its way there.
  bool _fair = false;

  TrickScene get _scene => widget.pill.scene as TrickScene;

  bool get _inPlace => widget.look == UnmaskLook.inPlace;

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  /// To the chart drawn fairly, or back to the one that ran.
  void _show({required bool fair}) {
    if (fair == _fair) return;
    if (fair) {
      Analytics.capture('explore chart unmasked', {
        'pill_id': widget.pill.id,
        'trick': _scene.trick.name,
      });
    }
    setState(() {
      _fair = fair;
      _told = _inPlace ? _told || fair : fair;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _t.value = fair ? 1 : 0;
      return;
    }
    fair ? _t.forward() : _t.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final Pill p = widget.pill;
    final TrickScene s = _scene;
    final l = context.l10n;
    return CardTap(
      pill: p,
      onTap: widget.onOpen,
      child: Container(
        width: 320,
        height: _kAskHeight,
        padding: const EdgeInsets.all(18),
        decoration: cardFace(context, p.color, radius: 22),
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final double e = Curves.easeInOutCubic.transform(_t.value);
            final bool fair = _t.value >= 0.5;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardHead(pill: p),
                const SizedBox(height: 12),
                // The question, and where it was, the trick said plainly.
                SizedBox(
                  height: 64,
                  width: double.infinity,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topLeft,
                      children: [...previous, ?current],
                    ),
                    child: Semantics(
                      key: ValueKey(_told),
                      liveRegion: _told,
                      child: CardQuestion(
                        text: _told
                            ? unmaskTrickSaid(l, s)
                            : _unbroken(l.unmaskAsk),
                        color: p.ink,
                        min: 13,
                        max: 22,
                        height: 1.12,
                        tracking: -0.025,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
                    decoration: BoxDecoration(
                      color: _clipping,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _inPlace
                        ? _turned(context, e, fair)
                        : _paired(context, e),
                  ),
                ),
                const SizedBox(height: 14),
                _controls(context),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Where the chart ran, its headline, and what it measures — the honest
  /// headline and measure once [fair].
  Widget _header(BuildContext context, {required bool fair}) {
    final Pill p = widget.pill;
    final TrickScene s = _scene;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s.outlet.isNotEmpty) ...[
          Text(
            upper(context, s.outlet),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(
              size: 8.5,
              weight: FontWeight.w700,
              spacing: 1.1,
              color: subOn(p),
            ),
          ),
          const SizedBox(height: 6),
        ],
        // Two lines' room, the headline sat on the line under it, so one
        // of a single line leaves the room above it rather than a gap.
        SizedBox(
          height: 36,
          width: double.infinity,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.bottomLeft,
              children: [...previous, ?current],
            ),
            child: Align(
              key: ValueKey(fair),
              alignment: Alignment.bottomLeft,
              child: CardQuestion(
                text: _unbroken(fair ? s.honest : s.headline),
                color: p.ink,
                min: 11.5,
                max: 15.5,
                height: 1.12,
                tracking: -0.02,
                alignment: Alignment.bottomLeft,
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        _measure(context, fair ? s.honestLabel : s.label),
      ],
    );
  }

  /// What the numbers measure, in the card's quieter ink.
  Widget _measure(BuildContext context, String text) => Text(
    text.isEmpty ? _scene.label : text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: AppText.body(
      size: 11,
      weight: FontWeight.w600,
      height: 1.2,
      color: subOn(widget.pill),
    ),
  );

  /// The chart at [t], its type [k] times the size a full chart sets it.
  _ChartPainter _painter(double t, {double k = 1}) => _ChartPainter(
    scene: _scene,
    t: t,
    ink: widget.pill.ink,
    faint: hairOn(widget.pill),
    tone: shade(widget.pill.color, 0.82),
    tidy: true,
    locale: context.l10n.localeName,
    k: k,
    ground: _clipping,
  );

  /// The clipping's colour: the card's, under a shade of its ink.
  Color get _clipping => Color.alphaBlend(
    widget.pill.ink.withValues(alpha: 0.07),
    widget.pill.color,
  );

  /// In place: one chart, turning fair where it stands.
  Widget _turned(BuildContext context, double e, bool fair) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context, fair: fair),
        const SizedBox(height: 8),
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: CustomPaint(painter: _painter(e)),
          ),
        ),
      ],
    );
  }

  /// Before and after: the chart as it ran, which moves up and makes room
  /// for the same numbers drawn fairly under it, each named.
  Widget _paired(BuildContext context, double e) {
    final TrickScene s = _scene;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRect(
          child: Align(
            alignment: Alignment.topLeft,
            heightFactor: 1 - e,
            child: Opacity(
              opacity: 1 - e,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _header(context, fair: false),
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              const double tag = 18, gap = 10;
              final double charts = box.maxHeight - (2 * tag + gap) * e;
              final double before = charts * lerpDouble(1, 0.5, e)!;
              Widget named(String name, String measure, {required bool lit}) =>
                  ClipRect(
                    child: Align(
                      alignment: Alignment.topLeft,
                      heightFactor: e,
                      child: SizedBox(
                        height: tag,
                        child: Opacity(
                          opacity: e,
                          child: _Tag(
                            pill: widget.pill,
                            name: name,
                            measure: measure,
                            lit: lit,
                          ),
                        ),
                      ),
                    ),
                  );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  named(l.unmaskOriginal, s.label, lit: false),
                  SizedBox(
                    height: before,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _painter(0, k: lerpDouble(1, _kSmall, e)!),
                    ),
                  ),
                  SizedBox(height: gap * e),
                  named(
                    l.unmaskCorrected,
                    s.honestLabel.isEmpty ? s.label : s.honestLabel,
                    lit: true,
                  ),
                  SizedBox(
                    height: charts - before,
                    width: double.infinity,
                    child: Opacity(
                      opacity: e,
                      child: CustomPaint(painter: _painter(1, k: _kSmall)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// The button that shows the trick; once it is said, the switch between
  /// the original and the corrected chart in place, or before and after the
  /// button that hides the trick and asks again.
  Widget _controls(BuildContext context) {
    final Pill p = widget.pill;
    final l = context.l10n;
    if (_inPlace && _told) {
      return _Switch(
        pill: p,
        labels: [l.unmaskOriginal, l.unmaskCorrected],
        selected: _fair ? 1 : 0,
        onPick: (i) => _show(fair: i == 1),
      );
    }
    return FlatButton(
      key: ValueKey('unmask-${p.id}'),
      label: _fair ? l.unmaskHideTrick : l.unmaskShowTrick,
      background: p.ink,
      foreground: p.color,
      height: 36,
      size: 12.5,
      onTap: () => _show(fair: !_fair),
    );
  }
}

/// A chart's name before and after — ORIGINAL, CORRECTED — and what it
/// measures beside it; the corrected one filled in the card's ink.
class _Tag extends StatelessWidget {
  const _Tag({
    required this.pill,
    required this.name,
    required this.measure,
    required this.lit,
  });

  final Pill pill;
  final String name;
  final String measure;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final Pill p = pill;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: lit ? p.ink : p.ink.withValues(alpha: 0),
            border: Border.all(color: p.ink, width: 1),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            upper(context, name),
            maxLines: 1,
            style: AppText.label(
              size: 8,
              weight: FontWeight.w700,
              spacing: 0.9,
              height: 1,
              color: lit ? p.color : p.ink,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            measure,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              size: 10.5,
              weight: FontWeight.w600,
              height: 1.2,
              color: subOn(p),
            ),
          ),
        ),
      ],
    );
  }
}

/// Two words, one lit, in the card's own colours: which chart is drawn.
/// Too wide for the card at the largest text ("Origineel", "Gecorrigeerd"),
/// it sets both words smaller rather than cutting the second.
class _Switch extends StatelessWidget {
  const _Switch({
    required this.pill,
    required this.labels,
    required this.selected,
    required this.onPick,
  });

  final Pill pill;
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final Pill p = pill;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: fillOn(p),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < labels.length; i++)
              Semantics(
                key: ValueKey(
                  'unmask-${p.id}-${i == 0 ? 'original' : 'corrected'}',
                ),
                button: true,
                selected: i == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onPick(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected ? p.ink : p.ink.withValues(alpha: 0),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      style: AppText.body(
                        size: 12.5,
                        weight: FontWeight.w700,
                        height: 1,
                        color: i == selected
                            ? p.color
                            : p.ink.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The chart, published at t = 0 and honest at t = 1, everything in between
/// a slide from one to the other: the axis's ends, the window's edges, a
/// bar's length, a scale turning over.
class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.scene,
    required this.t,
    required this.ink,
    required this.faint,
    required this.tone,
    this.tidy = false,
    this.locale = 'en',
    this.k = 1,
    this.ground,
  });

  final TrickScene scene;
  final double t;
  final Color ink;
  final Color faint;
  final Color tone;

  /// Numbers as the trick said over the chart quotes them, in [locale]:
  /// the axis's marks with no more decimals than they need ("82.5%", not
  /// "83%"; "43°C", not "43.00 °C"), and a minus sign.
  final bool tidy;
  final String locale;

  /// The type, against a full chart's.
  final double k;

  /// What the chart is drawn on, cut out behind each bar's number; none
  /// leaves the gridlines to run behind them.
  final Color? ground;

  String _fmt(double v, {required bool honest, bool axis = false}) {
    final TrickScene s = scene;
    final bool rate = honest && s.trick == TrickSceneKind.totals;
    final int dp = rate ? s.honestDecimals : s.decimals;
    final String unit = rate ? s.honestUnit : s.unit;
    if (tidy) {
      return axis
          ? unmaskFigure(v, 2, unit, locale: locale)
          : unmaskFigure(v, dp, unit, locale: locale, trim: false);
    }
    final String n = v.toStringAsFixed(dp);
    if (unit.isEmpty) return n;
    if (const {'€', r'$', '£', '¥'}.contains(unit)) return '$unit$n';
    if (unit == '%') return '$n%';
    return '$n $unit';
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at, {
    double size = 9.5,
    FontWeight weight = FontWeight.w600,
    Color? color,
    TextAlign align = TextAlign.left,
    double? maxWidth,
    Color? knockout,
  }) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: AppText.body(
          size: size,
          weight: weight,
          height: 1,
          color: color ?? ink.withValues(alpha: 0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);
    final double dx = switch (align) {
      TextAlign.right => at.dx - tp.width,
      TextAlign.center => at.dx - tp.width / 2,
      _ => at.dx,
    };
    // A gridline runs behind a number, never through it.
    if (knockout != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(dx - 2.5, at.dy - 1.5, tp.width + 5, tp.height + 3),
          const Radius.circular(3),
        ),
        Paint()..color = knockout,
      );
    }
    tp.paint(canvas, Offset(dx, at.dy));
    tp.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final TrickScene s = scene;
    final int n = s.count;
    final bool honest = t >= 0.5;

    // The value axis, sliding from the published range to the fair one.
    final double lo = lerpDouble(s.shown.lo, s.fair.lo, t)!;
    final double hi = lerpDouble(s.shown.hi, s.fair.hi, t)!;

    // As wide as its widest number, so "43.0 °C" is not cut to "43.0 …".
    double widest = 0;
    for (int m = 0; m <= 2; m++) {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: _fmt(lo + (hi - lo) * m / 2, honest: honest, axis: true),
          style: AppText.body(size: 9 * k, weight: FontWeight.w600, height: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      widest = math.max(widest, tp.width);
      tp.dispose();
    }
    final double axisW = (widest + 10).clamp(26.0, 72.0);
    const double bottomH = 16;
    final Rect plot = Rect.fromLTWH(
      axisW,
      14,
      size.width - axisW,
      size.height - 14 - bottomH,
    );

    // The columns in view, opening from the window to the whole run.
    final double firstCol = lerpDouble(s.first.toDouble(), 0, t)!;
    final double lastCol = lerpDouble(
      s.last.toDouble(),
      (n - 1).toDouble(),
      t,
    )!;
    final double span = math.max(1e-6, lastCol - firstCol);

    final bool flipped = s.trick == TrickSceneKind.flipped;
    double norm(double v, double a, double b) =>
        ((v - a) / math.max(1e-9, b - a)).clamp(0, 1);
    double y(double nv) {
      final double up = plot.bottom - nv * plot.height;
      if (!flipped) return up;
      final double down = plot.top + nv * plot.height;
      return lerpDouble(down, up, t)!;
    }

    // Gridlines and the axis's numbers: bottom, middle, top.
    final Paint grid = Paint()
      ..color = faint
      ..strokeWidth = 1;
    for (int m = 0; m <= 2; m++) {
      final double nv = m / 2;
      final double gy = y(nv);
      canvas.drawLine(Offset(plot.left, gy), Offset(plot.right, gy), grid);
      final double value = lo + (hi - lo) * nv;
      _text(
        canvas,
        _fmt(value, honest: honest, axis: true),
        Offset(axisW - 6, gy - 5 * k),
        align: TextAlign.right,
        maxWidth: axisW - 4,
        size: 9 * k,
      );
    }

    canvas.save();
    // Clipped at the sides, where columns slide out of the window, but not
    // at the top: a bar that reaches it keeps the number over it whole.
    canvas.clipRect(
      Rect.fromLTRB(plot.left - 2, 0, plot.right + 2, plot.bottom + 2),
    );
    final bool bars = s.form == TrickSceneForm.bars;
    final List<double> published = s.values;
    final List<double> fair = s.honestValues;
    double heightOf(int i) {
      final double a = norm(published[i], s.shown.lo, s.shown.hi);
      final double b = norm(fair[i], s.fair.lo, s.fair.hi);
      // A total turns into its rate; everything else keeps its value and
      // only the axis under it moves.
      if (s.trick == TrickSceneKind.totals) return lerpDouble(a, b, t)!;
      return norm(published[i], lo, hi);
    }

    double xOf(double col) => plot.left + (col - firstCol) / span * plot.width;

    if (bars) {
      final double slot = plot.width / (span + 1);
      final double bw = math.min(46, slot * 0.58);
      for (int i = 0; i < n; i++) {
        final double cx =
            plot.left + (i - firstCol + 0.5) / (span + 1) * plot.width;
        if (cx < plot.left - bw || cx > plot.right + bw) continue;
        final double top = y(heightOf(i));
        final double base = y(0);
        final Rect r = Rect.fromLTRB(
          cx - bw / 2,
          math.min(top, base),
          cx + bw / 2,
          math.max(top, base),
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            r,
            topLeft: const Radius.circular(6),
            topRight: const Radius.circular(6),
          ),
          Paint()..color = i == n - 1 || i == s.last ? ink : tone,
        );
        _text(
          canvas,
          _fmt(honest ? fair[i] : published[i], honest: honest),
          Offset(cx, r.top - 12 * k),
          align: TextAlign.center,
          size: 10 * k,
          weight: FontWeight.w700,
          color: ink,
          knockout: ground,
        );
      }
    } else {
      final Path path = Path();
      bool started = false;
      for (int i = 0; i < n; i++) {
        final Offset o = Offset(xOf(i.toDouble()), y(heightOf(i)));
        if (!started) {
          path.moveTo(o.dx, o.dy);
          started = true;
        } else {
          path.lineTo(o.dx, o.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      final int every = math.max(1, (n / 12).ceil());
      for (int i = 0; i < n; i += every) {
        canvas.drawCircle(
          Offset(xOf(i.toDouble()), y(heightOf(i))),
          2.6,
          Paint()..color = ink,
        );
      }
    }
    canvas.restore();

    // The columns' names along the bottom: all of them for bars, the two
    // ends for a line.
    final double ly = plot.bottom + 4;
    if (bars) {
      for (int i = 0; i < n; i++) {
        final double cx =
            plot.left + (i - firstCol + 0.5) / (span + 1) * plot.width;
        if (cx < plot.left || cx > plot.right) continue;
        _text(
          canvas,
          s.columns[i],
          Offset(cx, ly),
          align: TextAlign.center,
          size: 9 * k,
          maxWidth: plot.width / (span + 1) + 6,
        );
      }
    } else {
      final int a = firstCol.round().clamp(0, n - 1);
      final int b = lastCol.round().clamp(0, n - 1);
      _text(canvas, s.columns[a], Offset(plot.left, ly), size: 9 * k);
      _text(
        canvas,
        s.columns[b],
        Offset(plot.right, ly),
        align: TextAlign.right,
        size: 9 * k,
      );
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.t != t ||
      old.scene != scene ||
      old.ink != ink ||
      old.tidy != tidy ||
      old.locale != locale ||
      old.k != k ||
      old.ground != ground;
}
