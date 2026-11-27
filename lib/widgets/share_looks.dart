part of 'share_day.dart';

// The day's picture two new ways, beside A, the picture as it shipped until
// November 2026 (DayPicture; picked in the developer tools,
// DebugLooks.sharePicture). The owner asked for it nicer, softly graded and
// coloured, as it had been once (the day's first and last colours lit its
// corners), and weighed three ways of showing a card: its drawing whole, a
// small preview of it, or only its subject's mark. A cut a card's drawing
// down to a square under its question, small, often mid-drawing. Both of
// these keep every question whole and never cut a drawing:
//
// * B, the cards: the day's first drawn card as the reader met it, the
//   whole card, large, lit from behind by its colour, the others by their
//   marks; on the list the five cards whole in a row over their questions,
//   the small preview made whole.
// * C, light: no drawing at all. Black lit by the day's colours from its
//   corners, every card its subject's mark on a disc of its colour, and the
//   questions set as a paper sets its index. The one that ships.
//
// The same type in both: Fraunces for the questions, Figtree for the rest.
// The same head (Today's five, the date and the edition, the app's name)
// and the same foot (Your turn, the address, the streak).

/// [c] taken toward black by [k], from 0 (itself) to 1 (black): a deeper
/// tone of the same hue.
Color _deeper(Color c, double k) => Color.lerp(c, const Color(0xFF000000), k)!;

/// [c] as it reads on black: a deep hue (Space's blue, Cinema's violet)
/// lifted toward white until it carries small type; any other as it is.
Color _onBlack(Color c) =>
    c.computeLuminance() < 0.16 ? Color.lerp(c, Colors.white, 0.42)! : c;

/// How deep a card's colour is taken at the far end of its grade: as far as
/// its ink still reads on it. A pale colour under dark ink goes a little
/// way; a saturated one under white goes further, toward its own night.
double _gradeOf(Pill pill) => pill.ink.computeLuminance() > 0.5 ? 0.34 : 0.16;

/// A card's colour, graded from its own at the top left to a deeper tone of
/// it at the bottom right.
Gradient _graded(Pill pill) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [pill.color, _deeper(pill.color, _gradeOf(pill))],
);

/// A soft light of [colour] on the black, centred [at], reaching [radius]
/// of the picture's shorter side.
class _Light {
  const _Light(this.colour, this.at, {this.radius = 1.0, this.strength = 0.34});

  final Color colour;
  final Alignment at;
  final double radius;
  final double strength;

  Gradient get gradient {
    // A white (Thinking's) lights the black grey: half as strong.
    final double s = colour.computeLuminance() > 0.7
        ? strength * 0.5
        : strength;
    return RadialGradient(
      center: at,
      radius: radius,
      colors: [
        colour.withValues(alpha: s),
        colour.withValues(alpha: s * 0.4),
        colour.withValues(alpha: 0),
      ],
      stops: const [0, 0.45, 1],
    );
  }
}

/// The black every new look is set on, opaque, so a light chat never shows
/// through it, lit by [lights].
class _Lit extends StatelessWidget {
  const _Lit({required this.lights, required this.child});

  final List<_Light> lights;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DayPicture.ground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final _Light light in lights)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: light.gradient),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// The type the new looks share, and the frame every one of them is set in:
/// the head, the body in the room left, and the foot.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.summary,
    required this.date,
    required this.tall,
    required this.lights,
    required this.body,
  });

  final DaySummary summary;
  final String date;
  final bool tall;
  final List<_Light> lights;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return _Lit(
      lights: lights,
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'Figtree',
          color: DayPicture._ink,
          fontSize: 14,
          height: 1.2,
          letterSpacing: 0,
          decoration: TextDecoration.none,
        ),
        child: Padding(
          // A story leaves its top to the name and the bars a story app
          // lays over it, and its foot to the reply box.
          padding: tall
              ? const EdgeInsets.fromLTRB(26, 56, 26, 44)
              : const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Masthead(date: date, edition: summary.edition, tall: tall),
              SizedBox(height: tall ? 22 : 16),
              Expanded(child: body),
              SizedBox(height: tall ? 22 : 14),
              _Sign(streak: summary.streak, tall: tall),
            ],
          ),
        ),
      ),
    );
  }
}

/// The head of the new looks: Today's five, its date and edition, and the
/// app's name — beside them on the square shapes, over them on a story's
/// tall one, which has the height for it.
class _Masthead extends StatelessWidget {
  const _Masthead({
    required this.date,
    required this.edition,
    required this.tall,
  });

  final String date;
  final int edition;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final double big = tall ? 30 : 22;
    final Widget title = _OneLine(
      context.l10n.shareDayHeadline,
      style: AppText.body(
        size: big,
        weight: FontWeight.w800,
        height: 1.1,
        spacing: -0.025 * big,
        color: DayPicture._ink,
      ),
    );
    final Widget when = _OneLine(
      '$date  ·  #$edition',
      style: AppText.body(
        size: tall ? 14.5 : 12.5,
        weight: FontWeight.w500,
        height: 1.25,
        color: DayPicture._muted,
      ),
    );
    if (!tall) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 3), when],
            ),
          ),
          const SizedBox(width: 12),
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: _Brand(size: 13.5),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(children: [_Brand(size: 16)]),
        const SizedBox(height: 18),
        title,
        const SizedBox(height: 4),
        when,
      ],
    );
  }
}

/// The foot of the new looks: Your turn and the address, and the streak.
class _Sign extends StatelessWidget {
  const _Sign({required this.streak, required this.tall});

  final int streak;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OneLine(
                l.shareDayTurn,
                style: AppText.body(
                  size: tall ? 16 : 12.5,
                  weight: FontWeight.w700,
                  height: 1.25,
                  color: DayPicture._ink.withValues(alpha: 0.94),
                ),
              ),
              const SizedBox(height: 2),
              _OneLine(
                kSiteHost,
                style: AppText.body(
                  size: tall ? 13 : 11,
                  weight: FontWeight.w600,
                  height: 1.25,
                  spacing: 0.2,
                  color: DayPicture._muted,
                ),
              ),
            ],
          ),
        ),
        if (streak > 0) ...[
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: tall ? 17 : 14,
                color: DayPicture._flame,
              ),
              const SizedBox(width: 3),
              Text(
                l.streakDays(streak),
                style: AppText.body(
                  size: tall ? 13.5 : 11.5,
                  weight: FontWeight.w700,
                  height: 1.25,
                  color: DayPicture._ink.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A subject's name over its question, in its colour where that reads on
/// black, or in [ink].
TextStyle _labelStyle(Color colour, {double size = 9.5, Color? ink}) =>
    AppText.label(
      size: size,
      weight: FontWeight.w700,
      spacing: 1.4,
      height: 1.2,
      color: ink ?? _onBlack(colour),
    );

/// A subject's name, as the picture prints it.
String _subjectOf(BuildContext context, Pill pill) {
  final String name = context.l10n.subjectOf(pill.topic);
  return Localizations.localeOf(context).languageCode == 'tr'
      ? name.replaceAll('i', 'İ').toUpperCase()
      : name.toUpperCase();
}

/// A subject's mark on a disc of its colour, graded: how C shows a card,
/// and how B shows the cards it does not draw.
class _Disc extends StatelessWidget {
  const _Disc({required this.pill, required this.size});

  final Pill pill;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [pill.color, _deeper(pill.color, 0.24)],
        ),
      ),
      child: SubjectIcon(subject: pill.topic, size: size * 0.52, ink: pill.ink),
    );
  }
}

/// A hairline across the page, between two parts of it.
class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: DayPicture._ink.withValues(alpha: 0.1));
}

/// The sizes the new looks set type at, found by measuring: the largest on a
/// quarter step at which what must fit does, never less than a floor while
/// anything else can give, and never cut.
abstract final class _Fit {
  static const double _step = 0.25;

  /// The largest size from [hi] down to [lo] at which [fits] holds, or null
  /// where not even [lo] does. [fits] holds less as the size grows.
  static double? largest(double hi, double lo, bool Function(double) fits) {
    if (!fits(lo)) return null;
    int a = 0;
    int b = ((hi - lo) / _step).floor();
    if (b <= 0 || fits(lo + b * _step)) return lo + math.max(b, 0) * _step;
    while (b - a > 1) {
      final int mid = (a + b) ~/ 2;
      if (fits(lo + mid * _step)) {
        a = mid;
      } else {
        b = mid;
      }
    }
    return lo + a * _step;
  }

  /// The size for a list: as large as [hi] where the room allows, at least
  /// [good] where it can, at least [lo] where that is all; under [lo] only
  /// where even that would cut a question, as far as it takes.
  static double size(
    double hi,
    double good,
    double lo,
    bool Function(double) fits,
  ) {
    final double? at = largest(hi, good, fits) ?? largest(good, lo, fits);
    if (at != null) return at;
    double s = lo - _step;
    while (s > 6 && !fits(s)) {
      s -= _step;
    }
    return s;
  }
}

/// Rows of questions, each led by [lead] (a disc, a number, nothing) and,
/// where [label], its subject's name over it; the room between them opened
/// up to [gapMax] and parted by hairlines where [rules].
class _QuestionRows extends StatelessWidget {
  const _QuestionRows({
    required this.pills,
    required this.size,
    required this.heights,
    required this.gap,
    required this.leadWidth,
    required this.lead,
    this.label = false,
    this.rules = true,
  });

  final List<Pill> pills;
  final double size;
  final List<double> heights;
  final double gap;
  final double leadWidth;
  final Widget Function(int i, Pill pill) lead;
  final bool label;
  final bool rules;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < pills.length; i++) ...[
          if (i > 0)
            SizedBox(
              height: gap,
              child: rules ? const Center(child: _Rule()) : null,
            ),
          SizedBox(
            height: heights[i],
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: leadWidth,
                  child: Center(child: lead(i, pills[i])),
                ),
                const SizedBox(width: _RowsPlan.leadGap),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (label) ...[
                        Text(
                          _subjectOf(context, pills[i]),
                          maxLines: 1,
                          softWrap: false,
                          style: _labelStyle(pills[i].color),
                        ),
                        const SizedBox(height: _RowsPlan.labelGap),
                      ],
                      BalancedText(
                        pills[i].question,
                        style: _questionStyle(size),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// How rows of questions fit a room: one size for all, the height of each,
/// and the room between them.
class _RowsPlan {
  const _RowsPlan({
    required this.size,
    required this.heights,
    required this.gap,
  });

  final double size;
  final List<double> heights;
  final double gap;

  static const double leadGap = 12;
  static const double labelGap = 3;

  double get height =>
      heights.fold(0.0, (a, b) => a + b) +
      gap * math.max(0, heights.length - 1);

  /// The heights of [pills] at [size] in [width], led by [lead] and, with
  /// [label], their subjects' names over them.
  static List<double> heightsOf(
    BuildContext context,
    _Measure m,
    List<Pill> pills,
    double width,
    double size, {
    required double lead,
    bool label = false,
  }) {
    final double words = width - lead - leadGap;
    return [
      for (final Pill pill in pills)
        math.max(
          lead,
          (label
                  ? m.height(
                          _subjectOf(context, pill),
                          _labelStyle(pill.color),
                          words,
                        ) +
                        labelGap
                  : 0) +
              m.height(pill.question, _questionStyle(size), words) +
              1,
        ),
    ];
  }

  /// [pills] fitted into [room]: the largest size from [hi], at least
  /// [good] where it can, [lo] where it must, the room between them at
  /// least [gapMin].
  static _RowsPlan fit(
    BuildContext context,
    _Measure m,
    List<Pill> pills,
    double width,
    double room, {
    required double hi,
    required double good,
    required double lo,
    required double gapMin,
    required double lead,
    bool label = false,
  }) {
    if (pills.isEmpty) return const _RowsPlan(size: 0, heights: [], gap: 0);
    List<double> at(double s) =>
        heightsOf(context, m, pills, width, s, lead: lead, label: label);
    bool fits(double s) =>
        at(s).fold(0.0, (a, b) => a + b) + gapMin * (pills.length - 1) <= room;
    final double s = _Fit.size(hi, good, lo, fits);
    return _RowsPlan(size: s, heights: at(s), gap: gapMin);
  }

  /// Whether they fit [room] at [floor] or more.
  static bool fitsAt(
    BuildContext context,
    _Measure m,
    List<Pill> pills,
    double width,
    double room,
    double floor, {
    required double gapMin,
    required double lead,
    bool label = false,
  }) {
    final List<double> h = heightsOf(
      context,
      m,
      pills,
      width,
      floor,
      lead: lead,
      label: label,
    );
    return h.fold(0.0, (a, b) => a + b) + gapMin * (pills.length - 1) <= room;
  }

  /// This plan with the room between rows opened by up to [extra], to at
  /// most [gapMax].
  _RowsPlan opened(double extra, double gapMax) {
    if (heights.length < 2 || extra <= 0) return this;
    final double more = math.min(extra / (heights.length - 1), gapMax - gap);
    if (more <= 0) return this;
    return _RowsPlan(size: size, heights: heights, gap: gap + more);
  }
}

// ── C: light ──────────────────────────────────────────────────────────────

/// C: black, lit from its corners by the day's colours — the first card's
/// from the top, the last card's from the foot, the middle one's faintly
/// from the side — and every card its subject's mark on a disc of its
/// colour. The cover and the story set the first question large, over the
/// other four; the list sets the five alike, each under its subject's name.
class _LightLook extends StatelessWidget {
  const _LightLook({
    required this.summary,
    required this.five,
    required this.date,
    required this.layout,
  });

  final DaySummary summary;
  final List<Pill> five;
  final String date;
  final DayLayout layout;

  static List<_Light> lightsOf(List<Pill> five, {bool tall = false}) {
    // A story is taller than it is wide: its lights reach as far down it.
    final double r = tall ? 1.3 : 1.0;
    if (five.isEmpty) return const [];
    final Color first = five.first.color;
    final Color last = five.length > 1 ? five.last.color : first;
    final Color middle = five[five.length ~/ 2].color;
    return [
      _Light(
        first,
        const Alignment(1.15, -1.1),
        radius: 1.15 * r,
        strength: 0.4,
      ),
      _Light(
        last,
        const Alignment(-1.15, 1.1),
        radius: 1.05 * r,
        strength: 0.32,
      ),
      _Light(
        middle,
        const Alignment(-1.25, -0.2),
        radius: 0.75,
        strength: 0.14,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool tall = layout == DayLayout.story;
    return _Frame(
      summary: summary,
      date: date,
      tall: tall,
      lights: lightsOf(five, tall: tall),
      body: layout == DayLayout.list
          ? _LightList(five: five)
          : _LightCover(five: five, tall: tall),
    );
  }
}

/// C's cover and story: the first card's subject and question large, a
/// hairline, and the other four with their marks.
class _LightCover extends StatelessWidget {
  const _LightCover({required this.five, required this.tall});

  final List<Pill> five;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    if (five.isEmpty) return const SizedBox.shrink();
    final Pill hero = five.first;
    final List<Pill> rest = five.sublist(1);
    final double disc = tall ? 34 : 28;
    final double lead = tall ? 30 : 24;
    final double heroHi = tall ? 30 : 24;
    final double heroLo = tall ? 19 : 16;
    final double ruleMin = tall ? 22 : 16;
    final double ruleMax = tall ? 40 : 28;
    final double gapMin = tall ? 12 : 9;
    final double gapMax = tall ? 24 : 16;
    final double hi = tall ? 17 : 14;
    final double good = tall ? 14 : 12.25;
    final double lo = tall ? 12.5 : 11;
    final TextStyle label = _labelStyle(hero.color, size: tall ? 11.5 : 10);
    final String subject = _subjectOf(context, hero);
    return LayoutBuilder(
      builder: (context, box) {
        final _Measure m = _Measure(context);
        final double width = box.maxWidth;
        final double room = box.maxHeight;
        final double head = math.max(
          disc,
          m.height(subject, label, width - disc - 10),
        );
        double heroHeight(double s) =>
            head + 10 + m.height(hero.question, _questionStyle(s), width) + 1;

        // The first question as large as it can be with the four keeping a
        // comfortable size; failing that, a readable one; failing that, the
        // first as small as it goes and the four below their floor.
        double heroSize = heroLo;
        _RowsPlan? rows;
        for (final double floor in [good, lo]) {
          for (double s = heroHi; s >= heroLo; s -= 1) {
            final double left = room - heroHeight(s) - ruleMin;
            if (_RowsPlan.fitsAt(
              context,
              m,
              rest,
              width,
              left,
              floor,
              gapMin: gapMin,
              lead: lead,
            )) {
              heroSize = s;
              rows = _RowsPlan.fit(
                context,
                m,
                rest,
                width,
                left,
                hi: hi,
                good: floor,
                lo: floor,
                gapMin: gapMin,
                lead: lead,
              );
              break;
            }
          }
          if (rows != null) break;
        }
        rows ??= _RowsPlan.fit(
          context,
          m,
          rest,
          width,
          room - heroHeight(heroLo) - ruleMin,
          hi: lo,
          good: lo,
          lo: lo,
          gapMin: gapMin,
          lead: lead,
        );
        final double top = heroHeight(heroSize);
        double left = room - top - ruleMin - rows.height;
        final _RowsPlan list = rows.opened(left * 0.6, gapMax);
        left -= list.height - rows.height;
        final double rule =
            ruleMin + math.max(0.0, math.min(left, ruleMax - ruleMin));
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: top,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: head,
                      child: Row(
                        children: [
                          _Disc(pill: hero, size: disc),
                          const SizedBox(width: 10),
                          Expanded(child: Text(subject, style: label)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    BalancedText(
                      hero.question,
                      style: _questionStyle(heroSize),
                    ),
                  ],
                ),
              ),
              if (rest.isNotEmpty) ...[
                SizedBox(
                  height: rule,
                  child: const Center(child: _Rule()),
                ),
                _QuestionRows(
                  pills: rest,
                  size: list.size,
                  heights: list.heights,
                  gap: list.gap,
                  leadWidth: lead,
                  lead: (_, pill) => _Disc(pill: pill, size: lead),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// C's list: the five alike, each its mark, its subject's name and its
/// question, parted by hairlines.
class _LightList extends StatelessWidget {
  const _LightList({required this.five});

  final List<Pill> five;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final _Measure m = _Measure(context);
        const double lead = 30;
        final _RowsPlan first = _RowsPlan.fit(
          context,
          m,
          five,
          box.maxWidth,
          box.maxHeight,
          hi: 15,
          good: 12.5,
          lo: 11,
          gapMin: 12,
          lead: lead,
          label: true,
        );
        final _RowsPlan plan = first.opened(box.maxHeight - first.height, 24);
        return Center(
          child: _QuestionRows(
            pills: five,
            size: plan.size,
            heights: plan.heights,
            gap: plan.gap,
            leadWidth: lead,
            label: true,
            lead: (_, pill) => _Disc(pill: pill, size: lead),
          ),
        );
      },
    );
  }
}

// ── B: the card whole ─────────────────────────────────────────────────────

/// A card whole, at [width] across and its own proportion: its front as
/// the reader met it, drawing and all — the card's own picture, never cut —
/// or, on a card in words, or a drawn one whose picture will not come, the
/// card in words as the app draws it, in small.
class _WholeCard extends StatelessWidget {
  const _WholeCard({
    required this.pill,
    required this.width,
    this.sharp = false,
  });

  final Pill pill;
  final double width;

  /// Drawn from the large picture, for a card set large: the small one,
  /// blown up, is soft. The small one stays under it until it comes.
  final bool sharp;

  double get height => width / WebThumbs.aspect;

  @override
  Widget build(BuildContext context) {
    final String? ref = CardThumb.refOf(pill, CardSide.front);
    final BorderRadius round = BorderRadius.circular(width * 34 / 366);
    final Widget words = _CardInWords(pill: pill);
    Widget picture(String at) => Positioned.fill(
      child: Image(
        image: CardThumb.image(CardThumb.urlOf(at)),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ref == null ? pill.color : groundOf(pill),
        borderRadius: round,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: round,
        border: Border.all(
          color: DayPicture._ink.withValues(alpha: 0.12),
          width: 0.6,
        ),
      ),
      child: ref == null
          ? words
          : Stack(
              fit: StackFit.expand,
              children: [
                words,
                picture(ref),
                if (sharp) picture(CardThumb.largeOf(ref)),
              ],
            ),
    );
  }
}

/// A card in words, whole, as the app draws its front: laid out at the
/// card's own size and shrunk to the room, so its type, its head and its
/// margins are the card's.
class _CardInWords extends StatelessWidget {
  const _CardInWords({required this.pill});

  final Pill pill;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: Container(
        width: 366,
        height: 606,
        decoration: BoxDecoration(gradient: _graded(pill)),
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CardMark(pill: pill, size: 16, ink: pill.ink),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _subjectOf(context, pill),
                    maxLines: 1,
                    softWrap: false,
                    style: AppText.label(
                      size: 11,
                      spacing: 1.4,
                      color: pill.ink.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: ScaledText(
                text: pill.question,
                min: 18,
                max: 34,
                alignment: Alignment.centerLeft,
                styleFor: (size) => AppText.display(
                  size: size,
                  weight: FontWeight.w600,
                  height: 1.08,
                  spacing: -0.4 - size * 0.028,
                  color: pill.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A light of [colour] thrown on what lies under [child], round it: the
/// glow behind the card set large. Screened, so it lights the black and
/// leaves white words white.
class _Glow extends StatelessWidget {
  const _Glow({
    required this.colour,
    required this.size,
    required this.reach,
    required this.child,
  });

  final Color colour;

  /// The child's size: the light is a circle round its middle, wide enough
  /// to reach [reach] past its longer side, and gone at its own edge, so it
  /// never ends in a line.
  final Size size;

  /// How far past the child's longer side the light reaches.
  final double reach;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double s = colour.computeLuminance() > 0.7 ? 0.3 : 0.55;
    final double side = math.max(size.width, size.height) + reach * 2;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          left: (size.width - side) / 2,
          top: (size.height - side) / 2,
          width: side,
          height: side,
          child: DecoratedBox(
            decoration: BoxDecoration(
              backgroundBlendMode: BlendMode.screen,
              gradient: RadialGradient(
                radius: 0.5,
                colors: [
                  colour.withValues(alpha: s),
                  colour.withValues(alpha: s * 0.3),
                  colour.withValues(alpha: 0),
                ],
                stops: const [0, 0.48, 1],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// B: the cards. On the cover and the story the day's first drawn card —
/// the first card, on a day with none — as the reader met it, the whole
/// card, large, lit from behind by its colour, its question beside it in
/// the picture's type, and the other four by their marks. On the list the
/// five cards whole in a row, over their questions, numbered as they came.
class _CardLook extends StatelessWidget {
  const _CardLook({
    required this.summary,
    required this.five,
    required this.date,
    required this.layout,
  });

  final DaySummary summary;
  final List<Pill> five;
  final String date;
  final DayLayout layout;

  @override
  Widget build(BuildContext context) {
    final bool tall = layout == DayLayout.story;
    final Pill? hero = layout == DayLayout.list
        ? null
        : DayPicture.heroOf(five);
    final Color wash =
        hero?.color ?? (five.isEmpty ? DayPicture._flame : five.first.color);
    return _Frame(
      summary: summary,
      date: date,
      tall: tall,
      lights: [
        _Light(wash, const Alignment(0.9, -1.25), radius: 1.35, strength: 0.3),
        if (five.length > 1)
          _Light(
            five.last.color,
            const Alignment(-1.2, 1.15),
            radius: 0.9,
            strength: 0.16,
          ),
      ],
      body: switch (layout) {
        DayLayout.list => _CardStrip(five: five),
        DayLayout.cover => _CardBeside(five: five, spec: _BesideSpec.cover),
        DayLayout.story => _CardBeside(five: five, spec: _BesideSpec.story),
      },
    );
  }
}

/// How B sets the card beside its question, on the cover or on a story:
/// the card's height, largest and smallest; the question's size beside it;
/// the marks and the type of the other four; the room between them.
class _BesideSpec {
  const _BesideSpec({
    required this.cardMax,
    required this.cardComfort,
    required this.cardMin,
    required this.heroHi,
    required this.heroLo,
    required this.label,
    required this.lead,
    required this.hi,
    required this.good,
    required this.lo,
    required this.gapMin,
    required this.gapMax,
    required this.ruleMin,
    required this.ruleMax,
  });

  final double cardMax;

  /// The card's height the four give up their comfortable size to keep,
  /// before it comes down any further: B is the card.
  final double cardComfort;
  final double cardMin;
  final double heroHi;
  final double heroLo;
  final double label;
  final double lead;
  final double hi;
  final double good;
  final double lo;
  final double gapMin;
  final double gapMax;
  final double ruleMin;
  final double ruleMax;

  static const double beside = 16;

  static const _BesideSpec cover = _BesideSpec(
    cardMax: 228,
    cardComfort: 168,
    cardMin: 116,
    heroHi: 18,
    heroLo: 12.5,
    label: 10,
    lead: 24,
    hi: 14,
    good: 12.25,
    lo: 11,
    gapMin: 8,
    gapMax: 14,
    ruleMin: 16,
    ruleMax: 26,
  );

  static const _BesideSpec story = _BesideSpec(
    cardMax: 300,
    cardComfort: 220,
    cardMin: 150,
    heroHi: 21,
    heroLo: 14,
    label: 11.5,
    lead: 30,
    hi: 16.5,
    good: 14,
    lo: 12,
    gapMin: 11,
    gapMax: 22,
    ruleMin: 20,
    ruleMax: 36,
  );
}

/// B's cover and story: the card set large, whole, lit from behind, on the
/// right; its subject and question beside it; and the other four under
/// them with their marks.
class _CardBeside extends StatelessWidget {
  const _CardBeside({required this.five, required this.spec});

  final List<Pill> five;
  final _BesideSpec spec;

  @override
  Widget build(BuildContext context) {
    final Pill? hero = DayPicture.heroOf(five);
    if (hero == null) return const SizedBox.shrink();
    final List<Pill> rest = [
      for (final Pill p in five)
        if (!identical(p, hero)) p,
    ];
    final String subject = _subjectOf(context, hero);
    final TextStyle label = _labelStyle(hero.color, size: spec.label);
    return LayoutBuilder(
      builder: (context, box) {
        final _Measure m = _Measure(context);
        final double width = box.maxWidth;
        final double room = box.maxHeight;

        // The question beside a card [h] tall: the largest size at which it
        // stands no taller than the card, down to the floor, and the height
        // it takes there.
        (double, double) words(double h) {
          final double at = width - h * WebThumbs.aspect - _BesideSpec.beside;
          final double head = m.height(subject, label, at) + 7;
          double tall(double s) =>
              head + m.height(hero.question, _questionStyle(s), at) + 1;
          final double s =
              _Fit.largest(spec.heroHi, spec.heroLo, (s) => tall(s) <= h) ??
              spec.heroLo;
          return (s, tall(s));
        }

        _RowsPlan rowsIn(double left, double floor) => _RowsPlan.fit(
          context,
          m,
          rest,
          width,
          left,
          hi: math.max(spec.hi, floor),
          good: floor,
          lo: floor,
          gapMin: spec.gapMin,
          lead: spec.lead,
        );

        // The card as large as it can be with the four keeping a
        // comfortable size, down to the size it is kept at; then the four
        // at a readable size, the card from its largest to its smallest;
        // failing that, the card at its smallest and the four as small as
        // it takes.
        (double, double, double, _RowsPlan)? plan;
        for (final (double floor, double least) in [
          (spec.good, spec.cardComfort),
          (spec.lo, spec.cardMin),
        ]) {
          for (double h = spec.cardMax; h >= least; h -= 4) {
            final (double s, double t) = words(h);
            final double top = math.max(h, t);
            final double left = room - top - spec.ruleMin;
            if (_RowsPlan.fitsAt(
              context,
              m,
              rest,
              width,
              left,
              floor,
              gapMin: spec.gapMin,
              lead: spec.lead,
            )) {
              plan = (h, s, top, rowsIn(left, floor));
              break;
            }
          }
          if (plan != null) break;
        }
        if (plan == null) {
          final double h = spec.cardMin;
          final (double s, double t) = words(h);
          final double top = math.max(h, t);
          plan = (h, s, top, rowsIn(room - top - spec.ruleMin, spec.lo));
        }
        final (double h, double s, double top, _RowsPlan rows) = plan;
        double left = room - top - spec.ruleMin - rows.height;
        final _RowsPlan list = rows.opened(left * 0.6, spec.gapMax);
        left -= list.height - rows.height;
        final double rule =
            spec.ruleMin +
            math.max(0.0, math.min(left, spec.ruleMax - spec.ruleMin));
        final double w = h * WebThumbs.aspect;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: top,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(subject, style: label),
                          const SizedBox(height: 7),
                          BalancedText(hero.question, style: _questionStyle(s)),
                        ],
                      ),
                    ),
                    const SizedBox(width: _BesideSpec.beside),
                    _Glow(
                      colour: hero.color,
                      size: Size(w, h),
                      reach: w * 0.5,
                      child: _WholeCard(pill: hero, width: w, sharp: true),
                    ),
                  ],
                ),
              ),
              if (rest.isNotEmpty) ...[
                SizedBox(
                  height: rule,
                  child: const Center(child: _Rule()),
                ),
                _QuestionRows(
                  pills: rest,
                  size: list.size,
                  heights: list.heights,
                  gap: list.gap,
                  leadWidth: spec.lead,
                  lead: (_, pill) => _Disc(pill: pill, size: spec.lead),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// B's list: the five cards whole in a row, as they came, and their
/// questions under them, each numbered in its card's colour.
class _CardStrip extends StatelessWidget {
  const _CardStrip({required this.five});

  final List<Pill> five;

  @override
  Widget build(BuildContext context) {
    if (five.isEmpty) return const SizedBox.shrink();
    const double gap = 8;
    const double lead = 16;
    return LayoutBuilder(
      builder: (context, box) {
        final _Measure m = _Measure(context);
        final double width = box.maxWidth;
        final double card = (width - gap * (five.length - 1)) / five.length;
        final double strip = card / WebThumbs.aspect;
        final double room = box.maxHeight - strip - 18;
        final _RowsPlan first = _RowsPlan.fit(
          context,
          m,
          five,
          width,
          room,
          hi: 14.5,
          good: 12.25,
          lo: 11,
          gapMin: 9,
          lead: lead,
        );
        final _RowsPlan plan = first.opened(room - first.height, 16);
        final double under =
            18 + math.max(0.0, math.min(room - plan.height, 14));
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: strip,
                child: Row(
                  children: [
                    for (int i = 0; i < five.length; i++) ...[
                      if (i > 0) const SizedBox(width: gap),
                      _WholeCard(pill: five[i], width: card),
                    ],
                  ],
                ),
              ),
              SizedBox(height: under),
              _QuestionRows(
                pills: five,
                size: plan.size,
                heights: plan.heights,
                gap: plan.gap,
                leadWidth: lead,
                rules: false,
                lead: (i, pill) => Text(
                  '${i + 1}',
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w800,
                    height: 1.1,
                    color: _onBlack(pill.color),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
