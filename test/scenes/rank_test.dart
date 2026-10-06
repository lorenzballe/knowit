import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/scene.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/scene_view.dart';

/// `rank`: the data is read strictly, and the reader can drag the rows into
/// an order, lock it in and reach the truth on any phone, in any height the
/// card gives the scene.
void main() {
  Map<String, Object?> animals() => {
    'type': 'rank',
    'quantity': 'People killed each year',
    'most': 'Most',
    'log': true,
    'items': [
      {'label': 'Sharks', 'value': 6, 'note': 'About six a year.'},
      {'label': 'Dogs', 'value': 59000},
      {'label': 'Mosquitoes', 'value': 597000},
      {'label': 'Snakes', 'value': 81000, 'note': 'At least 81,000.'},
    ],
  };

  RankScene parse(Map<String, Object?> raw) =>
      Scene.fromJson(raw, id: 'test') as RankScene;

  group('parse', () {
    test('reads every field, keeping the order the reader first sees', () {
      final s = parse(animals());
      expect(s.quantity, 'People killed each year');
      expect(s.most, 'Most');
      expect(s.unit, '');
      expect(s.log, isTrue);
      expect(s.items.map((i) => i.label), [
        'Sharks',
        'Dogs',
        'Mosquitoes',
        'Snakes',
      ]);
      expect(s.items.first.note, 'About six a year.');
      expect(s.items[1].note, '');
    });

    test('truth runs from the largest value down', () {
      expect(parse(animals()).truth, [2, 3, 1, 0]);
    });

    test('bars follow the values, the smallest still visible on a log '
        'scale', () {
      final s = parse(animals());
      final bars = [for (final i in s.truth) s.barOf(i)];
      expect(bars.first, closeTo(1, 1e-9));
      for (var k = 1; k < bars.length; k++) {
        expect(bars[k], lessThan(bars[k - 1]));
      }
      expect(bars.last, greaterThan(0.03));
      final plain = parse({...animals(), 'log': false});
      expect(plain.barOf(0), closeTo(6 / 597000, 1e-12));
    });

    test('the surprise is the item placed furthest from its place', () {
      final s = parse(animals());
      // Left as it starts, sharks sit on top: three places off.
      expect(s.surpriseFor([0, 1, 2, 3]), 0);
      // Dogs and snakes swapped: one place each, the higher one wins.
      expect(s.surpriseFor([2, 1, 3, 0]), 3);
      // A perfect order holds up the top item.
      expect(s.surpriseFor(s.truth), 2);
    });

    test('refuses bad data', () {
      void bad(Map<String, Object?> raw) =>
          expect(() => parse(raw), throwsFormatException);
      bad({
        ...animals(),
        'items': (animals()['items'] as List).take(2).toList(),
      });
      bad({
        ...animals(),
        'items': [
          ...(animals()['items'] as List),
          {'label': 'Hippos', 'value': 500},
          {'label': 'Lions', 'value': 200},
        ],
      });
      bad({...animals(), 'quantity': ''});
      bad({...animals()}..remove('most'));
      bad({
        ...animals(),
        'items': [
          {'label': 'A', 'value': 1},
          {'label': 'B', 'value': 1},
          {'label': 'C', 'value': 2},
        ],
      });
      bad({
        ...animals(),
        'items': [
          {'label': 'A', 'value': 0},
          {'label': 'B', 'value': 1},
          {'label': 'C', 'value': 2},
        ],
      });
      bad({
        ...animals(),
        'items': [
          {'label': 'A', 'value': '1'},
          {'label': 'B', 'value': 1},
          {'label': 'C', 'value': 2},
        ],
      });
      bad({
        ...animals(),
        'items': [
          {'value': 3},
          {'label': 'B', 'value': 1},
          {'label': 'C', 'value': 2},
        ],
      });
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
              padding: const EdgeInsets.symmetric(horizontal: 22),
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

    double y(WidgetTester tester, String label) =>
        tester.getCenter(find.text(label).first).dy;

    List<String> order(WidgetTester tester, List<String> labels) =>
        [...labels]..sort((a, b) => y(tester, a).compareTo(y(tester, b)));

    const labels = ['Sharks', 'Dogs', 'Mosquitoes', 'Snakes'];

    for (final (name, size, height) in [
      ('small phone', const Size(360, 740), 330.0),
      ('large phone', const Size(430, 932), 520.0),
      ('back of an asking card', const Size(360, 740), 270.0),
    ]) {
      testWidgets('on a $name: drag into order, lock in, see the truth', (
        tester,
      ) async {
        await phone(tester, size);
        await tester.pumpWidget(host(animals(), height: height));
        await tester.pumpAndSettle();
        expect(order(tester, labels), labels);
        expect(find.text('MOST'), findsOneWidget);

        // Mosquitoes, third, dragged to the top.
        final pitch = y(tester, 'Dogs') - y(tester, 'Sharks');
        await tester.drag(
          find.text('Mosquitoes'),
          Offset(0, -pitch * 2.2),
          touchSlopY: 0,
        );
        await tester.pumpAndSettle();
        expect(order(tester, labels), [
          'Mosquitoes',
          'Sharks',
          'Dogs',
          'Snakes',
        ]);

        // Sharks, now second, dragged to the bottom.
        await tester.drag(find.text('Sharks'), Offset(0, pitch * 2.4));
        await tester.pumpAndSettle();
        expect(order(tester, labels), [
          'Mosquitoes',
          'Dogs',
          'Snakes',
          'Sharks',
        ]);

        await tester.tap(find.text('LOCK IT IN'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // The true order, its values printed, the score in the corner.
        expect(order(tester, labels), [
          'Mosquitoes',
          'Snakes',
          'Dogs',
          'Sharks',
        ]);
        expect(find.text('597,000'), findsOneWidget);
        expect(find.text('81,000'), findsOneWidget);
        expect(find.text('6'), findsWidgets);
        expect(find.text('2 OF 4'), findsOneWidget);
        expect(find.text('LOCK IT IN'), findsNothing);
        // Dogs and Snakes were swapped; the tie goes to the higher one.
        expect(find.text('At least 81,000.'), findsOneWidget);
        // Snakes up one, dogs down one, beside the place numbers 1 to 4.
        expect(find.text('1'), findsNWidgets(3));
        expect(find.text('2'), findsOneWidget);
      });
    }

    testWidgets('a light ink on a dark ground plays the same', (tester) async {
      await phone(tester, const Size(360, 740));
      await tester.pumpWidget(
        host(
          animals(),
          height: 400,
          ground: const Color(0xFF5A2EA6),
          ink: Colors.white,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('597,000'), findsOneWidget);
      // Untouched: sharks on top were three places off, the surprise.
      // Mosquitoes and snakes up two, sharks down three, beside the place
      // numbers 1 to 4.
      expect(find.text('2'), findsNWidgets(3));
      expect(find.text('3'), findsNWidgets(2));
      expect(find.text('About six a year.'), findsOneWidget);
    });

    testWidgets('with animations off, the truth is there on the next frame', (
      tester,
    ) async {
      await phone(tester, const Size(360, 740));
      await tester.pumpWidget(host(animals(), height: 400, still: true));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pump();
      expect(find.text('597,000'), findsOneWidget);
      expect(find.text('0 OF 4'), findsOneWidget);
      expect(order(tester, labels), ['Mosquitoes', 'Snakes', 'Dogs', 'Sharks']);
    });

    testWidgets('units and money are printed the way they are read', (
      tester,
    ) async {
      await phone(tester, const Size(430, 932));
      await tester.pumpWidget(
        host({
          'type': 'rank',
          'quantity': 'Litres per kilogram',
          'most': 'Thirstiest',
          'unit': 'L',
          'items': [
            {'label': 'Rice', 'value': 2497},
            {'label': 'Beef', 'value': 15415},
            {'label': 'Tomatoes', 'value': 214, 'note': 'Mostly water.'},
          ],
        }, height: 360),
      );
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pumpAndSettle();
      expect(find.text('15,415 L'), findsOneWidget);
      expect(find.text('214 L'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        host({
          'type': 'rank',
          'quantity': 'Price',
          'most': 'Dearest',
          'unit': r'$',
          'items': [
            {'label': 'A', 'value': 0.5, 'note': 'n'},
            {'label': 'B', 'value': 12.5},
            {'label': 'C', 'value': 3000000},
          ],
        }, height: 360),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pumpAndSettle();
      expect(find.text(r'$3 million'), findsOneWidget);
      expect(find.text(r'$12.5'), findsOneWidget);
      expect(find.text(r'$0.50'), findsOneWidget);
    });

    testWidgets('a screen reader moves a row with increase and decrease', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await phone(tester, const Size(360, 740));
      await tester.pumpWidget(host(animals(), height: 400));
      await tester.pumpAndSettle();

      final mosquitoes = find.bySemanticsLabel('Mosquitoes');
      expect(
        tester.getSemantics(mosquitoes),
        isSemantics(
          label: 'Mosquitoes',
          value: '3 of 4',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
      tester.semantics.increase(find.semantics.byLabel('Mosquitoes'));
      await tester.pumpAndSettle();
      expect(order(tester, labels).indexOf('Mosquitoes'), 1);
      expect(tester.getSemantics(mosquitoes), isSemantics(value: '2 of 4'));

      expect(
        tester.getSemantics(find.bySemanticsLabel('LOCK IT IN')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(mosquitoes),
        isSemantics(label: 'Mosquitoes', value: '597,000, 1 of 4'),
      );
      handle.dispose();
    });
  });

  group('in the deck', () {
    testWidgets('dragging a row, even sideways, does not swipe the card '
        'away', (tester) async {
      tester.view.physicalSize = const Size(360, 740) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final pill = cardFromJson({
        'id': 'rank-deck-test',
        'topic': 'nature',
        'genre': 'nature.nature_myths',
        'strand': 'nature.nature_myths.cute_and_dangerous',
        'kind': 'read',
        'question': 'Which kills the most people each year?',
        'answer': 'Mosquitoes, by far.',
        'move': 'Fear follows the story.',
        'source': 'WHO',
        'scene': animals(),
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
      expect(find.text('Mosquitoes'), findsOneWidget);

      final before = tester.getCenter(find.text('Mosquitoes')).dy;
      await tester.drag(find.text('Mosquitoes'), const Offset(-260, -30));
      await tester.pumpAndSettle();
      expect(advanced, 0);
      expect(find.text('Mosquitoes'), findsOneWidget);
      expect(tester.getCenter(find.text('Mosquitoes')).dy, lessThan(before));

      // A tap among the rows does not turn the card over.
      await tester.tap(find.text('Dogs'));
      await tester.pumpAndSettle();
      expect(find.text('LOCK IT IN'), findsOneWidget);
    });
  });
}
