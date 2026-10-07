// The `count` scene: bet the number.
//
//   flutter test test/scenes/count_test.dart
//   flutter test test/scenes/count_test.dart --update-goldens --dart-define=SHOTS=true
//
// The second line also photographs each sample card on a small and a large
// phone, before the bet and after the count, into tool/shots/cards/.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/scene_view.dart';
import 'package:astuto/widgets/scenes/count_view.dart';

const _shots = bool.fromEnvironment('SHOTS');

const _phones = {'small': Size(360, 740), 'large': Size(430, 932)};

Future<void> _loadFonts() async {
  const faces = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
  };
  for (final face in faces.entries) {
    final loader = FontLoader(face.key);
    final bytes = await File(face.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

List<Map<String, Object?>> _samples() => [
  for (final c in jsonDecode(
    File('tool/cards/samples/count.json').readAsStringSync(),
  ) as List)
    (c as Map).cast<String, Object?>(),
];

Map<String, Object?> _glass() =>
    (_samples().first['scene'] as Map).cast<String, Object?>();

CountScene _parse(Map<String, Object?> raw) =>
    Scene.fromJson(raw, id: 'test') as CountScene;

Widget _app(Widget child, {bool calm = false}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAstutoTheme(Brightness.dark),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: calm),
      child: child,
    ),
  ),
);

/// A card on the black ground, sized as the deck sizes it.
Widget _card(Pill pill, {bool calm = false}) => _app(
  Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 60, 14, 96),
        child: PillCard(pill: pill, flipped: false),
      ),
    ),
  ),
  calm: calm,
);

void _phone(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Runs the reveal through to its end, frame by frame like a phone.
Future<void> _play(WidgetTester tester) async {
  for (var f = 0; f < 40; f++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

String _comma(num v) => v.round().toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

void main() {
  group('parse', () {
    test('reads every field of a sample', () {
      final s = _parse(_glass());
      expect(s.unit, 'of your molecules in every glass');
      expect(s.answer, 1570);
      expect(s.each, 1);
      expect(s.dots, 1570);
      expect(s.arrange, CountArrange.cloud);
      expect(s.options.map((o) => o.label), [
        'None',
        'About 1',
        'About 1,000',
        'A million',
      ]);
      expect(s.compare, isNotEmpty);
      expect(s.prefix, '');
    });

    test('every sample parses', () {
      for (final c in _samples()) {
        expect(cardFromJson(c).scene, isA<CountScene>());
      }
    });

    test('the nearest bet is counted in zeros', () {
      final s = _parse(_glass());
      expect(s.nearest, 2); // about 1,000 for 1,570
      expect(s.stopOf(0), 0);
      expect(s.stopOf(1), 1);
      expect(s.stopOf(1000), 2);
      expect(s.stopOf(1570), closeTo(2.065, 0.01));
      // Past the last bet the marker runs on by half a step at most.
      expect(s.stopOf(1e12), 3.5);
      // Below one, "none" sits a zero under the next bet.
      expect(s.stopOf(0.1), closeTo(0, 1e-9));
      expect(s.stopOf(0.5), closeTo(0.7, 0.01));
    });

    test('refuses what it cannot draw', () {
      void bad(Map<String, Object?> patch) => expect(
        () => _parse({..._glass(), ...patch}),
        throwsFormatException,
        reason: '$patch',
      );
      bad({'unit': null});
      bad({'unit': 3});
      bad({'eachLabel': ''});
      bad({'answer': 'many'});
      bad({'answer': -1});
      bad({'each': 0});
      bad({'decimals': 3});
      bad({'arrange': 'spiral'});
      final opts = (_glass()['options'] as List).cast<Map>();
      bad({'options': opts.take(2).toList()});
      bad({
        'options': [...opts, ...opts.take(1)],
      });
      bad({
        'options': [opts[1], opts[0], opts[2]],
      });
      bad({
        'options': [
          {'label': 'A', 'value': 1},
          ...opts.skip(1),
        ],
      });
    });

    test('a huge answer is capped to a field of dots, not a wash', () {
      final s = _parse({..._glass(), 'answer': 1e9, 'each': 1});
      expect(s.dots, CountScene.maxDots);
    });
  });

  group('plays', () {
    setUpAll(_loadFonts);

    for (final phone in _phones.entries) {
      testWidgets('bet, count, land on a ${phone.key} phone', (tester) async {
        _phone(tester, phone.value);
        final pill = cardFromJson(_samples().first);
        final s = pill.scene! as CountScene;
        await tester.pumpWidget(_card(pill));
        await tester.pump();

        // Before the bet: a question mark, the bets, a prompt.
        expect(find.text('?'), findsOneWidget);
        expect(find.text('YOUR GUESS'), findsOneWidget);
        expect(find.text('TRUTH'), findsNothing);

        await tester.tap(find.text('About\n1'));
        await tester.pump(const Duration(milliseconds: 400));
        // Mid-count: the number is on its way, the marker is out.
        expect(find.text('?'), findsNothing);
        expect(find.text('TRUTH'), findsOneWidget);
        expect(find.text(s.options[1].note), findsOneWidget);

        await _play(tester);
        expect(find.text(_comma(s.answer)), findsOneWidget);
        expect(find.text(s.options[1].note), findsOneWidget);
        // The line of scale shows only where the field can spare it.
        expect(
          find.text(s.compare),
          phone.key == 'large' ? findsOneWidget : findsNothing,
        );

        // The bet is placed once: another chip changes nothing.
        await tester.tap(find.text('A\nmillion'));
        await _play(tester);
        expect(find.text(s.options[3].note), findsNothing);
      });
    }

    testWidgets('fits the 270 high band on the back of asking cards', (
      tester,
    ) async {
      _phone(tester, const Size(360, 740));
      for (final c in _samples()) {
        final pill = cardFromJson(c);
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 270,
                  child: SceneView(
                    scene: pill.scene!,
                    ink: pill.ink,
                    ground: pill.color,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final s = pill.scene! as CountScene;
        await tester.tap(
          find.text(s.options.last.label.replaceFirst(' ', '\n')),
        );
        await _play(tester);
        expect(tester.takeException(), isNull);
        expect(find.text(s.options.last.note), findsOneWidget);
      }
    });

    testWidgets('with animations off, the bet lands at once', (tester) async {
      _phone(tester, const Size(390, 844));
      final pill = cardFromJson(_samples()[1]);
      final s = pill.scene! as CountScene;
      await tester.pumpWidget(_card(pill, calm: true));
      await tester.pump();
      await tester.tap(
        find.text(
          r'$20'
          '\nmillion',
        ),
      );
      await tester.pump();
      expect(find.text(r'$20,000,000'), findsOneWidget);
      expect(find.text(s.options[2].note), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a screen reader can read the bets and place one', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      _phone(tester, const Size(390, 844));
      final pill = cardFromJson(_samples()[2]);
      final s = pill.scene! as CountScene;
      await tester.pumpWidget(_card(pill));
      await tester.pump();

      for (final o in s.options) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(o.label)),
          matchesSemantics(
            label: o.label,
            hint: 'Tap your pick',
            isButton: true,
            isEnabled: true,
            hasEnabledState: true,
            isSelected: false,
            hasSelectedState: true,
            hasTapAction: true,
          ),
        );
      }
      tester.semantics.tap(find.semantics.byLabel('About 10'));
      await _play(tester);
      expect(find.bySemanticsLabel(RegExp('13 ${s.unit}')), findsOneWidget);
      expect(find.text(s.options[0].note), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a slide along the bets picks where it lifts', (tester) async {
      _phone(tester, const Size(360, 740));
      final pill = cardFromJson(_samples()[1]);
      final s = pill.scene! as CountScene;
      await tester.pumpWidget(_card(pill));
      await tester.pump();
      final from = tester.getCenter(find.text(r'$200,000'));
      final to = tester.getCenter(
        find.text(
          r'$20'
          '\nmillion',
        ),
      );
      await tester.dragFrom(from, to - from);
      await _play(tester);
      expect(find.text(s.options[2].note), findsOneWidget);
    });

    testWidgets('in the deck: a drag on the bets stays in the scene, and the '
        'card turns only once the count lands', (tester) async {
      final pill = cardFromJson(_samples().first);
      final s = pill.scene! as CountScene;
      var advanced = 0;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SizedBox(
              height: 640,
              child: PillCardStack(
                isSaved: (_) => false,
                onSave: (_) {},
                onShare: (_) {},
                deck: [pill, cardFromJson(_samples()[1])],
                index: 0,
                onAdvance: () => advanced++,
                answerFor: (_) => null,
                reviewIds: const {},
                onAnswer: (_, _, _, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // A hard horizontal fling across the bets does not throw the card.
      final row = tester.getCenter(find.text('About\n1'));
      await tester.flingFrom(row, const Offset(-260, 0), 1500);
      await _play(tester);
      expect(advanced, 0);
      expect(find.text(pill.question), findsOneWidget);
      expect(find.text('WHAT TO KEEP'), findsNothing);
      // The fling lifted on a chip, so it placed a bet.
      expect(find.text('TRUTH'), findsOneWidget);
      expect(find.text(_comma(s.answer)), findsOneWidget);

      // Landed: a tap on the field turns the card over.
      await tester.tap(find.text('1 DOT = 1 OF YOUR MOLECULES'));
      await _play(tester);
      expect(find.text('WHAT TO KEEP'), findsOneWidget);
    });

    testWidgets('before the bet, a tap in the scene does not turn the card', (
      tester,
    ) async {
      final pill = cardFromJson(_samples().first);
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SizedBox(
              height: 640,
              child: PillCardStack(
                isSaved: (_) => false,
                onSave: (_) {},
                onShare: (_) {},
                deck: [pill],
                index: 0,
                onAdvance: () {},
                answerFor: (_) => null,
                reviewIds: const {},
                onAnswer: (_, _, _, _) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('?'));
      await _play(tester);
      expect(find.text('WHAT TO KEEP'), findsNothing);
      // Outside the scene it still turns.
      await tester.tap(find.text('Tap to reveal'));
      await _play(tester);
      expect(find.text('WHAT TO KEEP'), findsOneWidget);
    });

    testWidgets('dark ink on a light subject draws too', (tester) async {
      _phone(tester, const Size(360, 740));
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Container(
              color: const Color(0xFFFFD23F),
              padding: const EdgeInsets.all(20),
              child: CountSceneView(
                scene: _parse(_glass()),
                ink: const Color(0xFF16130E),
                ground: const Color(0xFFFFD23F),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('About\n1,000'));
      await _play(tester);
      expect(find.text('1,570'), findsOneWidget);
      if (_shots) {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../../tool/shots/cards/count-light-ink.png'),
        );
      }
    });

    if (_shots) {
      for (final c in _samples()) {
        for (final phone in _phones.entries) {
          testWidgets('photograph ${c['id']} on ${phone.key}', (tester) async {
            _phone(tester, phone.value);
            final pill = cardFromJson(c);
            final s = pill.scene! as CountScene;
            await tester.pumpWidget(_card(pill));
            await tester.pump();
            Future<void> shoot(String stage) => expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                '../../tool/shots/cards/count-${pill.id}-${phone.key}-$stage.png',
              ),
            );
            await shoot('start');
            await tester.tap(
              find.text(s.options[1].label.replaceFirst(' ', '\n')),
            );
            for (var f = 0; f < 9; f++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
            await shoot('counting');
            await _play(tester);
            await shoot('end');
          });
        }
      }
    }
  });
}
