import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/scenes/translate_view.dart';

/// With `--dart-define=SHOTS=true` the play-through is photographed with
/// the real fonts into tool/shots/cards/, to be looked at, not kept.
const _shots = bool.fromEnvironment('SHOTS');

List<Map<String, Object?>> _samples() => [
  for (final c in jsonDecode(
    File('tool/cards/samples/translate.json').readAsStringSync(),
  ) as List)
    (c as Map).cast<String, Object?>(),
];

TranslateScene _scene([int i = 0]) =>
    Scene.fromJson(_samples()[i]['scene'], id: 'test') as TranslateScene;

Map<String, Object?> _raw(String body, List<Object?> phrases) => {
  'type': 'translate',
  'head': 'Contract',
  'body': body,
  'phrases': phrases,
  'ask': 'Which?',
  'watch': 'Read it.',
};

Map<String, Object?> _ph(String text, {Object? isCatch}) => {
  'text': text,
  'plain': 'plain $text',
  'why': 'Because.',
  'catch': ?isCatch,
};

/// The phones the brief names, and the room the scene gets on each: the
/// middle of a card front, and the fixed band on the back of an asking card.
const _phones = {
  'small': (Size(360, 740), 330.0),
  'large': (Size(430, 932), 520.0),
  'back': (Size(360, 740), 270.0),
};

/// Light ground with near-black ink, and a dark ground with white ink.
const _light = (ink: Color(0xFF10100C), ground: Color(0xFF00D9D9));
const _dark = (ink: Color(0xFFFFFFFF), ground: Color(0xFF2B5CFF));

Widget _host(
  TranslateScene scene, {
  required Size phone,
  required double height,
  ({Color ink, Color ground}) colours = _light,
  bool calm = false,
  bool reader = false,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: calm, accessibleNavigation: reader),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Container(
              width: phone.width - 36,
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              decoration: BoxDecoration(
                color: colours.ground,
                borderRadius: BorderRadius.circular(28),
              ),
              child: SizedBox(
                height: height,
                child: TranslateSceneView(
                  scene: scene,
                  ink: colours.ink,
                  ground: colours.ground,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void _setPhone(WidgetTester tester, Size phone) {
  tester.view.physicalSize = phone * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Where a thumb lands on phrase [i]: the middle of its first line.
Offset _on(WidgetTester tester, int i) =>
    tester.getCenter(find.byKey(ValueKey('translate-phrase-$i')).last);

Future<void> _tapPhrase(WidgetTester tester, int i, {bool settle = true}) async {
  await tester.tapAt(_on(tester, i));
  if (settle) await tester.pumpAndSettle();
}

Future<void> _loadFonts() async {
  final fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
  };
  for (final e in fonts.entries) {
    final loader = FontLoader(e.key);
    final bytes = await File(e.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

void main() {
  if (_shots) setUpAll(_loadFonts);

  group('parse', () {
    test('reads every sample', () {
      for (var i = 0; i < _samples().length; i++) {
        final s = _scene(i);
        expect(s.phrases.length, inInclusiveRange(2, 4));
        expect(s.asksForGuess, isTrue);
        expect(s.runs.map((r) => r.text).join(), s.body);
      }
      final xray = _scene(0);
      expect(xray.head, 'Radiology report');
      expect(xray.ref, 'Chest X-ray');
      expect(xray.phrases.map((p) => p.text), [
        'unremarkable',
        'impressive',
        'an occult infection',
      ]);
      expect(xray.catchIndex, 1);
      expect(
        xray.reading({1}),
        contains('lower lobe is large, and a real worry and suggests'),
      );
    });

    test('phrases are put in the order they are printed', () {
      final s = TranslateScene.parse(
        _raw('Alpha beta gamma delta.', [_ph('gamma'), _ph('Alpha')]),
        'x',
      );
      expect(s.phrases.first.text, 'Alpha');
      expect(s.catchIndex, -1);
      expect(s.asksForGuess, isFalse);
      expect(s.ref, '');
      expect(s.title, '');
      expect(s.runs.length, 4);
    });

    test('refuses bad data', () {
      void bad(Map<String, Object?> raw) =>
          expect(() => TranslateScene.parse(raw, 'x'), throwsFormatException);
      const body = 'Alpha beta gamma delta.';
      bad(_raw(body, [_ph('Alpha')]));
      bad(_raw(body, [_ph('Alpha'), _ph('omega')]));
      bad(_raw('Alpha beta Alpha.', [_ph('Alpha'), _ph('beta')]));
      bad(_raw(body, [_ph('Alpha beta'), _ph('beta gamma')]));
      bad(_raw(body, [_ph('Alpha', isCatch: true), _ph('beta', isCatch: true)]));
      bad(_raw(body, [_ph('Alpha', isCatch: 'yes'), _ph('beta')]));
      bad(_raw(body, [_ph('Alpha'), {'text': 'beta', 'plain': 'b'}]));
      bad(_raw(body, [_ph('Alpha'), 'beta']));
      bad({..._raw(body, [_ph('Alpha'), _ph('beta')]), 'watch': ''});
      bad({..._raw(body, [_ph('Alpha'), _ph('beta')]), 'head': null});
    });

    test('an unknown field does not break it', () {
      final s = Scene.fromJson({
        ..._raw('Alpha beta.', [_ph('Alpha'), _ph('beta')]),
        'later': 1,
      });
      expect(s, isA<TranslateScene>());
    });
  });

  for (final phone in _phones.entries) {
    final (size, height) = phone.value;
    for (final colours in [_light, _dark]) {
      final tone = colours == _light ? 'light' : 'dark';
      for (final sample in [0, 1, 2]) {
        // Every sample on every phone in the photo run. Otherwise the test
        // font, a square a full em wide, sets text far wider than the real
        // faces do, and the tight band on the back is played with one.
        if (!_shots && sample > 0 && phone.key == 'back') continue;
        testWidgets(
          'played to the end on ${phone.key}, $tone, sample $sample',
          (tester) async {
            _setPhone(tester, size);
            final scene = _scene(sample);
            await tester.pumpWidget(
              _host(scene, phone: size, height: height, colours: colours),
            );
            await tester.pumpAndSettle();
            String shot(String step) =>
                '../../tool/shots/cards/translate-$sample-${phone.key}-$tone-$step.png';
            if (_shots) {
              await expectLater(
                find.byType(TranslateSceneView),
                matchesGoldenFile(shot('0-start')),
              );
            }
            expect(find.text(scene.ask), findsOneWidget);
            expect(find.text('TAP YOUR PICK'), findsOneWidget);

            // The first tap is the guess, on the first phrase printed.
            await _tapPhrase(tester, 0, settle: false);
            await tester.pump();
            if (_shots) {
              await tester.pump(const Duration(milliseconds: 140));
              await expectLater(
                find.byType(TranslateSceneView),
                matchesGoldenFile(shot('1-select')),
              );
              await tester.pump(const Duration(milliseconds: 380));
              await expectLater(
                find.byType(TranslateSceneView),
                matchesGoldenFile(shot('2-typing')),
              );
            }
            await tester.pumpAndSettle();
            expect(find.text(scene.phrases[0].why), findsOneWidget);
            expect(find.text('1 OF ${scene.phrases.length}'), findsOneWidget);

            for (var i = 1; i < scene.phrases.length; i++) {
              await _tapPhrase(tester, i, settle: false);
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 1100));
              expect(find.text(scene.phrases[i].why), findsOneWidget);
              if (_shots && i == scene.phrases.length - 1) {
                await expectLater(
                  find.byType(TranslateSceneView),
                  matchesGoldenFile(shot('3-last')),
                );
              }
            }
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            // The note has been read; the stub moves on to the line to keep.
            expect(find.text(scene.watch), findsOneWidget);
            expect(find.text('YOUR GUESS'), findsOneWidget);
            expect(find.text('Try again'), findsOneWidget);
            if (_shots) {
              await expectLater(
                find.byType(TranslateSceneView),
                matchesGoldenFile(shot('4-end')),
              );
            }

            // A phrase can be read again, and a second tap lets go of it.
            await _tapPhrase(tester, 1);
            expect(find.text(scene.phrases[1].why), findsOneWidget);
            await _tapPhrase(tester, 1);
            expect(find.text(scene.watch), findsOneWidget);

            // Try again puts the jargon back.
            await tester.tap(find.text('Try again'));
            await tester.pumpAndSettle();
            expect(find.text(scene.ask), findsOneWidget);
            expect(find.text('YOUR GUESS'), findsNothing);
          },
        );
      }
    }
  }

  testWidgets('the reader hears the jargon, then the plain words and why', (
    tester,
  ) async {
    _setPhone(tester, const Size(360, 740));
    final handle = tester.ensureSemantics();
    final scene = _scene(0);
    await tester.pumpWidget(
      _host(scene, phone: const Size(360, 740), height: 330, reader: true),
    );
    await tester.pumpAndSettle();
    for (final p in scene.phrases) {
      final node = tester.getSemantics(find.bySemanticsLabel(p.text));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('${p.plain}. ${p.why}'), findsOneWidget);
    }
    // Nothing moved on by itself, but the sheet is done: the line to keep
    // is there to be read, and the whole document reads in plain words.
    expect(find.text(scene.watch), findsOneWidget);
    expect(
      find.bySemanticsLabel(scene.reading({0, 1, 2})),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('a guess on the catch is right, elsewhere it is wrong', (
    tester,
  ) async {
    _setPhone(tester, const Size(360, 740));
    final scene = _scene(1);
    await tester.pumpWidget(
      _host(scene, phone: const Size(360, 740), height: 330),
    );
    await tester.pumpAndSettle();
    // The catch, first: the guess sticks to it even though others follow.
    await _tapPhrase(tester, scene.catchIndex);
    for (var i = 0; i < scene.phrases.length; i++) {
      if (i != scene.catchIndex) await _tapPhrase(tester, i);
    }
    expect(find.text('YOUR GUESS'), findsOneWidget);
    expect(find.text(scene.watch), findsOneWidget);
  });

  testWidgets('a tap between phrases does nothing while there is work left', (
    tester,
  ) async {
    _setPhone(tester, const Size(360, 740));
    final scene = _scene(0);
    await tester.pumpWidget(
      _host(scene, phone: const Size(360, 740), height: 330),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('RADIOLOGY REPORT'));
    await tester.pumpAndSettle();
    expect(find.text(scene.ask), findsOneWidget);
  });

  testWidgets('with animations off it still plays to the end', (tester) async {
    _setPhone(tester, const Size(360, 740));
    final scene = _scene(2);
    await tester.pumpWidget(
      _host(scene, phone: const Size(360, 740), height: 330, calm: true),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < scene.phrases.length; i++) {
      await _tapPhrase(tester, i, settle: false);
      await tester.pump();
      expect(find.text(scene.phrases[i].why), findsOneWidget);
    }
    await tester.pumpAndSettle();
    expect(find.text(scene.watch), findsOneWidget);
  });

  testWidgets('a tap mid-flip on the next phrase finishes the first', (
    tester,
  ) async {
    _setPhone(tester, const Size(360, 740));
    final scene = _scene(0);
    await tester.pumpWidget(
      _host(scene, phone: const Size(360, 740), height: 330),
    );
    await tester.pumpAndSettle();
    await _tapPhrase(tester, 0, settle: false);
    await tester.pump(const Duration(milliseconds: 200));
    await _tapPhrase(tester, 2, settle: false);
    await tester.pumpAndSettle();
    expect(find.text(scene.phrases[2].why), findsOneWidget);
    expect(find.text('2 OF 3'), findsOneWidget);
  });

  group('in the deck', () {
    late List<Pill> deck;
    setUp(() {
      deck = [for (final c in _samples()) cardFromJson(c)];
    });

    Future<int Function()> pumpDeck(WidgetTester tester) async {
      var advanced = 0;
      var index = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.fromLTRB(18, 60, 18, 96),
                child: PillCardStack(
                  deck: deck,
                  index: index,
                  onAdvance: () => setState(() {
                    advanced++;
                    index++;
                  }),
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
          ),
        ),
      );
      await tester.pumpAndSettle();
      return () => advanced;
    }

    // The back of the card: its answer, which only a turned card shows.
    Finder answer() =>
        find.textContaining('That something is wrong', findRichText: true);

    for (final phone in [const Size(360, 740), const Size(430, 932)]) {
      testWidgets('taps on the sheet translate and keep the card, '
          '${phone.width.round()}', (tester) async {
        _setPhone(tester, phone);
        final advanced = await pumpDeck(tester);
        final scene = deck.first.scene! as TranslateScene;

        for (var i = 0; i < scene.phrases.length; i++) {
          await _tapPhrase(tester, i);
          expect(answer(), findsNothing, reason: 'a phrase tap turned the card');
        }
        // A tap on the letterhead, mid-play, is kept too.
        expect(advanced(), 0);
        expect(find.text(scene.watch), findsOneWidget);

        // Once the sheet is finished, a tap off the phrases turns the card.
        await tester.tap(find.text('RADIOLOGY REPORT'));
        await tester.pumpAndSettle();
        expect(answer(), findsOneWidget);
        expect(advanced(), 0);
      });
    }

    testWidgets('the sheet claims no drags: a swipe on it moves the deck', (
      tester,
    ) async {
      _setPhone(tester, const Size(360, 740));
      final advanced = await pumpDeck(tester);
      final g = await tester.startGesture(_on(tester, 1));
      for (var k = 0; k < 12; k++) {
        await g.moveBy(const Offset(-22, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pumpAndSettle();
      expect(advanced(), 1);
    });

    testWidgets('mid-play, a tap that misses every phrase keeps the card', (
      tester,
    ) async {
      _setPhone(tester, const Size(360, 740));
      await pumpDeck(tester);
      await tester.tap(find.text('RADIOLOGY REPORT'));
      await tester.pumpAndSettle();
      expect(answer(), findsNothing);
    });
  });
}
