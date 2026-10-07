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


const _mine = [
  'tool/cards/bank/technology/technology-kids-and-screens-1.json',
  'tool/cards/bank/life/life-choosing-work-5.json',
  'tool/cards/bank/medicine/medicine-screening-5.json',
  'tool/cards/bank/medicine/medicine-smoking-5.json',
  'tool/cards/bank/medicine/medicine-painkillers-11.json',
  'tool/cards/bank/sport/sport-coin-tosses-4.json',
  'tool/cards/bank/sport/sport-sprint-11.json',
  'tool/cards/bank/psychology/psychology-panic-4.json',
  'tool/cards/bank/psychology/psychology-framing-4.json',
  'tool/cards/bank/economics/economics-education-4.json',
  'tool/cards/bank/economics/economics-correlation-in-markets-4.json',
  'tool/cards/bank/economics/economics-interest-12.json',
  'tool/cards/bank/sport/sport-gender-1.json',
];

void main() {
  setUpAll(() async {
    if (_shots) await _loadFonts();
  });
  for (final phone in const {
    'small': Size(360, 740),
    'large': Size(430, 932),
  }.entries) {
    testWidgets('writer cards play to the end on a ${phone.key} phone', (tester) async {
      for (final path in _mine) {
        final c = (jsonDecode(File(path).readAsStringSync()) as Map).cast<String, Object?>();
        final handle = tester.ensureSemantics();
        final raw = (c['scene']! as Map).cast<String, Object?>();
        final s = _parse(raw);
        final pill = cardFromJson(c);
        final id = 'w-' + (c['id']! as String);
        await _showCard(tester, pill, phone.value);
        await _settle(tester);
        expect(tester.takeException(), isNull);
        await _shoot(tester, '$id-${phone.key}-0');
        final wrong = s.regions.firstWhere(
          (r) => !s.isTrick(r) && r != TrickSceneRegion.headline,
        );
        await tester.tapAt(_center(tester, s, wrong));
        await _settle(tester);
        await _shoot(tester, '$id-${phone.key}-1');
        await tester.tapAt(_center(tester, s, s.spot.first));
        await _settle(tester);
        await _settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.text(s.lesson), findsOneWidget);
        await _shoot(tester, '$id-${phone.key}-4');
        handle.dispose();
      }
    });
  }
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
