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

/// Photo tests write PNGs under tool/shots/cards/ only when asked:
/// `flutter test test/scenes/poll_test.dart --dart-define=SHOTS=true --update-goldens`.
const _shots = bool.fromEnvironment('SHOTS');

/// `poll`: the data is read strictly, and the reader can answer for
/// themself, with one question or two, and reach the crowd's answers on any
/// phone, in any height the card gives the scene.
void main() {
  // Real type for the photographs; a plain run keeps the test font.
  setUpAll(() async {
    if (!_shots) return;
    for (final (family, path) in [
      ('Fraunces', 'assets/fonts/Fraunces.ttf'),
      ('Figtree', 'assets/fonts/Figtree.ttf'),
    ]) {
      final bytes = await File(path).readAsBytes();
      await (FontLoader(
        family,
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
  });

  Map<String, Object?> driver() => {
    'type': 'poll',
    'who': '81 US students, Svenson 1981',
    'questions': [
      {
        'options': [
          {
            'label': 'Better than half',
            'share': 93,
            'mirror': 'So did 93% of the students asked.',
          },
          {
            'label': 'Not better than half',
            'share': 7,
            'mirror': 'Only 7% said this.',
          },
        ],
      },
    ],
    'why': 'We judge ourselves by our intentions.',
  };

  Map<String, Object?> four() => {
    'type': 'poll',
    'who': '2,000 adults, a made-up survey for tests',
    'questions': [
      {
        'prompt': 'How do you decide when you are tired?',
        'options': [
          {
            'label': 'Sleep on it',
            'share': 41,
            'mirror':
                'Like 41% of people. Sleeping on it tends to cut the regret '
                'that hasty choices bring the next day.',
          },
          {
            'label': 'Go with my gut',
            'share': 33,
            'mirror': 'Like a third of people.',
          },
          {'label': 'Ask someone', 'share': 18, 'mirror': 'Like 18%.'},
          {'label': 'Flip a coin', 'share': 8, 'mirror': 'Like 8%.'},
        ],
      },
    ],
    'why':
        'Tired minds lean on whatever is quickest, so people split by which '
        'shortcut they trust most when they cannot think it through.',
  };

  Map<String, Object?> disease() => {
    'type': 'poll',
    'who': 'Students, Tversky & Kahneman 1981',
    'questions': [
      {
        'prompt': 'Programme A or programme B?',
        'tag': 'Told as lives saved',
        'options': [
          {'label': '200 saved for sure', 'share': 72},
          {'label': '1/3 chance all 600 saved', 'share': 28},
        ],
      },
      {
        'prompt': 'Now the same 600, with programme C or D:',
        'tag': 'Told as deaths',
        'options': [
          {'label': '400 die for sure', 'share': 22},
          {'label': '1/3 chance nobody dies', 'share': 78},
        ],
      },
    ],
    'why':
        'A sure gain feels safe; a sure loss feels unbearable, so we gamble '
        'to dodge it.',
    'same':
        "You held steady. The crowd didn't: the sure plan fell from 72% to 22%.",
    'switched':
        'You switched, like most people. A and C are the same plan; so are '
        'B and D.',
  };

  PollScene parse(Map<String, Object?> raw) =>
      Scene.fromJson(raw, id: 'test') as PollScene;

  group('parse', () {
    test('reads one question, with a mirror on every option', () {
      final s = parse(driver());
      expect(s.who, '81 US students, Svenson 1981');
      expect(s.twice, isFalse);
      expect(s.questions.single.prompt, '');
      expect(s.questions.single.options.map((o) => o.label), [
        'Better than half',
        'Not better than half',
      ]);
      expect(s.questions.single.options.first.share, 93);
      expect(s.lineFor([1]), 'Only 7% said this.');
    });

    test('reads two questions, and tells steady from switched', () {
      final s = parse(disease());
      expect(s.twice, isTrue);
      expect(s.questions.map((q) => q.tag), [
        'Told as lives saved',
        'Told as deaths',
      ]);
      expect(s.lineFor([0, 0]), startsWith('You held steady'));
      expect(s.lineFor([1, 1]), startsWith('You held steady'));
      expect(s.lineFor([0, 1]), startsWith('You switched'));
    });

    test('refuses bad data', () {
      void bad(Map<String, Object?> raw) =>
          expect(() => parse(raw), throwsFormatException);
      Map<String, Object?> one(List<Object?> options) => {
        ...driver(),
        'questions': [
          {'options': options},
        ],
      };
      const ok = {'label': 'A', 'share': 50, 'mirror': 'm'};
      bad({...driver(), 'questions': []});
      bad({
        ...driver(),
        'questions': [...driver()['questions'] as List, ...disease()['questions'] as List],
      });
      bad(one([ok]));
      bad(one([ok, ok, ok, ok, ok]));
      bad(one([ok, {'label': 'B', 'share': 30, 'mirror': 'm'}])); // 80%
      bad(one([ok, {'label': 'B', 'share': 50}])); // no mirror
      bad(one([ok, {'label': '', 'share': 50, 'mirror': 'm'}]));
      bad(one([ok, {'label': 'B', 'share': '50', 'mirror': 'm'}]));
      bad(one([
        {'label': 'A', 'share': 150, 'mirror': 'm'},
        {'label': 'B', 'share': -50, 'mirror': 'm'},
      ]));
      bad({...driver()}..remove('who'));
      bad({...driver()}..remove('why'));
      bad({...disease()}..remove('switched'));
      final q = disease()['questions'] as List;
      bad({
        ...disease(),
        'questions': [
          {...q[0] as Map}..remove('tag'),
          q[1],
        ],
      });
      bad({
        ...disease(),
        'questions': [
          {...q[0] as Map}..remove('prompt'),
          q[1],
        ],
      });
      bad({
        ...disease(),
        'questions': [
          {
            ...q[0] as Map,
            'options': [
              {'label': 'a', 'share': 40},
              {'label': 'b', 'share': 30},
              {'label': 'c', 'share': 30},
            ],
          },
          q[1],
        ],
      });
      // Rounding in the paper is forgiven.
      expect(
        () => parse(one([
          {'label': 'A', 'share': 33, 'mirror': 'm'},
          {'label': 'B', 'share': 33, 'mirror': 'm'},
          {'label': 'C', 'share': 33, 'mirror': 'm'},
        ])),
        returnsNormally,
      );
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
                  child: RepaintBoundary(
                    child: ColoredBox(
                      color: ground,
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

    Future<void> phone(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    Future<void> shot(WidgetTester tester, String name) async {
      if (!_shots) return;
      await expectLater(
        find.byType(RepaintBoundary).last,
        matchesGoldenFile('../../tool/shots/cards/poll-$name.png'),
      );
    }

    final heights = [
      ('small phone', const Size(360, 740), 330.0),
      ('large phone', const Size(430, 932), 520.0),
      ('back of an asking card', const Size(360, 740), 270.0),
    ];

    for (final (name, size, height) in heights) {
      testWidgets('on a $name: pick one of four, see where you sit', (
        tester,
      ) async {
        await phone(tester, size);
        await tester.pumpWidget(host(four(), height: height));
        await tester.pumpAndSettle();
        expect(find.text('TAP YOUR PICK'), findsOneWidget);
        expect(find.text('41%'), findsNothing);
        await shot(tester, 'four-${height.round()}-before');

        await tester.tap(find.text('Go with my gut'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 380));
        await shot(tester, 'four-${height.round()}-mid');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        expect(find.text('41%'), findsOneWidget);
        expect(find.text('33%'), findsOneWidget);
        expect(find.text('18%'), findsOneWidget);
        expect(find.text('8%'), findsOneWidget);
        expect(find.text('YOU'), findsOneWidget);
        expect(find.text('Like a third of people.'), findsOneWidget);
        expect(find.text('TAP YOUR PICK'), findsNothing);
        // The YOU tag sits on the reader's row.
        expect(
          (tester.getCenter(find.text('YOU')).dy -
                  tester.getCenter(find.text('Go with my gut')).dy)
              .abs(),
          lessThan(4),
        );
        await shot(tester, 'four-${height.round()}-after');
      });

      testWidgets('on a $name: two wordings, a switch, both crowds', (
        tester,
      ) async {
        await phone(tester, size);
        await tester.pumpWidget(host(disease(), height: height));
        await tester.pumpAndSettle();
        expect(find.text('1 OF 2'), findsOneWidget);
        expect(find.text('Programme A or programme B?'), findsOneWidget);
        await shot(tester, 'twice-${height.round()}-first');

        await tester.tap(find.text('200 saved for sure'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 640));
        await shot(tester, 'twice-${height.round()}-turn');
        await tester.pumpAndSettle();
        expect(find.text('2 OF 2'), findsOneWidget);
        expect(find.text('200 saved for sure'), findsNothing);
        // The first crowd is not shown before the second answer.
        expect(find.text('72%'), findsNothing);
        await shot(tester, 'twice-${height.round()}-second');

        await tester.tap(find.text('1/3 chance nobody dies'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final p in ['72%', '28%', '22%', '78%']) {
          expect(find.text(p), findsOneWidget);
        }
        expect(find.text('Told as lives saved'), findsOneWidget);
        expect(find.text('Told as deaths'), findsOneWidget);
        expect(find.text('YOU'), findsNWidgets(2));
        expect(find.textContaining('You switched'), findsOneWidget);
        await shot(tester, 'twice-${height.round()}-after');
      });
    }

    testWidgets('holding steady gets its own line', (tester) async {
      await phone(tester, const Size(390, 844));
      await tester.pumpWidget(host(disease(), height: 420));
      await tester.tap(find.text('1/3 chance all 600 saved'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1/3 chance nobody dies'));
      await tester.pumpAndSettle();
      expect(find.textContaining('You held steady'), findsOneWidget);
    });

    testWidgets('a light ink on a dark ground plays the same', (tester) async {
      await phone(tester, const Size(360, 740));
      await tester.pumpWidget(
        host(
          driver(),
          height: 400,
          ground: const Color(0xFF5A2EA6),
          ink: Colors.white,
        ),
      );
      await tester.pumpAndSettle();
      await shot(tester, 'dark-before');
      await tester.tap(find.text('Not better than half'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('93%'), findsOneWidget);
      expect(find.text('7%'), findsOneWidget);
      expect(find.text('Only 7% said this.'), findsOneWidget);
      expect(find.text('We judge ourselves by our intentions.'), findsOneWidget);
      await shot(tester, 'dark-after');
    });

    testWidgets('with animations off, the crowd is there on the next frame', (
      tester,
    ) async {
      await phone(tester, const Size(360, 740));
      await tester.pumpWidget(host(disease(), height: 400, still: true));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      await tester.tap(find.text('200 saved for sure'));
      await tester.pump();
      expect(find.text('2 OF 2'), findsOneWidget);
      await tester.tap(find.text('400 die for sure'));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('72%'), findsOneWidget);
      expect(find.text('22%'), findsOneWidget);
      expect(find.textContaining('You held steady'), findsOneWidget);
    });

    testWidgets('one tap commits: the pick cannot be changed', (tester) async {
      await phone(tester, const Size(360, 740));
      await tester.pumpWidget(host(driver(), height: 400));
      await tester.tap(find.text('Better than half'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not better than half'));
      await tester.pumpAndSettle();
      expect(find.text('So did 93% of the students asked.'), findsOneWidget);
      expect(find.text('Only 7% said this.'), findsNothing);
    });

    testWidgets('a screen reader picks with a tap and hears the shares', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await phone(tester, const Size(360, 740));
      await tester.pumpWidget(host(driver(), height: 400));
      await tester.pumpAndSettle();
      final better = find.bySemanticsLabel('Better than half');
      expect(
        tester.getSemantics(better),
        isSemantics(
          label: 'Better than half',
          isButton: true,
          hasTapAction: true,
        ),
      );
      tester.semantics.tap(find.semantics.byLabel('Better than half'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(better),
        isSemantics(label: 'Better than half', value: '93%, YOU'),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Not better than half')),
        isSemantics(label: 'Not better than half', value: '7%'),
      );
      handle.dispose();
    });
  });

  group('in the deck', () {
    Future<int> deck(
      WidgetTester tester,
      Future<void> Function() play,
    ) async {
      tester.view.physicalSize = const Size(360, 740) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pill = cardFromJson({
        'id': 'poll-deck-test',
        'topic': 'psychology',
        'genre': 'psychology.know_your_own_mind',
        'strand': 'psychology.know_your_own_mind.overconfidence',
        'kind': 'read',
        'question': 'Are you a more skilful driver than half of a room?',
        'answer': 'Only half can be.',
        'move': 'Ask how the others would rank you.',
        'source': 'Svenson 1981',
        'scene': driver(),
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
      await play();
      return advanced;
    }

    testWidgets('a tap on an option answers instead of turning the card', (
      tester,
    ) async {
      final advanced = await deck(tester, () async {
        // A tap on the scene beside the slabs is not a flip either.
        await tester.tap(find.text('TAP YOUR PICK'));
        await tester.pumpAndSettle();
        expect(find.text('TAP YOUR PICK'), findsOneWidget);

        await tester.tap(find.text('Better than half'));
        await tester.pumpAndSettle();
        expect(find.text('93%'), findsOneWidget);
        expect(find.text('So did 93% of the students asked.'), findsOneWidget);
      });
      expect(advanced, 0);
    });

    testWidgets('the scene claims only taps: a swipe still moves the deck', (
      tester,
    ) async {
      final advanced = await deck(tester, () async {
        await tester.timedDrag(
          find.text('Better than half'),
          const Offset(-300, 0),
          const Duration(milliseconds: 200),
        );
        await tester.pumpAndSettle();
      });
      expect(advanced, 1);
    });
  });
}
