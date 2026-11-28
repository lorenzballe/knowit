part of 'paywall_screen.dart';

// The paywall's prototypes, B, C and D, which the developer tools put on a
// phone in place of A, the paywall as it ships (DebugLooks.paywall, Profile
// → Debug). Each is A made better, never a new design: the badge, the
// headline with its one painted word, the line, every feature with its
// line, the plans, the button, the links, the three lights — and three
// things the paywalls that sell best all have:
//
// * the product, not drawings of it: the app's own cards, real ones from
//   the bank, in the reader's subjects, drifting slowly past where the
//   drawn marks were;
// * the free days as the days they go by, each with its date — today
//   everything opens and nothing is paid, the day the app reminds the
//   reader, the day the year starts at the store's price — right over the
//   button they explain. A plan charged today says that instead;
// * the plans as A has them, the year picked, with its month and the
//   saving against the month.
//
// B is that. C is B opening on what the reader told the app: the area of
// life they want to get better at (their goal) in the headline, and the
// subjects they leaned the mix towards in the line and the cards. D is B in
// two steps: what Astute+ is, with the room to say it, and one button; then
// the plans, rising over it as a sheet, with the free days laid out day by
// day — the same page under it the whole time.

/// The subjects a strip of cards goes through, in an order that puts no two
/// near hues side by side.
const List<String> _stripOrder = [
  'psychology',
  'economics',
  'space',
  'history',
  'science',
  'human_body',
  'technology',
  'thinking',
  'language',
  'pop_culture',
  'nature',
  'philosophy',
  'maths',
  'weird_facts',
  'medicine',
  'food',
  'art',
  'music',
  'cinema',
  'sport',
  'life',
];

/// The subjects the reader leaned the mix towards, the most first: the two
/// or three set above all the others, or the few they kept. None for a mix
/// left as it came, all the way in, or never set: then nothing stands out,
/// and no subject is named as the reader's.
List<String> leaningSubjects(AppState app) {
  final List<MapEntry<String, double>> mix =
      app.topicWeights.entries
          .where((e) => e.key != 'thinking' && e.value > 0)
          .where((e) => kTopics.containsKey(e.key))
          .toList()
        ..sort((a, b) {
          final int by = b.value.compareTo(a.value);
          return by != 0
              ? by
              : kTopicOrder
                    .indexOf(a.key)
                    .compareTo(kTopicOrder.indexOf(b.key));
        });
  for (int k = 3; k >= 1; k--) {
    if (mix.length <= k || mix[k - 1].value > mix[k].value) {
      return [for (final e in mix.take(k)) e.key];
    }
  }
  return const [];
}

/// [subjects] by name, in the reader's language, as a sentence reads them:
/// "Psychology, Economics and Science". Null for none.
String? _subjectsSaid(AppLocalizations l, List<String> subjects) {
  final List<String> names = [for (final k in subjects) l.subjectName(k)];
  return switch (names) {
    [] => null,
    [final a] => a,
    [final a, final b] => l.subjectsTwo(a, b),
    [final a, final b, final c, ...] => l.subjectsThree(a, b, c),
  };
}

/// What C opens on: on the door everyone else comes through, the reader's
/// own — the area of life they want to get better at in the headline, the
/// subjects they leaned towards in the line — wherever they told the app;
/// the door's own words wherever they did not. A door reached for one
/// thing (the record, the five, the days read, a path) still opens on
/// that thing: it is what they came for.
({String title, String mark, String line}) _madeFor(
  AppLocalizations l,
  PaywallVariant variant,
  AppState app,
) {
  final opening = _opening(l, variant, app);
  if (variant != PaywallVariant.outcome) return opening;
  final Goal? goal = Goal.of(app.goal);
  final String? subjects = _subjectsSaid(l, leaningSubjects(app));
  return (
    title: goal == null ? opening.title : l.paywallGoalTitle(goal.key),
    mark: goal == null ? opening.mark : l.paywallGoalMark(goal.key),
    line: subjects == null ? opening.line : l.paywallMadeLine(subjects),
  );
}

/// Real cards from the bank for a strip, [count] at most, going round
/// [subjects] in their order so that the colours change from one to the
/// next: each short enough to stand whole in a tile of [tile], none a
/// film, the same all day and new the next.
List<Pill> _previewCards(
  BuildContext context, {
  required List<String> subjects,
  required Size tile,
  required int count,
}) {
  final DateTime now = DateTime.now();
  final int seed = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(2026)).inDays;
  int mix(String id) {
    int h = 0x811c9dc5 ^ seed;
    for (final int c in id.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h;
  }

  final TileLook look = TileLook.forBox(tile);
  final List<String> names = [
    for (final String k in subjects)
      if (kTopics[k] case final TopicStyle style) style.name,
  ];
  final Map<String, List<Pill>> pools = {for (final String n in names) n: []};
  for (final Pill p in PillBank.cards) {
    final List<Pill>? pool = pools[p.topic];
    // Long questions are passed over before they are measured: no tile of
    // a strip holds one.
    if (pool == null || p.question.length > 96) continue;
    if (!dealableOn(p, now) || videoCardOf(p) != null) continue;
    pool.add(p);
  }
  for (final List<Pill> pool in pools.values) {
    pool.sort((a, b) => mix(a.id).compareTo(mix(b.id)));
  }
  final List<Pill> cards = [];
  final Map<String, int> next = {};
  bool more = true;
  while (cards.length < count && more) {
    more = false;
    for (final String n in names) {
      final List<Pill> pool = pools[n]!;
      int i = next[n] ?? 0;
      while (i < pool.length && !questionFits(context, pool[i], tile, look)) {
        i++;
      }
      if (i < pool.length) {
        cards.add(pool[i]);
        more = true;
        i++;
      }
      next[n] = i;
      if (cards.length >= count) break;
    }
  }
  return cards;
}

/// A row of the app's own cards drifting slowly to the left, from one edge
/// of the screen to the other, fading in and out at both: what Astute+
/// deals, shown rather than drawn. Still for anyone who asked for less
/// motion. Looked at, not read aloud: the words around it say what it is.
class _CardStrip extends StatelessWidget {
  const _CardStrip({super.key, required this.cards, required this.tile});

  final List<Pill> cards;

  /// The size of each card.
  final Size tile;

  /// The room between two cards.
  static const double gap = 10;

  /// How fast it drifts, in points a second: slow enough to read a card as
  /// it goes by.
  static const double speed = 11;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final double step = tile.width + gap;
    final double run = step * cards.length;
    // Started half a card in, so the first card does not sit flush on the
    // edge as if the row began there.
    final double start = step * 0.6;
    return ExcludeSemantics(
      child: SizedBox(
        height: tile.height,
        child: LayoutBuilder(
          builder: (context, room) {
            final int copies = ((room.maxWidth + start) / run).ceil() + 1;
            // Laid out once; the drift only moves it.
            final Widget row = RepaintBoundary(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int c = 0; c < copies; c++)
                    for (final Pill p in cards)
                      Padding(
                        padding: EdgeInsetsDirectional.only(end: gap),
                        child: BoxTile(pill: p, box: tile),
                      ),
                ],
              ),
            );
            return ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => LinearGradient(
                colors: const [
                  Color(0x00FFFFFF),
                  Colors.white,
                  Colors.white,
                  Color(0x00FFFFFF),
                ],
                stops: [
                  0,
                  (26 / r.width).clamp(0.0, 0.5),
                  1 - (26 / r.width).clamp(0.0, 0.5),
                  1,
                ],
              ).createShader(r),
              child: ClipRect(
                child: AmbientLoop(
                  period: Duration(milliseconds: (run / speed * 1000).round()),
                  reverse: false,
                  builder: (context, t) => OverflowBox(
                    alignment: AlignmentDirectional.centerStart,
                    minWidth: 0,
                    maxWidth: double.infinity,
                    child: Transform.translate(
                      offset: Offset(-(start + run * t), 0),
                      child: row,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The size a card is laid out at before it is made small for a feature's
/// mark: a tile of Explore's, so its question is set as Explore sets it.
const Size _thumbBase = Size(96, 120);

/// A feature's mark, made of the app's own cards in place of A's drawing:
/// one card, or for the five of the day three in a fan, or for the days
/// read three in a pile — real cards of the reader's subjects, small — and
/// at its corner the feature's own drawn mark, in A's colour for it, so
/// what each line is about still shows at a glance.
class _FeatureCards extends StatelessWidget {
  const _FeatureCards({
    required this.cards,
    required this.glyph,
    required this.hue,
  });

  final List<Pill> cards;
  final _Glyph glyph;
  final Color hue;

  /// The room the mark takes, and the size of each card in it.
  static const double side = 40;
  static const Size card = Size(28, 35);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    Widget face(Pill pill) => SizedBox(
      width: card.width,
      height: card.height,
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: _thumbBase.width,
          height: _thumbBase.height,
          child: BoxTile(pill: pill, box: _thumbBase),
        ),
      ),
    );
    final List<Widget> layers = switch (glyph) {
      _Glyph.five => [
        for (final (int i, Pill pill) in cards.take(3).indexed)
          Transform.rotate(
            angle: const [-0.3, 0.0, 0.3][i],
            alignment: Alignment.bottomCenter,
            child: face(pill),
          ),
      ],
      _Glyph.read => [
        for (final (int i, Pill pill) in cards.take(3).indexed)
          Transform.translate(
            offset: Offset(-4.0 + 4.0 * i, -4.0 + 4.0 * i),
            child: face(pill),
          ),
      ],
      _ => [
        Transform.rotate(
          angle: glyph.index.isEven ? -0.07 : 0.07,
          child: face(cards.first),
        ),
      ],
    };
    final Color ground = p.surface;
    return ExcludeSemantics(
      child: SizedBox(
        width: side,
        height: side,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            ...layers,
            if (glyph != _Glyph.five)
              PositionedDirectional(
                end: -3,
                bottom: -3,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      hue.withValues(alpha: p.isDark ? 0.16 : 0.12),
                      ground,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: ground, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: CustomPaint(
                    size: const Size.square(13),
                    painter: _GlyphPainter(glyph, hue, ground),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Every feature, one under the other, each its name and its line, as A has
/// them — marked, where A drew a mark, by real cards ([_FeatureCards]), or,
/// with no cards to show, by a thin rule in the colour A gave its mark.
class _PlainFeatures extends StatelessWidget {
  const _PlainFeatures({
    super.key,
    required this.features,
    this.cards = const [],
    this.gap = 11,
  });

  final List<_Feature> features;

  /// The cards the marks are made of, in order: three for the five of the
  /// day and three for the days read, one for each of the others.
  final List<Pill> cards;

  /// The room between two features.
  final double gap;

  /// How many cards [features] take for their marks.
  static int cardsFor(List<_Feature> features) => [
    for (final _Feature f in features)
      f.glyph == _Glyph.five || f.glyph == _Glyph.read ? 3 : 1,
  ].fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final bool marked = cards.length >= cardsFor(features);
    int next = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (int i, _Feature f) in features.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
            child: RiseIn.staggered(
              i,
              step: const Duration(milliseconds: 45),
              child: _row(
                context,
                f,
                marked
                    ? cards.sublist(
                        next,
                        next += f.glyph == _Glyph.five || f.glyph == _Glyph.read
                            ? 3
                            : 1,
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  Widget _row(BuildContext context, _Feature f, List<Pill>? mine) {
    final l = context.l10n;
    final p = context.p;
    final List<Color> hues = p.isDark
        ? _FeatureList._night
        : _FeatureList._paper;
    final Color hue = hues[f.glyph.index % hues.length];
    final Widget words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              f.title,
              style: AppText.body(
                size: 15,
                weight: FontWeight.w700,
                height: 1.22,
                color: p.ink,
              ),
            ),
            if (f.fresh)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: hue.withValues(alpha: 0.7)),
                ),
                child: Text(
                  l.perkNew,
                  style: AppText.label(
                    size: 9,
                    weight: FontWeight.w800,
                    spacing: 1,
                    height: 1.1,
                    color: hue,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          f.sub,
          style: AppText.body(
            size: 13.5,
            height: 1.3,
            color: p.ink.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
    if (mine != null) {
      return Row(
        key: ValueKey('paywall-feature-${f.glyph.name}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FeatureCards(cards: mine, glyph: f.glyph, hue: hue),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: words,
            ),
          ),
        ],
      );
    }
    return Container(
      key: ValueKey('paywall-feature-${f.glyph.name}'),
      padding: const EdgeInsetsDirectional.only(start: 13, top: 1, bottom: 1),
      decoration: BoxDecoration(
        border: BorderDirectional(start: BorderSide(color: hue, width: 2)),
      ),
      child: words,
    );
  }
}

/// The free days on one line, over the button they explain: today, when
/// everything opens and nothing is paid; the day the app reminds the
/// reader, where a notification can reach them; and the day the plan starts,
/// at the store's own price. Three stops on a hairline — the first at the
/// start, the last at the end — each its day and a few words under it, in
/// the headline's three colours: today's dot filled, the days to come open.
class _TrialRail extends StatelessWidget {
  const _TrialRail({
    super.key,
    required this.from,
    required this.days,
    required this.price,
    required this.remind,
  });

  /// The day the trial would start.
  final DateTime from;

  /// How many days free the store gives this reader.
  final int days;

  /// The plan's price as the store writes it, with how often it is charged.
  final String price;

  /// Whether the reminder before the charge can reach the reader.
  final bool remind;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final List<Color> hues = p.isDark ? _perkHues : _perkHuesOnPaper;
    final String locale = Localizations.localeOf(context).toString();
    String date(int after) => formatDay(
      DateFormat.MMMd(locale),
      DateTime(from.year, from.month, from.day + after),
    );
    const int warn = AppState.kTrialWarningDays;
    final List<({String day, String what, Color hue})> stops = [
      (day: l.trialStepToday, what: l.paywallStepFree, hue: hues[0]),
      if (remind && days > warn)
        (day: date(days - warn), what: l.paywallStepRemind, hue: hues[1]),
      (day: date(days), what: price, hue: hues[2]),
    ];
    final TextStyle dayStyle = AppText.body(
      size: 13,
      weight: FontWeight.w700,
      height: 1.25,
      color: p.ink,
    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final TextStyle whatStyle = AppText.body(
      size: 12.5,
      weight: FontWeight.w500,
      height: 1.25,
      color: p.ink.withValues(alpha: 0.58),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 12,
          child: CustomPaint(
            painter: _RailLinePainter(
              hues: [for (final s in stops) s.hue],
              rail: p.ink.withValues(alpha: 0.16),
              ground: p.surface,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (int i, s) in stops.indexed)
              Expanded(
                key: ValueKey('paywall-rail-$i'),
                child: Column(
                  crossAxisAlignment: i == 0
                      ? CrossAxisAlignment.start
                      : i == stops.length - 1
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.center,
                  children: [
                    FitText(
                      s.day,
                      maxLines: 1,
                      minSize: 10,
                      textAlign: _alignOf(i, stops.length),
                      style: dayStyle,
                    ),
                    const SizedBox(height: 1),
                    FitText(
                      s.what,
                      maxLines: 2,
                      minSize: 10,
                      textAlign: _alignOf(i, stops.length),
                      style: i == stops.length - 1
                          ? whatStyle.copyWith(
                              color: p.ink.withValues(alpha: 0.82),
                              fontWeight: FontWeight.w600,
                            )
                          : whatStyle,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  static TextAlign _alignOf(int i, int n) => i == 0
      ? TextAlign.start
      : i == n - 1
      ? TextAlign.end
      : TextAlign.center;
}

/// The rail of [_TrialRail]: a hairline from the first dot to the last, and
/// a dot for each stop — at the start, the middle and the end — in its
/// colour, the first filled.
class _RailLinePainter extends CustomPainter {
  const _RailLinePainter({
    required this.hues,
    required this.rail,
    required this.ground,
  });

  final List<Color> hues;
  final Color rail;
  final Color ground;

  @override
  void paint(Canvas canvas, Size size) {
    const double r = 6;
    final double y = size.height / 2;
    final int n = hues.length;
    double xOf(int i) => n == 1 ? r : r + (size.width - 2 * r) * i / (n - 1);
    canvas.drawLine(
      Offset(xOf(0), y),
      Offset(xOf(n - 1), y),
      Paint()
        ..strokeWidth = 1.5
        ..color = rail,
    );
    for (int i = 0; i < n; i++) {
      final Offset c = Offset(xOf(i), y);
      canvas.drawCircle(c, r, Paint()..color = ground);
      if (i == 0) {
        canvas.drawCircle(c, 5, Paint()..color = hues[i]);
      } else {
        canvas.drawCircle(
          c,
          4.25,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..color = hues[i],
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RailLinePainter old) =>
      old.rail != rail || old.ground != ground || !_sameHues(old.hues, hues);

  static bool _sameHues(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// One line under the button, a check before it: that nothing more is to
/// come, or, for a plan charged today, that it is.
class _CheckLine extends StatelessWidget {
  const _CheckLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ExcludeSemantics(
        child: Icon(
          Icons.check_circle_rounded,
          size: 14,
          color: _smallPrintStyle(context).color,
        ),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: _smallPrintStyle(context),
        ),
      ),
    ],
  );
}

/// Two or more things under the button, each with its check: side by side
/// where they fit on one line, one under the other where they do not. One
/// that takes two lines on a narrow phone is a list's item: its check on
/// its first line, its words from there, the two in the middle together —
/// not the check at the edge and the words away from it.
class _CheckLines extends StatelessWidget {
  const _CheckLines(this.lines, {super.key});

  final List<String> lines;

  static const double _check = 14;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = _smallPrintStyle(context);
    // The check in the middle of the first line, at whatever size the
    // reader's text is.
    final double line =
        MediaQuery.textScalerOf(context).scale(style.fontSize ?? 12.5) *
        (style.height ?? 1.4);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 3,
      children: [
        for (final String text in lines)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: math.max(0, (line - _check) / 2),
                ),
                child: ExcludeSemantics(
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: _check,
                    color: style.color,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  textWidthBasis: TextWidthBasis.longestLine,
                  style: style,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// The evidence for what Astute+ trains, only as far as it holds up: that
/// calibration can be measured and trained with feedback, as forecasting
/// research does, and that Astute measures the reader's — no percentage,
/// since the size of the Good Judgment Project's training effect is
/// disputed (Hauenstein et al., Psychological Science, 2025). Under it,
/// smaller, where it comes from, a page's mark before it, as the site
/// marks a source.
class _ScienceLine extends StatelessWidget {
  const _ScienceLine({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: ExcludeSemantics(
            child: CustomPaint(
              size: const Size(13, 15),
              painter: _SourceMark(p.ink.withValues(alpha: 0.45)),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: l.paywallScience),
                const TextSpan(text: '\n'),
                TextSpan(
                  text: l.paywallScienceSource,
                  style: AppText.body(
                    size: 11.5,
                    weight: FontWeight.w500,
                    height: 1.45,
                    color: p.ink.withValues(alpha: 0.42),
                  ),
                ),
              ],
            ),
            style: AppText.body(
              size: 13,
              weight: FontWeight.w500,
              height: 1.35,
              color: p.ink.withValues(alpha: 0.66),
            ),
          ),
        ),
      ],
    );
  }
}

/// A page with its corner folded, in the line weight of the features'
/// marks: the site's mark for a source.
class _SourceMark extends CustomPainter {
  const _SourceMark(this.ink);

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width, h = size.height;
    final double fold = w * 0.38;
    final Paint line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final Path page = Path()
      ..moveTo(1, 1)
      ..lineTo(w - fold, 1)
      ..lineTo(w - 1, fold)
      ..lineTo(w - 1, h - 1)
      ..lineTo(1, h - 1)
      ..close();
    canvas.drawPath(page, line);
    canvas.drawPath(
      Path()
        ..moveTo(w - fold, 1)
        ..lineTo(w - fold, fold)
        ..lineTo(w - 1, fold),
      line,
    );
  }

  @override
  bool shouldRepaint(_SourceMark old) => old.ink != ink;
}

/// D's second step: the plans, rising over the first as a sheet, with the
/// free days laid out day by day over them. The page stays under it,
/// dimmed; a tap on it, or the back gesture, lowers the sheet again. What
/// is in the sheet is there only while it is up, or on its way down.
class _PlansSheet extends StatefulWidget {
  const _PlansSheet({
    required this.up,
    required this.onDown,
    required this.children,
  });

  final bool up;
  final VoidCallback onDown;
  final List<Widget> children;

  @override
  State<_PlansSheet> createState() => _PlansSheetState();
}

class _PlansSheetState extends State<_PlansSheet> {
  /// Whether the sheet's content is built: from the moment it is asked up
  /// until it is all the way down again.
  late bool _present = widget.up;

  @override
  void didUpdateWidget(_PlansSheet old) {
    super.didUpdateWidget(old);
    if (widget.up) _present = true;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final bool up = widget.up;
    final double homeBar = MediaQuery.viewPaddingOf(context).bottom;
    final double height = MediaQuery.sizeOf(context).height;
    final double top = MediaQuery.paddingOf(context).top;
    const Duration time = Duration(milliseconds: 320);
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          ignoring: !up,
          child: GestureDetector(
            key: const ValueKey('paywall-sheet-scrim'),
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDown,
            child: AnimatedOpacity(
              opacity: up ? 1 : 0,
              duration: time,
              curve: Curves.easeOut,
              child: const ColoredBox(color: Color(0x99000000)),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            ignoring: !up,
            child: AnimatedSlide(
              offset: up ? Offset.zero : const Offset(0, 1.05),
              duration: time,
              curve: up ? Curves.easeOutCubic : Curves.easeInCubic,
              onEnd: () {
                if (!widget.up && mounted) setState(() => _present = false);
              },
              child: !_present
                  ? const SizedBox(width: double.infinity, height: 1)
                  : ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: height - top - 24),
                      child: Container(
                        key: const ValueKey('paywall-sheet'),
                        decoration: BoxDecoration(
                          color: p.surfaceRaised,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: p.ink.withValues(alpha: 0.1),
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 40,
                              offset: const Offset(0, -10),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            22,
                            10,
                            22,
                            homeBar > 0 ? homeBar : 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: 38,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: p.ink.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              ...widget.children,
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
