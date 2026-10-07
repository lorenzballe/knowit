/// Something on the card the reader plays with before reading the answer.
///
/// A diagram is looked at; a scene is handled. Moving a slider and watching
/// the noise of a street barely drop as half its cars vanish teaches what a
/// sentence about logarithms cannot — the reader feels the curve with a
/// thumb. Like [Diagram] it is data, never pixels: a few numbers from the
/// card, drawn live in the card's colours.
///
/// Every kind has one job. `slider` is "move it and watch": one quantity the
/// reader controls, one that follows it along measured points, and a line
/// that changes at the moments that matter.
///
/// The JSON is kept as it arrived, and a kind this app does not know is
/// ignored rather than refused, so a newer bank never breaks an older app.
///
/// Each other kind lives in its own file under `scenes/`, model beside view:
/// `count` bet on a number, `draw` draw the curve you expect, `sort` swipe
/// things into two piles, `timeline` place events in time, `hold` hold for as
/// long as you think, `rank` put things in order, `sample` grow a sample,
/// `trick` find the trick in a chart, `why` ask why until the root cause,
/// `poll` answer for yourself then see everyone, `story` a case in scenes
/// with a guess at what happens next, `translate` jargon into plain words,
/// `match` pair things up, `clues` guess from clues that arrive one by one.
library;

import 'scenes/count.dart';
import 'scenes/draw.dart';
import 'scenes/hold.dart';
import 'scenes/rank.dart';
import 'scenes/sample.dart';
import 'scenes/sort.dart';
import 'scenes/timeline.dart';
import 'scenes/trick.dart';
import 'scenes/why.dart';
import 'scenes/poll.dart';
import 'scenes/story.dart';
import 'scenes/translate.dart';
import 'scenes/match.dart';
import 'scenes/clues.dart';
import 'scenes/beauty.dart';
import 'scenes/music.dart';
import 'scenes/news.dart';

export 'scenes/count.dart';
export 'scenes/draw.dart';
export 'scenes/hold.dart';
export 'scenes/rank.dart';
export 'scenes/sample.dart';
export 'scenes/sort.dart';
export 'scenes/timeline.dart';
export 'scenes/trick.dart';
export 'scenes/why.dart';
export 'scenes/poll.dart';
export 'scenes/story.dart';
export 'scenes/translate.dart';
export 'scenes/match.dart';
export 'scenes/clues.dart';
export 'scenes/beauty.dart';
export 'scenes/music.dart';
export 'scenes/news.dart';

abstract class Scene {
  final Map<String, Object?> raw;
  const Scene(this.raw);

  static Scene? fromJson(Object? json, {Object? id}) {
    if (json == null) return null;
    if (json is! Map) throw FormatException('scene is not an object', id);
    final raw = json.cast<String, Object?>();
    num n(String k, {num? or}) {
      final v = raw[k];
      if (v is num) return v;
      if (or != null) return or;
      throw FormatException('scene.$k must be a number', id);
    }

    String t(String k) => raw[k] is String ? raw[k] as String : '';
    switch (raw['type']) {
      case 'slider':
        final pts = <(double, double)>[];
        for (final p in (raw['points'] as List? ?? const [])) {
          if (p is! List || p.length != 2 || p[0] is! num || p[1] is! num) {
            throw FormatException('scene.points must be [x, y] pairs', id);
          }
          pts.add(((p[0] as num).toDouble(), (p[1] as num).toDouble()));
        }
        if (pts.length < 2) throw FormatException('scene needs two points', id);
        pts.sort((a, b) => a.$1.compareTo(b.$1));
        final notes = <SceneNote>[
          for (final m in (raw['notes'] as List? ?? const []))
            if (m is Map && m['at'] is num && m['text'] is String)
              SceneNote((m['at'] as num).toDouble(), m['text'] as String),
        ]..sort((a, b) => a.at.compareTo(b.at));
        return SliderScene(
          raw,
          control: t('control'),
          controlUnit: t('controlUnit'),
          readout: t('readout'),
          readoutUnit: t('readoutUnit'),
          start: n('start', or: pts.first.$1).toDouble(),
          step: n('step', or: 1).toDouble(),
          points: pts,
          notes: notes,
          decimals: n('decimals', or: 0).toInt(),
        );
      case 'count':
        return CountScene.parse(raw, id);
      case 'draw':
        return DrawScene.parse(raw, id);
      case 'hold':
        return HoldScene.parse(raw, id);
      case 'rank':
        return RankScene.parse(raw, id);
      case 'sample':
        return SampleScene.parse(raw, id);
      case 'sort':
        return SortScene.parse(raw, id);
      case 'timeline':
        return TimelineScene.parse(raw, id);
      case 'trick':
        return TrickScene.parse(raw, id);
      case 'why':
        return WhyScene.parse(raw, id);
      case 'poll':
        return PollScene.parse(raw, id);
      case 'story':
        return StoryScene.parse(raw, id);
      case 'translate':
        return TranslateScene.parse(raw, id);
      case 'match':
        return MatchScene.parse(raw, id);
      case 'clues':
        return CluesScene.parse(raw, id);
      case 'beauty':
        return BeautyScene.parse(raw, id);
      case 'music':
        return MusicScene.parse(raw, id);
      case 'news':
        return NewsScene.parse(raw, id);
      default:
        return null;
    }
  }
}

/// A line that holds from [at] on the slider until the next one.
class SceneNote {
  final double at;
  final String text;
  const SceneNote(this.at, this.text);
}

/// Move it and watch.
class SliderScene extends Scene {
  /// What the reader moves ("Cars taken off the road") and its unit.
  final String control;
  final String controlUnit;

  /// What follows it ("Quieter by") and its unit.
  final String readout;
  final String readoutUnit;

  final double start;
  final double step;

  /// Measured or worked-out pairs, joined by straight lines between them.
  final List<(double, double)> points;
  final List<SceneNote> notes;
  final int decimals;

  const SliderScene(
    super.raw, {
    required this.control,
    required this.controlUnit,
    required this.readout,
    required this.readoutUnit,
    required this.start,
    required this.step,
    required this.points,
    required this.notes,
    required this.decimals,
  });

  double get from => points.first.$1;
  double get to => points.last.$1;
  double get low => points.map((p) => p.$2).reduce((a, b) => a < b ? a : b);
  double get high => points.map((p) => p.$2).reduce((a, b) => a > b ? a : b);

  /// The readout at [x], along the straight line between its neighbours.
  double valueAt(double x) {
    if (x <= points.first.$1) return points.first.$2;
    for (var i = 1; i < points.length; i++) {
      final (x0, y0) = points[i - 1];
      final (x1, y1) = points[i];
      if (x <= x1) return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
    }
    return points.last.$2;
  }

  /// The line in force at [x]: the last note whose point has been reached.
  String noteAt(double x) {
    var out = '';
    for (final n in notes) {
      if (x + 1e-9 >= n.at) out = n.text;
    }
    return out;
  }
}
