import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/scene.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/scene_view.dart';

/// Photographs under tool/shots/cards/ only when asked:
/// `flutter test test/scenes/clues_test.dart --dart-define=SHOTS=true`.
const _shots = bool.fromEnvironment('SHOTS');

/// `clues`: the data is read strictly, and the reader can turn clues over,
/// pick a suspect, lock it in and reach the verdict on any phone, in any
/// height the card gives the scene.
void main() {
  Map<String, Object?> cholera() => {
    'type': 'clues',
    'options': ['Cholera', 'Plague', 'Smallpox', 'Typhoid'],
    'answer': 0,
    'clues': [
      {
        'text': 'Over 500 people in a few London streets die within ten days.',
        'tag': '500 dead in ten days',
        'rulesOut': <int>[],
      },
      {
        'text': 'No pocks, no swollen glands: violent diarrhoea and vomiting.',
        'tag': 'No pocks, no swellings',
        'rulesOut': [1, 2],
      },
      {
        'text': 'Many die within a day of the first cramp.',
        'tag': 'Dead within a day',
        'rulesOut': [3],
      },
      {
        'text': "The dead drank from one pump. The brewery's men drank beer, and lived.",
        'tag': 'One pump, spared brewers',
        'rulesOut': <int>[],
      },
    ],
    'why': 'Speed decides: typhoid takes weeks to kill, cholera hours.',
  };

  CluesScene parse(Map<String, Object?> raw) =>
      Scene.fromJson(raw, id: 'test') as CluesScene;

  group('parse', () {
    test('reads every field', () {
      final s = parse(cholera());
      expect(s.options, ['Cholera', 'Plague', 'Smallpox', 'Typhoid']);
      expect(s.answer, 0);
      expect(s.clues, hasLength(4));
      expect(s.clues[1].tag, 'No pocks, no swellings');
      expect(s.clues[1].rulesOut, [1, 2]);
      expect(s.clues.first.rulesOut, isEmpty);
      expect(s.why, startsWith('Speed decides'));
    });

    test('the decisive clue strikes off the last rival', () {
      final s = parse(cholera());
      expect(s.decisive, 2);
      expect(s.outBy(0), -1);
      expect(s.outBy(1), 1);
      expect(s.outBy(3), 2);
    });

    test('points fall by an even step per clue', () {
      final s = parse(cholera());
      expect(
        [for (var k = 1; k <= 4; k++) s.pointsAfter(k)],
        [100, 75, 50, 25],
      );
      expect(s.pointsAfter(9), 25);
    });

    test('refuses bad data', () {
      void bad(Map<String, Object?> raw) =>
          expect(() => parse(raw), throwsFormatException);
      List<Map<String, Object?>> clues() =>
          (cholera()['clues'] as List).cast<Map<String, Object?>>();
      bad({
        ...cholera(),
        'options': ['A', 'B'],
      });
      bad({
        ...cholera(),
        'options': ['A', 'B', 'C', 'D', 'E', 'F'],
      });
      bad({
        ...cholera(),
        'options': ['A', 'a', 'B', 'C'],
      });
      bad({...cholera(), 'answer': 4});
      bad({...cholera(), 'answer': '0'});
      bad({...cholera()}..remove('why'));
      bad({...cholera(), 'clues': clues().take(2).toList()});
      // A clue that rules out the answer.
      bad({
        ...cholera(),
        'clues': [
          ...clues().take(3),
          {
            'text': 'x',
            'tag': 'y',
            'rulesOut': [0],
          },
        ],
      });
      // An option ruled out twice.
      bad({
        ...cholera(),
        'clues': [
          ...clues().take(3),
          {
            'text': 'x',
            'tag': 'y',
            'rulesOut': [3],
          },
        ],
      });
      // A wrong option never ruled out.
      bad({
        ...cholera(),
        'clues': [
          clues()[0],
          clues()[1],
          {...clues()[2], 'rulesOut': <int>[]},
        ],
      });
      // The first clue settles it alone.
      bad({
        ...cholera(),
        'clues': [
          {
            ...clues()[0],
            'rulesOut': [1, 2, 3],
          },
          {...clues()[1], 'rulesOut': <int>[]},
          {...clues()[2], 'rulesOut': <int>[]},
        ],
      });
      bad({
        ...cholera(),
        'clues': [
          ...clues().take(3),
          {'tag': 'y'},
        ],
      });
    });
  });

  Widget host(
    Map<String, Object?> raw, {
    required double height,
    Color ground = const Color(0xFFFFC49B),
    Color ink = const Color(0xFF10100C),
    bool still = false,
    Key? key,
  }) => MaterialApp(
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
              child: RepaintBoundary(
                key: key,
                child: ColoredBox(
                  color: ground,
                  child: SizedBox(
                    height: height,
                    child: SceneView(
                      scene: parse(raw),
                      ink: ink,
                      ground: ground,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  group('play', () {
    Future<void> phone(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    String digits(WidgetTester tester) => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((d) => RegExp(r'^\d$').hasMatch(d))
        .take(3)
        .join();

    for (final (name, size, height) in [
      ('small phone', const Size(360, 740), 330.0),
      ('large phone', const Size(430, 932), 520.0),
      ('back of an asking card', const Size(360, 740), 270.0),
    ]) {
      testWidgets('on a $name: turn clues, pick, lock in, see the verdict', (
        tester,
      ) async {
        await phone(tester, size);
        await tester.pumpWidget(host(cholera(), height: height));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(digits(tester), '100');
        expect(find.text('2 OF 4'), findsOneWidget);
        expect(find.text('Tap your pick'), findsOneWidget);

        // Two more clues: the points drain a step each.
        await tester.tap(find.text('2 OF 4'));
        await tester.pumpAndSettle();
        expect(digits(tester), '075');
        await tester.tap(find.text('3 OF 4'));
        await tester.pumpAndSettle();
        expect(digits(tester), '050');
        expect(
          find.text('Many die within a day of the first cramp.'),
          findsOneWidget,
        );

        // An older card brought back to the front by its edge.
        if (height >= 300) {
          await tester.tap(find.text('No pocks, no swellings'));
          await tester.pumpAndSettle();
          expect(find.textContaining('violent diarrhoea'), findsOneWidget);
        }

        await tester.tap(find.text('Typhoid'));
        await tester.pump();
        expect(find.text('LOCK IT IN'), findsOneWidget);
        await tester.tap(find.text('LOCK IT IN'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Wrong: the points drain away; the verdict and the why remain.
        expect(digits(tester), '000');
        expect(find.text('YOU'), findsOneWidget);
        expect(find.textContaining('Speed decides'), findsOneWidget);
        expect(find.text('LOCK IT IN'), findsNothing);
        // The decisive clue is at the front.
        expect(
          find.text('Many die within a day of the first cramp.'),
          findsOneWidget,
        );
        // Each struck suspect carries the number of the clue that ruled it
        // out: two by clue 2, one by clue 3. Card 2 shows its number too,
        // unless its edge is a sliver.
        expect(find.text('2'), findsNWidgets(height >= 300 ? 3 : 2));
      });
    }

    testWidgets('a right answer keeps its points; light ink on a dark ground', (
      tester,
    ) async {
      await phone(tester, const Size(360, 740));
      await tester.pumpWidget(
        host(
          cholera(),
          height: 400,
          ground: const Color(0xFF5A2EA6),
          ink: Colors.white,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 OF 4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cholera'));
      await tester.pump();
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(digits(tester), '075');
      expect(find.text('YOU'), findsOneWidget);
      // Every card was dealt.
      expect(find.text('One pump, spared brewers'), findsOneWidget);
    });

    testWidgets('tapping the same pick again lets it go', (tester) async {
      await phone(tester, const Size(360, 740));
      await tester.pumpWidget(host(cholera(), height: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plague'));
      await tester.pump();
      expect(find.text('LOCK IT IN'), findsOneWidget);
      await tester.tap(find.text('Plague'));
      await tester.pump();
      expect(find.text('LOCK IT IN'), findsNothing);
    });

    testWidgets('with animations off, the verdict is there on the next frame', (
      tester,
    ) async {
      await phone(tester, const Size(360, 740));
      await tester.pumpWidget(host(cholera(), height: 400, still: true));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      await tester.tap(find.text('Cholera'));
      await tester.pump();
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pump();
      expect(digits(tester), '100');
      expect(find.textContaining('Speed decides'), findsOneWidget);
      expect(
        find.text('Many die within a day of the first cramp.'),
        findsOneWidget,
      );
    });

    testWidgets('a screen reader can turn, pick and lock in', (tester) async {
      final handle = tester.ensureSemantics();
      await phone(tester, const Size(360, 740));
      await tester.pumpWidget(host(cholera(), height: 400));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.bySemanticsLabel('Cholera')),
        isSemantics(label: 'Cholera', isButton: true, hasTapAction: true),
      );
      tester.semantics.tap(find.semantics.byLabel('2 of 4'));
      await tester.pumpAndSettle();
      expect(digits(tester), '075');
      tester.semantics.tap(find.semantics.byLabel('Smallpox'));
      await tester.pumpAndSettle();
      tester.semantics.tap(find.semantics.byLabel('LOCK IT IN'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Cholera')),
        isSemantics(label: 'Cholera', value: 'TRUTH'),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Smallpox')),
        isSemantics(label: 'Smallpox', value: '✕ 2 of 4'),
      );
      handle.dispose();
    });
  });

  group('in the deck', () {
    testWidgets('a tap in the scene plays it and does not turn the card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 740) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final pill = cardFromJson({
        'id': 'clues-deck-test',
        'topic': 'medicine',
        'genre': 'medicine.medical_history',
        'strand': 'medicine.medical_history.germ_theory',
        'kind': 'read',
        'question': 'Soho, 1854. Which disease is it?',
        'answer': 'Cholera.',
        'move': 'Ask what a clue rules out.',
        'source': 'Snow, 1855',
        'scene': cholera(),
      });
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
      await tester.tap(find.text('2 OF 4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plague'));
      await tester.pumpAndSettle();
      // A tap on the card of evidence, not a control, is held too.
      await tester.tap(find.textContaining('violent diarrhoea'));
      await tester.pumpAndSettle();
      expect(advanced, 0);
      expect(find.text('LOCK IT IN'), findsOneWidget);
      expect(find.text('Cholera.'), findsNothing);
    });
  });

  group('photographs', () {
    Future<void> fonts() async {
      for (final e in {
        'Fraunces': 'assets/fonts/Fraunces.ttf',
        'Figtree': 'assets/fonts/Figtree.ttf',
      }.entries) {
        final bytes = await File(e.value).readAsBytes();
        await (FontLoader(e.key)..addFont(
              Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
            ))
            .load();
      }
    }

    // Real file reads hang inside a widget test's fake clock: load first.
    setUpAll(() async {
      if (_shots) await fonts();
    });

    final samples = _shots
        ? (jsonDecode(
            File('tool/cards/samples/clues.json').readAsStringSync(),
          ) as List).cast<Map<String, Object?>>()
        : const <Map<String, Object?>>[];
    for (final (phoneName, size, height, ground, ink) in [
      (
        'small',
        const Size(360, 740),
        340.0,
        const Color(0xFF00E59E),
        const Color(0xFF10100C),
      ),
      (
        'large',
        const Size(430, 932),
        520.0,
        const Color(0xFFFF3B30),
        Colors.white,
      ),
      (
        'back',
        const Size(360, 740),
        270.0,
        const Color(0xFF5A2EA6),
        Colors.white,
      ),
    ]) {
      for (final card in samples) {
        testWidgets('${card['id']} on $phoneName', (tester) async {
          tester.view.physicalSize = size * 3;
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final key = GlobalKey();
          final raw = (card['scene'] as Map).cast<String, Object?>();
          await tester.pumpWidget(
            host(raw, height: height, ground: ground, ink: ink, key: key),
          );
          await tester.pumpAndSettle();
          final id = card['id'];
          await expectLater(
            find.byKey(key),
            matchesGoldenFile('../../tool/shots/cards/$id-$phoneName-0.png'),
          );
          final s = parse(raw);
          await tester.tap(find.text('2 OF ${s.clues.length}'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('3 OF ${s.clues.length}'));
          await tester.pumpAndSettle();
          await tester.tap(find.text(s.options[(s.answer + 1) % 3]));
          await tester.pumpAndSettle();
          await expectLater(
            find.byKey(key),
            matchesGoldenFile('../../tool/shots/cards/$id-$phoneName-1.png'),
          );
          await tester.tap(find.text('LOCK IT IN'));
          await tester.pump(const Duration(milliseconds: 1300));
          await expectLater(
            find.byKey(key),
            matchesGoldenFile('../../tool/shots/cards/$id-$phoneName-2.png'),
          );
          await tester.pumpAndSettle();
          await expectLater(
            find.byKey(key),
            matchesGoldenFile('../../tool/shots/cards/$id-$phoneName-3.png'),
          );
        });
      }
    }
  });
}
