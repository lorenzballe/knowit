// `trick`: the data is read strictly, and the reader can tap the parts of a
// chart, be told when they miss, find the trick (or ask to be shown it) and
// reach the honest chart on any phone, in any height the card gives it.
//
//   flutter test test/scenes/trick_test.dart --update-goldens --dart-define=SHOTS=true
//
// With SHOTS the widget tests also photograph each step into
// tool/shots/cards/ (gitignored), to be looked at rather than kept.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/models/scene.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/scene_view.dart';

const _shots = bool.fromEnvironment('SHOTS');

Map<String, Object?> _tax() => {
  'type': 'trick',
  'trick': 'truncated',
  'outlet': 'Fox Business, 2012',
  'headline': 'If Bush tax cuts expire',
  'honest': 'Top tax rate: up 4.6 points',
  'label': 'Top income tax rate',
  'unit': '%',
  'decimals': 1,
  'columns': ['Now', 'Jan 1, 2013'],
  'values': [35, 39.6],
  'from': 34,
  'to': 42,
  'found': 'Yes: the axis starts at 34%, not at zero.',
  'miss': 'That part tells the truth. Look at the bottom of the bars.',
  'misses': {'marks': "The numbers are right. It's the heights that lie."},
  'name': 'The cut-off axis',
  'lesson': "A bar's length only means something from zero.",
};

/// The chart shown at a 2015 hearing: two lines, each on its own scale.
Map<String, Object?> _dual() => {
  'type': 'trick',
  'trick': 'dual',
  'headline': 'Abortions up, screenings down',
  'honest': 'Screenings fell; abortions barely moved',
  'label': 'Services a year',
  'columns': ['2006', '2013'],
  'values': [2007371, 935573],
  'values2': [289750, 327000],
  'series': ['Screenings', 'Abortions'],
  'from': 500000,
  'to': 2100000,
  'from2': 250000,
  'to2': 340000,
  'found': 'Yes: each line has its own scale.',
  'miss': 'Fair enough. Compare the two sides of the chart.',
  'name': 'Two axes, two stories',
  'lesson': 'Two scales can make any two lines cross.',
};

/// The 2009 pie whose slices add up to 193%.
Map<String, Object?> _pie() => {
  'type': 'trick',
  'trick': 'pie',
  'headline': '2012 presidential run',
  'honest': 'Each name, out of 100%',
  'label': 'Back each candidate',
  'columns': ['Palin', 'Huckabee', 'Romney'],
  'values': [70, 63, 60],
  'found': 'Yes: the slices add up to 193%.',
  'miss': 'The numbers are fine. Add them up.',
  'name': 'A pie past 100%',
  'lesson': 'A pie is one whole. If its parts add to more, it is the wrong chart.',
};

Map<String, Object?> _flipped() => {
  'type': 'trick',
  'trick': 'flipped',
  'headline': 'Deaths fell after the law',
  'honest': 'Deaths rose after the law',
  'label': 'Deaths a year',
  'columns': ['2000', '2002', '2004', '2006', '2008', '2010'],
  'values': [500, 520, 510, 700, 760, 740],
  'from': 0,
  'to': 800,
  'found': 'Yes: zero is at the top.',
  'miss': 'Look at which way the numbers run.',
  'name': 'Upside-down axis',
  'lesson': 'Check which way the axis runs before you read up as more.',
};

Map<String, Object?> _stretched() => {
  'type': 'trick',
  'trick': 'stretched',
  'headline': 'Temperatures: flat as a board',
  'honest': 'Up more than a degree',
  'label': 'Average temperature',
  'unit': '°C',
  'decimals': 1,
  'columns': ['1900', '1950', '2000', '2020'],
  'values': [13.7, 13.9, 14.3, 14.8],
  'from': -10,
  'to': 40,
  'honestFrom': 13,
  'honestTo': 15,
  'found': 'Yes: the axis spans 50 degrees.',
  'miss': 'Look at how tall the axis is.',
  'name': 'Stretched axis',
  'lesson': 'A scale far wider than the data flattens any change.',
};

List<Map<String, Object?>> _samples() =>
    (jsonDecode(File('tool/cards/samples/trick.json').readAsStringSync())
            as List)
        .cast<Map<String, Object?>>();

TrickScene _parse(Map<String, Object?> raw) =>
    Scene.fromJson(raw, id: 'test') as TrickScene;

Pill _card(String id, String topic, Map<String, Object?> scene) =>
    cardFromJson({
      'id': id,
      'topic': topic,
      'kind': 'read',
      'question': 'This chart ran on the news. Where is the trick?',
      'answer': 'In the drawing, not the numbers.',
      'move': 'Read the axis before the bars.',
      'source': 'Huff, How to Lie with Statistics (1954)',
      'scene': scene,
    });

Future<void> _loadFonts() async {
  for (final family in ['Fraunces', 'Figtree']) {
    final loader = FontLoader(family)
      ..addFont(rootBundle.load('assets/fonts/$family.ttf'));
    await loader.load();
  }
}

Future<void> _phone(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// A card as the deck shows it, on a phone of [size].
Future<void> _showCard(WidgetTester tester, Pill pill, Size size) async {
  await _phone(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 60, 14, 96),
            child: PillCard(pill: pill, flipped: false),
          ),
        ),
      ),
    ),
  );
}

/// Just the scene, in a box of a given height.
Widget _host(
  Map<String, Object?> raw, {
  required double height,
  Color ground = const Color(0xFFFFE600),
  Color ink = const Color(0xFF10100C),
  bool still = false,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAstutoTheme(Brightness.dark),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: still),
      child: Scaffold(
        backgroundColor: ground,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Center(
            child: SizedBox(
              height: height,
              child: SceneView(scene: _parse(raw), ink: ink, ground: ground),
            ),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _settle(WidgetTester tester) async {
  for (var f = 0; f < 40; f++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Where a part of the chart is: its screen-reader node, which covers
/// exactly the area a finger can tap.
Offset _part(WidgetTester tester, String label) =>
    tester.getCenter(find.bySemanticsLabel(label));

Future<void> _shoot(WidgetTester tester, String name) async {
  if (!_shots) return;
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../../tool/shots/cards/scene-trick-$name.png'),
  );
}

void main() {
  setUpAll(() async {
    if (_shots) await _loadFonts();
  });

  group('parse', () {
    test('reads a truncated bar chart, its honest range from zero', () {
      final s = _parse(_tax());
      expect(s.trick, TrickSceneKind.truncated);
      expect(s.form, TrickSceneForm.bars);
      expect(s.outlet, 'Fox Business, 2012');
      expect(s.columns, ['Now', 'Jan 1, 2013']);
      expect(s.values, [35, 39.6]);
      expect(s.shown, (lo: 34.0, hi: 42.0));
      expect(s.fair, (lo: 0.0, hi: 40.0));
      expect(s.spot, {TrickSceneRegion.yaxis});
      expect(s.regions, [
        TrickSceneRegion.headline,
        TrickSceneRegion.label,
        TrickSceneRegion.yaxis,
        TrickSceneRegion.xaxis,
        TrickSceneRegion.marks,
      ]);
      expect(s.missFor(TrickSceneRegion.marks), contains('heights'));
      expect(s.missFor(TrickSceneRegion.xaxis), contains('tells the truth'));
      expect(s.honestLabel, s.label);
      expect(s.honestValues, s.values);
      expect(s.refills, isFalse);
    });

    test('every sample card reads, and each trick finds its own part', () {
      final byTrick = {
        for (final c in _samples())
          (c['scene']! as Map)['trick']: _parse(
            (c['scene']! as Map).cast<String, Object?>(),
          ),
      };
      final window = byTrick['window']!;
      expect(window.form, TrickSceneForm.line);
      expect((window.first, window.last), (18, 32));
      expect(window.spot, {TrickSceneRegion.xaxis});
      // The kept years sit in a tidy band; the whole series from zero.
      expect(window.shown.lo, greaterThan(0));
      expect(window.fair.lo, 0);
      expect(window.fair.hi, greaterThanOrEqualTo(1.17));

      final totals = byTrick['totals']!;
      expect(totals.spot, {TrickSceneRegion.label});
      expect(totals.refills, isTrue);
      expect(totals.rates[0], closeTo(3.06 / 1438 * 1000, 1e-9));
      expect(totals.honestValues, totals.rates);
      expect(totals.honestLabel, contains('per person'));
    });

    test('the other tricks: dual, pie, flipped, stretched', () {
      final dual = _parse(_dual());
      expect(dual.form, TrickSceneForm.line);
      expect(dual.spot, {TrickSceneRegion.yaxis, TrickSceneRegion.yaxis2});
      expect(dual.regions, contains(TrickSceneRegion.yaxis2));
      expect(dual.shown2, (lo: 250000.0, hi: 340000.0));
      expect(dual.fair.lo, 0);
      expect(dual.fair.hi, greaterThanOrEqualTo(2007371));

      final pie = _parse(_pie());
      expect(pie.form, TrickSceneForm.pie);
      expect(pie.spot, {TrickSceneRegion.marks});
      expect(pie.regions, isNot(contains(TrickSceneRegion.yaxis)));

      final flipped = _parse(_flipped());
      expect(flipped.form, TrickSceneForm.line);
      expect(flipped.shown, flipped.fair);

      final stretched = _parse(_stretched());
      expect(stretched.shown, (lo: -10.0, hi: 40.0));
      expect(stretched.fair, (lo: 13.0, hi: 15.0));

      // A spot can be named, and named as a list.
      expect(_parse({..._tax(), 'spot': 'marks'}).spot, {
        TrickSceneRegion.marks,
      });
      expect(
        _parse({
          ..._tax(),
          'spot': ['yaxis', 'headline'],
        }).spot,
        {TrickSceneRegion.yaxis, TrickSceneRegion.headline},
      );
    });

    test('round ticks', () {
      expect(TrickScene.ticks((lo: 34, hi: 42)), [34, 36, 38, 40, 42]);
      expect(TrickScene.ticks((lo: 0, hi: 40)), [0, 10, 20, 30, 40]);
      expect(TrickScene.ticks((lo: 0, hi: 1.25)), [0, 0.5, 1]);
    });

    test('refuses what it cannot draw', () {
      final bad = <Map<String, Object?>>[
        {..._tax(), 'trick': 'sneaky'},
        {..._tax()}..remove('from'),
        {..._tax(), 'from': 36},
        {..._tax(), 'from': 0},
        {..._tax(), 'chart': 'pie'},
        {
          ..._tax(),
          'values': [35],
        },
        {
          ..._tax(),
          'columns': ['A'],
          'values': [35],
        },
        {..._tax(), 'headline': ''},
        {..._tax()}..remove('lesson'),
        {..._tax()}..remove('found'),
        {..._tax(), 'spot': 'yaxis2'},
        {..._tax(), 'spot': 'legend'},
        {
          ..._tax(),
          'misses': {'footer': 'x'},
        },
        {..._tax(), 'decimals': 3},
        {..._dual()}..remove('values2'),
        {..._dual(), 'from2': 300000},
        {
          ..._dual(),
          'series': ['Only'],
        },
        {
          ..._pie(),
          'values': [50, 30, 20],
        },
        {..._stretched()}..remove('honestTo'),
        {
          ..._flipped(),
          'trick': 'window',
          'window': [0, 5],
        },
        {
          ..._flipped(),
          'trick': 'window',
          'window': [3],
        },
        {
          ..._flipped(),
          'trick': 'totals',
          'per': [1, 2],
        },
      ];
      for (final raw in bad) {
        expect(() => _parse(raw), throwsFormatException, reason: '$raw');
      }
    });
  });

  group('play', () {
    for (final (name, size, height) in [
      ('small phone', const Size(360, 740), 330.0),
      ('large phone', const Size(430, 932), 520.0),
      ('back of an asking card', const Size(360, 740), 270.0),
    ]) {
      testWidgets('on a $name: miss, find the trick, see it honest', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _phone(tester, size);
        await tester.pumpWidget(_host(_tax(), height: height));
        await _settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('If Bush tax cuts expire'), findsOneWidget);
        expect(find.text('Tap your pick'), findsOneWidget);
        expect(find.text('Show me'), findsNothing);
        final slug = name.replaceAll(' ', '-');
        await _shoot(tester, 'play-$slug-0');

        // The bars: innocent, and they say why.
        await tester.tapAt(_part(tester, 'Now 35.0%, Jan 1, 2013 39.6%'));
        await _settle(tester);
        expect(find.text("The numbers are right. It's the heights that lie."),
            findsOneWidget);
        expect(find.text('Show me'), findsOneWidget);

        // The years along the bottom: innocent too, with the general line.
        await tester.tapAt(_part(tester, 'Now – Jan 1, 2013'));
        await _settle(tester);
        expect(
          find.text('That part tells the truth. Look at the bottom of the bars.'),
          findsOneWidget,
        );
        expect(find.text('If Bush tax cuts expire'), findsOneWidget);

        // The axis: found. The reader is told, then the chart is honest.
        await tester.tapAt(_part(tester, '34% – 42%'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Yes: the axis starts at 34%, not at zero.'),
            findsOneWidget);
        await _settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('Top tax rate: up 4.6 points'), findsOneWidget);
        expect(find.text('If Bush tax cuts expire'), findsNothing);
        expect(find.text('The cut-off axis'), findsOneWidget);
        expect(find.text("A bar's length only means something from zero."),
            findsOneWidget);
        expect(find.text('Show me'), findsNothing);
        // The axis now runs from zero, and says so.
        expect(find.bySemanticsLabel('0% – 40%'), findsOneWidget);
        await _shoot(tester, 'play-$slug-1');
        handle.dispose();
      });
    }

    for (final (id, raw, spot, honest) in [
      ('dual', _dual(), TrickSceneRegion.yaxis2, 'Screenings fell; abortions barely moved'),
      ('pie', _pie(), TrickSceneRegion.marks, 'Each name, out of 100%'),
      ('flipped', _flipped(), TrickSceneRegion.yaxis, 'Deaths rose after the law'),
      ('stretched', _stretched(), TrickSceneRegion.yaxis, 'Up more than a degree'),
    ]) {
      for (final (phone, size, height) in [
        ('small', const Size(360, 740), 300.0),
        ('large', const Size(430, 932), 520.0),
      ]) {
        testWidgets('$id on a $phone phone reaches the honest chart', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await _phone(tester, size);
          await tester.pumpWidget(_host(raw, height: height));
          await _settle(tester);
          await _shoot(tester, '$id-$phone-0');
          await tester.tapAt(_center(tester, _parse(raw), spot));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1200));
          await _shoot(tester, '$id-$phone-1');
          await _settle(tester);
          expect(tester.takeException(), isNull);
          expect(find.text(honest), findsOneWidget);
          expect(find.text(raw['name']! as String), findsOneWidget);
          await _shoot(tester, '$id-$phone-2');
          handle.dispose();
        });
      }
    }

    testWidgets('Show me reveals the trick without a tick', (tester) async {
      await _phone(tester, const Size(360, 740));
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_tax(), height: 400));
      await _settle(tester);
      await tester.tapAt(_part(tester, 'If Bush tax cuts expire'));
      await _settle(tester);
      await tester.tap(find.text('Show me'));
      await _settle(tester);
      expect(find.text('The cut-off axis'), findsOneWidget);
      expect(find.text('Yes: the axis starts at 34%, not at zero.'), findsNothing);
      expect(find.text('Top tax rate: up 4.6 points'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a light ink on a dark ground plays the same', (tester) async {
      final handle = tester.ensureSemantics();
      await _phone(tester, const Size(360, 740));
      await tester.pumpWidget(
        _host(
          _tax(),
          height: 400,
          ground: const Color(0xFF5A2EA6),
          ink: Colors.white,
        ),
      );
      await _settle(tester);
      await tester.tapAt(_part(tester, '34% – 42%'));
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('The cut-off axis'), findsOneWidget);
      await _shoot(tester, 'dark-end');
      handle.dispose();
    });

    testWidgets('with animations off, the honest chart is there on the next '
        'frame', (tester) async {
      final handle = tester.ensureSemantics();
      await _phone(tester, const Size(360, 740));
      await tester.pumpWidget(_host(_tax(), height: 400, still: true));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      await tester.tapAt(_part(tester, '34% – 42%'));
      await tester.pump();
      expect(find.text('Top tax rate: up 4.6 points'), findsOneWidget);
      expect(find.text('The cut-off axis'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      handle.dispose();
    });

    testWidgets('a screen reader taps the parts as buttons', (tester) async {
      final handle = tester.ensureSemantics();
      await _phone(tester, const Size(360, 740));
      await tester.pumpWidget(_host(_tax(), height: 400));
      await _settle(tester);
      expect(
        tester.getSemantics(find.bySemanticsLabel('34% – 42%')),
        isSemantics(label: '34% – 42%', isButton: true, hasTapAction: true),
      );
      tester.semantics.tap(find.semantics.byLabel('Now – Jan 1, 2013'));
      await _settle(tester);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Now – Jan 1, 2013')),
        isSemantics(
          value: 'That part tells the truth. Look at the bottom of the bars.',
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Show me')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      tester.semantics.tap(find.semantics.byLabel('34% – 42%'));
      await _settle(tester);
      expect(
        tester.getSemantics(find.bySemanticsLabel('0% – 40%')),
        isSemantics(value: 'The cut-off axis', isButton: false),
      );
      handle.dispose();
    });
  });

  group('in the deck', () {
    testWidgets('a drag on the chart does not swipe the card away, and a tap '
        'on it does not turn the card over', (tester) async {
      final handle = tester.ensureSemantics();
      await _phone(tester, const Size(360, 740));
      final pill = _card('trick-deck-test', 'economics', _tax());
      var advanced = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          home: Scaffold(
            body: PillCardStack(
              isSaved: (_) => false,
              onSave: (_) {},
              onShare: (_) {},
              isLiked: (_) => false,
              onLike: (_) {},
              deck: [pill],
              index: 0,
              onAdvance: () => advanced++,
              answerFor: (_) => null,
              reviewIds: const {},
              onAnswer: (_, _, _, _) {},
            ),
          ),
        ),
      );
      await _settle(tester);
      final bars = _part(tester, 'Now 35.0%, Jan 1, 2013 39.6%');
      await tester.dragFrom(bars, const Offset(-260, 0));
      await _settle(tester);
      expect(advanced, 0);
      expect(find.text('If Bush tax cuts expire'), findsOneWidget);

      await tester.tapAt(bars);
      await _settle(tester);
      expect(find.text('Show me'), findsOneWidget);
      expect(find.text('If Bush tax cuts expire'), findsOneWidget);
      handle.dispose();
    });
  });

  group('the sample cards', () {
    for (final phone in const {
      'small': Size(360, 740),
      'large': Size(430, 932),
    }.entries) {
      testWidgets('each plays to its end on a ${phone.key} phone', (
        tester,
      ) async {
        for (final c in _samples()) {
          final handle = tester.ensureSemantics();
          final raw = (c['scene']! as Map).cast<String, Object?>();
          final s = _parse(raw);
          final pill = cardFromJson(c);
          final id = (c['id']! as String).replaceFirst(RegExp(r'^\w+-trick-'), '');
          await _showCard(tester, pill, phone.value);
          await _settle(tester);
          expect(tester.takeException(), isNull);
          await _shoot(tester, '$id-${phone.key}-0');

          // First a wrong part, then the right one.
          final wrong = s.regions.firstWhere(
            (r) => !s.isTrick(r) && r != TrickSceneRegion.headline,
          );
          await tester.tapAt(_center(tester, s, wrong));
          await _settle(tester);
          expect(find.text(s.missFor(wrong)), findsOneWidget);
          await _shoot(tester, '$id-${phone.key}-1');

          await tester.tapAt(_center(tester, s, s.spot.first));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text(s.found), findsOneWidget);
          await _shoot(tester, '$id-${phone.key}-2');
          await tester.pump(const Duration(milliseconds: 900));
          await _shoot(tester, '$id-${phone.key}-3');
          await _settle(tester);
          expect(tester.takeException(), isNull);
          expect(find.text(s.honest), findsOneWidget);
          expect(find.text(s.name), findsOneWidget);
          expect(find.text(s.lesson), findsOneWidget);
          await _shoot(tester, '$id-${phone.key}-4');
          handle.dispose();
        }
      });
    }
  });
}

/// The middle of a part, found by what its screen-reader node says.
Offset _center(WidgetTester tester, TrickScene s, TrickSceneRegion r) {
  final f = find.byWidgetPredicate(
    (w) =>
        w is Semantics &&
        w.properties.sortKey != null &&
        w.properties.label != null &&
        (w.properties.button ?? false),
  );
  final widgets = f.evaluate().toList();
  final index = s.regions.indexOf(r);
  return tester.getCenter(find.byWidget(widgets[index].widget));
}
