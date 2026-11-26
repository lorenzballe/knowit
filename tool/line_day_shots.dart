// Photographs the line of the day (explore/blocks/core/line_block.dart) where
// Explore has it, under the news, on a 390 by 844 phone at its three pixels
// a point: three moments of its outline at night (widgets/glow_outline.dart,
// moving), the outline held still for a reader who asked for less motion,
// and the card on paper.
//
//   SHOTS=/some/folder flutter test tool/line_day_shots.dart \
//     --dart-define=LINE_OUTLINE=sheen
//
// LINE_OUTLINE picks the outline (sheen, breath or spectrum; the block's
// own when not given), and the pictures are named after it. They land in
// SHOTS, or in the gallery (tool/shots/gallery/lineday/), which is not
// kept. A camera, not a check: it lives outside test/ so CI never runs it.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/news_paper.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/explore/blocks/core/line_block.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/widgets/glow_outline.dart';
import 'package:astuto/widgets/web/card_thumb.dart';

import '../test/explore/core_harness.dart';
import '../test/web/thumbs_harness.dart' show onePixel;

/// The sections around the line, as the server's document has them.
List<ExploreSection> _sections() {
  final Map<String, Object?> config = jsonDecode(
    File('web/remote/config.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final List<Object?> all =
      (config['explore'] as Map<String, Object?>)['sections'] as List<Object?>;
  // From the news to the paths: what stands above and below the line on
  // any day, the weekday's surprise among them.
  final List<String> ids = [
    for (final Object? s in all)
      if (s is Map<String, Object?>) s['id'] as String,
  ];
  final int from = ids.indexOf('news-today'), to = ids.indexOf('paths');
  return sectionsOf([
    for (final Object? s in all.sublist(from, to + 1))
      s as Map<String, Object?>,
  ]);
}

/// This morning's paper, three stories, so the news stands above the line
/// as it does on a phone.
void _paperOfToday() {
  final String day = dateKey(DateTime.now());
  Map<String, Object?> story(
    String id,
    String topic,
    String headline,
    String outlet,
    String figure,
    String question,
    String answer,
  ) => {
    'id': 'news-$day-$id',
    'topic': topic,
    'kind': 'read',
    'difficulty': 'easy',
    'principle': 'none',
    'question': question,
    'answer': answer,
    'move': 'A small shortage makes a big price.',
    'keywords': [id],
    'era': 'recent',
    'region': 'world',
    'hook': 'mechanism',
    'mood': 'practical',
    'numeracy': 1,
    'abstraction': 'concrete',
    'shelf_life': 'months',
    'mature': false,
    'language': 'en',
    'figure': 'none',
    'scene': {
      'type': 'news',
      'headline': headline,
      'outlet': outlet,
      'reported': [outlet],
      'date': day,
      'panels': [
        {'label': 'What happened', 'figure': figure, 'text': headline},
        {'label': 'Why', 'text': answer},
        {'label': 'What it means for you', 'text': question},
      ],
      'expires': '2099-12-31',
    },
    'source': outlet,
    'source_kind': 'news_archive',
    'reference': 'https://www.bbc.co.uk/news/articles/example',
    'written': day,
  };
  NewsPaper.adopt(day, [
    story(
      'eggs',
      'economics',
      'Egg prices hit a record as bird flu empties henhouses',
      'BBC News',
      r'$6.23',
      'Bird flu cost American farms a slice of their hens. Why did the price '
          'of eggs double?',
      'Because almost nobody stops buying eggs, so a shortfall of under a '
          'tenth was settled by price.',
    ),
    story(
      'heat',
      'nature',
      'Europe records its hottest October in a century',
      'Reuters',
      '+2.1 °C',
      'Why does a warm autumn mean a worse allergy spring?',
      'Plants that never stop growing make pollen for longer.',
    ),
    story(
      'probe',
      'space',
      'A probe launched in 1977 is still sending data home',
      'AP',
      '24 bn km',
      'How does Voyager 1 still talk to Earth with a 23-watt radio?',
      'Dishes 70 metres wide listen for it, and they are very patient.',
    ),
  ]);
}

void main() {
  setUpAll(loadFonts);

  final String label = kLineOutline.name;

  /// When the three moments of each outline are taken, in milliseconds: a
  /// third of the way round and two for the ones that go round, and for the
  /// breath its faintest, half way and brightest.
  const Map<GlowOutlineStyle, List<int>> moments = {
    GlowOutlineStyle.sheen: [0, 3300, 6700],
    GlowOutlineStyle.breath: [0, 1500, 3000],
    GlowOutlineStyle.spectrum: [0, 6700, 13300],
  };

  testWidgets('the line of the day in Explore', (tester) async {
    final String out =
        Platform.environment['SHOTS'] ?? 'tool/shots/gallery/lineday';
    CardThumb.image = (url) => onePixel;
    // One day's line, whatever the day the camera runs: the long one of
    // 25 November 2026, the hardest to frame.
    final app = await readyApp(const {}, () => DateTime(2026, 11, 25, 12));
    _paperOfToday();
    final List<ExploreSection> sections = _sections();

    /// The screen as the phone draws it, three pixels a point: a golden
    /// file is one a point, too coarse for a hairline.
    Future<void> shoot(String name) async {
      RenderObject screen = tester.renderObject(find.byType(Scaffold));
      while (!screen.isRepaintBoundary) {
        screen = screen.parent!;
      }
      final Future<ui.Image> image = (screen.debugLayer! as OffsetLayer)
          .toImage(screen.paintBounds, pixelRatio: 3);
      await tester.runAsync(() async {
        final ui.Image shot = await image;
        final png = await shot.toByteData(format: ui.ImageByteFormat.png);
        shot.dispose();
        File('$out/line-$label-$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png!.buffer.asUint8List());
      });
    }

    /// The page drawn, and scrolled so the line stands in the middle of
    /// the screen, the news above it and the next shelf below.
    Future<void> show({bool paper = false, bool calm = false}) async {
      await pumpSections(
        tester,
        CoreHost(app, language: 'it'),
        sections,
        size: const Size(390, 844),
        paper: paper,
        calm: calm,
        locale: const Locale('it'),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final Finder card = find.byKey(const ValueKey('day-line'));
      final double top = tester.getTopLeft(card).dy;
      final ScrollPosition list = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      list.jumpTo((list.pixels + top - 330).clamp(0, list.maxScrollExtent));
      await tester.pump(const Duration(milliseconds: 100));
    }

    await show();
    expect(find.byType(DayLineCard), findsOneWidget);
    int at = 0;
    for (final (int i, int ms) in moments[kLineOutline]!.indexed) {
      await tester.pump(Duration(milliseconds: ms - at));
      at = ms;
      await shoot('dark-$i');
    }

    await show(calm: true);
    await tester.pump(const Duration(milliseconds: 3000));
    await shoot('still');

    await show(paper: true);
    await tester.pump(const Duration(milliseconds: 1500));
    await shoot('light');

    // Nothing left running once the page is gone.
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
