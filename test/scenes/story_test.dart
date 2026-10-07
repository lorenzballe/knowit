// The `story` scene: what happens next?
//
//   flutter test test/scenes/story_test.dart
//   flutter test test/scenes/story_test.dart --update-goldens --dart-define=SHOTS=true
//
// The second line also photographs each sample card on a small and a large
// phone, at the first scene, mid-change, at the question and at the end,
// into tool/shots/cards/.
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
import 'package:astuto/widgets/scenes/story_view.dart';

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
    File('tool/cards/samples/story.json').readAsStringSync(),
  ) as List)
    (c as Map).cast<String, Object?>(),
];

Map<String, Object?> _drachten() =>
    (_samples().first['scene'] as Map).cast<String, Object?>();

StoryScene _parse(Map<String, Object?> raw) =>
    Scene.fromJson(raw, id: 'test') as StoryScene;

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

Widget _deck(List<Pill> deck, {VoidCallback? onAdvance}) => _app(
  Scaffold(
    body: SizedBox(
      height: 640,
      child: PillCardStack(
        isSaved: (_) => false,
        onSave: (_) {},
        onShare: (_) {},
        deck: deck,
        index: 0,
        onAdvance: onAdvance ?? () {},
        answerFor: (_) => null,
        reviewIds: const {},
        onAnswer: (_, _, _, _) {},
      ),
    ),
  ),
);

void _phone(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Runs a change through to its end, frame by frame like a phone.
Future<void> _play(WidgetTester tester) async {
  for (var f = 0; f < 22; f++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The lines of the scene are set one per Text, so a sentence is found by
/// its first words.
Finder _starts(String text) => find.byWidgetPredicate(
  (w) =>
      w is Text &&
      w.data != null &&
      w.data!.isNotEmpty &&
      text.startsWith(w.data!) &&
      w.data!.length >= 6,
);

/// The scene of [pill], when a deck shows the next card behind it.
Finder _sceneOf(Pill pill) => find.byWidgetPredicate(
  (w) => w is StorySceneView && identical(w.scene, pill.scene),
);

/// Taps the scene's own area (the top strip), never a button.
Future<void> _tapScene(WidgetTester tester, [Finder? scene]) async {
  final strip = tester.getTopLeft(scene ?? find.byType(StorySceneView));
  await tester.tapAt(strip + const Offset(40, 6));
}

void main() {
  group('parse', () {
    test('reads every field of a sample', () {
      final s = _parse(_drachten());
      expect(s.scenes, hasLength(3));
      expect(s.scenes.first.fact, 'Drachten, the Netherlands');
      expect(s.scenes.first.glyph, StoryGlyph.car);
      expect(s.scenes[2].glyph, StoryGlyph.ban);
      expect(s.ask, 'What happens to the crashes?');
      expect(s.options, ['They go up', 'No real change', 'They go down']);
      expect(s.answer, 2);
      expect(s.outcome.glyph, StoryGlyph.fall);
      expect(s.why, startsWith('With nothing'));
      expect(s.stops, 5);
      expect(s.askAt, 3);
      expect(s.outcomeAt, 4);
    });

    test('every sample parses', () {
      for (final c in _samples()) {
        expect(cardFromJson(c).scene, isA<StoryScene>());
      }
    });

    test('a fact is optional', () {
      final raw = _drachten();
      final scenes = [
        for (final b in raw['scenes'] as List)
          {...(b as Map).cast<String, Object?>()}..remove('fact'),
      ];
      final s = _parse({...raw, 'scenes': scenes});
      expect(s.scenes.every((b) => b.fact.isEmpty), isTrue);
    });

    test('refuses what it cannot tell', () {
      void bad(Map<String, Object?> patch) => expect(
        () => _parse({..._drachten(), ...patch}),
        throwsFormatException,
        reason: '$patch',
      );
      final scenes = (_drachten()['scenes'] as List).cast<Map>();
      bad({'scenes': scenes.take(2).toList()});
      bad({
        'scenes': [...scenes, ...scenes],
      });
      bad({
        'scenes': [
          {'line': 'A line', 'glyph': 'unicorn'},
          ...scenes.skip(1),
        ],
      });
      bad({
        'scenes': [
          {'line': 'A line', 'glyph': 'question'},
          ...scenes.skip(1),
        ],
      });
      bad({
        'scenes': [
          {'glyph': 'car'},
          ...scenes.skip(1),
        ],
      });
      bad({'ask': ''});
      bad({'ask': 4});
      bad({
        'options': [
          {'label': 'Only one'},
        ],
      });
      bad({
        'options': [
          {'label': 'a'},
          {'label': 'b'},
          {'label': 'c'},
          {'label': 'd'},
        ],
      });
      bad({'answer': 3});
      bad({'answer': -1});
      bad({'answer': '2'});
      bad({'outcome': 'It went down'});
      bad({'why': null});
    });
  });

  group('plays', () {
    setUpAll(_loadFonts);

    for (final phone in _phones.entries) {
      testWidgets('scenes, the stop, the pick and the outcome on a '
          '${phone.key} phone', (tester) async {
        _phone(tester, phone.value);
        final pill = cardFromJson(_samples().first);
        final s = pill.scene! as StoryScene;
        await tester.pumpWidget(_card(pill));
        await _play(tester);

        expect(find.text('1 OF 5'), findsOneWidget);
        expect(find.text(s.scenes[0].fact.toUpperCase()), findsOneWidget);
        expect(_starts(s.scenes[0].line), findsWidgets);
        expect(find.text('Swipe or tap'), findsOneWidget);

        for (var i = 1; i < s.scenes.length; i++) {
          await _tapScene(tester);
          await _play(tester);
          expect(find.text('${i + 1} OF 5'), findsOneWidget);
          expect(find.text(s.scenes[i].fact.toUpperCase()), findsOneWidget);
          expect(find.text(s.scenes[i - 1].fact.toUpperCase()), findsNothing);
        }

        // The stop: the question and the outcomes, nothing given away.
        await _tapScene(tester);
        await _play(tester);
        expect(find.text('4 OF 5'), findsOneWidget);
        expect(find.text('Tap your pick'), findsOneWidget);
        for (final o in s.options) {
          expect(find.text(o), findsOneWidget);
        }
        expect(find.text(s.outcome.fact.toUpperCase()), findsNothing);

        // A tap in the scene off the buttons does not skip the question.
        await _tapScene(tester);
        await _play(tester);
        expect(find.text('4 OF 5'), findsOneWidget);

        // Commit to the wrong outcome.
        await tester.tap(find.text(s.options[0]));
        await tester.pump(const Duration(milliseconds: 300));
        await _play(tester);
        expect(find.text('5 OF 5'), findsOneWidget);
        expect(find.text(s.outcome.fact.toUpperCase()), findsOneWidget);
        expect(find.text('YOU'), findsOneWidget);
        // The pick is struck through: it did not happen.
        final pick = tester.widget<Text>(find.text(s.options[0]));
        expect(pick.style!.decoration, TextDecoration.lineThrough);
        expect(find.text(s.options[1]), findsNothing);
        expect(_starts(s.why), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a pick that came true is not struck through', (tester) async {
      _phone(tester, const Size(390, 844));
      final pill = cardFromJson(_samples()[1]);
      final s = pill.scene! as StoryScene;
      await tester.pumpWidget(_card(pill, calm: true));
      await tester.pump();
      for (var i = 0; i < s.scenes.length; i++) {
        await _tapScene(tester);
        await tester.pump();
      }
      await tester.tap(find.text(s.options[s.answer]));
      await tester.pump();
      final pick = tester.widget<Text>(find.text(s.options[s.answer]));
      expect(pick.style!.decoration, isNull);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a swipe goes on and back, and back stops at the start', (
      tester,
    ) async {
      _phone(tester, const Size(360, 740));
      final pill = cardFromJson(_samples()[2]);
      final s = pill.scene! as StoryScene;
      await tester.pumpWidget(_card(pill));
      await _play(tester);
      final centre = tester.getCenter(find.byType(StorySceneView));
      await tester.dragFrom(centre, const Offset(-120, 0));
      await _play(tester);
      expect(find.text(s.scenes[1].fact.toUpperCase()), findsOneWidget);
      await tester.dragFrom(centre, const Offset(120, 0));
      await _play(tester);
      expect(find.text(s.scenes[0].fact.toUpperCase()), findsOneWidget);
      await tester.dragFrom(centre, const Offset(120, 0));
      await _play(tester);
      expect(find.text('1 OF 5'), findsOneWidget);
    });

    testWidgets('a tap during a change goes straight on', (tester) async {
      _phone(tester, const Size(360, 740));
      final pill = cardFromJson(_samples()[1]);
      final s = pill.scene! as StoryScene;
      await tester.pumpWidget(_card(pill));
      await _play(tester);
      await _tapScene(tester);
      await tester.pump(const Duration(milliseconds: 120));
      await _tapScene(tester);
      await _play(tester);
      expect(find.text(s.scenes[2].fact.toUpperCase()), findsOneWidget);
    });

    testWidgets('fits the 270 high band on the back of asking cards', (
      tester,
    ) async {
      _phone(tester, const Size(360, 740));
      for (final c in _samples()) {
        final pill = cardFromJson(c);
        final s = pill.scene! as StoryScene;
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
        await _play(tester);
        for (var i = 0; i < s.scenes.length; i++) {
          await _tapScene(tester);
          await _play(tester);
        }
        if (_shots) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              '../../tool/shots/cards/story-band-${pill.id}-ask.png',
            ),
          );
        }
        await tester.tap(find.text(s.options.last));
        await _play(tester);
        expect(tester.takeException(), isNull);
        if (_shots) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              '../../tool/shots/cards/story-band-${pill.id}-end.png',
            ),
          );
        }
        expect(find.text(s.outcome.fact.toUpperCase()), findsOneWidget);
        // Nothing is set outside the band.
        final band = tester.getRect(find.byType(SceneView));
        for (final e in find.byType(Text).evaluate()) {
          final r = tester.getRect(find.byWidget(e.widget));
          expect(r.top, greaterThanOrEqualTo(band.top - 0.5));
          expect(
            r.bottom,
            lessThanOrEqualTo(band.bottom + 0.5),
            reason: (e.widget as Text).data,
          );
        }
      }
    });

    testWidgets('with animations off, every change lands at once', (
      tester,
    ) async {
      _phone(tester, const Size(390, 844));
      final pill = cardFromJson(_samples().first);
      final s = pill.scene! as StoryScene;
      await tester.pumpWidget(_card(pill, calm: true));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      for (var i = 0; i < s.scenes.length; i++) {
        await _tapScene(tester);
        await tester.pump();
        expect(tester.hasRunningAnimations, isFalse);
      }
      await tester.tap(find.text(s.options[2]));
      await tester.pump();
      expect(find.text(s.outcome.fact.toUpperCase()), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a screen reader can go through the story and pick', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      _phone(tester, const Size(390, 844));
      final pill = cardFromJson(_samples()[2]);
      final s = pill.scene! as StoryScene;
      await tester.pumpWidget(_card(pill));
      await _play(tester);

      final first = find.semantics.byLabel(
        RegExp('^1 of 5\\. ${RegExp.escape(s.scenes[0].fact)}'),
      );
      expect(first, findsOne);
      for (var i = 0; i < s.scenes.length; i++) {
        tester.semantics.tap(find.semantics.byLabel(RegExp('of 5\\.')));
        await _play(tester);
      }
      expect(find.semantics.byLabel(s.ask), findsOne);
      for (final o in s.options) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(o)),
          matchesSemantics(
            label: o,
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
      tester.semantics.tap(find.semantics.byLabel(s.options[s.answer]));
      await _play(tester);
      expect(
        find.bySemanticsLabel(
          RegExp(
            '${RegExp.escape(s.outcome.line)}.*YOU: ${s.options[s.answer]}',
          ),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('in the deck: a swipe in the story stays in the story, and '
        'the card turns only once the outcome lands', (tester) async {
      final pill = cardFromJson(_samples().first);
      final s = pill.scene! as StoryScene;
      var advanced = 0;
      await tester.pumpWidget(
        _deck([pill, cardFromJson(_samples()[1])], onAdvance: () => advanced++),
      );
      await _play(tester);

      // A hard fling across the scene moves the story, not the deck.
      final centre = tester.getCenter(_sceneOf(pill));
      await tester.flingFrom(centre, const Offset(-260, 0), 1500);
      await _play(tester);
      expect(advanced, 0);
      expect(find.text(pill.question), findsOneWidget);
      expect(find.text(s.scenes[1].fact.toUpperCase()), findsOneWidget);
      expect(find.text('WHAT TO KEEP'), findsNothing);

      // Taps go on through the story without turning the card.
      for (var i = 1; i < s.scenes.length; i++) {
        await _tapScene(tester, _sceneOf(pill));
        await _play(tester);
      }
      expect(find.text('WHAT TO KEEP'), findsNothing);
      await tester.tap(find.text(s.options[2]));
      await _play(tester);
      expect(find.text('WHAT TO KEEP'), findsNothing);

      // Landed: a tap on the scene turns the card over.
      await _tapScene(tester, _sceneOf(pill));
      await _play(tester);
      expect(find.text('WHAT TO KEEP'), findsOneWidget);
    });

    testWidgets('outside the scene the card still turns mid-story', (
      tester,
    ) async {
      final pill = cardFromJson(_samples().first);
      await tester.pumpWidget(_deck([pill]));
      await _play(tester);
      await _tapScene(tester, _sceneOf(pill));
      await _play(tester);
      expect(find.text('WHAT TO KEEP'), findsNothing);
      await tester.tap(find.text('Tap to reveal'));
      await _play(tester);
      expect(find.text('WHAT TO KEEP'), findsOneWidget);
    });

    testWidgets('dark ink on a light subject draws too', (tester) async {
      _phone(tester, const Size(360, 740));
      final s = _parse(_drachten());
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Container(
              color: const Color(0xFFFFD23F),
              padding: const EdgeInsets.fromLTRB(22, 120, 22, 160),
              child: StorySceneView(
                scene: s,
                ink: const Color(0xFF16130E),
                ground: const Color(0xFFFFD23F),
              ),
            ),
          ),
        ),
      );
      await _play(tester);
      for (var i = 0; i < s.scenes.length; i++) {
        await _tapScene(tester);
        await _play(tester);
      }
      await tester.tap(find.text(s.options[2]));
      await _play(tester);
      expect(find.text(s.outcome.fact.toUpperCase()), findsOneWidget);
      if (_shots) {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../../tool/shots/cards/story-light-ink.png'),
        );
      }
    });

    if (_shots) {
      for (final c in _samples()) {
        for (final phone in _phones.entries) {
          testWidgets('photograph ${c['id']} on ${phone.key}', (tester) async {
            _phone(tester, phone.value);
            final pill = cardFromJson(c);
            final s = pill.scene! as StoryScene;
            await tester.pumpWidget(_card(pill));
            Future<void> shoot(String stage) => expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                '../../tool/shots/cards/story-${pill.id}-${phone.key}-$stage.png',
              ),
            );
            await tester.pump(const Duration(milliseconds: 450));
            await shoot('0-drawing-in');
            await _play(tester);
            await shoot('1-first');
            await _tapScene(tester);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 330));
            await shoot('2-changing');
            await _play(tester);
            await shoot('3-second');
            for (var i = 2; i < s.scenes.length; i++) {
              await _tapScene(tester);
              await _play(tester);
            }
            await _tapScene(tester);
            await _play(tester);
            await shoot('4-ask');
            await tester.tap(find.text(s.options[0]));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 820));
            await shoot('5-landing');
            await _play(tester);
            await shoot('6-end');
          });
        }
      }
    }
  });
}
