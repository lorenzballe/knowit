// The `draw` scene: the reader draws the line they expect, locks it in, and
// the real line draws itself over theirs.
//
//   flutter test test/scenes/draw_test.dart
//   flutter test test/scenes/draw_test.dart --update-goldens --dart-define=SHOTS=true
//
// With SHOTS the three sample cards are also photographed, start, drawn and
// revealed, on a small and a large phone, into tool/shots/draw/.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/models/scene.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/scenes/draw_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

const _shots = bool.fromEnvironment('SHOTS');

Map<String, Object?> _ai() => {
  'type': 'draw',
  'label': 'Training compute, × today',
  'unit': '×',
  'columns': ['Today', 'Yr 1', 'Yr 2', 'Yr 3', 'Yr 4', 'Yr 5'],
  'values': [1, 4.5, 20.25, 91.1, 410, 1845],
  'given': 1,
  'min': 0,
  'max': 2000,
  'verdict': {'under': 'Too low.', 'near': 'Close.', 'over': 'Too high.'},
  'notes': [
    {'at': 2, 'text': 'Two years in: only ×20'},
  ],
};

DrawScene _parse(Map<String, Object?> raw) =>
    Scene.fromJson(raw, id: 't') as DrawScene;

List<Map<String, Object?>> _samples() => [
  for (final c
      in jsonDecode(File('tool/cards/samples/draw.json').readAsStringSync())
          as List)
    (c as Map).cast<String, Object?>(),
];

Future<void> _fonts() async {
  final fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons':
        '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final e in fonts.entries) {
    final bytes = await File(e.value).readAsBytes();
    final loader = FontLoader(e.key)
      ..addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
  }
}

/// The scene alone, in a box the size the card gives it, inside something
/// that pans and taps the way the deck does, to see who wins.
class _Host extends StatelessWidget {
  final DrawScene scene;
  final Color ink;
  final Color ground;
  final double height;
  final VoidCallback onDeckTap;
  final VoidCallback onDeckPan;
  final bool calm;
  const _Host({
    super.key,
    required this.scene,
    this.ink = const Color(0xFF111111),
    this.ground = const Color(0xFF00A6FF),
    this.height = 440,
    required this.onDeckTap,
    required this.onDeckPan,
    this.calm = false,
  });

  @override
  Widget build(BuildContext context) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: calm),
      child: Scaffold(
        backgroundColor: ground,
        body: GestureDetector(
          onTap: onDeckTap,
          onPanStart: (_) => onDeckPan(),
          child: Container(
            color: ground,
            padding: const EdgeInsets.all(22),
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: height,
              child: DrawSceneView(scene: scene, ink: ink, ground: ground),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A finger across the chart from the first column it may draw to the
/// right edge, along [shape] (0 at the bottom, 1 at the top).
Future<void> _sweep(
  WidgetTester tester,
  double Function(double u) shape, {
  double from = 0.2,
  double to = 0.99,
}) async {
  final box = tester.getRect(find.byKey(const ValueKey('draw-chart')));
  Offset at(double u) => Offset(
    box.left + box.width * u,
    box.bottom - 40 - (box.height - 90) * shape(u),
  );
  final g = await tester.startGesture(at(from));
  await tester.pump();
  const steps = 24;
  for (var k = 1; k <= steps; k++) {
    await g.moveTo(at(from + (to - from) * k / steps));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await tester.pump();
}

Future<void> _settle(WidgetTester tester) async {
  for (var f = 0; f < 30; f++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('parse', () {
    test('reads a full scene', () {
      final s = _parse(_ai());
      expect(s.count, 6);
      expect(s.given, 1);
      expect(s.anchor, 0);
      expect(s.firstDrawn, 1);
      expect(s.judge, 5);
      expect(s.max, 2000);
      expect(s.unit, '×');
      expect(s.notes.single.at, 2);
      expect(s.close, 'Close.');
    });

    test('defaults: given 1, judge last, range from the values', () {
      final raw = _ai()
        ..remove('given')
        ..remove('min')
        ..remove('max');
      final s = _parse(raw);
      expect(s.given, 1);
      expect(s.judge, 5);
      expect(s.min, 0);
      expect(s.max, greaterThanOrEqualTo(1845 * 1.25));
    });

    test('judges by share of the chart', () {
      final s = _parse(_ai());
      expect(s.verdictText(1845), 'Close.');
      expect(s.verdictText(1700), 'Close.');
      expect(s.verdictText(200), 'Too low.');
      expect(s.verdictText(2000 * 0.99 + 1), 'Close.');
      expect(_parse({..._ai(), 'max': 4000}).verdictText(3900), 'Too high.');
    });

    test('a log chart measures in powers of ten', () {
      final s = _parse({
        ..._ai(),
        'log': true,
        'min': 1,
        'max': 10000,
      });
      expect(s.share(100), closeTo(0.5, 1e-9));
      expect(s.fromShare(0.75), closeTo(1000, 1e-6));
    });

    for (final (why, patch) in <(String, Map<String, Object?>)>[
      ('too few columns', {'columns': ['a', 'b'], 'values': [1, 2]}),
      ('values do not match columns', {'values': [1, 2, 3]}),
      ('a value is not a number', {'values': [1, 2, 'x', 4, 5, 6]}),
      ('given leaves nothing to draw', {'given': 5}),
      ('given is negative', {'given': -1}),
      ('max under min', {'min': 10, 'max': 5}),
      ('a value above max', {'max': 1000}),
      ('log from zero', {'log': true}),
      ('judge on a given column', {'judge': 0}),
      ('decimals out of range', {'decimals': 4}),
      ('a note off the chart', {
        'notes': [
          {'at': 9, 'text': 'x'},
        ],
      }),
    ]) {
      test('refuses: $why', () {
        expect(
          () => _parse({..._ai(), ...patch}),
          throwsA(isA<FormatException>()),
        );
      });
    }

    test('every sample parses', () {
      for (final c in _samples()) {
        expect(_parse((c['scene'] as Map).cast()), isA<DrawScene>());
      }
    });
  });

  group('play', () {
    for (final (phone, size, height) in [
      ('small', const Size(360, 740), 330.0),
      ('large', const Size(430, 932), 520.0),
      ('back of an asking card', const Size(360, 740), 270.0),
    ]) {
      testWidgets('draw, lock in, see the truth on $phone', (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        var taps = 0, pans = 0;
        await tester.pumpWidget(
          _Host(
            scene: _parse(_ai()),
            height: height,
            onDeckTap: () => taps++,
            onDeckPan: () => pans++,
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Draw your guess with your finger'), findsOneWidget);

        // Half a line is not a guess yet.
        await _sweep(tester, (u) => u * 0.3, from: 0.12, to: 0.6);
        await tester.tap(find.text('LOCK IT IN'));
        await tester.pump();
        expect(find.text('Too low.'), findsNothing);

        // All the way across, low: most people's line.
        await _sweep(tester, (u) => u * 0.25, from: 0.12);
        expect(taps, 0, reason: 'a stroke in the chart is not a tap');
        expect(pans, 0, reason: 'a stroke in the chart does not swipe');

        await tester.tap(find.text('LOCK IT IN'));
        await _settle(tester);
        expect(find.text('Too low.'), findsOneWidget);
        expect(find.text('×1,845'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(taps, 0);

        // Locked, the chart is a picture again: the deck gets its gestures.
        final chart = tester.getRect(find.byKey(const ValueKey('draw-chart')));
        await tester.dragFrom(chart.center, const Offset(-160, 0));
        await tester.pump();
        expect(pans, 1);

        // And it can be drawn again.
        await tester.tap(find.bySemanticsLabel('Try again'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Draw your guess with your finger'), findsOneWidget);
        await _settle(tester);
      });
    }

    testWidgets('a guess near the truth is called close', (tester) async {
      await tester.pumpWidget(
        _Host(
          scene: _parse(_ai()),
          calm: true,
          onDeckTap: () {},
          onDeckPan: () {},
        ),
      );
      await _sweep(
        tester,
        (u) => u < 0.8 ? u * 0.05 : (u - 0.8) / 0.2 * 0.95,
        from: 0.12,
      );
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pump();
      expect(find.text('Close.'), findsOneWidget);
    });

    testWidgets('dark ink on a pale subject and white on a dark one', (
      tester,
    ) async {
      for (final (ink, ground) in [
        (const Color(0xFF111111), const Color(0xFFFFE600)),
        (const Color(0xFFFFFFFF), const Color(0xFF5A2EA6)),
      ]) {
        await tester.pumpWidget(
          _Host(
            key: ValueKey(ink),
            scene: _parse(_ai()),
            ink: ink,
            ground: ground,
            calm: true,
            onDeckTap: () {},
            onDeckPan: () {},
          ),
        );
        await _sweep(tester, (u) => 0.4, from: 0.12);
        expect(find.text('LOCK IT IN'), findsOneWidget);
        await tester.tap(find.text('LOCK IT IN'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('a screen reader can set the guess and lock it in', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _Host(
          scene: _parse(_ai()),
          calm: true,
          onDeckTap: () {},
          onDeckPan: () {},
        ),
      );
      final chart = find.bySemanticsLabel(RegExp('^Training compute'));
      expect(chart, findsOneWidget);
      final id = tester.getSemantics(chart).id;
      final owner = tester.binding.pipelineOwner.semanticsOwner!;
      for (var k = 0; k < 6; k++) {
        owner.performAction(id, SemanticsAction.increase);
        await tester.pump();
      }
      expect(tester.getSemantics(chart).value, startsWith('Yr 5: ×'));
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pump();
      expect(
        find.bySemanticsLabel(RegExp(r'TRUTH: ×1,845')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('given 0: the whole line is the reader\'s', (tester) async {
      await tester.pumpWidget(
        _Host(
          scene: _parse({..._ai(), 'given': 0}),
          calm: true,
          onDeckTap: () {},
          onDeckPan: () {},
        ),
      );
      await _sweep(tester, (u) => u, from: 0.02);
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pump();
      expect(find.text('×1,845'), findsOneWidget);
    });
  });

  group('cards', () {
    setUpAll(_fonts);
    for (final raw in _samples()) {
      final pill = cardFromJson(raw);
      for (final (phone, size) in [
        ('small', const Size(360, 740)),
        ('large', const Size(430, 932)),
      ]) {
        testWidgets('${pill.id} plays through on $phone', (tester) async {
          tester.view.physicalSize = size * 3;
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(_Card(pill));
          await _settle(tester);
          Future<void> shoot(String stage) async {
            if (!_shots) return;
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                '../../tool/shots/draw/${pill.id}-$phone-$stage.png',
              ),
            );
          }

          await shoot('start');
          final s = pill.scene! as DrawScene;
          final box = tester.getRect(find.byKey(const ValueKey('draw-chart')));
          final x0 = (s.anchor + 0.5) / (s.count - 0.4);
          await _sweep(tester, (u) => 0.55 - 0.3 * u, from: x0);
          await shoot('drawn');
          await tester.tap(find.text('LOCK IT IN'));
          await tester.pump(const Duration(milliseconds: 700));
          await shoot('drawing');
          await _settle(tester);
          await shoot('end');
          expect(tester.takeException(), isNull);
          expect(box.height, greaterThan(150));
        });
      }
    }
  });
}

class _Card extends StatelessWidget {
  final Pill pill;
  const _Card(this.pill);

  @override
  Widget build(BuildContext context) => MaterialApp(
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
  );
}
