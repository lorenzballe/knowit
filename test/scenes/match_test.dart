import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/scene.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/scene_view.dart';

/// Photographs, only when asked:
///   flutter test test/scenes/match_test.dart --update-goldens --dart-define=SHOTS=true
const _shots = bool.fromEnvironment('SHOTS');

/// `match`: the data is read strictly, and the reader can join every pair,
/// by dragging or by tapping, lock it in and reach the untangled truth on
/// any phone, in any height the card gives the scene.
void main() {
  // The real faces, so that what is measured to fit is what is drawn.
  setUpAll(_loadFonts);

  Map<String, Object?> biases() => {
    'type': 'match',
    'leftTitle': 'Bias',
    'rightTitle': 'Where it gets you',
    'pairs': [
      {
        'left': 'Anchoring',
        'right': "The 'was \$400' tag that makes \$199 feel cheap",
        'note': 'The first number becomes the ruler.',
        'missed': true,
      },
      {
        'left': 'Sunk cost',
        'right': 'Sitting through a bad film because you paid',
        'note': 'The money is gone either way.',
      },
      {
        'left': 'Availability',
        'right': 'Fearing the flight more than the drive there',
        'note': 'Crashes make the news.',
      },
      {
        'left': 'Planning fallacy',
        'right': "'The kitchen will take two weeks, tops'",
        'note': 'We plan the best case.',
      },
    ],
  };

  MatchScene parse(Map<String, Object?> raw) =>
      Scene.fromJson(raw, id: 'test') as MatchScene;

  const lefts = ['Anchoring', 'Sunk cost', 'Availability', 'Planning fallacy'];
  final rights = [
    for (final p in biases()['pairs'] as List) (p as Map)['right'] as String,
  ];

  group('parse', () {
    test('reads every field, pairs in their true order', () {
      final s = parse(biases());
      expect(s.leftTitle, 'Bias');
      expect(s.rightTitle, 'Where it gets you');
      expect(s.pairs.map((p) => p.left), lefts);
      expect(s.pairs.first.missed, isTrue);
      expect(s.pairs[1].missed, isFalse);
      expect(s.pairs[2].note, 'Crashes make the news.');
    });

    test('without an order, no item starts beside its partner', () {
      for (final n in [3, 4, 5]) {
        final order = MatchScene.matchSceneDefaultOrders[n]!;
        expect(order.toSet(), {for (var i = 0; i < n; i++) i});
        for (var k = 0; k < n; k++) {
          expect(order[k], isNot(k));
        }
      }
      expect(parse(biases()).order, [2, 0, 3, 1]);
      expect(parse({...biases(), 'order': [3, 2, 1, 0]}).order, [3, 2, 1, 0]);
    });

    test('the reveal opens on the missed pair, else the first wrong one', () {
      final s = parse(biases());
      expect(s.focusFor({0: 0, 1: 1, 2: 2, 3: 3}), 0);
      final pairs = [
        for (final p in biases()['pairs'] as List)
          {...(p as Map).cast<String, Object?>()}..remove('missed'),
      ];
      final plain = parse({...biases(), 'pairs': pairs});
      expect(plain.focusFor({0: 0, 1: 2, 2: 1, 3: 3}), 1);
      expect(plain.focusFor({0: 0, 1: 1, 2: 2, 3: 3}), 0);
    });

    test('refuses bad data', () {
      void bad(Map<String, Object?> raw) =>
          expect(() => parse(raw), throwsFormatException);
      final pairs = biases()['pairs'] as List;
      bad({...biases(), 'pairs': pairs.take(2).toList()});
      bad({
        ...biases(),
        'pairs': [...pairs, ...pairs.take(2)],
      });
      bad({...biases(), 'leftTitle': ''});
      bad({...biases()}..remove('rightTitle'));
      bad({
        ...biases(),
        'pairs': [
          ...pairs.take(3),
          {'left': 'Halo', 'right': 'r'},
        ],
      });
      bad({
        ...biases(),
        'pairs': [
          ...pairs.take(3),
          {'left': 'Halo', 'right': 'r', 'note': 'n', 'missed': true},
        ],
      });
      bad({
        ...biases(),
        'pairs': [
          ...pairs.take(3),
          {'left': 'Anchoring', 'right': 'r', 'note': 'n'},
        ],
      });
      bad({...biases(), 'order': [0, 1, 2]});
      bad({...biases(), 'order': [0, 1, 2, 2]});
      bad({...biases(), 'order': [0, 1, 2, 4]});
      bad({...biases(), 'order': 'shuffled'});
    });
  });

  group('play', () {
    Widget host(
      Map<String, Object?> raw, {
      required double height,
      Color ground = const Color(0xFFFFC49B),
      Color ink = const Color(0xFF10100C),
      bool still = false,
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
              // The card's own margins, so the scene is as wide as on a
              // phone: 276 px on a 360 px screen.
              padding: const EdgeInsets.symmetric(horizontal: 42),
              child: Center(
                child: SizedBox(
                  height: height,
                  child: SceneView(scene: parse(raw), ink: ink, ground: ground),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Future<void> phone(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    double y(WidgetTester tester, String text) =>
        tester.getCenter(find.text(text)).dy;

    /// The right item standing in the same row as left item [l].
    String besideOf(WidgetTester tester, String l) {
      final at = y(tester, l);
      return rights.reduce(
        (a, b) => (y(tester, a) - at).abs() < (y(tester, b) - at).abs() ? a : b,
      );
    }

    for (final (name, size, height) in [
      ('small phone', const Size(360, 740), 330.0),
      ('large phone', const Size(430, 932), 520.0),
      ('back of an asking card', const Size(360, 740), 270.0),
    ]) {
      testWidgets('on a $name: join by drag and by tap, lock in, untangle', (
        tester,
      ) async {
        await phone(tester, size);
        await tester.pumpWidget(host(biases(), height: height));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('BIAS'), findsOneWidget);
        expect(find.text('WHERE IT GETS YOU'), findsOneWidget);
        // Shuffled: nothing starts beside its partner.
        for (var i = 0; i < 4; i++) {
          expect(besideOf(tester, lefts[i]), isNot(rights[i]));
        }

        // A line dragged from Anchoring to the 'was $400' tag.
        final from = tester.getCenter(find.text('Anchoring'));
        final to = tester.getCenter(find.text(rights[0]));
        await tester.dragFrom(from, to - from);
        await tester.pumpAndSettle();
        // Dragged the other way, from the right: the film to sunk cost.
        await tester.dragFrom(
          tester.getCenter(find.text(rights[1])),
          tester.getCenter(find.text('Sunk cost')) -
              tester.getCenter(find.text(rights[1])),
        );
        await tester.pumpAndSettle();
        // Tapped: availability with the kitchen (wrong), then planning
        // fallacy with the flight (wrong too).
        await tester.tap(find.text('Availability'));
        await tester.tap(find.text(rights[3]));
        await tester.tap(find.text(rights[2]));
        await tester.tap(find.text('Planning fallacy'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('LOCK IT IN'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Every item beside its partner, the score, and the missed pair's
        // note opening the reveal.
        for (var i = 0; i < 4; i++) {
          expect(besideOf(tester, lefts[i]), rights[i]);
        }
        expect(find.text('2 OF 4'), findsOneWidget);
        expect(find.text('LOCK IT IN'), findsNothing);
        expect(find.text('The first number becomes the ruler.'), findsOne);

        // Any rung, tapped, gives its own note.
        await tester.tap(find.text('Availability'));
        await tester.pumpAndSettle();
        expect(find.text('Crashes make the news.'), findsOneWidget);
        await tester.tap(find.text(rights[3]));
        await tester.pumpAndSettle();
        expect(find.text('We plan the best case.'), findsOneWidget);
      });
    }

    testWidgets('lock waits for every pair; a new line takes over an end, '
        'and a linked item tapped lets its line go', (tester) async {
      await phone(tester, const Size(360, 740));
      await tester.pumpWidget(host(biases(), height: 400));
      await tester.pumpAndSettle();

      Future<void> join(String l, String r) async {
        await tester.tap(find.text(l));
        await tester.tap(find.text(r));
        await tester.pumpAndSettle();
      }

      await join('Anchoring', rights[1]);
      await join('Sunk cost', rights[0]);
      await join('Availability', rights[2]);
      // Three of four: the lock does nothing yet.
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pumpAndSettle();
      expect(find.text('LOCK IT IN'), findsOneWidget);

      // Planning fallacy takes the flight; availability lets go of it.
      await join('Planning fallacy', rights[2]);
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pumpAndSettle();
      expect(find.text('LOCK IT IN'), findsOneWidget);

      // Tapping a linked item takes its line off and picks it up.
      await tester.tap(find.text('Anchoring'));
      await tester.tap(find.text(rights[3]));
      await tester.pumpAndSettle();
      await join('Availability', rights[1]);
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pumpAndSettle();
      expect(find.text('LOCK IT IN'), findsNothing);
      expect(find.text('0 OF 4'), findsOneWidget);
    });

    testWidgets('a drag let go over nothing joins nothing', (tester) async {
      await phone(tester, const Size(360, 740));
      await tester.pumpWidget(host(biases(), height: 400));
      await tester.pumpAndSettle();
      // From Anchoring, only a little way into the gap, and back up.
      await tester.dragFrom(
        tester.getCenter(find.text('Anchoring')),
        const Offset(40, -10),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sunk cost'));
      await tester.tap(find.text(rights[1]));
      await tester.tap(find.text('Availability'));
      await tester.tap(find.text(rights[2]));
      await tester.tap(find.text('Planning fallacy'));
      await tester.tap(find.text(rights[3]));
      await tester.pumpAndSettle();
      // Anchoring is still free, so the lock still waits.
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pumpAndSettle();
      expect(find.text('LOCK IT IN'), findsOneWidget);
    });

    testWidgets('a light ink on a dark ground plays the same', (tester) async {
      await phone(tester, const Size(360, 740));
      await tester.pumpWidget(
        host(
          biases(),
          height: 400,
          ground: const Color(0xFF5A2EA6),
          ink: Colors.white,
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text(lefts[i]));
        await tester.tap(find.text(rights[i]));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('4 OF 4'), findsOneWidget);
    });

    testWidgets('with animations off, the truth is there on the next frame', (
      tester,
    ) async {
      await phone(tester, const Size(360, 740));
      await tester.pumpWidget(host(biases(), height: 400, still: true));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text(lefts[i]));
        await tester.tap(find.text(rights[(i + 1) % 4]));
        await tester.pump();
      }
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pump();
      expect(find.text('0 OF 4'), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        expect(besideOf(tester, lefts[i]), rights[i]);
      }
      expect(find.text('The first number becomes the ruler.'), findsOne);
    });

    testWidgets('five long pairs fit the back of an asking card', (
      tester,
    ) async {
      await phone(tester, const Size(360, 740));
      final five = {
        'type': 'match',
        'leftTitle': 'The trap',
        'rightTitle': 'The finding',
        'pairs': [
          for (final w in ['Survivors only', 'Small samples', 'Back to average',
              'A hidden cause', 'Base rates'])
            {
              'left': w,
              'right': 'Forty characters of right text for $w'.substring(0, 40),
              'note': 'A note of about seventy characters, which is two '
                  'lines under the ladder.',
            },
        ],
      };
      await tester.pumpWidget(host(five, height: 270));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (_shots) {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../../tool/shots/cards/match-five-270.png'),
        );
      }
      // Every tile keeps its words whole: nothing is cut to an ellipsis.
      for (final rp in tester.renderObjectList<RenderParagraph>(
        find.byType(RichText),
      )) {
        expect(rp.didExceedMaxLines, isFalse, reason: rp.text.toPlainText());
      }
    });

    testWidgets('a screen reader joins, locks and reads every rung', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await phone(tester, const Size(360, 740));
      await tester.pumpWidget(host(biases(), height: 400));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.bySemanticsLabel('Anchoring')),
        isSemantics(label: 'Anchoring', isButton: true, hasTapAction: true),
      );
      for (var i = 0; i < 4; i++) {
        tester.semantics.tap(find.semantics.byLabel(lefts[i]));
        await tester.pump();
        tester.semantics.tap(find.semantics.byLabel(rights[i == 2 ? 3 : i]));
        await tester.pumpAndSettle();
      }
      // Planning fallacy, last, took the kitchen from availability; it
      // is joined to the flight instead.
      tester.semantics.tap(find.semantics.byLabel('Availability'));
      await tester.pump();
      tester.semantics.tap(find.semantics.byLabel(rights[2]));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Anchoring')),
        isSemantics(value: rights[0]),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('LOCK IT IN')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('^Anchoring: '))),
        isSemantics(
          label: 'Anchoring: ${rights[0]}.',
          isSelected: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  group('in the deck', () {
    testWidgets('a line dragged sideways does not swipe the card away, and '
        'a tap on the board does not turn it over', (tester) async {
      tester.view.physicalSize = const Size(360, 740) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final pill = cardFromJson({
        'id': 'match-deck-test',
        'topic': 'psychology',
        'genre': 'psychology.bias',
        'strand': 'psychology.bias.anchoring_bias',
        'kind': 'read',
        'question': 'Which bias catches you in which moment?',
        'answer': 'Anchoring is the one people miss.',
        'move': 'Name the bias and step around it.',
        'source': 'Tversky and Kahneman 1974',
        'scene': biases(),
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
      expect(find.text('Anchoring'), findsOneWidget);

      // A long sideways fling from the left column to the right.
      final from = tester.getCenter(find.text('Anchoring'));
      await tester.flingFrom(from, const Offset(240, 20), 2000);
      await tester.pumpAndSettle();
      expect(advanced, 0);
      expect(find.text('Anchoring'), findsOneWidget);

      // A tap among the items does not turn the card over.
      await tester.tap(find.text('Sunk cost'));
      await tester.pumpAndSettle();
      expect(find.text('LOCK IT IN'), findsOneWidget);
    });
  });

  if (_shots) _photographs();
}

// ---- photographs ----

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

void _photographs() {
  group('photographs', () {
    final cards = [
      for (final c
          in jsonDecode(
                File('tool/cards/samples/match.json').readAsStringSync(),
              )
              as List)
        (c as Map).cast<String, Object?>(),
    ];

    Widget frame(Map<String, Object?> card, {bool flipped = false}) =>
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
                child: PillCard(pill: cardFromJson(card), flipped: flipped),
              ),
            ),
          ),
        );

    for (final card in cards) {
      for (final (phone, size) in [
        ('small', const Size(360, 740)),
        ('large', const Size(430, 932)),
      ]) {
        testWidgets('shoot ${card['id']} on $phone', (tester) async {
          tester.view.physicalSize = size * 3;
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          final id = card['id'];
          Future<void> shoot(String stage) => expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('../../tool/shots/cards/$id-$phone-$stage.png'),
          );
          await tester.pumpWidget(frame(card));
          await tester.pumpAndSettle();
          await shoot('start');

          final pairs = [
            for (final p in (card['scene'] as Map)['pairs'] as List)
              (p as Map).cast<String, Object?>(),
          ];
          String l(int i) => pairs[i]['left'] as String;
          String r(int i) => pairs[i]['right'] as String;
          // Two joined, one right and one wrong, and one picked up.
          await tester.tap(find.text(l(1)));
          await tester.tap(find.text(r(1)));
          await tester.tap(find.text(l(0)));
          await tester.tap(find.text(r(2)));
          await tester.pumpAndSettle();
          await tester.tap(find.text(l(3)));
          await tester.pumpAndSettle();
          await shoot('playing');

          // A line in mid-drag, held over the gap.
          final g = await tester.startGesture(
            tester.getCenter(find.text(l(3))),
          );
          await g.moveBy(const Offset(20, 0));
          await g.moveBy(const Offset(60, -40));
          await tester.pump();
          await shoot('drag');
          await g.moveTo(tester.getCenter(find.text(r(3))));
          await g.up();
          await tester.pumpAndSettle();
          await tester.tap(find.text(l(2)));
          await tester.tap(find.text(r(0)));
          await tester.pumpAndSettle();
          await shoot('full');

          await tester.tap(find.text('LOCK IT IN'));
          for (final ms in [500, 450]) {
            await tester.pump(Duration(milliseconds: ms));
            await shoot('reveal-$ms');
          }
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await shoot('end');
        });
      }
    }
  });
}
