import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/models/scene.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/scenes/sort_view.dart';

/// With `--dart-define=SHOTS=true` the play-through is photographed with
/// the real fonts into tool/shots/cards/, to be looked at, not kept.
const _shots = bool.fromEnvironment('SHOTS');

List<Map<String, Object?>> _samples() => [
  for (final c
      in jsonDecode(File('tool/cards/samples/sort.json').readAsStringSync())
          as List)
    (c as Map).cast<String, Object?>(),
];

SortScene _scene([int i = 0]) =>
    Scene.fromJson(_samples()[i]['scene'], id: 'test') as SortScene;

Map<String, Object?> _raw(List<Object?> items) => {
  'type': 'sort',
  'left': 'Myth',
  'right': 'True',
  'items': items,
};

Map<String, Object?> _item(String text, String pile) => {
  'text': text,
  'pile': pile,
  'verdict': 'Because.',
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
const _dark = (ink: Color(0xFFFFFFFF), ground: Color(0xFF1F2A6B));

Widget _host(
  SortScene scene, {
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
                child: SortSceneView(
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

/// Throws the top slip, found by its word, the way a thumb would.
Future<void> _throw(WidgetTester tester, String word, SortSide side) async {
  await tester.drag(
    find.text(word).last,
    Offset(side == SortSide.right ? 170 : -170, 0),
  );
  await tester.pumpAndSettle();
}

Future<void> _loadFonts() async {
  final fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
  };
  for (final e in fonts.entries) {
    final loader = FontLoader(e.key);
    final bytes = await File(e.value).readAsBytes();
    loader.addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
  }
}

void main() {
  if (_shots) setUpAll(_loadFonts);

  group('parse', () {
    test('reads every sample', () {
      for (var i = 0; i < _samples().length; i++) {
        final s = _scene(i);
        expect(s.items.length, inInclusiveRange(4, 8));
        expect(s.left, isNotEmpty);
        expect(s.right, isNotEmpty);
      }
      final swift = _scene(0);
      expect(swift.tag, 'The Tatler · No. 230');
      expect(swift.items.first.text, 'Mobb');
      expect(swift.items.first.pile, SortSide.right);
      expect(swift.nameOf(SortSide.left), 'Dead');
    });

    test('a note may be left out', () {
      final s = SortScene.parse(
        _raw([_item('A', 'left'), _item('B', 'right')]),
        'x',
      );
      expect(s.items.first.note, '');
      expect(s.tag, '');
    });

    test('refuses bad data', () {
      void bad(Map<String, Object?> raw) => expect(
        () => SortScene.parse(raw, 'x'),
        throwsFormatException,
      );
      bad({'type': 'sort', 'left': 'A', 'right': 'B'});
      bad(_raw([_item('A', 'left')]));
      bad(_raw([_item('A', 'left'), _item('B', 'up')]));
      bad(_raw([_item('A', 'left'), _item('B', 'left')]));
      bad({..._raw([_item('A', 'left'), _item('B', 'right')]), 'left': ''});
      bad(_raw([_item('A', 'left'), {'text': 'B', 'pile': 'right'}]));
      bad(_raw([_item('A', 'left'), 'B']));
    });

    test('an unknown field does not break it', () {
      final s = Scene.fromJson({
        ..._raw([_item('A', 'left'), _item('B', 'right')]),
        'later': 1,
      });
      expect(s, isA<SortScene>());
    });
  });

  for (final phone in _phones.entries) {
    final (size, height) = phone.value;
    for (final colours in [_light, _dark]) {
      final tone = colours == _light ? 'light' : 'dark';
      testWidgets('played to the end on ${phone.key}, $tone', (tester) async {
        _setPhone(tester, size);
        final scene = _scene(0);
        await tester.pumpWidget(
          _host(scene, phone: size, height: height, colours: colours),
        );
        await tester.pumpAndSettle();
        if (_shots) {
          await expectLater(
            find.byType(SortSceneView),
            matchesGoldenFile(
              '../../tool/shots/cards/sort-${phone.key}-$tone-0-start.png',
            ),
          );
        }

        // Every slip called Alive: right on four, wrong on three.
        for (var i = 0; i < scene.items.length; i++) {
          final word = scene.items[i].text;
          if (_shots && i == 1) {
            // Mid-drag, stamped, and on its back.
            final g = await tester.startGesture(
              tester.getCenter(find.text(word).last),
            );
            for (var k = 0; k < 6; k++) {
              await g.moveBy(const Offset(-14, 0));
              await tester.pump(const Duration(milliseconds: 16));
            }
            await expectLater(
              find.byType(SortSceneView),
              matchesGoldenFile(
                '../../tool/shots/cards/sort-${phone.key}-$tone-1-drag.png',
              ),
            );
            await g.moveBy(const Offset(-60, 0));
            await g.up();
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 900));
            await expectLater(
              find.byType(SortSceneView),
              matchesGoldenFile(
                '../../tool/shots/cards/sort-${phone.key}-$tone-2-back.png',
              ),
            );
            await tester.pumpAndSettle();
            continue;
          }
          await _throw(tester, word, SortSide.right);
        }
        expect(tester.takeException(), isNull);

        // Mobb, Banter, Bamboozle and Rep were alive; Pozz went left in the
        // shots run, so it is one more right there.
        final right = _shots ? 5 : 4;
        expect(find.text('$right of 7'), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        if (_shots) {
          await expectLater(
            find.byType(SortSceneView),
            matchesGoldenFile(
              '../../tool/shots/cards/sort-${phone.key}-$tone-3-end.png',
            ),
          );
        }

        // Try again deals the deck afresh.
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();
        expect(find.text('Mobb'), findsWidgets);
        expect(find.text('$right of 7'), findsNothing);
      });
    }
  }

  testWidgets('the trays are buttons too, and a wrong call is marked', (
    tester,
  ) async {
    _setPhone(tester, const Size(360, 740));
    final handle = tester.ensureSemantics();
    final scene = _scene(2);
    await tester.pumpWidget(
      _host(scene, phone: const Size(360, 740), height: 330),
    );
    await tester.pumpAndSettle();
    // Everything called a myth: four right, Octopus and Wombats wrong.
    for (var i = 0; i < scene.items.length; i++) {
      await tester.tap(find.bySemanticsLabel('Myth'));
      await tester.pumpAndSettle();
    }
    expect(find.text('4 of 6'), findsOneWidget);
    expect(find.bySemanticsLabel('Octopus: True. YOU: Myth'), findsOneWidget);
    expect(find.bySemanticsLabel('Goldfish: Myth'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a short drag puts the slip back and sorts nothing', (
    tester,
  ) async {
    _setPhone(tester, const Size(360, 740));
    final scene = _scene(1);
    await tester.pumpWidget(
      _host(scene, phone: const Size(360, 740), height: 330),
    );
    await tester.pumpAndSettle();
    final at = tester.getCenter(find.text('Writing').last);
    await tester.dragFrom(at, const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.text('Writing').last), at);
    expect(find.text('1 OF 6'), findsOneWidget);
  });

  testWidgets('a tap on the back skips the wait', (tester) async {
    _setPhone(tester, const Size(360, 740));
    final scene = _scene(1);
    await tester.pumpWidget(
      _host(scene, phone: const Size(360, 740), height: 330),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.text('Writing').last, const Offset(-170, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    // On its back: the true pile, large, and the verdict.
    expect(find.text('Before.'), findsOneWidget);
    await tester.tap(find.text('Before.'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('2 OF 6'), findsOneWidget);
  });

  testWidgets('with animations off it still plays to the end', (tester) async {
    _setPhone(tester, const Size(360, 740));
    final scene = _scene(1);
    await tester.pumpWidget(
      _host(scene, phone: const Size(360, 740), height: 330, calm: true),
    );
    await tester.pumpAndSettle();
    for (final item in scene.items) {
      await _throw(tester, item.text, item.pile);
    }
    expect(find.text('6 of 6'), findsOneWidget);
  });

  testWidgets('with a screen reader the back waits to be dismissed', (
    tester,
  ) async {
    _setPhone(tester, const Size(360, 740));
    final scene = _scene(1);
    await tester.pumpWidget(
      _host(scene, phone: const Size(360, 740), height: 330, reader: true),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('After'));
    await tester.pumpAndSettle();
    expect(find.text('Before.'), findsOneWidget);
    await tester.tap(find.text('Before.'));
    await tester.pumpAndSettle();
    expect(find.text('2 OF 6'), findsOneWidget);
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

    for (final phone in [const Size(360, 740), const Size(430, 932)]) {
      testWidgets('a swipe on the slip sorts it and keeps the card, '
          '${phone.width.round()}', (tester) async {
        _setPhone(tester, phone);
        final advanced = await pumpDeck(tester);

        // A slow drag and a hard flick, both ways, all on the slip.
        await _throw(tester, 'Mobb', SortSide.right);
        await tester.fling(find.text('Pozz').last, const Offset(-200, 0), 1500);
        await tester.pumpAndSettle();
        final g = await tester.startGesture(
          tester.getCenter(find.text('Banter').last),
        );
        for (var k = 0; k < 12; k++) {
          await g.moveBy(const Offset(18, 3));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await g.up();
        await tester.pumpAndSettle();

        expect(advanced(), 0, reason: 'a swipe on the slip moved the deck');
        expect(find.text('4 OF 7'), findsOneWidget);
        // Nor does a swipe that starts on a tray.
        await tester.drag(find.text('Alive'), const Offset(-200, 0));
        await tester.pumpAndSettle();
        expect(advanced(), 0);
        expect(find.text('5 OF 7'), findsOneWidget);

        // Above the scene, on the question, the deck still moves on.
        // (Its first line: the text box runs on under the scene.)
        final q = await tester.startGesture(
          tester.getRect(find.textContaining('Jonathan Swift named')).topLeft +
              const Offset(40, 12),
        );
        for (var k = 0; k < 10; k++) {
          await q.moveBy(const Offset(-20, 0));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await q.up();
        await tester.pumpAndSettle();
        expect(advanced(), 1);
      });
    }

    testWidgets('once the piles settle, a swipe on them moves the deck', (
      tester,
    ) async {
      _setPhone(tester, const Size(360, 740));
      final advanced = await pumpDeck(tester);
      final scene = deck.first.scene! as SortScene;
      for (final item in scene.items) {
        await _throw(tester, item.text, item.pile);
      }
      expect(find.text('7 of 7'), findsOneWidget);
      expect(advanced(), 0);
      await tester.drag(find.text('7 of 7'), const Offset(-260, 0));
      await tester.pumpAndSettle();
      expect(advanced(), 1);
    });
  });
}
