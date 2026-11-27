// Photographs Explore's weekly schedule as the owner's iPhone shows it (390
// by 844 points, dark): the server's own document (remote/explore.json, as
// the build bundles it), a reader two weeks in on the free plan with
// today's five read, a path and a book started, and a morning's real paper
// (tool/news/paper.json, a fixture).
//
//   flutter test tool/explore_week_shots.dart --update-goldens
//
// Pages (the default): every weekday's whole page in one picture, two
// pixels a point, beside a JSON of where each section stands, measured from
// the widgets (WEEK_DAYS, 1 Monday to 7 Sunday, all by default;
// WEEK_SUBJECT for one subject's page, by its chip: Economics; WEEK_LOOK to
// draw the news in another look). WEEK_MODE=news: the latest news in each
// of its looks (WEEK_LOOKS), on a page three pixels a point and on one
// screen. A camera, not a check: it lives outside test/ so CI never runs
// it. The pictures land in tool/shots/explore-tour/week/, to be looked at
// and not kept.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/news_paper.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/explore/blocks/core/books_block.dart';
import 'package:astuto/explore/blocks/core/layout.dart';
import 'package:astuto/explore/blocks/core/paths_block.dart';
import 'package:astuto/explore/catalogue.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/widgets/explore/explore_engine.dart';
import 'package:astuto/widgets/web/card_thumb.dart';

import '../test/explore/core_harness.dart';

const String _mode = String.fromEnvironment('WEEK_MODE', defaultValue: 'pages');
const String _days = String.fromEnvironment(
  'WEEK_DAYS',
  defaultValue: '1,2,3,4,5,6,7',
);
const String _subject = String.fromEnvironment('WEEK_SUBJECT');
const String _looks = String.fromEnvironment(
  'WEEK_LOOKS',
  defaultValue: 'front,lead,pager',
);

/// The look the news is drawn in on the pages; none keeps the document's.
const String _pageLook = String.fromEnvironment('WEEK_LOOK');

/// The phone, 390 points wide unless WEEK_WIDTH says otherwise (375 for an
/// SE, 430 for a Pro Max); its language (WEEK_LANG, Italian by default) and
/// its light (WEEK_THEME=light for the day). WEEK_DIR is where the pictures
/// go, WEEK_TALL how tall a whole page is drawn.
const int _width = int.fromEnvironment('WEEK_WIDTH', defaultValue: 390);
final Size _phone = Size(_width.toDouble(), 844);
const EdgeInsets _insets = EdgeInsets.only(top: 47, bottom: 34);
const String _lang = String.fromEnvironment('WEEK_LANG', defaultValue: 'it');
const bool _light = String.fromEnvironment('WEEK_THEME') == 'light';
const String _dirGiven = String.fromEnvironment('WEEK_DIR');
const String _dir = _dirGiven == '' ? 'shots/explore-tour/week' : _dirGiven;
const int _tall = int.fromEnvironment('WEEK_TALL', defaultValue: 16000);

/// Half past eight in Rome on the paper's morning.
final DateTime _morning = DateTime.utc(2026, 11, 26, 7, 30);

final Map<String, ImageProvider> _pictures = {};
ImageProvider _picture(Uri url) {
  final List<String> path = url.pathSegments;
  final String rel = path.sublist(path.indexOf('cards') + 1).join('/');
  return _pictures.putIfAbsent(rel, () {
    final File file = File('web/cards/$rel');
    return MemoryImage(
      file.existsSync() ? file.readAsBytesSync() : Uint8List(0),
    );
  });
}

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

Future<void> _decodeShown(WidgetTester tester) async {
  final Set<ImageProvider> shown = {
    for (final Image image in tester.widgetList<Image>(find.byType(Image)))
      image.image,
  };
  if (shown.isEmpty) return;
  final BuildContext context = tester.element(find.byType(MaterialApp).first);
  await tester.runAsync(() async {
    for (final ImageProvider p in shown) {
      await precacheImage(
        p,
        context,
        onError: (_, _) {},
      ).timeout(const Duration(seconds: 10), onTimeout: () {});
    }
  });
  await _settle(tester, 5);
}

/// The morning's real paper, as the pipeline wrote it from that day's
/// reports.
void _paper() {
  final Map<String, Object?> paper = jsonDecode(
    File('tool/news/paper.json').readAsStringSync(),
  ) as Map<String, Object?>;
  // ignore: invalid_use_of_visible_for_testing_member
  NewsPaper.reset();
  NewsPaper.clock = () => _morning;
  NewsPaper.adopt(paper['date'] as String?, paper['cards']! as List<Object?>);
}

List<Pill> _drawn(String topic, int n, {int skip = 0}) => PillBank.cards
    .where((p) => p.topic == topic && CardThumb.has(p, CardSide.front))
    .skip(skip)
    .take(n)
    .toList();

/// A reader two weeks in on the free plan: a streak, today's five read, a
/// path and a book started, cards kept, liked and read, a city, answers
/// come back to be answered again.
Map<String, Object> _twoWeeksIn() {
  final List<Pill> saved = [
    ..._drawn('Space', 3),
    ..._drawn('History', 2),
    ..._drawn('Psychology', 2),
  ];
  final List<Pill> liked = [
    ..._drawn('Space', 4, skip: 3),
    ..._drawn('Art', 2),
  ];
  final List<Pill> due = PillBank.cards
      .where((p) => p.challenge is PickOne && p.topic == 'History')
      .take(4)
      .toList();
  final DateTime now = DateTime.now();
  final String yesterday = dateKey(now.subtract(const Duration(days: 1)));
  final List<Pill> five = [
    ..._drawn('Human body', 1, skip: 1),
    ..._drawn('Space', 1, skip: 20),
    ..._drawn('Psychology', 1, skip: 6),
    ..._drawn('Economics', 1, skip: 2),
    ..._drawn('History', 1, skip: 9),
  ];
  final List<CardPath> paths = pathsOf(PillBank.live, today: now, limit: 8);
  final CardPath? path = paths.length > 1 ? paths[1] : null;
  final List<CardBook> books = booksOf(PillBank.live, today: now);
  final CardBook? book = books.length > 2 ? books[2] : null;
  final int secs = now.millisecondsSinceEpoch ~/ 1000;
  return {
    'knowit.todayDate': dateKey(now),
    'knowit.todayDeckIds': [for (final p in five) p.id],
    'knowit.todayIndex': five.length,
    'knowit.lastCompletionDate': dateKey(now),
    if (path != null)
      'knowit.pathsOpened': [
        '${path.genre.id}|${path.topicKey}|${path.part}|${secs - 3600}',
      ],
    'knowit.onboarded': true,
    'knowit.pushAsked': true,
    'knowit.streak': 13,
    'knowit.installedOn': dateKey(now.subtract(const Duration(days: 14))),
    'knowit.completedDates': [
      for (var back = 13; back >= 0; back--)
        dateKey(now.subtract(Duration(days: back))),
    ],
    'knowit.savedIds': [for (final p in saved) p.id],
    'knowit.likedIds': [for (final p in liked) p.id],
    'knowit.seenIds': {
      for (final p in [...saved, ...liked, ...due]) p.id,
      ...PillBank.cards.skip(200).take(60).map((p) => p.id),
      for (final p in five) p.id,
      if (path != null)
        for (final p in path.cards.take(4)) p.id,
      if (book != null)
        for (final p in book.cards.take(2)) p.id,
    }.toList(),
    'knowit.topicWeights': jsonEncode({'space': 1.0, 'history': 0.8}),
    'knowit.place': jsonEncode({
      'country': 'IT',
      'region': 'IT-45',
      'city': 'Bologna',
      'lat': 44.494,
      'lon': 11.343,
    }),
    'knowit.answersJson': jsonEncode({
      for (int i = 0; i < due.length; i++)
        due[i].id: {'r': '0', 's': i.isEven ? 1 : 0, 'd': yesterday},
    }),
  };
}

/// The server's shelves for that reader, as the phone kept them.
ServedExplore _servedShelves() {
  List<ServedRank> ranked(List<Pill> cards) => [
    for (int i = 0; i < cards.length; i++) ServedRank(cards[i], 90 - i * 7),
  ];
  final List<Pill> today = [
    for (final String topic in kTopicOrder.map((k) => kTopics[k]!.name))
      ..._drawn(topic, 2, skip: 5),
  ];
  return ServedExplore(
    day: dateKey(DateTime.now()),
    today: today,
    asking: askingPills(seed: 'served-asking', count: 40),
    topWeek: ranked([
      ..._drawn('Psychology', 3, skip: 3),
      ..._drawn('Space', 3, skip: 8),
    ]),
    topMonth: ranked([..._drawn('History', 3, skip: 6), ..._drawn('Food', 3)]),
    loved: ranked([
      ..._drawn('Art', 3, skip: 2),
      ..._drawn('Music', 3),
      ..._drawn('Cinema', 2),
    ]),
    bySubject: const {},
    because: 'space',
    mine: _drawn('Space', 10, skip: 10),
    forYou: [..._drawn('Nature', 4, skip: 2), ..._drawn('Technology', 4)],
    local: PillBank.placeCards
        .where((p) => p.place?.city == 'Bologna')
        .toList(),
  );
}

/// The document the build bundles, its Explore as it is on [weekday] (1
/// Monday to 7 Sunday): a rule of weekdays is made true for that day and
/// false for the others. The news drawn in [look], when one is given.
void _adopt(int weekday, {String look = ''}) {
  final Map<String, Object?> parts = Map.of(Remote.embedded.parts);
  Object? fixed(Object? rule) {
    if (rule is Map) {
      return {
        for (final MapEntry<Object?, Object?> e in rule.entries)
          if (e.key == 'weekdays')
            'minBuild': (e.value as List).contains(weekday) ? 0 : 99999
          else
            '${e.key}': fixed(e.value),
      };
    }
    if (rule is List) return [for (final Object? r in rule) fixed(r)];
    return rule;
  }

  final Map<String, Object?> explore = Map.of(
    parts['explore']! as Map<String, Object?>,
  );
  explore['sections'] = [
    for (final Object? s in explore['sections']! as List)
      if (s is Map<String, Object?>)
        {
          ...s,
          if (s['audience'] != null) 'audience': fixed(s['audience']),
          if (s['id'] == 'news-today' && look.isNotEmpty) 'look': look,
        },
  ];
  parts['explore'] = explore;
  Remote.adopt(
    RemoteConfig(
      hash: 'week-$weekday-$look',
      schema: kRemoteSchema,
      parts: parts,
    ),
  );
}

/// The app on a phone [height] points tall at [ratio] pixels a point, on
/// Explore, narrowed to [subject] when there is one.
Future<void> _open(
  WidgetTester tester, {
  required double height,
  required double ratio,
  String subject = '',
}) async {
  final view = tester.view;
  view.physicalSize = Size(_phone.width, height) * ratio;
  view.devicePixelRatio = ratio;
  view.padding = FakeViewPadding(
    top: _insets.top * ratio,
    bottom: _insets.bottom * ratio,
  );
  view.viewPadding = view.padding;
  tester.platformDispatcher.localesTestValue = [const Locale(_lang)];
  tester.platformDispatcher.localeTestValue = const Locale(_lang);
  tester.platformDispatcher.platformBrightnessTestValue = _light
      ? Brightness.light
      : Brightness.dark;
  addTearDown(() {
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
    view.reset();
    tester.platformDispatcher.clearLocalesTestValue();
    tester.platformDispatcher.clearLocaleTestValue();
  });
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    ..._twoWeeksIn(),
    if (_light) 'knowit.theme': 'light',
  });
  // ignore: invalid_use_of_visible_for_testing_member
  Served.useForTest(
    Served(
      storeOverride: MemoryServedStore()..shelves = _servedShelves(),
      uidOverride: 'reader',
    ),
  );
  await tester.pumpWidget(const AstutoApp());
  await _settle(tester, 20);
  await tester.tap(find.byKey(const ValueKey('tab-Explore')).first);
  await _settle(tester, 20);
  if (subject.isNotEmpty) {
    await tester.tap(find.byKey(ValueKey('subject-$subject-off')));
    await _settle(tester, 20);
  }
}

/// Where each section the page drew stands, in points from the page's top:
/// its top under the room above it, and its height; and where the feed
/// starts.
Map<String, Object?> _measure(WidgetTester tester) {
  final List<Map<String, Object?>> out = [];
  for (final ExploreSection s in exploreSections(Remote.config)) {
    final Finder slot = find.byKey(ValueKey('section-${s.id}'));
    if (slot.evaluate().isEmpty) continue;
    final Rect r = tester.getRect(slot.first);
    final ExploreBlock? block = kExploreBlocks[s.block];
    if (block == null || r.height <= 0.5) continue;
    final double gap = sectionGap(s, block);
    out.add({
      'id': s.id,
      'block': s.block,
      'title': s.title(_lang),
      'top': r.top + gap,
      'height': r.height - gap,
    });
  }
  final Finder feed = find.byKey(const ValueKey('watch-feed'));
  final double? feedAt = feed.evaluate().isEmpty
      ? null
      : tester.getRect(feed.first).top;
  return {'sections': out, 'feedAt': feedAt};
}

Future<void> _take(WidgetTester tester, String name) async {
  await _decodeShown(tester);
  await expectLater(
    find.byType(MaterialApp).first,
    matchesGoldenFile('$_dir/$name.png'),
  );
}

void _write(String name, Object json) {
  final File file = File(
    _dir.startsWith('/') ? '$_dir/$name.json' : 'tool/$_dir/$name.json',
  );
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent(' ').convert(json));
}

void main() {
  setUpAll(() async {
    await loadFonts();
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
    Remote.build = 99;
    CardThumb.image = _picture;
  });

  if (_mode == 'pages') {
    for (final String d in _days.split(',')) {
      final int weekday = int.parse(d);
      final String name =
          '${_subject.isEmpty ? 'tutte' : _subject.toLowerCase()}-day$weekday';
      testWidgets('page $name', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        _paper();
        _adopt(weekday, look: _pageLook);
        await _open(
          tester,
          height: _tall.toDouble(),
          ratio: 2,
          subject: _subject,
        );
        _write(name, _measure(tester));
        await _take(tester, name);
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }

  if (_mode == 'news') {
    for (final String look in _looks.split(',')) {
      testWidgets('news $look on the page', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        _paper();
        _adopt(4, look: look);
        await _open(tester, height: 2600, ratio: 3);
        _write('news-$look-page', _measure(tester));
        await _take(tester, 'news-$look-page');
        debugDefaultTargetPlatformOverride = null;
      });

      testWidgets('news $look on a screen', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        _paper();
        _adopt(4, look: look);
        await _open(tester, height: _phone.height, ratio: 3);
        final Finder down = find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first;
        final Finder news = find.byKey(const ValueKey('section-news-today'));
        await tester.scrollUntilVisible(news, 300, scrollable: down);
        await _settle(tester);
        final ScrollableState list = tester.state(down);
        // The news a little under the status bar, as a thumb leaves it.
        final double top = tester.getRect(news).top + 24;
        list.position.jumpTo(
          (list.position.pixels + top - _insets.top - 8).clamp(
            0,
            list.position.maxScrollExtent,
          ),
        );
        await _settle(tester);
        await _take(tester, 'news-$look-screen');
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }
}
