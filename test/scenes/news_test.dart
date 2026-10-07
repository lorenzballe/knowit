// The `news` scene: a clipping, explained in three taps; and the dealer
// that never deals it past its expiry.
//
//   flutter test test/scenes/news_test.dart
//   flutter test test/scenes/news_test.dart --update-goldens --dart-define=SHOTS=true
//
// The second line also photographs each sample card on a small and a large
// phone, at the contents, at each step and mid-turn, into tool/shots/cards/.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
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
    File('tool/cards/samples/news.json').readAsStringSync(),
  ) as List)
    (c as Map).cast<String, Object?>(),
];

/// Three panels, at the longest the bank allows.
Map<String, Object?> _eggs() => {
  'type': 'news',
  'headline':
      'Egg prices hit a record as bird flu empties henhouses, says the '
      'US',
  'outlet': 'US Labor Department',
  'date': '2025-04-10',
  'panels': [
    {
      'label': 'What happened',
      'figure': r'$6.23',
      'text':
          'The average dozen of eggs in US cities in March, a record: '
          'about twice the price of a year before, and still climbing then.',
    },
    {
      'label': 'Why',
      'text':
          'When one hen tests positive for bird flu, the whole barn is '
          'culled. Tens of millions of laying hens went in a few months.',
    },
    {
      'label': 'What it means for you',
      'text':
          "Few people buy fewer eggs. When buyers can't cut back, a "
          'shortage of under a tenth is settled by doubling the price.',
    },
  ],
  'expires': '2026-12-31',
};

/// Two panels and the time it happened before.
Map<String, Object?> _rice() => {
  'type': 'news',
  'headline': 'Japan opens its emergency rice stockpile as prices soar',
  'outlet': "Japan's farm ministry",
  'date': '2025-02-07',
  'panels': [
    {
      'label': 'What happened',
      'figure': '210,000 t',
      'text': 'Rice the government keeps for disasters goes on sale.',
    },
    {
      'label': 'Why',
      'text':
          'For decades Japan paid farmers to plant less rice, to hold its '
          'price up. When the hot 2023 summer spoiled part of the crop, none '
          'was spare.',
    },
  ],
  'then': {
    'label': 'It happened before',
    'year': 1993,
    'headline': 'A cold summer, and Japan has to import rice',
    'line':
        'Supply kept just tight enough has no cushion: one bad harvest, '
        'and the shelves are empty.',
  },
  'expires': '2026-11-30',
};

NewsScene _parse(Map<String, Object?> raw) =>
    Scene.fromJson(raw, id: 'test') as NewsScene;

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
  for (var f = 0; f < 10; f++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Everything a finder matches sits inside the scene.
void _inside(WidgetTester tester, Finder f) {
  final scene = tester.getRect(find.byType(SceneView));
  for (final e in f.evaluate()) {
    final r = tester.getRect(find.byWidget(e.widget));
    expect(r.top, greaterThanOrEqualTo(scene.top - 0.5));
    expect(r.bottom, lessThanOrEqualTo(scene.bottom + 0.5));
  }
}

Map<String, Object?> _bankCard(String id, {Map<String, Object?>? scene}) => {
  'id': id,
  'topic': 'space',
  'genre': 'space.the_moon',
  'strand': 'space.the_moon.tides',
  'kind': 'read',
  'difficulty': 'easy',
  'principle': 'none',
  'question': 'What is $id about?',
  'answer': 'It is about $id, and that is all it is about.',
  'move': 'The move of $id.',
  'keywords': [id, 'tests'],
  'era': 'recent',
  'region': 'none',
  'hook': 'mechanism',
  'mood': 'sober',
  'numeracy': 0,
  'abstraction': 'concrete',
  'shelf_life': 'months',
  'mature': false,
  'language': 'en',
  'source': 'A source',
  'scene': ?scene,
};

void main() {
  group('parse', () {
    test('reads every field', () {
      final s = _parse(_eggs());
      expect(s.headline, startsWith('Egg prices'));
      expect(s.outlet, 'US Labor Department');
      expect(s.date, DateTime(2025, 4, 10));
      expect(s.panels, hasLength(3));
      expect(s.panels.first.figure, r'$6.23');
      expect(s.panels[1].hasFigure, isFalse);
      expect(s.then, isNull);
      expect(s.expires, DateTime(2026, 12, 31));
      expect(s.steps, 3);
      expect(s.labelOf(2), 'What it means for you');
    });

    test('reads the time it happened before', () {
      final s = _parse(_rice());
      expect(s.panels, hasLength(2));
      expect(s.then!.year, 1993);
      expect(s.then!.headline, startsWith('A cold summer'));
      expect(s.labelOf(2), 'It happened before');
    });

    test('is stale from the day after it expires', () {
      final s = _parse(_eggs());
      expect(s.expiredOn(DateTime(2026, 12, 30)), isFalse);
      expect(s.expiredOn(DateTime(2026, 12, 31, 23, 59)), isFalse);
      expect(s.expiredOn(DateTime(2027, 1, 1)), isTrue);
    });

    test('every sample card parses', () {
      for (final c in _samples()) {
        expect(
          Scene.fromJson(c['scene'], id: c['id']),
          isA<NewsScene>(),
          reason: '${c['id']}',
        );
      }
    });

    test('refuses bad data', () {
      void bad(Map<String, Object?> raw) =>
          expect(() => _parse(raw), throwsFormatException);
      final panels = _eggs()['panels'] as List;
      bad({..._eggs()}..remove('expires'));
      bad({..._eggs(), 'expires': '2026-02-30'});
      bad({..._eggs(), 'expires': '31/12/2026'});
      bad({..._eggs()}..remove('date'));
      bad({..._eggs(), 'headline': ' '});
      bad({..._eggs()}..remove('outlet'));
      bad({..._eggs(), 'panels': panels.take(1).toList()});
      // Three taps: two panels need a past case, three cannot have one.
      bad({..._eggs(), 'panels': panels.take(2).toList()});
      bad({..._eggs(), 'then': _rice()['then']});
      bad({
        ..._eggs(),
        'panels': [
          ...panels.take(2),
          {'label': 'Then'},
        ],
      });
      bad({
        ..._eggs(),
        'panels': [
          ...panels.take(2),
          {'label': 'Then', 'text': 'Text', 'figure': 3},
        ],
      });
      bad({
        ..._rice(),
        'then': {
          'label': 'Before',
          'year': '1993',
          'headline': 'H',
          'line': 'L',
        },
      });
    });
  });

  group('the deal', () {
    final today = DateTime(2026, 10, 7);
    Map<String, Object?> news(String expires) => {
      ..._eggs(),
      'expires': expires,
    };

    setUp(() {
      PillBank.adopt(
        BankBundle.parse(
          jsonEncode({
            'format': 1,
            'version': 1,
            'built': '2026-10-01T03:00:00Z',
            'cards': [
              _bankCard('space-stale-1', scene: news('2026-10-06')),
              _bankCard('space-stale-2', scene: news('2026-10-06')),
              _bankCard('space-today', scene: news('2026-10-07')),
              _bankCard('space-fresh', scene: news('2026-12-01')),
              for (var i = 0; i < 8; i++) _bankCard('space-old-$i'),
            ],
            'editions': <String, String>{},
          }),
        ),
      );
      resetCalendar();
    });

    tearDown(() {
      PillBank.reset();
      resetCalendar();
    });

    test('a card is dealable up to its expiry day and not after', () {
      Pill pill(String id) => pillById(id)!;
      expect(dealableOn(pill('space-today'), today), isTrue);
      expect(dealableOn(pill('space-stale-1'), today), isFalse);
      expect(dealableOn(pill('space-old-0'), today), isTrue);
      expect(
        dealableOn(pill('space-today'), today.add(const Duration(days: 1))),
        isFalse,
      );
    });

    test('no day deals a card past its expiry, by any road', () {
      for (var d = 0; d < 30; d++) {
        final date = today.add(Duration(days: d));
        final ids = <String>{
          ...dealDay(
            date: date,
            topics: {'space'},
            own: kPillsPerDay,
          ).cards.map((p) => p.id),
          ...dealDay(date: date, topics: {'space'}).cards.map((p) => p.id),
          ...pillsForDate(date, count: 12).map((p) => p.id),
          ...pillsAtRandom(date, count: 12).map((p) => p.id),
        };
        expect(ids, isNot(contains('space-stale-1')), reason: 'day $d');
        expect(ids, isNot(contains('space-stale-2')), reason: 'day $d');
        if (d > 0) expect(ids, isNot(contains('space-today')));
        if (d > 55) expect(ids, isNot(contains('space-fresh')));
      }
      // On its last day the card is still in the pool.
      expect(
        pillsForDate(today, count: 12).map((p) => p.id),
        contains('space-today'),
      );
    });

    test('a stale card due for review is not brought back', () {
      final deal = dealDay(
        date: today,
        topics: {'space'},
        reviews: [pillById('space-stale-1')!],
        own: kPillsPerDay,
      );
      expect(deal.cards.map((p) => p.id), isNot(contains('space-stale-1')));
      expect(deal.cards, hasLength(kPillsPerDay));
    });
  });

  group('play', () {
    setUpAll(_loadFonts);

    for (final (name, size, height) in [
      ('small phone', const Size(360, 740), 330.0),
      ('large phone', const Size(430, 932), 520.0),
      ('back of an asking card', const Size(360, 740), 270.0),
    ]) {
      testWidgets('on a $name: three taps open what happened, why and what '
          'it means', (tester) async {
        _phone(tester, size);
        await tester.pumpWidget(_host(_eggs(), height: height));
        await _play(tester);
        expect(tester.takeException(), isNull);
        // The clipping and its contents; nothing opened yet.
        expect(find.textContaining('Egg prices hit'), findsOneWidget);
        expect(find.text('US LABOR DEPARTMENT'), findsOneWidget);
        expect(find.text('APR 10, 2025'), findsOneWidget);
        for (final l in ['What happened', 'Why', 'What it means for you']) {
          expect(find.text(l), findsOneWidget);
        }
        _inside(tester, find.text('What it means for you'));
        expect(find.text(r'$6.23'), findsNothing);

        await tester.tap(find.text('What happened'));
        await _play(tester);
        expect(find.text(r'$6.23'), findsOneWidget);
        expect(find.text('WHAT HAPPENED'), findsOneWidget);
        // The button names what comes next.
        expect(find.text('Why'), findsOneWidget);
        _inside(tester, find.textContaining('average dozen'));

        await tester.tap(find.text('Why'));
        await _play(tester);
        expect(find.textContaining('whole barn is culled'), findsOneWidget);
        expect(find.text(r'$6.23'), findsNothing);
        expect(find.text('What it means for you'), findsOneWidget);

        await tester.tap(find.text('What it means for you'));
        await _play(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('WHAT IT MEANS FOR YOU'), findsOneWidget);
        _inside(tester, find.textContaining("buyers can't cut back"));
        _inside(tester, find.textContaining('Egg prices hit'));
        // Nothing is left to open: no button.
        expect(find.text('Why'), findsNothing);
      });

      testWidgets('on a $name: the last step is the time it happened before', (
        tester,
      ) async {
        _phone(tester, size);
        await tester.pumpWidget(
          _host(
            _rice(),
            height: height,
            ground: const Color(0xFF233A8B),
            ink: Colors.white,
          ),
        );
        await _play(tester);
        expect(find.text('It happened before'), findsOneWidget);
        // A tap anywhere in the scene opens the next step.
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.textContaining('emergency rice'));
          await _play(tester);
        }
        expect(tester.takeException(), isNull);
        expect(find.text('1993'), findsOneWidget);
        expect(find.text('IT HAPPENED BEFORE'), findsOneWidget);
        _inside(tester, find.textContaining('the shelves are empty'));
        _inside(tester, find.text('1993'));
      });
    }

    testWidgets('the bars go back to a step read, and forward again', (
      tester,
    ) async {
      _phone(tester, const Size(360, 740));
      await tester.pumpWidget(_host(_eggs(), height: 400));
      await _play(tester);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(SceneView));
        await _play(tester);
      }
      expect(find.text('WHAT IT MEANS FOR YOU'), findsOneWidget);
      // The first bar, a third of the way along the strip.
      final scene = tester.getRect(find.byType(SceneView));
      final bar = tester.getCenter(find.text('WHAT IT MEANS FOR YOU'));
      await tester.tapAt(Offset(scene.left + scene.width / 6, bar.dy - 34));
      await _play(tester);
      expect(find.text(r'$6.23'), findsOneWidget);
      // The button leads on again, through the steps already read.
      await tester.tap(find.text('Why'));
      await _play(tester);
      expect(find.textContaining('whole barn is culled'), findsOneWidget);
    });

    testWidgets('a swipe to the left turns the page, to the right turns back', (
      tester,
    ) async {
      _phone(tester, const Size(360, 740));
      await tester.pumpWidget(_host(_eggs(), height: 400));
      await _play(tester);
      final head = find.textContaining('Egg prices hit');
      // A short drag springs back.
      await tester.drag(head, const Offset(-20, 0));
      await _play(tester);
      expect(find.text(r'$6.23'), findsNothing);
      await tester.drag(head, const Offset(-120, 0));
      await _play(tester);
      expect(find.text(r'$6.23'), findsOneWidget);
      await tester.drag(head, const Offset(-120, 0));
      await _play(tester);
      expect(find.textContaining('whole barn is culled'), findsOneWidget);
      await tester.drag(head, const Offset(120, 0));
      await _play(tester);
      expect(find.text(r'$6.23'), findsOneWidget);
    });

    testWidgets('a fast reader never skips a step', (tester) async {
      _phone(tester, const Size(360, 740));
      await tester.pumpWidget(_host(_eggs(), height: 400));
      await _play(tester);
      await tester.tap(find.byType(SceneView));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(find.byType(SceneView));
      await _play(tester);
      expect(find.text('WHY'), findsOneWidget);
      expect(find.textContaining('whole barn is culled'), findsOneWidget);
    });

    testWidgets('with animations off, each step is there on the next frame', (
      tester,
    ) async {
      _phone(tester, const Size(360, 740));
      await tester.pumpWidget(_host(_rice(), height: 400, still: true));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(SceneView));
        await tester.pump();
      }
      expect(find.text('1993'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a screen reader hears the clipping and opens every step', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      _phone(tester, const Size(360, 740));
      await tester.pumpWidget(_host(_eggs(), height: 400));
      await _play(tester);
      expect(
        find.bySemanticsLabel(RegExp(r'^US Labor Department, .*Egg prices')),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('What happened')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      tester.semantics.tap(find.semantics.byLabel('What happened'));
      await _play(tester);
      tester.semantics.tap(find.semantics.byLabel('Why').last);
      await _play(tester);
      tester.semantics.tap(
        find.semantics.byLabel('What it means for you').last,
      );
      await _play(tester);
      expect(find.text('WHAT IT MEANS FOR YOU'), findsOneWidget);
      handle.dispose();
    });
  });

  group('in the deck', () {
    testWidgets('a drag on the scene turns its pages and does not swipe the '
        'card away; once all three are open the card turns over again', (
      tester,
    ) async {
      _phone(tester, const Size(360, 740));
      final pill = cardFromJson({..._samples().first, 'scene': _eggs()});
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
      final head = find.textContaining('Egg prices hit');
      expect(head, findsOneWidget);

      // Sideways across the clipping: a page turns, the deck stays put.
      await tester.drag(head, const Offset(-260, 0));
      await tester.pumpAndSettle();
      expect(advanced, 0);
      expect(find.text(r'$6.23'), findsOneWidget);

      // A tap in the scene opens the next step rather than turning the card.
      await tester.tap(head);
      await tester.pumpAndSettle();
      expect(find.textContaining('whole barn is culled'), findsOneWidget);
      await tester.tap(find.text('What it means for you'));
      await tester.pumpAndSettle();
      expect(find.text('WHAT IT MEANS FOR YOU'), findsOneWidget);

      // All three open: the scene lets go, and a tap turns the card over.
      await tester.tap(head);
      await tester.pumpAndSettle();
      expect(find.textContaining('Because almost nobody'), findsWidgets);
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
            await tester.pumpWidget(_card(pill));
            await _play(tester);
            Future<void> shoot(String stage) => expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                '../../tool/shots/cards/news-${pill.id}-${phone.key}-$stage.png',
              ),
            );
            await shoot('0-contents');
            for (var i = 1; i <= 3; i++) {
              await tester.tap(find.byType(SceneView));
              if (i == 2) {
                await tester.pump();
                await tester.pump(const Duration(milliseconds: 230));
                await shoot('2-turning');
              }
              await _play(tester);
              await shoot('$i-step');
            }
          });
        }
      }
    });
  }
}
