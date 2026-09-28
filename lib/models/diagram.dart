/// The picture a card can carry: what it shows, as data, never as pixels.
///
/// A diagram is a handful of numbers and labels taken from the card itself —
/// a hundred people and the three who have the disease, a curve through five
/// measured points, two things a millionfold apart on one axis. The app draws
/// it live, in the card's own colour, and animates it in the order a person
/// explaining it at a whiteboard would: the frame first, then the thing, then
/// the comparison that is the point. Stored as data it costs a few hundred
/// bytes, stays sharp at any size and follows the theme, which a rendered
/// video could do none of.
///
/// Every kind has one job. `dots` is a share of a population; `bars` compares
/// a few amounts; `scale` puts things orders of magnitude apart on one
/// logarithmic line; `line` is a quantity that changes along another; `split`
/// is one whole in parts; `timeline` is when; `area` is how much bigger, as
/// the eye judges bigger; `tree` is a crowd split by one question and then
/// another, in counts. A card uses the one that shows its point and no
/// other, and a card whose point is not a quantity carries none.
///
/// The JSON is kept exactly as it arrived, so a card read and written back
/// comes out byte for byte the same. A kind this version of the app does not
/// know is ignored rather than refused: a newer bank must not take down an
/// older app.
library;

sealed class Diagram {
  /// The object as it appeared in the card, for writing it back unchanged.
  final Map<String, Object?> raw;

  /// A line under the picture, when the picture needs one.
  final String caption;

  const Diagram(this.raw, this.caption);

  /// Reads the `diagram` field. Null when there is none or when its kind is
  /// one this app does not draw; a [FormatException] when a kind it does
  /// draw is malformed, since the bank's gate should never have let it by.
  static Diagram? fromJson(Object? json, {Object? id}) {
    if (json == null) return null;
    if (json is! Map) throw FormatException('diagram is not an object', id);
    final raw = json.cast<String, Object?>();
    final r = _Reader(raw, id);
    final caption = r.text('caption');
    return switch (r.text('type')) {
      'dots' => DotsDiagram(
        raw,
        caption,
        total: r.integer('total'),
        groups: r.objects('groups').map((g) {
          final gr = _Reader(g, id);
          return DotGroup(
            n: gr.integer('n'),
            label: gr.text('label'),
            highlight: gr.flag('hi'),
            spread: gr.flag('spread'),
          );
        }).toList(),
      ),
      'bars' => BarsDiagram(
        raw,
        caption,
        unit: r.text('unit'),
        log: r.flag('log'),
        items: r.items(),
      ),
      'scale' => ScaleDiagram(
        raw,
        caption,
        unit: r.text('unit'),
        items: r.items(),
      ),
      'area' => AreaDiagram(
        raw,
        caption,
        unit: r.text('unit'),
        items: r.items(),
      ),
      'split' => SplitDiagram(
        raw,
        caption,
        unit: r.text('unit'),
        parts: r.items(key: 'parts'),
      ),
      'line' => LineDiagram(
        raw,
        caption,
        x: r.axis('x'),
        y: r.axis('y'),
        series: r.objects('series').map((s) {
          final sr = _Reader(s, id);
          return LineSeries(
            label: sr.text('label'),
            highlight: sr.flag('hi'),
            points: sr.points('points'),
          );
        }).toList(),
        marks: r.objects('marks', optional: true).map((m) {
          final mr = _Reader(m, id);
          return LineMark(
            x: mr.number('x'),
            y: mr.number('y'),
            label: mr.text('label'),
          );
        }).toList(),
      ),
      'timeline' => TimelineDiagram(
        raw,
        caption,
        from: r.number('from'),
        to: r.number('to'),
        unit: r.text('unit'),
        events: r.objects('events', optional: true).map((e) {
          final er = _Reader(e, id);
          return TimelineEvent(
            at: er.number('at'),
            label: er.text('label'),
            highlight: er.flag('hi'),
          );
        }).toList(),
        spans: r.objects('spans', optional: true).map((s) {
          final sr = _Reader(s, id);
          return TimelineSpan(
            from: sr.number('from'),
            to: sr.number('to'),
            label: sr.text('label'),
            highlight: sr.flag('hi'),
          );
        }).toList(),
      ),
      'tree' => TreeDiagram(raw, caption, root: r.node()),
      _ => null,
    };
  }
}

/// A crowd split and split again, in counts rather than percentages: a
/// thousand screened, ten of them ill, nine of those caught and eighty-nine
/// of the healthy flagged too. Natural frequencies are how people get
/// conditional probability right, so this is the picture for it.
class TreeDiagram extends Diagram {
  final TreeNode root;
  const TreeDiagram(super.raw, super.caption, {required this.root});
}

class TreeNode {
  final double n;
  final String label;
  final bool highlight;
  final List<TreeNode> children;
  const TreeNode({
    required this.n,
    required this.label,
    this.highlight = false,
    this.children = const [],
  });

  int get depth => children.isEmpty ? 0 : 1 + children.map((c) => c.depth).reduce((a, b) => a > b ? a : b);
}

/// One labelled amount: a bar, a point on a scale, a circle, a slice.
class DiagramItem {
  final String label;
  final double value;
  final bool highlight;
  const DiagramItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });
}

/// A share of a population, as a grid of people or things.
class DotsDiagram extends Diagram {
  /// 100 or 1,000: a hundred reads as per cent, a thousand as per mille.
  final int total;

  /// Filled in order, the first the strongest; the dots left over are the
  /// rest of the population, drawn faint.
  final List<DotGroup> groups;

  const DotsDiagram(
    super.raw,
    super.caption, {
    required this.total,
    required this.groups,
  });
}

class DotGroup {
  final int n;
  final String label;
  final bool highlight;

  /// Scattered through the crowd rather than gathered in one corner: where
  /// false alarms actually fall, as against the cases, drawn together so
  /// they can be counted.
  final bool spread;

  const DotGroup({
    required this.n,
    required this.label,
    this.highlight = false,
    this.spread = false,
  });
}

/// A few amounts side by side, on a linear or a logarithmic axis.
class BarsDiagram extends Diagram {
  final String unit;
  final bool log;
  final List<DiagramItem> items;
  const BarsDiagram(
    super.raw,
    super.caption, {
    required this.unit,
    required this.log,
    required this.items,
  });
}

/// Things orders of magnitude apart, on one logarithmic line.
class ScaleDiagram extends Diagram {
  final String unit;
  final List<DiagramItem> items;
  const ScaleDiagram(
    super.raw,
    super.caption, {
    required this.unit,
    required this.items,
  });
}

/// How much bigger, drawn as the eye judges bigger: by area.
class AreaDiagram extends Diagram {
  final String unit;
  final List<DiagramItem> items;
  const AreaDiagram(
    super.raw,
    super.caption, {
    required this.unit,
    required this.items,
  });
}

/// One whole, in its parts.
class SplitDiagram extends Diagram {
  final String unit;
  final List<DiagramItem> parts;
  const SplitDiagram(
    super.raw,
    super.caption, {
    required this.unit,
    required this.parts,
  });
}

class DiagramAxis {
  final String label;
  final double min;
  final double max;
  final bool log;
  const DiagramAxis({
    required this.label,
    required this.min,
    required this.max,
    this.log = false,
  });
}

/// A quantity that changes along another.
class LineDiagram extends Diagram {
  final DiagramAxis x;
  final DiagramAxis y;
  final List<LineSeries> series;
  final List<LineMark> marks;
  const LineDiagram(
    super.raw,
    super.caption, {
    required this.x,
    required this.y,
    required this.series,
    required this.marks,
  });
}

class LineSeries {
  final String label;
  final bool highlight;
  final List<(double, double)> points;
  const LineSeries({
    required this.label,
    required this.points,
    this.highlight = false,
  });
}

class LineMark {
  final double x;
  final double y;
  final String label;
  const LineMark({required this.x, required this.y, required this.label});
}

/// When: moments and stretches on one line of years.
class TimelineDiagram extends Diagram {
  final double from;
  final double to;

  /// Empty for years (the usual case, with BC and AD); otherwise what the
  /// line counts, minutes or days or seconds, written after each number.
  final String unit;
  final List<TimelineEvent> events;
  final List<TimelineSpan> spans;
  const TimelineDiagram(
    super.raw,
    super.caption, {
    required this.from,
    required this.to,
    this.unit = '',
    required this.events,
    required this.spans,
  });
}

class TimelineEvent {
  final double at;
  final String label;
  final bool highlight;
  const TimelineEvent({
    required this.at,
    required this.label,
    this.highlight = false,
  });
}

class TimelineSpan {
  final double from;
  final double to;
  final String label;
  final bool highlight;
  const TimelineSpan({
    required this.from,
    required this.to,
    required this.label,
    this.highlight = false,
  });
}

/// Reads fields out of one JSON object, naming the card when it fails.
class _Reader {
  final Map<String, Object?> raw;
  final Object? id;
  const _Reader(this.raw, this.id);

  Never _bad(String what) => throw FormatException('diagram: $what', id);

  String text(String key) {
    final v = raw[key];
    if (v == null) return '';
    if (v is! String) _bad('$key is not text');
    return v;
  }

  bool flag(String key) => raw[key] == true;

  double number(String key) {
    final v = raw[key];
    if (v is! num) _bad('$key is not a number');
    return v.toDouble();
  }

  int integer(String key) {
    final v = raw[key];
    if (v is! int) _bad('$key is not a whole number');
    return v;
  }

  List<Map<String, Object?>> objects(String key, {bool optional = false}) {
    final v = raw[key];
    if (v == null && optional) return const [];
    if (v is! List || v.isEmpty) _bad('$key is not a list');
    return [
      for (final e in v)
        if (e is Map) e.cast<String, Object?>() else _bad('$key holds a non-object'),
    ];
  }

  List<DiagramItem> items({String key = 'items'}) => objects(key).map((o) {
    final r = _Reader(o, id);
    return DiagramItem(
      label: r.text('label'),
      value: r.number('value'),
      highlight: r.flag('hi'),
    );
  }).toList();

  DiagramAxis axis(String key) {
    final v = raw[key];
    if (v is! Map) _bad('$key is not an axis');
    final r = _Reader(v.cast<String, Object?>(), id);
    return DiagramAxis(
      label: r.text('label'),
      min: r.number('min'),
      max: r.number('max'),
      log: r.flag('log'),
    );
  }

  /// This object as a tree node, its `branches` read as its children.
  TreeNode node() => TreeNode(
    n: number('n'),
    label: text('label'),
    highlight: flag('hi'),
    children: [
      for (final b in objects('branches', optional: true)) _Reader(b, id).node(),
    ],
  );

  List<(double, double)> points(String key) {
    final v = raw[key];
    if (v is! List || v.length < 2) _bad('$key needs two points or more');
    return [
      for (final p in v)
        if (p is List && p.length == 2 && p[0] is num && p[1] is num)
          ((p[0] as num).toDouble(), (p[1] as num).toDouble())
        else
          _bad('$key holds a point that is not [x, y]'),
    ];
  }
}
