// The `why` scene: ask why, layer by layer, down to the root.
//
//   flutter test test/scenes/why_test.dart
//   flutter test test/scenes/why_test.dart --update-goldens --dart-define=SHOTS=true
//
// The second line also photographs each sample card on a small and a large
// phone, at the surface, at the guess and on bedrock, into tool/shots/cards/.
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

const _shots = bool.fromEnvironment('SHOTS');

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
    File('tool/cards/samples/why.json').readAsStringSync(),
  ) as List)
    (c as Map).cast<String, Object?>(),
];

Map<String, Object?> _coffee() => {
  'type': 'why',
  'ask': 'And why?',
  'start': {'text': 'Same coffee, same chain: dearer at the gate.'},
  'levels': [
    {
      'text': 'The café hands the airport a cut of every sale.',
      'figure': '10–20%',
      'unit': 'of sales, typically',
    },
    {'text': 'Airports live off shops as much as off flights.'},
    {'text': 'A café can pay because its buyers cannot leave.'},
    {'text': 'Security makes a captive crowd.'},
  ],
  'guess': {
    'options': ['Beans cost more', 'Buyers cannot leave', 'Staff earn more'],
    'answer': 1,
  },
};

WhyScene _parse(Map<String, Object?> raw) =>
    Scene.fromJson(raw, id: 'test') as WhyScene;

void _phone(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _host(
  Map<String, Object?> raw, {
  required double height,
  Color ground = const Color(0xFFFFC49B),
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
          padding: const EdgeInsets.symmetric(horizontal: 28),
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

/// A whole card, as the deck shows it.
Widget _card(Pill pill) => MaterialApp(
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

Future<void> _play(WidgetTester tester) async {
  for (var f = 0; f < 24; f++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('parse', () {
    test('reads every field', () {
      final s = _parse(_coffee());
      expect(s.ask, 'And why?');
      expect(s.start.text, startsWith('Same coffee'));
      expect(s.start.hasFigure, isFalse);
      expect(s.levels, hasLength(4));
      expect(s.levels.first.figure, '10–20%');
      expect(s.levels.first.unit, 'of sales, typically');
      expect(s.root.text, 'Security makes a captive crowd.');
      expect(s.guess!.options, hasLength(3));
      expect(s.guess!.answer, 1);
    });

    test('the guess is optional', () {
      expect(_parse({..._coffee()}..remove('guess')).guess, isNull);
    });

    test('every sample card parses', () {
      for (final c in _samples()) {
        expect(
          Scene.fromJson(c['scene'], id: c['id']),
          isA<WhyScene>(),
          reason: '${c['id']}',
        );
      }
    });

    test('refuses bad data', () {
      void bad(Map<String, Object?> raw) =>
          expect(() => _parse(raw), throwsFormatException);
      final levels = _coffee()['levels'] as List;
      bad({..._coffee()}..remove('ask'));
      bad({..._coffee(), 'ask': ' '});
      bad({..._coffee()}..remove('start'));
      bad({
        ..._coffee(),
        'start': {'text': ''},
      });
      bad({..._coffee(), 'levels': levels.take(2).toList()});
      bad({
        ..._coffee(),
        'levels': [...levels, ...levels.take(2)],
      });
      bad({
        ..._coffee(),
        'levels': [
          ...levels.take(3),
          {'text': 'Root', 'unit': 'with no figure'},
        ],
      });
      bad({
        ..._coffee(),
        'levels': [...levels.take(3), 'Root'],
      });
      bad({
        ..._coffee(),
        'guess': {
          'options': ['Only one'],
          'answer': 0,
        },
      });
      bad({
        ..._coffee(),
        'guess': {
          'options': ['A', 'B'],
          'answer': 2,
        },
      });
      bad({
        ..._coffee(),
        'guess': {
          'options': ['A', 'A'],
          'answer': 0,
        },
      });
      bad({
        ..._coffee(),
        'guess': {
          'options': ['A', 'B'],
          'answer': '1',
        },
      });
    });
  });

  group('play', () {
    setUpAll(_loadFonts);

    for (final (name, size, height) in [
      ('small phone', const Size(360, 740), 330.0),
      ('large phone', const Size(430, 932), 520.0),
      ('back of an asking card', const Size(360, 740), 270.0),
    ]) {
      testWidgets('on a $name: dig to the guess, pick, land on the root', (
        tester,
      ) async {
        _phone(tester, size);
        await tester.pumpWidget(_host(_coffee(), height: height));
        await _play(tester);
        expect(find.textContaining('Same coffee'), findsOneWidget);
        expect(find.textContaining('a cut of every sale'), findsNothing);

        // Three layers down, each one appearing as it is dug.
        await tester.tap(find.text('And why?'));
        await _play(tester);
        expect(find.textContaining('a cut of every sale'), findsOneWidget);
        expect(find.text('10–20%'), findsOneWidget);
        await tester.tap(find.text('And why?'));
        await _play(tester);
        await tester.tap(find.text('And why?'));
        await _play(tester);
        expect(find.textContaining('buyers cannot leave'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // The guess: the button is gone, the options are there, and the
        // root is not.
        expect(find.text('And why?'), findsNothing);
        expect(find.text('YOUR GUESS'), findsOneWidget);
        expect(find.text('Security makes a captive crowd.'), findsNothing);
        for (final o in ['Beans cost more', 'Staff earn more']) {
          final r = tester.getRect(find.text(o));
          expect(r.bottom, lessThanOrEqualTo(size.height));
          expect(r.top, greaterThanOrEqualTo(0));
        }
        // A tap beside the options waits for a pick.
        await tester.tap(find.textContaining('buyers cannot leave'));
        await _play(tester);
        expect(find.text('Security makes a captive crowd.'), findsNothing);

        await tester.tap(find.text('Beans cost more'));
        await _play(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('Security makes a captive crowd.'), findsOneWidget);
        // The guess is printed under the root, with its mark.
        expect(find.text('YOUR GUESS'), findsOneWidget);
        expect(find.text('Beans cost more'), findsOneWidget);
        expect(find.text('Buyers cannot leave'), findsNothing);

        // The root sits whole inside the scene.
        final scene = tester.getRect(find.byType(SceneView));
        final root = tester.getRect(
          find.text('Security makes a captive crowd.'),
        );
        expect(root.top, greaterThanOrEqualTo(scene.top));
        expect(root.bottom, lessThanOrEqualTo(scene.bottom));
      });
    }

    testWidgets('a pull upward on the section digs too', (tester) async {
      _phone(tester, const Size(360, 740));
      await tester.pumpWidget(_host(_coffee(), height: 400));
      await _play(tester);
      final start = tester.getCenter(find.textContaining('Same coffee'));
      // A short pull springs back.
      await tester.dragFrom(start, const Offset(0, -20));
      await _play(tester);
      expect(find.textContaining('a cut of every sale'), findsNothing);
      // A long one digs.
      await tester.dragFrom(start, const Offset(0, -160));
      await _play(tester);
      expect(find.textContaining('a cut of every sale'), findsOneWidget);
      // And a tap on the section digs one more.
      await tester.tap(find.textContaining('Same coffee'));
      await _play(tester);
      expect(find.textContaining('shops as much'), findsOneWidget);
    });

    testWidgets('without a guess the last "And why?" lands the root', (
      tester,
    ) async {
      _phone(tester, const Size(360, 740));
      await tester.pumpWidget(
        _host(
          {..._coffee()}..remove('guess'),
          height: 330,
          ground: const Color(0xFF233A8B),
          ink: Colors.white,
        ),
      );
      await _play(tester);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('And why?'));
        await _play(tester);
      }
      expect(tester.takeException(), isNull);
      expect(find.text('Security makes a captive crowd.'), findsOneWidget);
      expect(find.text('And why?'), findsNothing);
      expect(find.text('YOUR GUESS'), findsNothing);
      if (_shots) {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../../tool/shots/cards/why-light-ink.png'),
        );
      }
    });

    testWidgets('a fast reader never skips a layer', (tester) async {
      _phone(tester, const Size(360, 740));
      await tester.pumpWidget(_host(_coffee(), height: 400));
      await _play(tester);
      await tester.tap(find.text('And why?'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('And why?'));
      await _play(tester);
      expect(find.textContaining('a cut of every sale'), findsOneWidget);
      expect(find.textContaining('shops as much'), findsOneWidget);
      expect(find.textContaining('buyers cannot leave'), findsNothing);
    });

    testWidgets('with animations off, each step is there on the next frame', (
      tester,
    ) async {
      _phone(tester, const Size(360, 740));
      await tester.pumpWidget(_host(_coffee(), height: 400, still: true));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('And why?'));
        await tester.pump();
      }
      expect(find.text('YOUR GUESS'), findsOneWidget);
      await tester.tap(find.text('Buyers cannot leave'));
      await tester.pump();
      expect(find.text('Security makes a captive crowd.'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a screen reader digs with the button and picks an option', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      _phone(tester, const Size(360, 740));
      await tester.pumpWidget(_host(_coffee(), height: 400));
      await _play(tester);
      final ask = find.bySemanticsLabel('And why?');
      expect(
        tester.getSemantics(ask),
        isSemantics(isButton: true, hasTapAction: true),
      );
      for (var i = 0; i < 3; i++) {
        tester.semantics.tap(find.semantics.byLabel('And why?'));
        await _play(tester);
      }
      expect(
        tester.getSemantics(find.bySemanticsLabel('Buyers cannot leave')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      tester.semantics.tap(find.semantics.byLabel('Buyers cannot leave'));
      await _play(tester);
      expect(
        find.bySemanticsLabel('Security makes a captive crowd.'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('in the deck', () {
    testWidgets('a drag on the section digs and does not swipe the card '
        'away; once at the root the card turns over again', (tester) async {
      _phone(tester, const Size(360, 740));
      final pill = cardFromJson({..._samples().first, 'scene': _coffee()});
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
      await tester.pumpAndSettle();
      final surface = find.textContaining('Same coffee');
      expect(surface, findsOneWidget);

      // Sideways across the section: the deck stays put.
      await tester.drag(surface, const Offset(-260, 0));
      await tester.pumpAndSettle();
      expect(advanced, 0);
      expect(surface, findsOneWidget);

      // Slanted and upward: it digs, the deck still stays.
      await tester.drag(surface, const Offset(-120, -180));
      await tester.pumpAndSettle();
      expect(advanced, 0);
      expect(find.textContaining('a cut of every sale'), findsOneWidget);

      // A tap in the section digs rather than turning the card.
      await tester.tap(find.textContaining('a cut of every sale'));
      await tester.pumpAndSettle();
      expect(find.textContaining('shops as much'), findsOneWidget);
      await tester.tap(find.text('And why?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buyers cannot leave'));
      await tester.pumpAndSettle();
      expect(find.text('Security makes a captive crowd.'), findsOneWidget);

      // At the root the section lets go: a tap turns the card over.
      await tester.tap(find.text('Security makes a captive crowd.'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining("Because the buyers can't leave"),
        findsWidgets,
      );
    });
  });

  if (_shots) {
    group('photographs', () {
      setUpAll(_loadFonts);
      const phones = {'small': Size(360, 740), 'large': Size(430, 932)};
      for (final c in _samples()) {
        for (final phone in phones.entries) {
          testWidgets('${c['id']} on ${phone.key}', (tester) async {
            _phone(tester, phone.value);
            final pill = cardFromJson(c);
            final s = pill.scene! as WhyScene;
            await tester.pumpWidget(_card(pill));
            await _play(tester);
            Future<void> shoot(String stage) => expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                '../../tool/shots/cards/why-${pill.id}-${phone.key}-$stage.png',
              ),
            );
            await shoot('0-surface');
            await tester.tap(find.text(s.ask));
            await _play(tester);
            await shoot('1-first');
            await tester.tap(find.text(s.ask));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 330));
            await shoot('2-digging');
            await _play(tester);
            await tester.tap(find.text(s.ask));
            await _play(tester);
            await shoot('3-guess');
            await tester.tap(find.text(s.guess!.options.first));
            for (var f = 0; f < 9; f++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
            await shoot('4-impact');
            await _play(tester);
            await shoot('5-root');
          });
        }
      }
    });
  }
}
