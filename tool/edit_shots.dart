// Photographs the reader's own screens as somebody who has been reading a
// while sees them: the day once read and seen again, Explore's panel of the
// day, the topics and their fine-tuning, the saved and liked shelves, the
// archive.
//
//   flutter test tool/edit_shots.dart --update-goldens
//
// A camera, not a check, like the other shots: it lives outside test/ so CI
// never runs it. The pictures land in tool/shots/edit/, to be looked at and
// not kept. Cards with pictures are shown with the real ones, read from
// web/cards/thumbs/.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/explore/blocks/core/paths_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/archive_screen.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/screens/saved_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/web/card_thumb.dart';
import 'package:astuto/widgets/widget_ask.dart';

import '../test/explore/core_harness.dart';

const String _out = 'shots/edit';

/// A picture of the bank's own, from the folder the site serves them from,
/// read once and kept: the same provider for the same picture, so what was
/// decoded before the photograph is what the photograph shows.
final Map<String, ImageProvider> _pictures = {};
ImageProvider _picture(Uri url) {
  final String name = url.pathSegments.last.split('?').first;
  return _pictures.putIfAbsent(
    name,
    () => MemoryImage(File('web/cards/thumbs/$name').readAsBytesSync()),
  );
}

Future<void> _settle(WidgetTester tester, [int frames = 16]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

/// Every picture [pills] will show, decoded before the photograph.
Future<void> _precache(WidgetTester tester, Iterable<Pill> pills) async {
  await tester.runAsync(() async {
    final BuildContext context = tester.element(find.byType(MaterialApp));
    for (final Pill pill in pills) {
      for (final CardSide side in CardSide.values) {
        final String? ref = CardThumb.refOf(pill, side);
        if (ref == null) continue;
        await precacheImage(
          _picture(CardThumb.urlOf(ref)),
          context,
        ).timeout(const Duration(seconds: 20), onTimeout: () {});
      }
    }
  });
}

Future<void> _shoot(WidgetTester tester, String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('$_out/$name.png'));

Widget _app(Widget child, {Brightness brightness = Brightness.dark}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(brightness),
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: child),
    );

/// The cards of [topic] with a picture, the first [n] of them.
List<Pill> _pictured(String topic, int n) => [
  ...PillBank.cards
      .where((p) => p.topic == topic && CardThumb.has(p, CardSide.back))
      .take(n),
];

/// The cards of [topic] without one.
List<Pill> _plain(String topic, int n) => [
  ...PillBank.cards.where((p) => p.topic == topic && p.web == null).take(n),
];

/// What a reader a month in has kept, liked and thrown, and how they set
/// their mix on the first day.
Map<String, Object> _aMonthIn() {
  final List<Pill> saved = [
    ..._pictured('Space', 4),
    ..._pictured('History', 3),
    ..._plain('Psychology', 2),
    ..._pictured('Maths', 2),
    ..._pictured('Nature', 2),
    ..._pictured('Economics', 1),
  ];
  final List<Pill> liked = [
    ..._pictured('Space', 5),
    ..._pictured('History', 4),
    ..._pictured('Human body', 3),
    ..._pictured('Technology', 2),
  ];
  final List<Pill> thrown = [
    ..._plain('Economics', 3),
    ..._plain('Sport', 3),
    ..._plain('Pop culture', 2),
  ];
  // Five cards that ask something, answered: four right, one wrong, so the
  // day's picture has a score to show.
  final List<Pill> deck = [
    // Three with pictures, as most of a day's five are now, and two without.
    for (final topic in ['Space', 'History', 'Maths'])
      ...PillBank.cards
          .where((p) => p.topic == topic && CardThumb.has(p, CardSide.front))
          .skip(4)
          .take(1),
    for (final topic in ['Psychology', 'Science'])
      ...PillBank.cards
          .where(
            (p) =>
                p.topic == topic &&
                p.web == null &&
                p.isGraded &&
                p.challenge.accepts('0') != p.challenge.accepts('1'),
          )
          .take(1),
  ];
  String? responseFor(Pill pill, {required bool right}) {
    for (final String r in [
      for (int i = 0; i < 6; i++) '$i',
      for (int i = 0; i < 6; i++) '$i|x',
    ]) {
      if (pill.challenge.accepts(r) == right) return r;
    }
    return null;
  }

  final Map<String, Object> answers = {
    for (int i = 0; i < deck.length; i++)
      if (responseFor(deck[i], right: i != 2) case final String r)
        deck[i].id: {'r': r, 'c': 80},
  };
  final DateTime now = DateTime.now();
  return {
    'knowit.onboarded': true,
    'knowit.pushAsked': true,
    'knowit.plus': true,
    'knowit.streak': 13,
    'knowit.todayDate': dateKey(now),
    'knowit.todayDeckIds': [for (final p in deck) p.id],
    'knowit.todayIndex': 5,
    'knowit.answersJson': jsonEncode(answers),
    'knowit.lastCompletionDate': dateKey(now),
    'knowit.completedDates': [
      for (var back = 0; back < 9; back++)
        dateKey(now.subtract(Duration(days: back))),
    ],
    'knowit.savedIds': [for (final p in saved) p.id],
    'knowit.likedIds': [for (final p in liked) p.id],
    'knowit.dislikedIds': [for (final p in thrown) p.id],
    'knowit.seenIds': {
      for (final p in [...saved, ...liked, ...thrown, ...deck]) p.id,
      ...PillBank.cards.skip(300).take(40).map((p) => p.id),
    }.toList(),
    // The first day's mix: everything in but cinema, sport turned down.
    'knowit.topicWeights':
        '{${[for (final k in kTopicOrder)
          if (k != 'thinking' && k != 'cinema') '"$k": ${k == 'sport' ? 0.4 : 1.0}'].join(', ')}}',
    'knowit.topics': [
      for (final k in kTopicOrder)
        if (k != 'cinema') k,
    ],
  };
}

void main() {
  setUpAll(() async {
    await loadFonts();
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
    // The camera lives outside test/, so the analyzer does not count it
    // as one; these two are the test hooks it needs.
    // ignore: invalid_use_of_visible_for_testing_member
    Remote.baseline = const RemoteConfig(
      hash: 'the-build-own',
      schema: kRemoteSchema,
      parts: {},
    );
    // ignore: invalid_use_of_visible_for_testing_member
    Remote.reset();
    CardThumb.image = _picture;
  });

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(402, 874) * 3;
    view.devicePixelRatio = 3;
  });

  testWidgets('the day read, and seen again', (tester) async {
    final Map<String, Object> prefs = _aMonthIn();
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(prefs);
    await tester.pumpWidget(const AstutoApp());
    await _precache(tester, [
      for (final id in prefs['knowit.todayDeckIds']! as List<String>)
        if (PillBank.byId(id) != null) PillBank.byId(id)!,
    ]);
    await _settle(tester);
    await _shoot(tester, '1-today');

    await tester.tap(find.byKey(const ValueKey('shelf-share-day')));
    await _settle(tester);
    await _shoot(tester, '1b-share-day');
    await tester.tap(find.byKey(const ValueKey('share-day-story')));
    await _settle(tester);
    await _shoot(tester, '1c-share-story');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('shelf-see-again')));
    await _settle(tester);
    await _shoot(tester, '2-today-again');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('tab-Explore')).first);
    await _settle(tester, 30);
    await _shoot(tester, '3-explore');
  });

  testWidgets('the topics, and their fine-tuning', (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(_aMonthIn());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await _settle(tester);
    for (var attempt = 0; attempt < 10; attempt++) {
      if (find.byKey(const ValueKey('profile-topics')).evaluate().isNotEmpty &&
          tester.getTopLeft(find.byKey(const ValueKey('profile-topics'))).dy <
              500) {
        break;
      }
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await _settle(tester);
    }
    await _shoot(tester, '4-profile-topics');

    await tester.tap(find.byKey(const ValueKey('profile-topics')));
    await _settle(tester);
    await _shoot(tester, '5-topics-editor');

    await tester.tap(find.byKey(const ValueKey('topics-fine-tune')));
    await _settle(tester, 24);
    await _shoot(tester, '6-tune');
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -760));
    await _settle(tester);
    await _shoot(tester, '7-tune-parts');
  });

  testWidgets('the shelves and the archive', (tester) async {
    final AppState app = await readyApp(_aMonthIn());
    final List<Pill> all = [
      for (final id in {...app.savedIds, ...app.likedIds})
        if (PillBank.byId(id) != null) PillBank.byId(id)!,
    ];

    await tester.pumpWidget(_app(SavedScreen(app: app, onBackToToday: () {})));
    await _precache(tester, all);
    await _settle(tester);
    await _shoot(tester, '8-saved');

    await tester.tap(find.byKey(const ValueKey('saved-filter-space')));
    await _settle(tester);
    await _shoot(tester, '8b-saved-space');

    await tester.pumpWidget(
      _app(SavedScreen(app: app, onBackToToday: () {}, shelf: Shelf.liked)),
    );
    await _settle(tester);
    await _shoot(tester, '9-liked');

    await tester.tap(find.byKey(const ValueKey('saved-filter-history')));
    await _settle(tester);
    await _shoot(tester, '10-liked-history');

    // Paths, on the free plan (locked) as most readers meet them.
    final AppState free = await readyApp({
      ..._aMonthIn(),
      'knowit.plus': false,
    });
    await pumpSections(
      tester,
      CoreHost(free),
      sectionsOf([
        {
          'id': 'paths',
          'block': 'paths',
          'title': {'en': 'Ten-card paths'},
          'subtitle': {
            'en': 'One theme, from the easiest card to the hardest.',
          },
        },
      ]),
      size: const Size(402, 400),
    );
    await _settle(tester);
    await _shoot(tester, '3b-paths');

    await tester.pumpWidget(_app(ArchiveScreen(app: app, onBack: () {})));
    await _precache(tester, [
      for (final day in [0, 1, 2])
        ...app.deckOn(DateTime.now().subtract(Duration(days: day))),
    ]);
    await _settle(tester);
    await _shoot(tester, '11-archive');

    await tester.pumpWidget(
      _app(
        SavedScreen(app: app, onBackToToday: () {}),
        brightness: Brightness.light,
      ),
    );
    await _settle(tester);
    await _shoot(tester, '12-saved-paper');
  });

  testWidgets('paths begun free, and the widget offered', (tester) async {
    final AppState free = await readyApp({
      ..._aMonthIn(),
      'knowit.plus': false,
    });
    final CardPath path = pathsOf(PillBank.live, today: DateTime.now()).first;

    // The card after a path's two free ones, at the size a card is dealt.
    await tester.pumpWidget(
      _app(
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 60, 18, 70),
            child: PathMore(app: free, path: path),
          ),
        ),
      ),
    );
    await _settle(tester);
    await _shoot(tester, '14-path-more');

    // The plans, opened from a path.
    await tester.pumpWidget(_app(PaywallScreen(app: free, source: 'paths')));
    await _settle(tester, 30);
    await _shoot(tester, '15-paywall-paths');

    // The widget sheet, over the finished day, on both phones.
    final Pill lead =
        free.tomorrowsDeck.firstOrNull ??
        PillBank.live.firstWhere((p) => p.hasPage);
    for (final (String name, bool apple, bool canPin) in [
      ('16-widget-iphone', true, false),
      ('17-widget-android', false, true),
    ]) {
      await tester.pumpWidget(
        _app(
          ColoredBox(
            color: const Color(0x8C141416),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: WidgetAsk(card: lead, canPin: canPin, apple: apple),
            ),
          ),
        ),
      );
      await _settle(tester);
      await _shoot(tester, name);
    }
  });
}
