import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../analytics.dart';
import '../../data/explore_mix.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../state/explore_play.dart';
import '../../theme.dart';
import 'parts.dart';

/// Through time — artboard 141c's ruler, on the ages the bank's cards are
/// set in, and a year to type.
///
/// Drag along the ruler, or step with the arrows, and the shelf under it
/// turns to that age: the ancient world, the Middle Ages, the centuries
/// after, the last one, this one. The canvas ran its ruler back to the first
/// light; the bank tags the ages people lived in, so that is where this one
/// starts. The cards for an age are dealt afresh every day, and the ruler
/// opens on a different age each morning.
///
/// A ruler alone only ever says roughly when. Under it is a year to type —
/// the one you were born in, 1492, 44 BC — and the shelf travels there: the
/// year rolls into place, the ruler slides to the age that holds it, and the
/// cards are the ones whose questions name the years nearest it, looked for
/// through every card of that age no other shelf holds. A year no card is
/// near, or an age with nothing in it today, is said plainly, with the
/// nearest there is.
class ThroughTime extends StatefulWidget {
  const ThroughTime({
    super.key,
    required this.eras,
    required this.startAt,
    required this.isRead,
    required this.onOpen,
    this.pool = const {},
    this.day = 0,
    this.onShown,
  });

  /// The cards for each age that has any, oldest first.
  final List<(String, List<Pill>)> eras;

  /// For each age, every card a typed year can bring up, the day's first.
  /// An age missing here looks only through its own cards.
  final Map<String, List<Pill>> pool;

  /// The day, which settles which of two cards as near to a year comes
  /// first.
  final int day;

  /// The age the ruler opens on.
  final int startAt;
  final bool Function(Pill) isRead;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  /// Where the year travelled to today is kept, so the shelf is still there
  /// when it is scrolled back to.
  static const String yearKey = 'through-year';

  /// The most cards a year brings up: two on the shelf and the rest a tap
  /// away, which is a handful, not the whole of an age.
  static const int yearCards = 8;

  @override
  State<ThroughTime> createState() => _ThroughTimeState();
}

class _ThroughTimeState extends State<ThroughTime> {
  late int _at = widget.startAt.clamp(0, widget.eras.length - 1);

  /// The year travelled to, as the ruler counts years (see [yearBc]), or
  /// null while the ages are being browsed.
  int? _year;

  /// Whether the year being typed is before Christ.
  bool _bc = false;

  /// The last year tried was 0, which there was none of.
  bool _zero = false;

  /// Counts the journeys, so the year rolls every time it lands, even on
  /// the same digits.
  int _rolls = 0;

  final TextEditingController _field = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focused);
    // A year travelled to earlier today is where the shelf still is.
    if (ExplorePlay.instance[ThroughTime.yearKey] case final int year) {
      _year = year;
      _bc = year <= 0;
      _field.text = '${year <= 0 ? 1 - year : year}';
      _at = _ageFor(year);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_focused);
    _focus.dispose();
    _field.dispose();
    super.dispose();
  }

  void _focused() {
    // Coming back to a year already there selects it, so typing replaces
    // it rather than adding a fifth digit that will not fit.
    if (_focus.hasFocus && _field.text.isNotEmpty) {
      _field.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _field.text.length,
      );
    }
    setState(() {});
  }

  /// The age a year goes to: its own, or, where that has no cards today,
  /// the age nearest it that does.
  int _ageFor(int year) {
    final int wanted = kEras.indexOf(eraOfYear(year));
    int best = 0;
    for (int i = 0; i < widget.eras.length; i++) {
      final int gap = (kEras.indexOf(widget.eras[i].$1) - wanted).abs();
      final int bestGap = (kEras.indexOf(widget.eras[best].$1) - wanted).abs();
      if (gap < bestGap || (gap == bestGap && i > best)) best = i;
    }
    return best;
  }

  /// Browsing by age lets go of the year: the ruler and the year say where
  /// the shelf is, and they must not say two places.
  void _go(int to) {
    final int next = to.clamp(0, widget.eras.length - 1);
    if (next == _at) return;
    Analytics.capture('explore era', {'era': widget.eras[next].$1});
    if (_year != null) ExplorePlay.instance.put(ThroughTime.yearKey, null);
    _field.clear();
    _focus.unfocus();
    setState(() {
      _at = next;
      _year = null;
      _zero = false;
    });
  }

  void _typed(String text) {
    if (_zero) setState(() => _zero = false);
    // Four digits are a year: no need to ask for it to be gone to.
    if (text.length == 4) {
      _travel();
    } else {
      setState(() {});
    }
  }

  void _travel() {
    final int? n = int.tryParse(_field.text.trim());
    if (n == null) return;
    if (n == 0) {
      setState(() => _zero = true);
      return;
    }
    final int year = _bc ? yearBc(n) : n;
    final int to = _ageFor(year);
    _focus.unfocus();
    HapticFeedback.selectionClick();
    Analytics.capture('explore year', {
      'year': year,
      'era': widget.eras[to].$1,
    });
    ExplorePlay.instance.put(ThroughTime.yearKey, year);
    setState(() {
      _zero = false;
      _year = year;
      _at = to;
      _rolls++;
    });
  }

  void _pickEra(bool bc) {
    if (bc == _bc) return;
    setState(() => _bc = bc);
    // A year already typed is the other side of Christ now: go there. With
    // none typed yet, the choice is for the year about to be.
    if (int.tryParse(_field.text.trim()) != null) {
      _travel();
    } else {
      _focus.requestFocus();
    }
  }

  (String, String) _names(BuildContext context, String era) {
    final l = context.l10n;
    return switch (era) {
      'ancient' => (l.eraAncient, l.eraAncientWhen),
      'medieval' => (l.eraMedieval, l.eraMedievalWhen),
      'early_modern' => (l.eraEarlyModern, l.eraEarlyModernWhen),
      'nineteenth' => (l.eraNineteenth, l.eraNineteenthWhen),
      'twentieth' => (l.eraTwentieth, l.eraTwentiethWhen),
      _ => (l.eraRecent, l.eraRecentWhen),
    };
  }

  /// A year as a sentence says it: 1969, AD 476, 44 BC.
  static String _words(BuildContext context, int year) {
    final l = context.l10n;
    if (year <= 0) return l.yearBcOf('${1 - year}');
    if (year < 1000) return l.yearAdOf('$year');
    return l.yearNamed('$year');
  }

  /// The cards a year brings up in the age shown, nearest first, kept
  /// while the year and the age stand: the age can hold a thousand cards.
  List<Pill> _ranked = const [];
  String _rankedFor = '';

  List<Pill> _nearest(String era, List<Pill> dealt, int year) {
    final List<Pill> pool = widget.pool[era] ?? dealt;
    final String key = '$era|$year|${identityHashCode(pool)}|${widget.day}';
    if (key != _rankedFor) {
      _rankedFor = key;
      _ranked = nearestToYear(
        pool,
        year,
        era: era,
        day: widget.day,
      ).take(ThroughTime.yearCards).toList();
    }
    return _ranked;
  }

  /// What a year typed came to, said under the year.
  String? _note(BuildContext context, String era, List<Pill> cards) {
    final l = context.l10n;
    if (_zero) return l.yearZero;
    final int? year = _year;
    if (year == null) return null;
    final String said = _words(context, year);
    if (year > DateTime.now().year) return l.yearFuture(said);
    if (eraOfYear(year) != era) return l.yearNoAge(said);
    if (cards.isNotEmpty && yearsAway(cards.first, year, era: era) != null) {
      return l.yearNearest(said);
    }
    return l.yearNoneNamed(said);
  }

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    final int n = widget.eras.length;
    final (String era, List<Pill> dealt) = widget.eras[_at];
    final (String name, String span) = _names(context, era);
    final int? year = _year;
    final List<Pill> cards = year == null ? dealt : _nearest(era, dealt, year);
    final List<Pill> shown = cards.take(2).toList();
    for (final p in shown) {
      widget.onShown?.call(p);
    }
    final String? note = _note(context, era, cards);

    Widget arrow(IconData icon, int to, String key) {
      final bool live = to >= 0 && to < n;
      return Semantics(
        key: ValueKey(key),
        button: true,
        enabled: live,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: live ? () => _go(to) : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: live ? 1 : 0.3,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ink.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: ink),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.bottomLeft,
                    children: [...previous, ?current],
                  ),
                  child: Column(
                    key: ValueKey(era),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Kicker(name, color: ink.withValues(alpha: 0.5)),
                      const SizedBox(height: 7),
                      Text(
                        span,
                        style: AppText.display(
                          size: 32,
                          weight: FontWeight.w600,
                          height: 1.02,
                          spacing: -1,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              arrow(Icons.chevron_left_rounded, _at - 1, 'era-back'),
              const SizedBox(width: 6),
              arrow(Icons.chevron_right_rounded, _at + 1, 'era-on'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 29),
          child: _Ruler(stops: n, at: _at, onPick: _go),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                context.l10n.eraRulerOld,
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w600,
                  height: 1,
                  color: ink.withValues(alpha: 0.45),
                ),
              ),
              const Spacer(),
              Text(
                context.l10n.eraRulerNow,
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w600,
                  height: 1,
                  color: ink.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _yearBar(context),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: note == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  // Under the year's own figures, where the eye already is.
                  padding: const EdgeInsets.fromLTRB(38, 10, 24, 0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topLeft,
                      children: [...previous, ?current],
                    ),
                    child: Text(
                      note,
                      key: ValueKey('era-year-said-$note'),
                      style: AppText.body(
                        size: 12.5,
                        weight: FontWeight.w600,
                        height: 1.35,
                        color: ink.withValues(alpha: 0.62),
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: SizedBox(
              key: ValueKey('era-cards-$era${year == null ? '' : '-$year'}'),
              height: 236,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < shown.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: _eraCard(context, cards, shown[i])),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (cards.length > 2) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FlatButton(
                key: const ValueKey('era-more'),
                label: context.l10n.eraMore(cards.length - 2),
                background: ink.withValues(alpha: 0.08),
                foreground: ink,
                height: 36,
                size: 12.5,
                icon: Icon(Icons.layers_rounded, size: 15, color: ink),
                onTap: () => widget.onOpen(cards, cards[2]),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// The year to type: large, in the face the years on the cards are set
  /// in, before Christ or after it, and an arrow to go.
  Widget _yearBar(BuildContext context) {
    final Color ink = context.p.ink;
    final l = context.l10n;
    final bool focused = _focus.hasFocus;
    final int? year = _year;
    // Once gone to, the year is drawn by the rolling figures rather than
    // the field, which keeps it underneath to be tapped and typed over.
    final bool rolled = year != null && !focused;
    final bool ready = int.tryParse(_field.text.trim()) != null;

    return LayoutBuilder(
      builder: (context, box) {
        // The eras side by side where there is room beside them for a year,
        // one over the other where there is not: apr. J.-C. and av. J.-C.
        // on a narrow phone would leave the year a few pixels.
        final double ad = _EraSwitch.width(context, l.yearAd);
        final double bc = _EraSwitch.width(context, l.yearBc);
        const double around = 18 + 10 + 8 + 8 + 44 + 3;
        final double beside = box.maxWidth - around - (ad + bc + 6);
        final bool stacked = beside < 110;
        final double room = stacked
            ? box.maxWidth - around - (math.max(ad, bc) + 6)
            : beside;
        // Four figures and the caret in the room there is, never larger
        // than the year on a card is drawn twice over.
        final TextStyle digits = AppText.display(
          size: ((room - 6) / 2.6).clamp(18.0, 34.0),
          weight: FontWeight.w600,
          height: 1,
          spacing: 0.5,
          color: ink,
        ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 64,
          padding: const EdgeInsets.only(left: 18, right: 10),
          decoration: BoxDecoration(
            color: ink.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ink.withValues(alpha: focused ? 0.55 : 0),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Set by hand rather than as the field's hint, so a
                    // long one in a narrow field is made smaller, not cut.
                    if (_field.text.isEmpty)
                      IgnorePointer(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l.yearHint,
                            maxLines: 1,
                            style: AppText.display(
                              size: 21,
                              weight: FontWeight.w500,
                              height: 1.2,
                              color: ink.withValues(alpha: 0.34),
                            ),
                          ),
                        ),
                      ),
                    TextField(
                      key: const ValueKey('era-year'),
                      controller: _field,
                      focusNode: _focus,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.go,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onChanged: _typed,
                      onSubmitted: (_) => _travel(),
                      style: digits.copyWith(
                        color: rolled ? ink.withValues(alpha: 0) : ink,
                      ),
                      cursorColor: ink,
                      decoration: const InputDecoration.collapsed(
                        hintText: null,
                      ),
                    ),
                    if (rolled)
                      IgnorePointer(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _RollingYear(
                            text: '${year <= 0 ? 1 - year : year}',
                            style: digits,
                            rolls: _rolls,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _EraSwitch(bc: _bc, onPick: _pickEra, stacked: stacked),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                enabled: ready,
                label: l.yearGo,
                child: GestureDetector(
                  key: const ValueKey('era-year-go'),
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onTap: ready ? _travel : null,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: ready ? 1 : 0.3,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.p.inverse,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: context.p.onInverse,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _eraCard(BuildContext context, List<Pill> cards, Pill p) {
    final String? year = yearSaid(p);
    return CardTap(
      pill: p,
      onTap: () => widget.onOpen(cards, p),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.color,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardHead(
              pill: p,
              trailing: widget.isRead(p) ? ReadMark(pill: p) : null,
            ),
            if (year != null) ...[
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  year,
                  maxLines: 1,
                  style: AppText.display(
                    size: 26,
                    weight: FontWeight.w600,
                    height: 1,
                    spacing: -0.8,
                    color: shade(p.color, 0.62),
                  ),
                ),
              ),
            ],
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: CardQuestion(
                  text: p.question,
                  color: p.ink,
                  min: 10.5,
                  max: 16.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AD or BC: two words, one lit, the subject row's chip made into a pair —
/// side by side, or one over the other where the year needs the width.
class _EraSwitch extends StatelessWidget {
  const _EraSwitch({
    required this.bc,
    required this.onPick,
    this.stacked = false,
  });

  final bool bc;
  final ValueChanged<bool> onPick;
  final bool stacked;

  static TextStyle _style(Color color) => AppText.body(
    size: 11.5,
    weight: FontWeight.w700,
    height: 1,
    color: color,
  );

  /// How wide one era's half of the switch is: its word and its margins.
  static double width(BuildContext context, String label) {
    final TextPainter measure = TextPainter(
      text: TextSpan(text: label, style: _style(const Color(0xFF000000))),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final double w = measure.width;
    measure.dispose();
    return math.max(36, w + 16);
  }

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    Widget side(String label, bool isBc) {
      final bool on = bc == isBc;
      return Semantics(
        key: ValueKey('era-${isBc ? 'bc' : 'ad'}-${on ? 'on' : 'off'}'),
        button: true,
        selected: on,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: on ? null : () => onPick(isBc),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: stacked ? 25 : 30,
            constraints: const BoxConstraints(minWidth: 36),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on
                  ? context.p.inverse
                  : context.p.inverse.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(stacked ? 8 : 9),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: _style(
                on ? context.p.onInverse : ink.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
      );
    }

    final List<Widget> both = [
      side(context.l10n.yearAd, false),
      side(context.l10n.yearBc, true),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: stacked
          ? IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: both,
              ),
            )
          : Row(mainAxisSize: MainAxisSize.min, children: both),
    );
  }
}

/// The year gone to, rolling into place: each figure spins up through the
/// few before it and lands, the last ones spinning longest, the way a
/// counter on a dashboard settles.
class _RollingYear extends StatefulWidget {
  const _RollingYear({
    required this.text,
    required this.style,
    required this.rolls,
  });

  final String text;
  final TextStyle style;

  /// Changes on every journey, which is what sets the figures rolling.
  final int rolls;

  @override
  State<_RollingYear> createState() => _RollingYearState();
}

class _RollingYearState extends State<_RollingYear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _roll = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void didUpdateWidget(_RollingYear old) {
    super.didUpdateWidget(old);
    if (old.rolls != widget.rolls || old.text != widget.text) {
      _roll.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _roll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String text = widget.text;
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(text, style: widget.style);
    }
    final double h = widget.style.fontSize ?? 34;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _roll,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < text.length; i++)
                _figure(text, i, h * scaler.scale(1), scaler),
            ],
          ),
        ),
      ),
    );
  }

  /// One figure: a strip of the [spins] figures before it and itself,
  /// moved up through a window one figure high.
  Widget _figure(String text, int i, double h, TextScaler scaler) {
    final int d = int.tryParse(text[i]) ?? 0;
    final int spins = 3 + i;
    final double t = Interval(
      (0.1 * i).clamp(0.0, 0.5),
      (0.55 + 0.12 * i).clamp(0.0, 1.0),
      curve: Curves.easeOutCubic,
    ).transform(_roll.value);
    final TextPainter measure = TextPainter(
      text: TextSpan(text: text[i], style: widget.style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final double w = measure.width;
    measure.dispose();
    return ClipRect(
      child: SizedBox(
        width: w,
        height: h,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: double.infinity,
          maxWidth: w * 1.4,
          child: Transform.translate(
            offset: Offset(0, -spins * h * t),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int k = spins; k >= 0; k--)
                  SizedBox(
                    height: h,
                    child: Center(
                      child: Text(
                        '${(d - k) % 10}',
                        textScaler: scaler,
                        style: widget.style,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The ruler: a stop for every age, a line filled as far as the one chosen,
/// and a thumb that can be dragged from one to the next.
class _Ruler extends StatelessWidget {
  const _Ruler({required this.stops, required this.at, required this.onPick});

  final int stops;
  final int at;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return LayoutBuilder(
      builder: (context, box) {
        final double w = box.maxWidth;
        double x(int i) => stops < 2 ? 0 : w * i / (stops - 1);
        int nearest(double dx) =>
            stops < 2 ? 0 : (dx / w * (stops - 1)).round().clamp(0, stops - 1);
        return GestureDetector(
          key: const ValueKey('era-ruler'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => onPick(nearest(d.localPosition.dx)),
          onHorizontalDragUpdate: (d) => onPick(nearest(d.localPosition.dx)),
          child: SizedBox(
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = 0; i < stops; i++)
                  Positioned(
                    left: x(i) - 0.5,
                    top: 6,
                    width: 1,
                    height: 14,
                    child: ColoredBox(color: ink.withValues(alpha: 0.24)),
                  ),
                Positioned(
                  left: -9,
                  right: -9,
                  top: 28,
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ink.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  left: -9,
                  top: 28,
                  height: 4,
                  width: x(at) + 9,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                for (int i = 0; i < stops; i++)
                  Positioned(
                    left: x(i) - 4,
                    top: 26,
                    width: 8,
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= at ? ink : ink.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  left: x(at) - 11,
                  top: 19,
                  width: 22,
                  height: 22,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.p.surface,
                      border: Border.all(color: ink, width: 3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
