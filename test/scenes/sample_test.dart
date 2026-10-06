// The `sample` scene: its data, its draws, and a reader growing it to the
// end on a small phone and a large one.
//
//   flutter test test/scenes/sample_test.dart
//   flutter test test/scenes/sample_test.dart --update-goldens --dart-define=SHOTS=true
//
// With SHOTS the widget tests also photograph each step into
// tool/shots/cards/ (gitignored), to be looked at rather than kept.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

Map<String, Object?> _deaths() => {
  'type': 'sample',
  'dots': 'Simulated deaths',
  'hit': 'In the week after the date',
  'rate': 0.5,
  'steps': [20, 200, 2000, 20000, 309221],
  'seed': 12123,
  'button': 'Grow the sample',
  'notes': [
    '14 of 20 died after the date: 70%. Pure chance; no effect is built in.',
    'Ten times the deaths, still 57% after. A dip you could publish.',
    'At 2,000 it is 52%. The pattern is melting into the truth, 50%.',
    'Twenty thousand deaths. Before and after are level.',
    "As many as Ohio's real study. Its records found no dip either.",
  ],
};

Map<String, Object?> _aspirin() => {
  'type': 'sample',
  'dots': 'Simulated patients',
  'hit': 'Vascular death in 5 weeks',
  'groups': [
    {'label': 'Dummy pill', 'rate': 0.118},
    {'label': 'Aspirin', 'rate': 0.094},
  ],
  'steps': [200, 1000, 2864, 17187],
  'seed': 14917,
  'button': 'Add patients',
  'notes': [
    '200 patients, and aspirin looks deadly: 17% against 11%. Simulated chance.',
    '1,000 patients. Aspirin still looks worse: 12.6% against 9.2%.',
    "2,864, a sixth of the trial, about two star signs' worth. No benefit yet.",
    'All 17,187: 9.4% against 11.8%, as in the real trial. Aspirin saves lives.',
  ],
};

SampleScene _parse(Map<String, Object?> raw) =>
    Scene.fromJson(raw, id: 'test') as SampleScene;

Pill _card(String id, String topic, Map<String, Object?> scene) =>
    cardFromJson({
      'id': id,
      'topic': topic,
      'kind': 'read',
      'question':
          'Can dying people hold on until a birthday or a holiday has passed?',
      'answer': 'Not that the big records show.',
      'move': 'Before believing a pattern, ask how many cases drew it.',
      'source': 'Young & Hade, JAMA (2004)',
      'scene': scene,
    });

Future<void> _loadFonts() async {
  for (final family in ['Fraunces', 'Figtree']) {
    final loader = FontLoader(family)
      ..addFont(rootBundle.load('assets/fonts/$family.ttf'));
    await loader.load();
  }
}

/// A card as the deck shows it, on a phone of [size].
Future<void> _showCard(WidgetTester tester, Pill pill, Size size) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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

/// Just the scene, in a box of a given height: the back of an asking card
/// gives it 270.
Future<void> _showScene(
  WidgetTester tester,
  SampleScene scene, {
  double height = 270,
  bool calm = false,
  Color ground = const Color(0xFFF2F1EC),
  Color ink = const Color(0xFF10100C),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: calm),
        child: Scaffold(
          backgroundColor: ground,
          body: Center(
            child: SizedBox(
              width: 304,
              height: height,
              child: SceneView(scene: scene, ink: ink, ground: ground),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var f = 0; f < 20; f++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('parse', () {
    test('one rate', () {
      final s = _parse(_deaths());
      expect(s.compares, isFalse);
      expect(s.groups.single.rate, 0.5);
      expect(s.steps, [20, 200, 2000, 20000, 309221]);
      expect(s.decimals, 0);
      expect(s.top, 1.0);
      expect(s.button, 'Grow the sample');
    });

    test('two groups, a decimal truth and a gauge that fits them', () {
      final s = _parse(_aspirin());
      expect(s.compares, isTrue);
      expect(s.groups.map((g) => g.label), ['Dummy pill', 'Aspirin']);
      expect(s.decimals, 1);
      expect(s.top, 0.25);
      expect(s.percent(0.118), '11.8%');
      expect(s.percent(0.8), '80%');
      expect(_parse({..._deaths(), 'max': 0.8}).top, 0.8);
    });

    test('refuses what it cannot draw', () {
      final bad = <Map<String, Object?>>[
        {..._deaths()}..remove('rate'),
        {..._deaths(), 'rate': 1.2},
        {
          ..._deaths(),
          'steps': [20],
        },
        {
          ..._deaths(),
          'steps': [200, 20, 2000, 20000, 309221],
        },
        {
          ..._deaths(),
          'steps': [20, 200, 2000, 20000, 2000000],
        },
        {
          ..._deaths(),
          'notes': ['one'],
        },
        {..._deaths(), 'seed': 0},
        {..._deaths(), 'seed': 'x'},
        {..._deaths(), 'max': 0.4},
        {..._deaths(), 'button': ''},
        {
          ..._aspirin(),
          'groups': [
            {'label': 'Only', 'rate': 0.1},
          ],
        },
      ];
      for (final raw in bad) {
        expect(
          () => _parse(raw),
          throwsFormatException,
          reason: raw.toString(),
        );
      }
    });

    test('the draws are the ones the checker counts', () {
      // tool/cards/scene_kinds/sample.py prints the same figures.
      final d = _parse(_deaths()).draw();
      expect(d.hitsOf(20, 0), 14);
      expect(d.hitsOf(200, 0), 114);
      expect(d.hitsOf(2000, 0), 1041);
      expect(d.hitsOf(309221, 0), 154754);

      final a = _parse(_aspirin()).draw();
      expect([a.sizeOf(17187, 0), a.sizeOf(17187, 1)], [8594, 8593]);
      expect([a.hitsOf(17187, 0), a.hitsOf(17187, 1)], [1012, 808]);
      expect([a.hitsOf(2864, 0), a.hitsOf(2864, 1)], [140, 151]);
      expect(a.shareOf(0, 0), isNull);
    });

    test('the step in force', () {
      final s = _parse(_deaths());
      expect(s.stepAt(0), -1);
      expect(s.stepAt(20), 0);
      expect(s.stepAt(1999), 1);
      expect(s.stepAt(309221), 4);
    });
  });

  setUpAll(() async {
    if (_shots) await _loadFonts();
  });

  for (final phone in const {
    'small': Size(360, 740),
    'large': Size(430, 932),
  }.entries) {
    for (final (id, topic, scene) in [
      ('deaths', 'weird_facts', _deaths()),
      ('aspirin', 'medicine', _aspirin()),
      (
        'spins',
        'science',
        {
          ..._deaths(),
          'dots': 'Simulated spins',
          'hit': 'Came up red',
          'rate': 0.486486486,
          'steps': [10, 100, 1000, 10000, 100000],
          'seed': 530,
        },
      ),
    ]) {
      testWidgets('$id grows to its end on a ${phone.key} phone', (
        tester,
      ) async {
        final pill = _card('sample-$id', topic, scene);
        final s = pill.scene! as SampleScene;
        await _showCard(tester, pill, phone.value);
        await _settle(tester);
        if (_shots) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              '../../tool/shots/cards/scene-sample-$id-${phone.key}-0.png',
            ),
          );
        }
        expect(find.text(s.notes.first), findsOneWidget);

        for (var i = 1; i < s.steps.length; i++) {
          await tester.tap(find.text(s.button));
          await _settle(tester);
          expect(find.text(s.notes[i]), findsOneWidget);
          if (_shots) {
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                '../../tool/shots/cards/scene-sample-$id-${phone.key}-$i.png',
              ),
            );
          }
        }

        // The whole sample: its size in full, and the button starts over.
        final last = s.steps.last.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
        );
        expect(find.text(last), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        await tester.tap(find.text('Try again'));
        await _settle(tester);
        expect(find.text(s.notes.first), findsOneWidget);
        expect(find.text(s.button), findsOneWidget);
      });
    }
  }

  testWidgets('fits the 270 points on the back of an asking card', (
    tester,
  ) async {
    for (final raw in [_deaths(), _aspirin()]) {
      final s = _parse(raw);
      await _showScene(
        tester,
        s,
        ground: const Color(0xFFFF3B30),
        ink: Colors.white,
      );
      await _settle(tester);
      for (var i = 1; i < s.steps.length; i++) {
        await tester.tap(find.text(s.button));
        await _settle(tester);
      }
      expect(find.text(s.notes.last), findsOneWidget);
      if (_shots) {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            '../../tool/shots/cards/scene-sample-back-${s.compares ? 2 : 1}.png',
          ),
        );
      }
    }
  });

  testWidgets('with motion off the sample is simply there', (tester) async {
    final s = _parse(_deaths());
    await _showScene(tester, s, height: 420, calm: true);
    await tester.pump();
    expect(find.text('20'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
    await tester.tap(find.text(s.button));
    await tester.pump();
    expect(find.text('200'), findsOneWidget);
    expect(find.text('57%'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a tap on the dots grows it too', (tester) async {
    final s = _parse(_deaths());
    await _showScene(tester, s, height: 460);
    await _settle(tester);
    final dots = find.bySemanticsLabel('Simulated deaths');
    await tester.tap(dots);
    await _settle(tester);
    expect(find.text('200'), findsOneWidget);
  });

  testWidgets('a screen reader can step it up and down', (tester) async {
    final handle = tester.ensureSemantics();
    final s = _parse(_deaths());
    await _showScene(tester, s, height: 460);
    await _settle(tester);

    final dots = find.bySemanticsLabel('Simulated deaths');
    expect(
      tester.getSemantics(dots),
      isSemantics(
        label: 'Simulated deaths',
        value: '20, In the week after the date 70%',
        isSlider: true,
        hasIncreaseAction: true,
      ),
    );
    tester.semantics.performAction(
      find.semantics.byLabel('Simulated deaths'),
      SemanticsAction.increase,
    );
    await _settle(tester);
    expect(find.text('200'), findsOneWidget);
    tester.semantics.performAction(
      find.semantics.byLabel('Simulated deaths'),
      SemanticsAction.decrease,
    );
    await _settle(tester);
    expect(find.text('20'), findsOneWidget);

    expect(
      tester.getSemantics(find.bySemanticsLabel('Grow the sample')),
      isSemantics(label: 'Grow the sample', isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });

  testWidgets('a sideways drag in the scene scrubs it and keeps the deck', (
    tester,
  ) async {
    final deck = [
      _card('sample-a', 'weird_facts', _deaths()),
      _card('sample-b', 'medicine', _aspirin()),
    ];
    var advanced = 0;
    tester.view.physicalSize = const Size(360, 740) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PillCardStack(
            deck: deck,
            index: 0,
            onAdvance: () => advanced++,
            answering: false,
            reviewIds: const {},
            answerFor: (_) => null,
            onAnswer: (_, _, _, _) {},
            isSaved: (_) => false,
            onSave: (_) {},
            onShare: (_) {},
          ),
        ),
      ),
    );
    await _settle(tester);
    final dots = find.bySemanticsLabel('Simulated deaths').first;
    final at = tester.getCenter(dots);

    // A fast throw to the left from the middle of the dots, the gesture
    // that sends a card away anywhere else on it.
    final gesture = await tester.startGesture(at + const Offset(60, 0));
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await _settle(tester);
    expect(advanced, 0, reason: 'the drag belonged to the scene');
    expect(
      find.byWidgetPredicate((w) => w is PillCard && w.pill.id == 'sample-a'),
      findsWidgets,
    );

    // And to the right it grows the sample.
    final more = await tester.startGesture(at - const Offset(100, 0));
    for (var i = 0; i < 10; i++) {
      await more.moveBy(const Offset(25, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await more.up();
    await _settle(tester);
    expect(advanced, 0);
    expect(find.text('20'), findsNothing, reason: 'the sample grew');
  });
}
