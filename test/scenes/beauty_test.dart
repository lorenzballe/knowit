// The `beauty` scene: its data, and a reader watching each piece and putting
// a hand in, on a small phone and a large one.
//
//   flutter test test/scenes/beauty_test.dart
//   flutter test test/scenes/beauty_test.dart --update-goldens --dart-define=SHOTS=true
//
// With SHOTS the widget tests also photograph each piece into
// tool/shots/cards/ (gitignored), to be looked at rather than kept.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

Map<String, Object?> _flock() => {
  'type': 'beauty',
  'piece': 'flock',
  'caption':
      "Each bird watches only its 7 nearest neighbours: stay close, match them, don't collide.",
  'hint': 'Touch to send a falcon',
  'reveal':
      'No bird sees the whole dive. The swerve passes from neighbour to neighbour.',
  'params': {'birds': 240},
  'seed': 1986,
};

Map<String, Object?> _sunflower() => {
  'type': 'beauty',
  'piece': 'phyllotaxis',
  'caption':
      'Each new seed grows 137.5° round from the last. That one number is the whole rule.',
  'hint': 'Drag sideways to change the turn',
  'reveal':
      'Off the golden angle, seeds stack into straight spokes and leave gaps.',
  'dial': {
    'label': 'Turn between seeds',
    'unit': '°',
    'value': 137.508,
    'from': 125,
    'to': 150,
    'decimals': 1,
  },
  'params': {'seeds': 700},
  'seed': 7,
};

Map<String, Object?> _venus() => {
  'type': 'beauty',
  'piece': 'orbits',
  'caption':
      'Venus circles the Sun 13 times while Earth circles it 8. A line joins them every 3 days.',
  'hint': "Drag to change Venus's year",
  'reveal': 'A few days off and the rose smears. Only 13 to 8 closes it.',
  'dial': {
    'label': "Venus's year",
    'unit': 'days',
    'value': 224.701,
    'from': 205,
    'to': 245,
    'decimals': 1,
  },
  'params': {
    'outer': 365.256,
    'radii': [0.723, 1.0],
    'every': 3,
    'span': 2922,
  },
  'accent': '#FFE600',
};

Map<String, Object?> _waves() => {
  'type': 'beauty',
  'piece': 'waves',
  'caption':
      'Where a crest meets a trough the water stays still. Those lanes never move.',
  'hint': 'Drag a source to move it',
  'reveal': 'Move the sources apart and more still lanes open between them.',
  'params': {'wavelength': 0.1, 'gap': 0.3},
  'accent': '#FFE600',
};

Map<String, Object?> _tree() => {
  'type': 'beauty',
  'piece': 'fractal',
  'caption': 'One rule, done ten times: end each branch by splitting it in two.',
  'hint': 'Drag sideways to change the fork',
  'dial': {
    'label': 'Turn at each fork',
    'unit': '°',
    'value': 25,
    'from': 0,
    'to': 120,
    'decimals': 0,
  },
  'params': {'ratio': 0.72, 'depth': 10},
  'accent': '#FF3D7F',
};

BeautyScene _parse(Map<String, Object?> raw) =>
    Scene.fromJson(raw, id: 'test') as BeautyScene;

Pill _card(String id, String topic, Map<String, Object?> scene) =>
    cardFromJson({
      'id': id,
      'topic': topic,
      'kind': 'read',
      'question':
          'A sunflower turns each new seed 137.5° from the last. Why that angle and no other?',
      'answer': 'Because it never repeats.',
      'move': 'Perfect packing here comes from a turn that never repeats.',
      'source': 'Vogel, Mathematical Biosciences (1979)',
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
Future<void> _showCard(
  WidgetTester tester,
  Pill pill,
  Size size, {
  bool calm = false,
}) async {
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: calm),
        child: child!,
      ),
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
  BeautyScene scene, {
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

/// [seconds] of a running drawing, a frame at a time.
Future<void> _run(WidgetTester tester, double seconds) async {
  for (var f = 0; f < (seconds * 30).round(); f++) {
    await tester.pump(const Duration(milliseconds: 33));
  }
}

Future<void> _shoot(String name) async {
  if (!_shots) return;
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../../tool/shots/cards/scene-beauty-$name.png'),
  );
}

/// Where a thumb would drag across the drawing: the middle of the area
/// above the caption.
Offset _middle(WidgetTester tester, String caption) {
  final text = tester.getRect(find.text(caption));
  final scene = tester.getRect(
    find.ancestor(of: find.text(caption), matching: find.byType(SceneView)),
  );
  return Offset(scene.center.dx, (scene.top + text.top) / 2 - 30);
}

void main() {
  group('parse', () {
    test('a dialled piece', () {
      final s = _parse(_sunflower());
      expect(s.piece, BeautyPiece.phyllotaxis);
      expect(s.dial!.value, 137.508);
      expect(s.dial!.format(137.508), '137.5°');
      expect(s.seeds, 700);
      expect(s.seed, 7);
      expect(s.accent, isNull);
    });

    test('orbits, with an accent and a unit after a space', () {
      final s = _parse(_venus());
      expect(s.piece, BeautyPiece.orbits);
      expect(s.outer, 365.256);
      expect(s.innerRadius, 0.723);
      expect(s.every, 3);
      expect(s.span, 2922);
      expect(s.accent, 0xFFFFE600);
      expect(s.dial!.format(224.701), '224.7 days');
    });

    test('touched pieces and defaults', () {
      final f = _parse(_flock());
      expect(f.dial, isNull);
      expect(f.birds, 240);
      expect(f.seed, 1986);
      final w = _parse({..._waves()}..remove('params'));
      expect(w.wavelength, 0.1);
      expect(w.gap, 0.3);
      expect(_parse(_tree()).depth, 10);
      expect(_parse({..._flock()}..remove('reveal')).reveal, '');
    });

    test('refuses what it cannot draw', () {
      final bad = <Map<String, Object?>>[
        {..._flock(), 'piece': 'galaxy'},
        {..._flock()}..remove('caption'),
        {..._flock(), 'caption': 'x' * 91},
        {..._flock(), 'hint': 'x' * 35},
        {..._flock(), 'dial': _sunflower()['dial']},
        {..._sunflower()}..remove('dial'),
        {
          ..._sunflower(),
          'dial': {'label': 'Turn', 'value': 160, 'from': 125, 'to': 150},
        },
        {
          ..._sunflower(),
          'dial': {'label': 'Turn', 'value': 137.5, 'from': 0, 'to': 150},
        },
        {
          ..._sunflower(),
          'dial': {
            'label': 'Turn',
            'value': 137.5,
            'from': 125,
            'to': 150,
            'decimals': 4,
          },
        },
        {
          ..._venus(),
          'params': {'outer': 230},
        },
        {
          ..._venus(),
          'params': {
            'outer': 365.256,
            'radii': [1.0, 0.7],
          },
        },
        {
          ..._venus(),
          'params': {'outer': 365.256, 'every': 1, 'span': 9000},
        },
        {
          ..._flock(),
          'params': {'birds': 5000},
        },
        {..._flock(), 'accent': 'yellow'},
        {..._flock(), 'seed': 0},
        {
          ..._tree(),
          'params': {'depth': 14},
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
  });

  setUpAll(() async {
    if (_shots) await _loadFonts();
  });

  for (final phone in const {
    'small': Size(360, 740),
    'large': Size(430, 932),
  }.entries) {
    for (final (id, topic, raw) in [
      ('sunflower', 'science', _sunflower()),
      ('venus', 'space', _venus()),
      ('tree', 'art', _tree()),
    ]) {
      testWidgets('$id: a drag turns the dial on a ${phone.key} phone', (
        tester,
      ) async {
        final pill = _card('beauty-$id', topic, raw);
        final s = pill.scene! as BeautyScene;
        final dial = s.dial!;
        await _showCard(tester, pill, phone.value);
        await _run(tester, 1.5);
        await _shoot('$id-${phone.key}-0');
        expect(find.text(dial.format(dial.value)), findsOneWidget);
        expect(find.text(s.caption), findsOneWidget);
        expect(find.text(s.hint), findsOneWidget);

        // A long drag to the right runs the dial to its end.
        final at = _middle(tester, s.caption);
        final g = await tester.startGesture(at - const Offset(100, 0));
        for (var i = 0; i < 30; i++) {
          await g.moveBy(const Offset(25, 0));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await g.up();
        await _run(tester, 1);
        await _shoot('$id-${phone.key}-1');
        expect(find.text(dial.format(dial.to)), findsOneWidget);
        if (s.reveal.isNotEmpty) expect(find.text(s.reveal), findsOneWidget);

        // Back to the left to the other end.
        final back = await tester.startGesture(at + const Offset(100, 0));
        for (var i = 0; i < 60; i++) {
          await back.moveBy(const Offset(-25, 0));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await back.up();
        await _run(tester, 0.5);
        expect(find.text(dial.format(dial.from)), findsOneWidget);
        await _shoot('$id-${phone.key}-2');
      });
    }

    for (final (id, topic, raw) in [
      ('flock', 'nature', _flock()),
      ('waves', 'psychology', _waves()),
    ]) {
      testWidgets('$id: a touch plays on a ${phone.key} phone', (
        tester,
      ) async {
        final pill = _card('beauty-$id', topic, raw);
        final s = pill.scene! as BeautyScene;
        await _showCard(tester, pill, phone.value);
        await _run(tester, 2);
        await _shoot('$id-${phone.key}-0');
        expect(find.text(s.hint), findsOneWidget);

        final at = _middle(tester, s.caption);
        final g = await tester.startGesture(at - const Offset(60, 20));
        for (var i = 0; i < 20; i++) {
          await g.moveBy(const Offset(6, 2));
          await tester.pump(const Duration(milliseconds: 33));
        }
        await _shoot('$id-${phone.key}-1');
        await g.up();
        await _run(tester, 1.5);
        expect(find.text(s.reveal), findsOneWidget);
        expect(find.text(s.hint), findsNothing);
        await _shoot('$id-${phone.key}-2');
      });
    }
  }

  testWidgets('the sunflower clicks back to the golden angle', (
    tester,
  ) async {
    final s = _parse(_sunflower());
    await _showScene(tester, s, height: 480);
    await _run(tester, 0.5);
    final at = _middle(tester, s.caption);
    // About a degree away, and let go: close enough to click home.
    final g = await tester.startGesture(at);
    await g.moveBy(const Offset(6, 0));
    await tester.pump();
    expect(find.text('137.5°'), findsNothing);
    await g.up();
    await tester.pump();
    expect(find.text('137.5°'), findsOneWidget);
  });

  testWidgets('a drag on the scale puts the dial under the finger', (
    tester,
  ) async {
    final s = _parse(_tree());
    await _showScene(tester, s, height: 480);
    await _run(tester, 0.5);
    final label = tester.getRect(find.text('TURN AT EACH FORK'));
    final scale = Offset(label.right - 4, label.bottom + 12);
    await tester.tapAt(scale);
    await tester.pump();
    expect(find.text('120°'), findsOneWidget);
  });

  testWidgets('fits the 270 points on the back of an asking card', (
    tester,
  ) async {
    for (final raw in [_sunflower(), _venus(), _flock(), _waves(), _tree()]) {
      final s = _parse(raw);
      await _showScene(
        tester,
        s,
        ground: const Color(0xFF2B5CFF),
        ink: Colors.white,
      );
      await _run(tester, 1.5);
      expect(find.text(s.caption), findsOneWidget);
      await _shoot('back-${s.piece.name}');
    }
  });

  testWidgets('with motion off it is a still frame the hand still moves', (
    tester,
  ) async {
    for (final raw in [_sunflower(), _venus(), _flock(), _waves(), _tree()]) {
      final s = _parse(raw);
      await _showScene(tester, s, height: 480, calm: true);
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse, reason: s.piece.name);
      await _shoot('calm-${s.piece.name}');
      final at = _middle(tester, s.caption);
      final g = await tester.startGesture(at);
      await g.moveBy(const Offset(40, 10));
      await tester.pump();
      await g.up();
      await tester.pump();
      expect(find.text(s.reveal.isEmpty ? s.hint : s.reveal), findsOneWidget);
      if (s.dial != null) {
        expect(find.text(s.dial!.format(s.dial!.value)), findsNothing);
      }
      expect(tester.binding.hasScheduledFrame, isFalse, reason: s.piece.name);
    }
  });

  testWidgets('stops asking for frames when it is not painted', (
    tester,
  ) async {
    final s = _parse(_flock());
    Widget at(double opacity) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Center(
        child: Opacity(
          opacity: opacity,
          child: SizedBox(
            width: 304,
            height: 420,
            child: SceneView(
              scene: s,
              ink: Colors.black,
              ground: Colors.white,
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(at(1));
    await _run(tester, 0.5);
    expect(tester.binding.hasScheduledFrame, isTrue);

    // Faded to nothing, as the third card in the deck is: it sleeps.
    await tester.pumpWidget(at(0));
    await _run(tester, 0.5);
    expect(tester.binding.hasScheduledFrame, isFalse);

    // And wakes when it is shown again.
    await tester.pumpWidget(at(1));
    await tester.pump();
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue);

    // Under a TickerMode that is off, as on a route that is covered.
    await tester.pumpWidget(TickerMode(enabled: false, child: at(1)));
    await _run(tester, 0.2);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a screen reader can turn a dial and send a falcon', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final s = _parse(_sunflower());
    await _showScene(tester, s, height: 480);
    await _run(tester, 0.3);
    final dial = find.bySemanticsLabel('Turn between seeds').first;
    expect(
      tester.getSemantics(dial),
      isSemantics(
        label: 'Turn between seeds',
        value: '137.5°',
        isSlider: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    tester.semantics.performAction(
      find.semantics.byLabel('Turn between seeds'),
      SemanticsAction.increase,
    );
    await tester.pump();
    expect(find.text('138.8°'), findsOneWidget);

    final f = _parse(_flock());
    await _showScene(tester, f, height: 480);
    await _run(tester, 0.3);
    expect(
      tester.getSemantics(find.bySemanticsLabel(f.hint).first),
      isSemantics(label: f.hint, isButton: true, hasTapAction: true),
    );
    tester.semantics.performAction(
      find.semantics.byLabel(f.hint),
      SemanticsAction.tap,
    );
    await _run(tester, 0.8);
    expect(find.text(f.reveal), findsOneWidget);
    await _shoot('falcon-pass');
    handle.dispose();
  });

  testWidgets('a drag in the drawing does not move the deck', (tester) async {
    final deck = [
      _card('beauty-a', 'nature', _flock()),
      _card('beauty-b', 'science', _sunflower()),
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
    await _run(tester, 0.5);
    final caption = _parse(_flock()).caption;
    final at = _middle(tester, caption);

    // A fast throw to the left from the middle of the flock, the gesture
    // that sends a card away anywhere else on it.
    final gesture = await tester.startGesture(at + const Offset(60, 0));
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await _run(tester, 1);
    expect(advanced, 0, reason: 'the drag belonged to the drawing');
    expect(
      find.byWidgetPredicate((w) => w is PillCard && w.pill.id == 'beauty-a'),
      findsWidgets,
    );
    expect(find.text(_parse(_flock()).reveal), findsOneWidget);
  });
}
