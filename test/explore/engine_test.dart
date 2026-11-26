// Explore as a list of sections: the build's own when the document says
// nothing, a document's read item by item, each aimed at its audience and
// drawn by its block, numbered as the reader meets it, built only as it
// comes near the screen — and a newer document taken up without the page
// moving under the reader.
//
//   flutter test test/explore/engine_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/explore/blocks/core/layout.dart' show kSectionGap;
import 'package:astuto/explore/blocks/core/own_explore.dart';
import 'package:astuto/explore/catalogue.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/measure/shelves.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/explore_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/explore/explore_engine.dart';

import 'core_harness.dart';

/// A section of a given height that counts how often it is asked to draw
/// and how often it is built.
class _Tall extends ExploreBlock {
  const _Tall();

  static int asked = 0;
  static final List<String> built = [];

  @override
  String get name => 'test-tall';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    asked++;
    if (section.json['empty'] == true) return null;
    final Object? height = section.json['height'];
    return _Counted(
      id: section.id,
      height: height is num ? height.toDouble() : 150,
    );
  }
}

class _Counted extends StatelessWidget {
  const _Counted({required this.id, required this.height});

  final String id;
  final double height;

  @override
  Widget build(BuildContext context) {
    _Tall.built.add(id);
    return SizedBox(key: ValueKey('tall-$id'), height: height, child: Text(id));
  }
}

/// A block that is one thing for every subject: drawn on Explore of every
/// subject only.
class _ForAll extends _Tall {
  const _ForAll();

  @override
  String get name => 'test-for-all';

  @override
  bool get onSubjectPages => false;
}

/// A block that fails.
class _Broken extends ExploreBlock {
  const _Broken();

  @override
  String get name => 'test-broken';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) => throw StateError('a block that fails');
}

Map<String, Object?> _tall(String id, {double? height, bool empty = false}) => {
  'id': id,
  'block': 'test-tall',
  'height': ?height,
  if (empty) 'empty': true,
};

int _documents = 0;

/// Takes up a remote document whose Explore is [explore].
void _adopt(Object? explore) => Remote.adopt(
  RemoteConfig(
    hash: 'test-${_documents++}',
    schema: kRemoteSchema,
    parts: {'explore': explore},
  ),
);

Future<void> _pumpScreen(WidgetTester tester, AppState app) async {
  tester.view.physicalSize = const Size(375, 667) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: Scaffold(body: ExploreScreen(app: app)),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

ScrollPosition _list(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(ExploreScreen),
            matching: find.byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            ),
          )
          .first,
    )
    .position;

void main() {
  setUpAll(() {
    kExploreBlocks['test-tall'] = const _Tall();
    kExploreBlocks['test-for-all'] = const _ForAll();
    kExploreBlocks['test-broken'] = const _Broken();
  });
  tearDownAll(() {
    kExploreBlocks.remove('test-tall');
    kExploreBlocks.remove('test-for-all');
    kExploreBlocks.remove('test-broken');
  });
  setUp(() {
    Served.useForTest(Served());
    _Tall.asked = 0;
    _Tall.built.clear();
  });
  tearDown(Remote.reset);

  group('which sections', () {
    test('no explore in the document is the build\'s own list', () {
      // Tests start from the build's own document (test/flutter_test_config
      // .dart), not from the one embedded, which says what the server said.
      expect(exploreSections(Remote.config), same(kOwnExplore));
      for (final Object? part in [
        null,
        'sections',
        <String, Object?>{},
        {'sections': 'all of them'},
      ]) {
        _adopt(part);
        expect(exploreSections(Remote.config), same(kOwnExplore));
      }
    });

    test('the Explore the build embeds reads whole, and every block of it '
        'is one this build draws', () {
      final Object? raw = jsonDecode(
        File('remote/explore.json').readAsStringSync(),
      );
      final List<ExploreSection> sections = exploreSections(Remote.embedded);
      if (raw is Map && raw['sections'] is List) {
        expect(sections, hasLength((raw['sections'] as List).length));
      } else {
        expect(sections, same(kOwnExplore));
      }
      for (final ExploreSection s in sections) {
        expect(kExploreBlocks, contains(s.block), reason: s.id);
      }
    });

    test('the build\'s own list is remote/examples/explore-today.json', () {
      final Map<String, Object?> doc = jsonDecode(
        File('remote/examples/explore-today.json').readAsStringSync(),
      ) as Map<String, Object?>;
      expect(doc['sections'], kOwnExploreJson);
    });

    test('a document\'s sections are read one by one: one that cannot be '
        'read, or that takes an id already taken, is left out', () {
      _adopt({
        'sections': [
          {'id': 'a', 'block': 'text'},
          'not a section',
          {'block': 'text'},
          {'id': 'b'},
          {'id': 'a', 'block': 'divider'},
          {'id': 'c', 'block': 'block-from-a-later-build'},
        ],
      });
      expect(
        [for (final s in exploreSections(Remote.config)) s.id],
        ['a', 'c'],
      );
      _adopt({'sections': <Object?>[]});
      expect(exploreSections(Remote.config), isEmpty);
    });
  });

  group('drawn on the screen', () {
    testWidgets('in order, each aimed at its readers, a block this build '
        'does not know passed over', (tester) async {
      final AppState app = await readyApp();
      _adopt({
        'sections': [
          _tall('first'),
          {'id': 'later', 'block': 'block-from-a-later-build'},
          {
            ..._tall('italian'),
            'audience': {
              'languages': ['it'],
            },
          },
          {
            ..._tall('newer-build'),
            'audience': {'minBuild': 9999},
          },
          {
            ..._tall('second'),
            'audience': {
              'languages': ['en'],
            },
          },
        ],
      });
      await _pumpScreen(tester, app);
      expect(find.byKey(const ValueKey('tall-first')), findsOneWidget);
      expect(find.byKey(const ValueKey('tall-second')), findsOneWidget);
      expect(find.byKey(const ValueKey('tall-italian')), findsNothing);
      expect(find.byKey(const ValueKey('tall-newer-build')), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('tall-first'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('tall-second'))).dy,
        ),
      );
    });

    testWidgets('a section with nothing to show leaves no room behind, and '
        'each one stands its gap under the one above', (tester) async {
      final AppState app = await readyApp();
      _adopt({
        'sections': [
          {..._tall('a', height: 100), 'gap': 0},
          _tall('nothing', empty: true),
          {..._tall('b', height: 100), 'gap': 40},
          _tall('c', height: 100),
        ],
      });
      await _pumpScreen(tester, app);
      double top(String id) =>
          tester.getTopLeft(find.byKey(ValueKey('tall-$id'))).dy;
      expect(top('b') - top('a'), 100 + 40);
      // A section that names no gap stands the default one.
      expect(top('c') - top('b'), 100 + kSectionGap);
    });

    testWidgets('a subject\'s page leaves out what is not about a subject: '
        'its block says so, or the section', (tester) async {
      final AppState app = await readyApp();
      final List<ExploreSection> sections = sectionsOf([
        _tall('shelf'),
        {'id': 'challenge', 'block': 'test-for-all'},
        {..._tall('kept-off'), 'subjectPages': false},
        {'id': 'brought', 'block': 'test-for-all', 'subjectPages': true},
      ]);
      await pumpSections(tester, CoreHost(app), sections);
      for (final String id in ['shelf', 'challenge', 'kept-off', 'brought']) {
        expect(find.byKey(ValueKey('tall-$id')), findsOneWidget, reason: id);
      }
      await pumpSections(tester, CoreHost(app, subject: 'Sport'), sections);
      expect(find.byKey(const ValueKey('tall-shelf')), findsOneWidget);
      expect(find.byKey(const ValueKey('tall-brought')), findsOneWidget);
      expect(find.byKey(const ValueKey('tall-challenge')), findsNothing);
      expect(find.byKey(const ValueKey('tall-kept-off')), findsNothing);
    });

    testWidgets('the bet of the day, the quick games and the reader\'s '
        'subjects are Explore\'s for every subject only; the day\'s '
        'challenge is on every page, five on All, a subject\'s own three on '
        'its page', (tester) async {
      for (final String block in [
        'bets-day',
        'quick-games',
        'subject-levels',
        'purpose.set',
      ]) {
        expect(kExploreBlocks[block]!.onSubjectPages, isFalse, reason: block);
      }
      for (final String block in [
        'three',
        'cover',
        'feed',
        'paths',
        'books',
        'top',
      ]) {
        expect(kExploreBlocks[block]!.onSubjectPages, isTrue, reason: block);
      }
    });

    testWidgets('the shelves are numbered as the reader meets them, and a '
        'line that is not a shelf is not watched', (tester) async {
      final AppState app = await readyApp();
      _adopt({
        'sections': [
          {'id': 'offline', 'block': 'offline'},
          {'id': 'intro', 'block': 'text', 'text': 'Hello'},
          {'id': 'rule', 'block': 'divider'},
          _tall('nothing', empty: true),
          _tall('shelf'),
          {'id': 'room', 'block': 'spacer'},
        ],
      });
      await _pumpScreen(tester, app);
      final Map<String, int> watched = {
        for (final ShelfWatch w in tester.widgetList<ShelfWatch>(
          find.byType(ShelfWatch, skipOffstage: false),
        ))
          w.shelf: w.position,
      };
      expect(watched, {'intro': 1, 'shelf': 2});
    });

    testWidgets('the build\'s own Explore is drawn when the document says '
        'nothing, every shelf numbered in its order', (tester) async {
      final AppState app = await readyApp();
      await _pumpScreen(tester, app);
      final ScrollPosition list = _list(tester);
      final Map<String, int> watched = {};
      for (int i = 0; i < 80; i++) {
        for (final ShelfWatch w in tester.widgetList<ShelfWatch>(
          find.byType(ShelfWatch, skipOffstage: false),
        )) {
          watched[w.shelf] = w.position;
        }
        if (list.pixels >= list.maxScrollExtent) break;
        list.jumpTo(list.pixels + 400);
        await tester.pump();
      }
      final List<String> order = [
        for (final s in kOwnExplore)
          if (watched.containsKey(s.id)) s.id,
      ];
      // Explore opens on today's three, the same for everyone, then its
      // cover, the day's cards in a mosaic: the reader's day is at the top
      // of Profile now, not here.
      expect(order.first, 'three');
      expect(order, isNot(contains('your-day')));
      expect(
        order,
        // The top list, with nothing counted yet in a test, is left out.
        containsAllInOrder([
          'three',
          'cover',
          'quick-games',
          'paths',
          'theme-practical-0',
        ]),
      );
      expect(
        [for (final id in order) watched[id]],
        [for (int i = 1; i <= order.length; i++) i],
      );
    });

    testWidgets('a newer document is drawn at once, and what is on screen '
        'stays where it was', (tester) async {
      final AppState app = await readyApp();
      _adopt({
        'sections': [for (int i = 0; i < 20; i++) _tall('s$i')],
      });
      await _pumpScreen(tester, app);
      final ScrollPosition list = _list(tester);
      list.jumpTo(10 * (150 + 24) + 30);
      await tester.pump();
      final double before = tester
          .getTopLeft(find.byKey(const ValueKey('tall-s11')))
          .dy;

      // A section put in above, one taken out above, one changed below.
      _adopt({
        'sections': [
          _tall('new', height: 300),
          for (int i = 0; i < 20; i++)
            if (i != 3) _tall('s$i', height: i == 15 ? 90 : null),
        ],
      });
      await tester.pump();
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('tall-s11'))).dy,
        moreOrLessEquals(before, epsilon: 0.5),
      );
      expect(find.byKey(const ValueKey('tall-s3')), findsNothing);

      // And from the top, the page is the new one.
      list.jumpTo(0);
      await tester.pump();
      expect(find.byKey(const ValueKey('tall-new')), findsOneWidget);
    });

    testWidgets('forty sections: each is asked what it shows on every build, '
        'and built only as it comes near the screen', (tester) async {
      final AppState app = await readyApp();
      _adopt({
        'sections': [for (int i = 0; i < 40; i++) _tall('s$i', height: 200)],
      });
      await _pumpScreen(tester, app);
      expect(_Tall.asked, greaterThanOrEqualTo(40));
      final Set<String> built = {..._Tall.built};
      // A screen and a little more: 667 points, the list's own margin
      // beyond it, sections of 224.
      expect(built.length, lessThanOrEqualTo(6));
      expect(built, contains('s0'));
      expect(built, isNot(contains('s39')));

      final ScrollPosition list = _list(tester);
      list.jumpTo(list.maxScrollExtent);
      await tester.pump();
      expect(_Tall.built, contains('s39'));
    });

    testWidgets('a block that fails is left out, the failure reported, and '
        'the page goes on', (tester) async {
      final AppState app = await readyApp();
      final List<FlutterErrorDetails> reported = [];
      final void Function(FlutterErrorDetails)? was = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = was);
      _adopt({
        'sections': [
          _tall('before'),
          {'id': 'broken', 'block': 'test-broken'},
          _tall('after'),
        ],
      });
      await _pumpScreen(tester, app);
      FlutterError.onError = was;
      expect(find.byKey(const ValueKey('tall-before')), findsOneWidget);
      expect(find.byKey(const ValueKey('tall-after')), findsOneWidget);
      expect(reported, isNotEmpty);
      expect(reported.first.exception, isA<StateError>());
      expect(reported.first.library, 'explore');
    });
  });
}
