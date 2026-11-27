// Photographs the top edge of the six long pages with a way back that
// scrolls away and comes back (lib/widgets/quick_return.dart): Your journey,
// Tune your mix, a subject's home, an area, a path and a news story, on a
// 390 by 844 iPhone with its status bar, at night.
//
// Each page at the top; scrolled down, the way back gone; and scrolled back
// up a little, the way back on its way and then back, as the owner's own
// screenshots show it: Your journey with the week's headline and with How
// you reason under it, Tune your mix with a row of parts. On paper too: the
// tops, to be compared pixel for pixel with an earlier build, and the way
// back come back.
//
//   flutter test tool/edge_shots.dart --update-goldens \
//     --dart-define=EDGE_DIR=/some/folder
//
// A camera, not a check: it lives outside test/ so CI never runs it. The
// pictures land in tool/shots/edge/ unless EDGE_DIR says otherwise, to be
// looked at and not kept.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/genres.dart';
import 'package:astuto/data/goals.dart';
import 'package:astuto/data/news_paper.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/explore/blocks/core/paths_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/area_screen.dart';
import 'package:astuto/screens/card_path_screen.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/screens/subject_home_screen.dart';
import 'package:astuto/screens/tune_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/news/news_story_page.dart';

import '../test/explore/core_harness.dart';

const String _dir = String.fromEnvironment(
  'EDGE_DIR',
  defaultValue: 'tool/shots/edge',
);

/// The phone the owner holds: 390 by 844, its status bar and its home bar.
const Size _phone = Size(390, 844);
const double _status = 47;

Uri _out(String name) => Uri.file(File('$_dir/$name.png').absolute.path);

void _phoneOf(WidgetTester tester) {
  tester.view.physicalSize = _phone * 3;
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: _status * 3, bottom: 34 * 3);
  tester.view.viewPadding = tester.view.padding;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

Widget _app(Widget home, {Brightness brightness = Brightness.dark}) =>
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(brightness),
      debugShowCheckedModeBanner: false,
      home: home,
    );

/// [body] on an iPhone: the scrolling, the glass drawn by hand where the
/// system's is not there (as under this camera), as on the owner's phone.
Future<void> _onIPhone(Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

/// The page's own scrolling, the first that goes down.
ScrollPosition _page(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    )
    .position;

Future<void> _take(WidgetTester tester, String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile(_out(name)));

/// Where the page has to be for [what] to stand with its top at [y] on the
/// screen: the page is gone down until [what] has been built, which a list
/// built as it comes into view only does on the way.
Future<double> _offsetFor(WidgetTester tester, Finder what, double y) async {
  final ScrollPosition page = _page(tester);
  while (what.evaluate().isEmpty && page.pixels < page.maxScrollExtent) {
    page.jumpTo((page.pixels + 300).clamp(0, page.maxScrollExtent));
    await tester.pump(const Duration(milliseconds: 50));
  }
  final double at = tester.getTopLeft(what.first).dy;
  return (page.pixels + at - y).clamp(0, page.maxScrollExtent);
}

/// The way back, as a reader brings it: at the top, if [top]; forty points
/// under [back], gone; then a little way back up to [back], the way back on
/// its way 45 and 105 ms later, if [between], and back. [name] and [tag]
/// name each picture.
Future<void> _quickReturn(
  WidgetTester tester,
  String name,
  double back, {
  bool top = true,
  bool between = true,
  String tag = '',
}) async {
  final ScrollPosition page = _page(tester);
  if (page.pixels > 0) {
    page.jumpTo(0);
    await _settle(tester, 8);
  }
  if (top) await _take(tester, '$name-1-top');
  // Down to forty points under where it comes back, the page built on the
  // way: a list built as it comes into view only knows how far it goes once
  // it has been there.
  while (page.pixels < back + 40 - 0.5 && page.pixels < page.maxScrollExtent) {
    page.jumpTo(math.min(back + 40, page.maxScrollExtent));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await _settle(tester, 6);
  if (top) await _take(tester, '$name-2-down');
  page.jumpTo(back);
  await tester.pump();
  if (between) {
    await tester.pump(const Duration(milliseconds: 45));
    await _take(tester, '$name-3-coming$tag');
    await tester.pump(const Duration(milliseconds: 60));
    await _take(tester, '$name-4-coming$tag');
  }
  await _settle(tester, 6);
  await _take(tester, '$name-5-back$tag');
}

/// A reader one day in, as the owner's phone shows it: six cards read, three
/// answered without saying how sure; the week's headline is that the
/// journey starts here.
Map<String, Object> _journeyReader() {
  final List<Pill> read = PillBank.cards
      .where((p) => p.isGraded)
      .take(6)
      .toList();
  final String today = dateKey(DateTime.now());
  return {
    'knowit.plus': true,
    'knowit.seenIds': [for (final p in read) p.id],
    'knowit.judgements': jsonEncode([
      for (final p in read.take(3))
        {'c': null, 'k': true, 'p': p.id, 'd': today},
    ]),
  };
}

/// A theme deep enough for three parts.
CardPath _path() {
  for (final MapEntry<String, List<Genre>> s in kGenres.entries) {
    for (final Genre g in s.value) {
      final List<CardPath> parts = partsOf(g, s.key, PillBank.live);
      if (parts.length == kPathParts) return parts.first;
    }
  }
  throw StateError('no theme of thirty cards');
}

/// The lead story of the paper of 26 November 2026 (tool/news/paper.json, a
/// fixture), as Explore would open it.
Pill _story() {
  final Map<String, Object?> paper = jsonDecode(
    File('tool/news/paper.json').readAsStringSync(),
  ) as Map<String, Object?>;
  // ignore: invalid_use_of_visible_for_testing_member
  NewsPaper.reset();
  NewsPaper.clock = () => DateTime.utc(2026, 11, 26, 7, 30);
  NewsPaper.adopt(paper['date'] as String?, paper['cards']! as List<Object?>);
  return NewsPaper.front().first;
}

void main() {
  setUpAll(() async {
    await loadFonts();
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
  });

  testWidgets(
    'your journey',
    (tester) => _onIPhone(() async {
      _phoneOf(tester);
      final AppState app = await readyApp(_journeyReader());
      await tester.pumpWidget(_app(JourneyScreen(app: app, onBack: () {})));
      await _settle(tester);
      final Finder headline = find.byWidgetPredicate(
        (w) => '${w.key}'.contains('story-headline-'),
      );
      // The headline under the band, as in the owner's first screenshot.
      final double atHeadline = await _offsetFor(tester, headline, 88);
      await _quickReturn(tester, 'journey', atHeadline);
      // How you reason under it, as in the third.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app(JourneyScreen(app: app, onBack: () {})));
      await _settle(tester);
      final Finder reason = find.textContaining('HOW YOU REASON');
      final double atReason = await _offsetFor(tester, reason, 92);
      await _quickReturn(
        tester,
        'journey',
        atReason,
        top: false,
        between: false,
        tag: '-reason',
      );
    }),
  );

  testWidgets(
    'tune your mix',
    (tester) => _onIPhone(() async {
      _phoneOf(tester);
      final AppState app = await readyApp({'knowit.tuneHoldHint': true});
      await tester.pumpWidget(
        _app(TuneScreen(app: app, picked: app.pickedTopics)),
      );
      await _settle(tester, 16);
      // A row of parts under the band, as in the owner's second screenshot.
      final Finder chip = find.text('Look closer');
      final double atChip = await _offsetFor(tester, chip, 94);
      await _quickReturn(tester, 'tune', atChip);
    }),
  );

  testWidgets(
    'a subject\'s home',
    (tester) => _onIPhone(() async {
      _phoneOf(tester);
      final AppState app = await readyApp(_journeyReader());
      await tester.pumpWidget(
        _app(SubjectHomeScreen(app: app, topicKey: 'economics')),
      );
      await _settle(tester);
      await _quickReturn(tester, 'subject', 360);
    }),
  );

  testWidgets(
    'an area',
    (tester) => _onIPhone(() async {
      _phoneOf(tester);
      final AppState app = await readyApp(_journeyReader());
      await tester.pumpWidget(_app(AreaScreen(app: app, area: Goal.decide)));
      await _settle(tester);
      await _quickReturn(tester, 'area', 300);
    }),
  );

  testWidgets(
    'a path',
    (tester) => _onIPhone(() async {
      _phoneOf(tester);
      final AppState app = await readyApp(_journeyReader());
      await tester.pumpWidget(_app(CardPathScreen(app: app, path: _path())));
      await _settle(tester);
      await _quickReturn(tester, 'path', 330);
    }),
  );

  testWidgets(
    'a news story',
    (tester) => _onIPhone(() async {
      _phoneOf(tester);
      await tester.pumpWidget(_app(NewsStoryPage(pill: _story())));
      await _settle(tester);
      await _quickReturn(tester, 'news', 420);
      // ignore: invalid_use_of_visible_for_testing_member
      NewsPaper.reset();
    }),
  );

  // On paper, where there is paper (Tune your mix keeps its own dark): each
  // top, and the way back come back.
  testWidgets(
    'on paper',
    (tester) => _onIPhone(() async {
      _phoneOf(tester);
      final AppState app = await readyApp(_journeyReader());
      final Map<String, (Widget, double)> pages = {
        'journey': (JourneyScreen(app: app, onBack: () {}), 896),
        'subject': (SubjectHomeScreen(app: app, topicKey: 'economics'), 360),
        'area': (AreaScreen(app: app, area: Goal.decide), 300),
        'path': (CardPathScreen(app: app, path: _path()), 330),
        'news': (NewsStoryPage(pill: _story()), 420),
      };
      for (final MapEntry<String, (Widget, double)> page in pages.entries) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          _app(page.value.$1, brightness: Brightness.light),
        );
        await _settle(tester);
        await _take(tester, '${page.key}-1-top-light');
        await _quickReturn(
          tester,
          page.key,
          page.value.$2,
          top: false,
          between: false,
          tag: '-light',
        );
      }
      // ignore: invalid_use_of_visible_for_testing_member
      NewsPaper.reset();
    }),
  );
}
